--!strict

local LockerConfig = {
	WORLD_PATH = { "World", "School", "LockerHallway", "Lockers" },
	LOCKER_ID_PREFIX = "Locker_",
	LOCKER_TAG = "HinomoriLocker",
	SLOT_IDS = { "Slot_01", "Slot_02", "Slot_03" },
	ATTRIBUTE_LOCKER_ID = "LockerId",
	ATTRIBUTE_INTERACT_DISTANCE = "InteractDistance",
	DEFAULT_INTERACT_DISTANCE = 10,
	DECOR_COOLDOWN_SECONDS = 0.5,
}

function LockerConfig.formatLockerId(index: number): string
	return `{LockerConfig.LOCKER_ID_PREFIX}{string.format("%03d", index)}`
end

function LockerConfig.isValidSlotId(slotId: string): boolean
	for _, id in LockerConfig.SLOT_IDS do
		if id == slotId then
			return true
		end
	end
	return false
end

function LockerConfig.isValidLockerId(lockerId: string): boolean
	if not string.match(lockerId, "^Locker_%d%d%d$") then
		return false
	end
	local numberPart = tonumber(string.sub(lockerId, 8))
	return numberPart ~= nil and numberPart >= 1
end

return LockerConfig
