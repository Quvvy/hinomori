--!strict

local RhythmMapParser = require(script.Parent.RhythmMapParser)

local GarageSkillCharts = script.Parent.GarageSkillCharts

local GarageSkillCatalog = {}

export type GarageSkillChart = {
	id: string,
	stationId: string,
	soundKey: string,
	displayName: string,
	artist: string,
	difficulty: string,
	laneCount: number,
	resultText: string,
	mapText: string,
}

export type GarageSkillSummary = {
	id: string,
	stationId: string,
	soundKey: string,
	displayName: string,
	artist: string,
	difficulty: string,
	laneCount: number,
	noteCount: number,
	durationSeconds: number,
	resultText: string,
	warnings: { string },
}

local CHARTS: { GarageSkillChart } = {
	require(GarageSkillCharts.TeenageDirtbagDrumsPractice),
	require(GarageSkillCharts.TeenageDirtbagBassPractice),
	require(GarageSkillCharts.TeenageDirtbagGuitarPractice),
	require(GarageSkillCharts.TeenageDirtbagVoicePractice),
}

local chartById: { [string]: GarageSkillChart } = {}
local chartByStationId: { [string]: GarageSkillChart } = {}

for _, chart in CHARTS do
	assert(chartById[chart.id] == nil, `Duplicate garage skill chart id: {chart.id}`)
	assert(chartByStationId[chart.stationId] == nil, `Duplicate garage skill station chart: {chart.stationId}`)
	chartById[chart.id] = chart
	chartByStationId[chart.stationId] = chart
end

function GarageSkillCatalog.get(chartId: string?): GarageSkillChart?
	if not chartId or chartId == "" then
		return nil
	end

	return chartById[chartId]
end

function GarageSkillCatalog.getForStation(stationId: string?): GarageSkillChart?
	if not stationId or stationId == "" then
		return nil
	end

	return chartByStationId[stationId]
end

function GarageSkillCatalog.getAll(): { GarageSkillChart }
	return CHARTS
end

function GarageSkillCatalog.getSummary(chartId: string): GarageSkillSummary?
	local chart = GarageSkillCatalog.get(chartId)
	if not chart then
		return nil
	end

	local parsed = RhythmMapParser.parse(chart.mapText)
	return {
		id = chart.id,
		stationId = chart.stationId,
		soundKey = chart.soundKey,
		displayName = chart.displayName,
		artist = chart.artist,
		difficulty = chart.difficulty,
		laneCount = parsed.laneCount,
		noteCount = #parsed.notes,
		durationSeconds = parsed.durationMs / 1000,
		resultText = chart.resultText,
		warnings = parsed.warnings,
	}
end

function GarageSkillCatalog.validateAll(): { { chartId: string, warning: string } }
	local warnings = {}
	for _, chart in CHARTS do
		local parsed = RhythmMapParser.parse(chart.mapText)
		if #parsed.notes == 0 then
			table.insert(warnings, {
				chartId = chart.id,
				warning = "Chart has no notes.",
			})
		end

		for _, warning in parsed.warnings do
			table.insert(warnings, {
				chartId = chart.id,
				warning = warning,
			})
		end
	end
	return warnings
end

return GarageSkillCatalog
