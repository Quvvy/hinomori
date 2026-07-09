--!strict

local PlayerUtil = {}

function PlayerUtil.getDisplayName(player: Player): string
	return player.DisplayName
end

return PlayerUtil
