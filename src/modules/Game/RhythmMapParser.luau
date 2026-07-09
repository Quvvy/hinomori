--!strict

local RhythmScoring = require(script.Parent.RhythmScoring)

local RhythmMapParser = {}

export type RhythmNote = {
	timeMs: number,
	lane: number,
	holdMs: number,
}

export type ParsedMap = {
	metadata: { [string]: string },
	laneCount: number,
	offsetMs: number,
	durationMs: number,
	notes: { RhythmNote },
	warnings: { string },
}

local function trim(text: string): string
	return (string.gsub(text, "^%s*(.-)%s*$", "%1"))
end

local function stripComment(text: string): string
	local hashIndex = string.find(text, "#", 1, true)
	if hashIndex then
		text = string.sub(text, 1, hashIndex - 1)
	end

	local slashIndex = string.find(text, "//", 1, true)
	if slashIndex then
		text = string.sub(text, 1, slashIndex - 1)
	end

	return trim(text)
end

local function splitTokens(text: string): { string }
	local tokens = {}
	for token in string.gmatch(text, "[^,%s|;]+") do
		table.insert(tokens, token)
	end
	return tokens
end

local function readNumber(value: string?): number?
	if not value then
		return nil
	end

	return tonumber(trim(value))
end

function RhythmMapParser.parse(mapText: string): ParsedMap
	local metadata: { [string]: string } = {}
	local notes: { RhythmNote } = {}
	local warnings: { string } = {}
	local laneCount = RhythmScoring.LANE_COUNT
	local offsetMs = 0
	local inNotesSection = false

	for lineNumber, rawLine in string.split(mapText, "\n") do
		local line = stripComment(rawLine)
		if line == "" then
			continue
		end

		if string.sub(line, 1, 1) == "[" and string.sub(line, -1) == "]" then
			local sectionName = string.lower(trim(string.sub(line, 2, -2)))
			inNotesSection = sectionName == "notes" or sectionName == "hitobjects"
			continue
		end

		local key, value = string.match(line, "^([%w_%-]+)%s*=%s*(.+)$")
		if key and value and not inNotesSection then
			local normalizedKey = string.lower(trim(key))
			metadata[normalizedKey] = trim(value)
			if normalizedKey == "lanes" or normalizedKey == "keys" then
				laneCount = math.clamp(math.floor(tonumber(value) or laneCount), 1, 8)
			elseif normalizedKey == "offset" or normalizedKey == "offsetms" then
				offsetMs = tonumber(value) or 0
			end
			continue
		end

		local tokens = splitTokens(line)
		local timeMs = readNumber(tokens[1])
		local lane = readNumber(tokens[2])
		local holdMs = readNumber(tokens[3]) or 0

		if not timeMs or not lane then
			table.insert(warnings, `Line {lineNumber}: expected note as timeMs,lane[,holdMs].`)
			continue
		end

		lane = math.floor(lane)
		if lane < 1 or lane > laneCount then
			table.insert(warnings, `Line {lineNumber}: lane {lane} is outside 1-{laneCount}.`)
			continue
		end

		table.insert(notes, {
			timeMs = math.max(0, timeMs),
			lane = lane,
			holdMs = math.max(0, holdMs),
		})
	end

	table.sort(notes, function(a, b)
		if a.timeMs == b.timeMs then
			return a.lane < b.lane
		end
		return a.timeMs < b.timeMs
	end)

	local durationMs = 0
	for _, note in notes do
		note.timeMs = math.max(0, note.timeMs + offsetMs)
		durationMs = math.max(durationMs, note.timeMs + note.holdMs)
	end

	return {
		metadata = metadata,
		laneCount = laneCount,
		offsetMs = offsetMs,
		durationMs = durationMs,
		notes = notes,
		warnings = warnings,
	}
end

return RhythmMapParser
