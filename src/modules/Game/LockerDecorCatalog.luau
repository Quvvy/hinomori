--!strict

export type DecorItem = {
	id: string,
	displayName: string,
	slotType: string,
	color: Color3,
}

local LockerDecorCatalog: { [string]: DecorItem } = {
	spring_sticker = {
		id = "spring_sticker",
		displayName = "Spring Sticker",
		slotType = "sticker",
		color = Color3.fromRGB(144, 198, 149),
	},
	arcade_token_sticker = {
		id = "arcade_token_sticker",
		displayName = "Arcade Token",
		slotType = "sticker",
		color = Color3.fromRGB(255, 214, 102),
	},
	stationery_label = {
		id = "stationery_label",
		displayName = "Stationery Label",
		slotType = "label",
		color = Color3.fromRGB(196, 168, 214),
	},
}

local orderedIds = { "spring_sticker", "arcade_token_sticker", "stationery_label" }

local LockerDecorCatalogModule = {}

function LockerDecorCatalogModule.get(itemId: string): DecorItem?
	return LockerDecorCatalog[itemId]
end

function LockerDecorCatalogModule.isValid(itemId: string): boolean
	return LockerDecorCatalog[itemId] ~= nil
end

function LockerDecorCatalogModule.getStarterItems(): { DecorItem }
	local items: { DecorItem } = {}
	for _, id in orderedIds do
		local item = LockerDecorCatalog[id]
		if item then
			table.insert(items, item)
		end
	end
	return items
end

return LockerDecorCatalogModule
