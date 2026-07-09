--!strict

export type HandOffItem = {
	id: string,
	displayName: string,
	kind: string,
	color: Color3,
}

local items: { HandOffItem } = {
	{
		id = "rice_cracker",
		displayName = "Rice Cracker",
		kind = "Snack",
		color = Color3.fromRGB(239, 214, 153),
	},
	{
		id = "melon_bread",
		displayName = "Melon Bread",
		kind = "Snack",
		color = Color3.fromRGB(173, 220, 132),
	},
	{
		id = "strawberry_milk",
		displayName = "Strawberry Milk",
		kind = "Snack",
		color = Color3.fromRGB(244, 156, 184),
	},
}

local byId: { [string]: HandOffItem } = {}
for _, item in items do
	byId[item.id] = item
end

local HandOffCatalog = {}

function HandOffCatalog.getAll(): { HandOffItem }
	return items
end

function HandOffCatalog.get(itemId: string): HandOffItem?
	return byId[itemId]
end

function HandOffCatalog.isValid(itemId: string): boolean
	return byId[itemId] ~= nil
end

return HandOffCatalog
