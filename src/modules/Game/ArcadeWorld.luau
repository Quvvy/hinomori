--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ArcadeConfig = require(ReplicatedStorage.Shared.Modules.Game.ArcadeConfig)
local Validate = require(ReplicatedStorage.Shared.Modules.Core.Validate)

local ArcadeWorld = {}

function ArcadeWorld.getArcadeRoot(): Instance?
	return ArcadeConfig.getWorldRoot()
end

function ArcadeWorld.getCabinetModel(): Model?
	local arcadeRoot = ArcadeWorld.getArcadeRoot()
	if not arcadeRoot then
		return nil
	end

	local cabinet = arcadeRoot:FindFirstChild(ArcadeConfig.CABINET_MODEL_NAME)
	if cabinet and cabinet:IsA("Model") then
		return cabinet
	end

	return nil
end

function ArcadeWorld.getPromptPart(): BasePart?
	local cabinet = ArcadeWorld.getCabinetModel()
	if not cabinet then
		return nil
	end

	local promptPart = cabinet:FindFirstChild("PromptPart")
	if promptPart and promptPart:IsA("BasePart") then
		return promptPart
	end

	return nil
end

function ArcadeWorld.getInteractDistance(): number
	local cabinet = ArcadeWorld.getCabinetModel()
	if cabinet then
		local attribute = cabinet:GetAttribute(ArcadeConfig.ATTRIBUTE_INTERACT_DISTANCE)
		if typeof(attribute) == "number" then
			return attribute
		end
	end

	return ArcadeConfig.DEFAULT_INTERACT_DISTANCE
end

function ArcadeWorld.isNearCabinet(player: Player): boolean
	local promptPart = ArcadeWorld.getPromptPart()
	if not promptPart then
		return false
	end

	return Validate.isWithinDistance(player, promptPart.Position, ArcadeWorld.getInteractDistance())
end

return ArcadeWorld
