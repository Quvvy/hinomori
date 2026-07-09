--!strict

local ArcadeConfig = {
	WORLD_PATH = { "World", "Arcade" },
	CABINET_MODEL_NAME = "CabinetPair_001",
	CABINET_ID = "CabinetPair_001",
	ATTRIBUTE_CABINET_ID = "CabinetId",
	ATTRIBUTE_INTERACT_DISTANCE = "InteractDistance",
	DEFAULT_INTERACT_DISTANCE = 14,

	SOLO_TICKET_REWARD = 1,
	DUEL_TICKET_REWARD = 2,
	LOCKER_REWARD_ITEM_ID = "arcade_token_sticker",

	STUB_SONGS = {
		{ id = "cicada_steps_easy", displayName = "Cicada Steps", difficulty = "Easy" },
		{ id = "rainy_platform_medium", displayName = "Rainy Platform", difficulty = "Medium" },
	},
}

function ArcadeConfig.getWorldRoot(): Instance?
	local current: Instance = workspace
	for _, pathPart in ArcadeConfig.WORLD_PATH do
		local child = current:FindFirstChild(pathPart)
		if not child then
			return nil
		end
		current = child
	end
	return current
end

return ArcadeConfig
