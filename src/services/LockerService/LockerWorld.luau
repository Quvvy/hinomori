--!strict

-- Shared locker world helpers (client + server can require from ReplicatedStorage).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LockerConfig = require(ReplicatedStorage.Shared.Modules.Game.LockerConfig)
local WorldAutoIds = require(ReplicatedStorage.Shared.Modules.Game.WorldAutoIds)

local LockerWorld = {}

local function getLockersFolder(): Instance?
	local workspace = game:GetService("Workspace")
	local current: Instance = workspace

	for _, segment in LockerConfig.WORLD_PATH do
		local child = current:FindFirstChild(segment)
		if not child then
			return nil
		end
		current = child
	end

	return current
end

function LockerWorld.getLockersFolder(): Instance?
	return getLockersFolder()
end

function LockerWorld.findLockerById(lockerId: string): Model?
	local lockersFolder = getLockersFolder()
	if not lockersFolder then
		return nil
	end

	for _, child in lockersFolder:GetChildren() do
		if
			child:IsA("Model")
			and LockerWorld.isLockerCandidate(child)
			and child:GetAttribute(LockerConfig.ATTRIBUTE_LOCKER_ID) == lockerId
		then
			return child
		end
	end

	return nil
end

function LockerWorld.getPromptPart(lockerModel: Model): BasePart?
	local promptPart = lockerModel:FindFirstChild("PromptPart")
	if promptPart and promptPart:IsA("BasePart") then
		return promptPart
	end
	return nil
end

function LockerWorld.getDecorSlotsFolder(lockerModel: Model): Folder?
	local decorSlots = lockerModel:FindFirstChild("DecorSlots")
	if decorSlots and decorSlots:IsA("Folder") then
		return decorSlots
	end
	return nil
end

function LockerWorld.getDecorSlotPart(lockerModel: Model, slotId: string): BasePart?
	local decorSlots = LockerWorld.getDecorSlotsFolder(lockerModel)
	if not decorSlots then
		return nil
	end

	local slotPart = decorSlots:FindFirstChild(slotId)
	if slotPart and slotPart:IsA("BasePart") then
		return slotPart
	end

	return nil
end

function LockerWorld.isLockerCandidate(lockerModel: Model): boolean
	return LockerWorld.getPromptPart(lockerModel) ~= nil and LockerWorld.getDecorSlotsFolder(lockerModel) ~= nil
end

function LockerWorld.ensureLockerIds(): { string }
	return WorldAutoIds.ensureSequentialIds({
		folder = getLockersFolder(),
		tagName = LockerConfig.LOCKER_TAG,
		attributeName = LockerConfig.ATTRIBUTE_LOCKER_ID,
		formatId = LockerConfig.formatLockerId,
		isValidId = LockerConfig.isValidLockerId,
		isCandidate = LockerWorld.isLockerCandidate,
	})
end

function LockerWorld.getLockerIds(): { string }
	local lockerIds = {}
	LockerWorld.iterateLockers(function(_lockerModel: Model, lockerId: string)
		table.insert(lockerIds, lockerId)
	end)
	table.sort(lockerIds)
	return lockerIds
end

function LockerWorld.isKnownLockerId(lockerId: string): boolean
	return LockerConfig.isValidLockerId(lockerId) and LockerWorld.findLockerById(lockerId) ~= nil
end

function LockerWorld.iterateLockers(callback: (Model, string) -> ())
	local lockersFolder = getLockersFolder()
	if not lockersFolder then
		return
	end

	for _, child in lockersFolder:GetChildren() do
		if child:IsA("Model") then
			local lockerId = child:GetAttribute(LockerConfig.ATTRIBUTE_LOCKER_ID)
			if
				typeof(lockerId) == "string"
				and lockerId ~= ""
				and LockerConfig.isValidLockerId(lockerId)
				and LockerWorld.isLockerCandidate(child)
			then
				callback(child, lockerId)
			end
		end
	end
end

return LockerWorld
