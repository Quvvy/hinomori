--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DeskWorld = require(ReplicatedStorage.Shared.Modules.Game.DeskWorld)

local DeskVisuals = {}

local VISUAL_NAME = "DeskAssignmentLabel"

local function clearExisting(deskModel: Model)
	local labelPart = DeskWorld.getLabelPart(deskModel)
	if not labelPart then
		return
	end

	local existing = labelPart:FindFirstChild(VISUAL_NAME)
	if existing then
		existing:Destroy()
	end
end

function DeskVisuals.applyAssignments(_assignments: { any }, _localUserId: number)
	local desksFolder = DeskWorld.getDesksFolder()
	if desksFolder then
		for _, child in desksFolder:GetChildren() do
			if child:IsA("Model") then
				clearExisting(child)
			end
		end
	end
end

return DeskVisuals
