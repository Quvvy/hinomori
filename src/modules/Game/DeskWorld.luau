--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DeskConfig = require(ReplicatedStorage.Shared.Modules.Game.DeskConfig)
local WorldAutoIds = require(ReplicatedStorage.Shared.Modules.Game.WorldAutoIds)

local DeskWorld = {}

function DeskWorld.getDesksFolder(): Instance?
	local current: Instance = workspace
	for _, pathPart in DeskConfig.WORLD_PATH do
		local child = current:FindFirstChild(pathPart)
		if not child then
			return nil
		end
		current = child
	end
	return current
end

function DeskWorld.findDeskById(deskId: string): Model?
	local desksFolder = DeskWorld.getDesksFolder()
	if not desksFolder then
		return nil
	end

	for _, child in desksFolder:GetChildren() do
		if child:IsA("Model") and child:GetAttribute(DeskConfig.ATTRIBUTE_DESK_ID) == deskId then
			return child
		end
	end

	local direct = desksFolder:FindFirstChild(deskId)
	if direct and direct:IsA("Model") then
		return direct
	end

	return nil
end

function DeskWorld.ensureDeskIds(): { string }
	return WorldAutoIds.ensureSequentialIds({
		folder = DeskWorld.getDesksFolder(),
		tagName = DeskConfig.DESK_TAG,
		attributeName = DeskConfig.ATTRIBUTE_DESK_ID,
		formatId = DeskConfig.formatDeskId,
		isValidId = DeskConfig.isValidDeskId,
	})
end

function DeskWorld.getLabelPart(deskModel: Model): BasePart?
	local labelPart = deskModel:FindFirstChild("LabelPart")
	if labelPart and labelPart:IsA("BasePart") then
		return labelPart
	end

	local seat = deskModel:FindFirstChild("Seat")
	if seat and seat:IsA("BasePart") then
		return seat
	end

	return deskModel.PrimaryPart
end

return DeskWorld
