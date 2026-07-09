--!strict

export type GarageStationConfig = {
	id: string,
	displayName: string,
	credit: string?,
	modelName: string,
	soundPath: string,
	joinText: string,
	leaveText: string,
}

local GarageJamConfig = {
	WORLD_PATH = { "World", "Garage", "GarageJam_001" },
	PROMPT_PART_NAME = "PromptPart",
	PROMPT_BOUND_ATTRIBUTE = "HinomoriGarageJamBound",
}

GarageJamConfig.STATIONS = {
	{
		id = "drums",
		displayName = "Drums",
		credit = "Peter Brown",
		modelName = "DrumsStation",
		soundPath = "Workspace.Wheatus-Teenage Dirtbag-drums-05-29-2026",
		joinText = "Joined drums - Peter Brown.",
		leaveText = "Left drums.",
	},
	{
		id = "bass",
		displayName = "Bass",
		modelName = "BassStation",
		soundPath = "Workspace.Wheatus-Teenage Dirtbag-bass-05-29-2026",
		joinText = "Joined bass.",
		leaveText = "Left bass.",
	},
	{
		id = "guitar",
		displayName = "Guitar",
		modelName = "GuitarStation",
		soundPath = "Workspace.Wheatus-Teenage Dirtbag-guitar-05-29-2026",
		joinText = "Joined guitar.",
		leaveText = "Left guitar.",
	},
	{
		id = "voice",
		displayName = "Voice",
		modelName = "VoiceStation",
		soundPath = "Workspace.Wheatus-Teenage Dirtbag-voice-05-29-2026",
		joinText = "Joined voice.",
		leaveText = "Left voice.",
	},
} :: { GarageStationConfig }

function GarageJamConfig.getWorldRoot(): Model?
	local current: Instance = workspace
	for _, pathPart in GarageJamConfig.WORLD_PATH do
		local child = current:FindFirstChild(pathPart)
		if not child then
			return nil
		end
		current = child
	end

	return if current:IsA("Model") then current else nil
end

function GarageJamConfig.getStation(stationId: string): GarageStationConfig?
	for _, station in GarageJamConfig.STATIONS do
		if station.id == stationId then
			return station
		end
	end

	return nil
end

function GarageJamConfig.resolvePath(path: string): Instance?
	local current: Instance = game
	for part in string.gmatch(path, "[^%.]+") do
		if part == "game" then
			current = game
		else
			local child = current:FindFirstChild(part)
			if not child then
				return nil
			end
			current = child
		end
	end

	return current
end

return GarageJamConfig
