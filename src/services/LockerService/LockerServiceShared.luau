--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LockerConfig = require(ReplicatedStorage.Shared.Modules.Game.LockerConfig)

return {
	ATTRIBUTE_LOCKER_ID = LockerConfig.ATTRIBUTE_LOCKER_ID,
	ATTRIBUTE_INTERACT_DISTANCE = LockerConfig.ATTRIBUTE_INTERACT_DISTANCE,
	SLOT_IDS = LockerConfig.SLOT_IDS,
}
