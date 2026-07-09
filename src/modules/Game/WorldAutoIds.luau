--!strict

local CollectionService = game:GetService("CollectionService")

local WorldAutoIds = {}

export type EnsureSequentialIdsParams = {
	folder: Instance?,
	tagName: string,
	attributeName: string,
	formatId: (number) -> string,
	isValidId: (string) -> boolean,
	isCandidate: ((Model) -> boolean)?,
}

local function modelPosition(model: Model): Vector3
	return model:GetPivot().Position
end

local function modelOrder(a: Model, b: Model): boolean
	if a.Name ~= b.Name then
		return a.Name < b.Name
	end

	local aPosition = modelPosition(a)
	local bPosition = modelPosition(b)
	if aPosition.X ~= bPosition.X then
		return aPosition.X < bPosition.X
	elseif aPosition.Y ~= bPosition.Y then
		return aPosition.Y < bPosition.Y
	end
	return aPosition.Z < bPosition.Z
end

local function duplicatePreserveOrder(attributeName: string): (Model, Model) -> boolean
	return function(a: Model, b: Model): boolean
		local aId = a:GetAttribute(attributeName)
		local bId = b:GetAttribute(attributeName)
		local aNameMatchesId = typeof(aId) == "string" and a.Name == aId
		local bNameMatchesId = typeof(bId) == "string" and b.Name == bId

		if aNameMatchesId ~= bNameMatchesId then
			return aNameMatchesId
		end

		return modelOrder(a, b)
	end
end

local function collectCandidates(params: EnsureSequentialIdsParams): { Model }
	local folder = params.folder
	if not folder then
		return {}
	end

	local models = {}
	for _, child in folder:GetChildren() do
		if child:IsA("Model") and (not params.isCandidate or params.isCandidate(child)) then
			table.insert(models, child)
		end
	end

	table.sort(models, modelOrder)
	return models
end

function WorldAutoIds.ensureSequentialIds(params: EnsureSequentialIdsParams): { string }
	local models = collectCandidates(params)
	local byId: { [string]: { Model } } = {}
	local repairQueue: { Model } = {}

	for _, model in models do
		CollectionService:AddTag(model, params.tagName)

		local rawId = model:GetAttribute(params.attributeName)
		if typeof(rawId) == "string" and params.isValidId(rawId) then
			if not byId[rawId] then
				byId[rawId] = {}
			end
			table.insert(byId[rawId], model)
		else
			table.insert(repairQueue, model)
		end
	end

	local usedIds: { [string]: boolean } = {}
	for id, modelsWithId in byId do
		table.sort(modelsWithId, duplicatePreserveOrder(params.attributeName))
		usedIds[id] = true

		for index = 2, #modelsWithId do
			table.insert(repairQueue, modelsWithId[index])
		end
	end

	table.sort(repairQueue, modelOrder)

	local nextIndex = 1
	for _, model in repairQueue do
		local nextId = params.formatId(nextIndex)
		while usedIds[nextId] do
			nextIndex += 1
			nextId = params.formatId(nextIndex)
		end

		model:SetAttribute(params.attributeName, nextId)
		usedIds[nextId] = true
		nextIndex += 1
	end

	local ids = {}
	for _, model in models do
		local id = model:GetAttribute(params.attributeName)
		if typeof(id) == "string" and id ~= "" then
			table.insert(ids, id)
		end
	end

	table.sort(ids)
	return ids
end

return WorldAutoIds
