--!strict

export type NoteTemplate = {
	id: string,
	text: string,
}

local templates: { NoteTemplate } = {
	{ id = "nice_locker", text = "Nice locker!" },
	{ id = "after_school", text = "See you after school?" },
	{ id = "cute_umbrella", text = "Your umbrella is cute." },
	{ id = "good_luck", text = "Good luck on the test!" },
	{ id = "arcade_later", text = "Want to play arcade later?" },
}

local byId: { [string]: NoteTemplate } = {}
for _, template in templates do
	byId[template.id] = template
end

local NoteTemplates = {}

function NoteTemplates.getAll(): { NoteTemplate }
	return templates
end

function NoteTemplates.get(templateId: string): NoteTemplate?
	return byId[templateId]
end

function NoteTemplates.isValid(templateId: string): boolean
	return byId[templateId] ~= nil
end

return NoteTemplates
