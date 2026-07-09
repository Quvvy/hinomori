--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local LockerConfig = require(ReplicatedStorage.Shared.Modules.Game.LockerConfig)
local LockerWorld = require(ReplicatedStorage.Shared.Services.LockerService.LockerWorld)

-- Studio multi-client tests often desync client prompt vs server character position.
local STUDIO_SERVER_DISTANCE_TOLERANCE = 4

local LockerValidate = {}

function LockerValidate.getLockerWorldPosition(lockerId: string): Vector3?
	local lockerModel = LockerWorld.findLockerById(lockerId)
	if not lockerModel then
		return nil
	end

	local promptPart = LockerWorld.getPromptPart(lockerModel)
	if promptPart then
		return promptPart.Position
	end

	if lockerModel.PrimaryPart then
		return lockerModel.PrimaryPart.Position
	end

	return nil
end

function LockerValidate.getInteractDistance(lockerId: string): number
	local lockerModel = LockerWorld.findLockerById(lockerId)
	if not lockerModel then
		return LockerConfig.DEFAULT_INTERACT_DISTANCE
	end

	local distance = lockerModel:GetAttribute(LockerConfig.ATTRIBUTE_INTERACT_DISTANCE)
	if typeof(distance) == "number" then
		return distance
	end

	return LockerConfig.DEFAULT_INTERACT_DISTANCE
end

function LockerValidate.getPlayerLockerDistance(player: Player, lockerId: string): number?
	local position = LockerValidate.getLockerWorldPosition(lockerId)
	if not position then
		return nil
	end

	local character = player.Character
	if not character then
		return nil
	end

	local root = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root then
		return nil
	end

	return (root.Position - position).Magnitude
end

function LockerValidate.isNearLocker(player: Player, lockerId: string): boolean
	local distance = LockerValidate.getPlayerLockerDistance(player, lockerId)
	if distance == nil then
		return false
	end

	local maxDistance = LockerValidate.getInteractDistance(lockerId)
	if RunService:IsStudio() and RunService:IsServer() then
		maxDistance += STUDIO_SERVER_DISTANCE_TOLERANCE
	end

	return distance <= maxDistance
end

return LockerValidate
