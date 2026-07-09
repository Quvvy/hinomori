--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GarageJamConfig = require(ReplicatedStorage.Shared.Modules.Game.GarageJamConfig)
local Logger = require(ReplicatedStorage.Shared.Modules.Core.Logger)

local GarageJamServiceClient = {}
GarageJamServiceClient.__index = GarageJamServiceClient

export type GarageJamServiceClient = typeof(setmetatable(
	{} :: {
		_boundPrompts: { [ProximityPrompt]: boolean },
		_stationPrompts: { [string]: ProximityPrompt },
		_playingStations: { [string]: Sound },
		_sessionStartedAt: number?,
	},
	GarageJamServiceClient
))

local function isAnyStationPlaying(playingStations: { [string]: Sound }): boolean
	for _, sound in playingStations do
		if sound.Playing then
			return true
		end
	end

	return false
end

function GarageJamServiceClient.Init(self: GarageJamServiceClient)
	self._boundPrompts = {}
	self._stationPrompts = {}
	self._playingStations = {}
	self._sessionStartedAt = nil
end

function GarageJamServiceClient.Start(self: GarageJamServiceClient)
	Logger.info("GarageJamServiceClient", "Started")
	self:_bindWhenGarageExists()
end

function GarageJamServiceClient._bindWhenGarageExists(self: GarageJamServiceClient)
	local root = GarageJamConfig.getWorldRoot()
	if root then
		self:_bindGarage(root)
		return
	end

	task.spawn(function()
		for _ = 1, 40 do
			task.wait(0.25)
			root = GarageJamConfig.getWorldRoot()
			if root then
				self:_bindGarage(root)
				return
			end
		end

		Logger.warn("GarageJamServiceClient", "GarageJam_001 not found; garage prompts are unavailable.")
	end)
end

function GarageJamServiceClient._bindGarage(self: GarageJamServiceClient, root: Model)
	for _, station in GarageJamConfig.STATIONS do
		self:_bindStation(root, station)
	end

	root.ChildAdded:Connect(function(child: Instance)
		if child:IsA("Model") then
			for _, station in GarageJamConfig.STATIONS do
				if station.modelName == child.Name then
					self:_bindStation(root, station)
					break
				end
			end
		end
	end)
end

function GarageJamServiceClient._bindStation(
	self: GarageJamServiceClient,
	root: Model,
	station: GarageJamConfig.GarageStationConfig
)
	local stationModel = root:FindFirstChild(station.modelName)
	if not stationModel or not stationModel:IsA("Model") then
		Logger.warn("GarageJamServiceClient", `Missing garage station model: {station.modelName}`)
		return
	end

	local promptPart = stationModel:FindFirstChild(GarageJamConfig.PROMPT_PART_NAME)
	if not promptPart or not promptPart:IsA("BasePart") then
		Logger.warn("GarageJamServiceClient", `Missing garage PromptPart for {station.modelName}`)
		return
	end

	local prompt = promptPart:FindFirstChildOfClass("ProximityPrompt")
	if not prompt or self._boundPrompts[prompt] then
		return
	end

	self._boundPrompts[prompt] = true
	self._stationPrompts[station.id] = prompt
	prompt:SetAttribute(GarageJamConfig.PROMPT_BOUND_ATTRIBUTE, true)
	prompt.Triggered:Connect(function()
		self:ToggleStation(station.id)
	end)
end

function GarageJamServiceClient.ToggleStation(self: GarageJamServiceClient, stationId: string)
	local station = GarageJamConfig.getStation(stationId)
	if not station then
		return
	end

	local existingSound = self._playingStations[stationId]
	if existingSound and existingSound.Playing then
		self:_stopStation(station)
	else
		self:_startStation(station)
	end
end

function GarageJamServiceClient._startStation(
	self: GarageJamServiceClient,
	station: GarageJamConfig.GarageStationConfig
)
	local sound = GarageJamConfig.resolvePath(station.soundPath)
	if not sound or not sound:IsA("Sound") then
		self:_setPromptMessage(station, `Missing stem: {station.displayName}`)
		Logger.warn("GarageJamServiceClient", `Missing Sound at {station.soundPath}`)
		return
	end

	if not self._sessionStartedAt or not isAnyStationPlaying(self._playingStations) then
		self._sessionStartedAt = os.clock()
	end

	sound.Looped = true
	sound.Volume = math.max(sound.Volume, 0.5)
	sound.TimePosition = self:_alignedTimePosition(sound)
	self._playingStations[station.id] = sound
	self:_setPromptAction(station, true)
	sound:Play()
end

function GarageJamServiceClient._stopStation(self: GarageJamServiceClient, station: GarageJamConfig.GarageStationConfig)
	local sound = self._playingStations[station.id]
	if sound then
		sound:Stop()
		sound.TimePosition = 0
		self._playingStations[station.id] = nil
	end

	self:_setPromptAction(station, false)

	if not isAnyStationPlaying(self._playingStations) then
		self._sessionStartedAt = nil
	end
end

function GarageJamServiceClient._alignedTimePosition(self: GarageJamServiceClient, sound: Sound): number
	if not self._sessionStartedAt then
		return 0
	end

	local timeLength = sound.TimeLength
	if timeLength <= 0 then
		return 0
	end

	return (os.clock() - self._sessionStartedAt) % timeLength
end

function GarageJamServiceClient._setPromptMessage(
	self: GarageJamServiceClient,
	station: GarageJamConfig.GarageStationConfig,
	message: string
)
	local prompt = self._stationPrompts[station.id]
	if prompt then
		prompt.ObjectText = message
	end
end

function GarageJamServiceClient._defaultPromptObjectText(
	_self: GarageJamServiceClient,
	station: GarageJamConfig.GarageStationConfig
): string
	return if station.credit then `{station.displayName} - {station.credit}` else station.displayName
end

function GarageJamServiceClient._setPromptAction(
	self: GarageJamServiceClient,
	station: GarageJamConfig.GarageStationConfig,
	isPlaying: boolean
)
	local prompt = self._stationPrompts[station.id]
	if not prompt then
		return
	end

	if isPlaying then
		prompt.ActionText = `Leave {station.displayName}`
		prompt.ObjectText = station.joinText
		return
	end

	prompt.ActionText = `Join {station.displayName}`
	prompt.ObjectText = station.leaveText

	task.delay(1.2, function()
		if prompt.Parent and prompt.ActionText == `Join {station.displayName}` then
			prompt.ObjectText = self:_defaultPromptObjectText(station)
		end
	end)
end

return setmetatable({} :: GarageJamServiceClient, GarageJamServiceClient)
