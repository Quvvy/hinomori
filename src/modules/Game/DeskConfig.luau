--!strict

local DeskConfig = {
	WORLD_PATH = { "World", "School", "Classroom", "Desks" },
	DESK_ID_PREFIX = "Desk_",
	DESK_TAG = "HinomoriDesk",
	ATTRIBUTE_DESK_ID = "DeskId",
}

function DeskConfig.formatDeskId(index: number): string
	return `{DeskConfig.DESK_ID_PREFIX}{string.format("%02d", index)}`
end

function DeskConfig.isValidDeskId(deskId: string): boolean
	if not string.match(deskId, "^Desk_%d%d$") then
		return false
	end
	local numberPart = tonumber(string.sub(deskId, 6))
	return numberPart ~= nil and numberPart >= 1
end

return DeskConfig
