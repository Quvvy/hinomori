--!strict

local RhythmMapParser = require(script.Parent.RhythmMapParser)

local RhythmSongs = script.Parent.RhythmSongs

local RhythmSongCatalog = {}

export type RhythmSong = {
	id: string,
	displayName: string,
	artist: string,
	difficulty: string,
	laneCount: number,
	workspaceSoundName: string?,
	soundId: string,
	mapText: string,
}

export type RhythmSongSummary = {
	id: string,
	displayName: string,
	artist: string,
	difficulty: string,
	laneCount: number,
	noteCount: number,
	durationSeconds: number,
	warnings: { string },
}

RhythmSongCatalog.DEFAULT_SONG_ID = "life_in_an_elevator_easy"

local SONGS: { RhythmSong } = {
	require(RhythmSongs.LifeInAnElevatorEasy),
	require(RhythmSongs.LifeInAnElevatorMedium),
	require(RhythmSongs.CamelliaFlamewallTest),
}

local songById: { [string]: RhythmSong } = {}
for _, song in SONGS do
	assert(songById[song.id] == nil, `Duplicate rhythm song id: {song.id}`)
	songById[song.id] = song
end

function RhythmSongCatalog.get(songId: string?): RhythmSong?
	if not songId or songId == "" then
		return songById[RhythmSongCatalog.DEFAULT_SONG_ID]
	end

	return songById[songId]
end

function RhythmSongCatalog.isValid(songId: string?): boolean
	return RhythmSongCatalog.get(songId) ~= nil
end

function RhythmSongCatalog.getDefault(): RhythmSong
	return songById[RhythmSongCatalog.DEFAULT_SONG_ID]
end

function RhythmSongCatalog.getAll(): { RhythmSong }
	return SONGS
end

function RhythmSongCatalog.parseSong(songId: string): RhythmMapParser.ParsedMap?
	local song = RhythmSongCatalog.get(songId)
	if not song then
		return nil
	end

	return RhythmMapParser.parse(song.mapText)
end

function RhythmSongCatalog.getSummary(songId: string): RhythmSongSummary?
	local song = RhythmSongCatalog.get(songId)
	if not song then
		return nil
	end

	local parsed = RhythmMapParser.parse(song.mapText)
	return {
		id = song.id,
		displayName = song.displayName,
		artist = song.artist,
		difficulty = song.difficulty,
		laneCount = parsed.laneCount,
		noteCount = #parsed.notes,
		durationSeconds = parsed.durationMs / 1000,
		warnings = parsed.warnings,
	}
end

function RhythmSongCatalog.getSummaries(): { RhythmSongSummary }
	local summaries = {}
	for _, song in SONGS do
		local summary = RhythmSongCatalog.getSummary(song.id)
		if summary then
			table.insert(summaries, summary)
		end
	end
	return summaries
end

function RhythmSongCatalog.validateAll(): { { songId: string, warning: string } }
	local warnings = {}
	for _, song in SONGS do
		local parsed = RhythmMapParser.parse(song.mapText)
		if #parsed.notes == 0 then
			table.insert(warnings, {
				songId = song.id,
				warning = "Song has no notes.",
			})
		end

		for _, warning in parsed.warnings do
			table.insert(warnings, {
				songId = song.id,
				warning = warning,
			})
		end
	end
	return warnings
end

return RhythmSongCatalog
