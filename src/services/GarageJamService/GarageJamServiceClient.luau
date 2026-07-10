--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GarageJamConfig = require(ReplicatedStorage.Shared.Modules.Game.GarageJamConfig)
local Logger = require(ReplicatedStorage.Shared.Modules.Core.Logger)
local Networker = require(ReplicatedStorage.Packages.Networker)

type GarageState = {
	practiceReady: boolean?,
	stationOccupants: { [string]: { userId: number, displayName: string } }?,
	activeStationId: string?,
	activeStationByUserId: { [number]: string }?,
	jamStartedAtServerTime: number?,
}

local GarageJamServiceClient = {}
GarageJamServiceClient.__index = GarageJamServiceClient

export type GarageJamServiceClient = typeof(setmetatable(
	{} :: {
		_networker: Networker.Client?,
		_menuModule: any?,
		_boundPrompts: { [ProximityPrompt]: boolean },
		_stationPrompts: { [string]: ProximityPrompt },
		_playingStations: { [string]: Sound },
		_warnedMissing: { [string]: boolean },
		_currentState: GarageState?,
		_syncLoopRunning: boolean,
		_retryBindingStarted: boolean,
		_garageChildWatcherBound: boolean,
	},
	GarageJamServiceClient
))

local function stationOccupant(state: GarageState?, stationId: string): { userId: number, displayName: string }?
	local occupants = state and state.stationOccupants
	if not occupants then
		return nil
	end

	return occupants[stationId]
end

function GarageJamServiceClient.Init(self: GarageJamServiceClient)
	self._networker = Networker.client.new("GarageJamService", self)
	self._boundPrompts = {}
	self._stationPrompts = {}
	self._playingStations = {}
	self._warnedMissing = {}
	self._currentState = nil
	self._syncLoopRunning = false
	self._retryBindingStarted = false
	self._garageChildWatcherBound = false
end

function GarageJamServiceClient.Start(self: GarageJamServiceClient)
	Logger.info("GarageJamServiceClient", "Started")

	local ui = ReplicatedStorage:WaitForChild("UI")
	self._menuModule = require(ui.Menus.GarageBoardMenu)
	self._menuModule.mount({
		enterPractice = function()
			return self:EnterPractice()
		end,
	})

	self:_bindWhenGarageExists()
	self:FetchState()
end

function GarageJamServiceClient.FetchState(self: GarageJamServiceClient): GarageState?
	if not self._networker then
		return nil
	end

	local state = self._networker:fetch("requestGarageState")
	if typeof(state) ~= "table" then
		return nil
	end

	self:garageStateUpdated(state :: GarageState)
	return state :: GarageState
end

function GarageJamServiceClient.EnterPractice(self: GarageJamServiceClient): boolean
	if not self._networker then
		return false
	end

	local ok = self._networker:fetch("enterPractice") == true
	if ok then
		self:FetchState()
	end
	return ok
end

function GarageJamServiceClient.JoinStation(self: GarageJamServiceClient, stationId: string): boolean
	if not self._networker then
		return false
	end

	local ok = self._networker:fetch("joinStation", stationId) == true
	if not ok then
		self:_showToast("That station is unavailable.")
	end
	return ok
end

function GarageJamServiceClient.LeaveStation(self: GarageJamServiceClient): boolean
	if not self._networker then
		return false
	end

	return self._networker:fetch("leaveStation") == true
end

function GarageJamServiceClient.garageStateUpdated(self: GarageJamServiceClient, state: GarageState)
	self._currentState = state
	self:_updatePrompts()
	self:_updateStemPlayback()
end

function GarageJamServiceClient._bindWhenGarageExists(self: GarageJamServiceClient)
	local root = GarageJamConfig.getWorldRoot()
	if root then
		self:_bindGarage(root)
		self:_startStationBindingRetry()
		return
	end

	task.spawn(function()
		for _ = 1, 40 do
			task.wait(0.25)
			root = GarageJamConfig.getWorldRoot()
			if root then
				self:_bindGarage(root)
				self:_startStationBindingRetry()
				return
			end
		end

		self:_warnOnce("garageRoot", "GarageJam_001 not found; garage prompts are unavailable.")
	end)
end

function GarageJamServiceClient._bindGarage(self: GarageJamServiceClient, root: Model)
	for _, station in GarageJamConfig.STATIONS do
		self:_bindStation(station)
	end

	if self._garageChildWatcherBound then
		return
	end

	self._garageChildWatcherBound = true
	root.ChildAdded:Connect(function(child: Instance)
		if child:IsA("Model") then
			for _, station in GarageJamConfig.STATIONS do
				if station.modelName == child.Name then
					self:_bindStation(station)
					break
				end
			end
		end
	end)
end

function GarageJamServiceClient._startStationBindingRetry(self: GarageJamServiceClient)
	if self._retryBindingStarted then
		return
	end

	self._retryBindingStarted = true
	task.spawn(function()
		for _ = 1, 40 do
			local allBound = true
			for _, station in GarageJamConfig.STATIONS do
				if not self._stationPrompts[station.id] then
					allBound = false
					self:_bindStation(station)
				end
			end

			self:_updatePrompts()
			if allBound then
				self._retryBindingStarted = false
				return
			end

			task.wait(0.25)
		end

		self._retryBindingStarted = false
	end)
end

function GarageJamServiceClient._bindStation(self: GarageJamServiceClient, station: GarageJamConfig.GarageStationConfig)
	local promptPart = GarageJamConfig.getStationPromptPart(station)
	if not promptPart then
		self:_warnOnce(station.id .. ":promptPart", `Missing garage PromptPart for {station.modelName}`)
		return
	end

	local prompt = promptPart:FindFirstChildOfClass("ProximityPrompt")
	if not prompt then
		self:_warnOnce(station.id .. ":prompt", `Missing garage ProximityPrompt for {station.modelName}`)
		return
	end

	if self._boundPrompts[prompt] then
		return
	end

	self._boundPrompts[prompt] = true
	self._stationPrompts[station.id] = prompt
	prompt:SetAttribute(GarageJamConfig.PROMPT_BOUND_ATTRIBUTE, true)
	prompt.Triggered:Connect(function()
		self:_handleStationPrompt(station.id)
	end)
	self:_updateStationPrompt(station)
end

function GarageJamServiceClient._handleStationPrompt(self: GarageJamServiceClient, stationId: string)
	local state = self._currentState
	if not state or not state.practiceReady then
		self:_showToast("Check the rehearsal board first.")
		return
	end

	if state.activeStationId == stationId then
		self:LeaveStation()
		return
	end

	if state.activeStationId then
		self:_showToast("Leave your instrument first.")
		return
	end

	local occupant = stationOccupant(state, stationId)
	if occupant and occupant.userId ~= Players.LocalPlayer.UserId then
		self:_showToast(`{occupant.displayName} is using that.`)
		return
	end

	self:JoinStation(stationId)
end

function GarageJamServiceClient._updatePrompts(self: GarageJamServiceClient)
	for _, station in GarageJamConfig.STATIONS do
		self:_updateStationPrompt(station)
	end
end

function GarageJamServiceClient._updateStationPrompt(
	self: GarageJamServiceClient,
	station: GarageJamConfig.GarageStationConfig
)
	local prompt = self._stationPrompts[station.id]
	if not prompt then
		return
	end

	local state = self._currentState
	if not state or not state.practiceReady then
		prompt.Enabled = false
		prompt.ActionText = "Practice first"
		prompt.ObjectText = "Check the rehearsal board."
		return
	end

	local activeStationId = state.activeStationId
	if activeStationId == station.id then
		prompt.Enabled = true
		prompt.ActionText = `Leave {station.displayName}`
		prompt.ObjectText = station.joinText
		return
	end

	if activeStationId then
		prompt.Enabled = false
		prompt.ActionText = "Leave first"
		prompt.ObjectText = "Leave your instrument first."
		return
	end

	local occupant = stationOccupant(state, station.id)
	if occupant then
		prompt.Enabled = true
		prompt.ActionText = "Occupied"
		prompt.ObjectText = `{occupant.displayName} is on {station.displayName}.`
		return
	end

	prompt.Enabled = true
	prompt.ActionText = `Join {station.displayName}`
	prompt.ObjectText = self:_defaultPromptObjectText(station)
end

function GarageJamServiceClient._updateStemPlayback(self: GarageJamServiceClient)
	local state = self._currentState
	local occupants = state and state.stationOccupants or {}

	for _, station in GarageJamConfig.STATIONS do
		if occupants[station.id] then
			self:_playStation(station)
		else
			self:_stopStation(station)
		end
	end

	self:_startSyncLoopIfNeeded()
end

function GarageJamServiceClient._playStation(self: GarageJamServiceClient, station: GarageJamConfig.GarageStationConfig)
	local sound = GarageJamConfig.resolvePath(station.soundPath)
	if not sound or not sound:IsA("Sound") then
		self:_warnOnce(station.id .. ":sound", `Missing garage stem Sound at {station.soundPath}`)
		return
	end

	sound.Looped = true
	sound.Volume = math.max(sound.Volume, 0.5)
	self._playingStations[station.id] = sound
	self:_alignSoundToJamClock(station, sound, not sound.Playing)

	if not sound.Playing then
		sound:Play()
	end
end

function GarageJamServiceClient._stopStation(self: GarageJamServiceClient, station: GarageJamConfig.GarageStationConfig)
	local sound = self._playingStations[station.id]
	if not sound then
		return
	end

	sound:Stop()
	sound.TimePosition = 0
	self._playingStations[station.id] = nil
end

function GarageJamServiceClient._alignSoundToJamClock(
	self: GarageJamServiceClient,
	station: GarageJamConfig.GarageStationConfig,
	sound: Sound,
	force: boolean
)
	local state = self._currentState
	local jamStartedAtServerTime = state and state.jamStartedAtServerTime
	if not jamStartedAtServerTime then
		self:_warnOnce("jamClock", "Garage jam clock missing; starting stem without shared alignment.")
		return
	end

	local timeLength = sound.TimeLength
	if timeLength <= 0 then
		self:_warnOnce(
			station.id .. ":timeLength",
			`Garage stem TimeLength unavailable for {station.displayName}; alignment deferred.`
		)
		return
	end

	local elapsed = math.max(workspace:GetServerTimeNow() - jamStartedAtServerTime, 0)
	local targetPosition = elapsed % timeLength
	if force or math.abs(sound.TimePosition - targetPosition) > 0.35 then
		sound.TimePosition = targetPosition
	end
end

function GarageJamServiceClient._startSyncLoopIfNeeded(self: GarageJamServiceClient)
	if self._syncLoopRunning or not next(self._playingStations) then
		return
	end

	self._syncLoopRunning = true
	task.spawn(function()
		while next(self._playingStations) do
			for _, station in GarageJamConfig.STATIONS do
				local sound = self._playingStations[station.id]
				if sound then
					self:_alignSoundToJamClock(station, sound, false)
				end
			end
			task.wait(2)
		end

		self._syncLoopRunning = false
	end)
end

function GarageJamServiceClient._defaultPromptObjectText(
	_self: GarageJamServiceClient,
	station: GarageJamConfig.GarageStationConfig
): string
	return if station.credit then `{station.displayName} - {station.credit}` else station.displayName
end

function GarageJamServiceClient._showToast(self: GarageJamServiceClient, message: string)
	if self._menuModule and type(self._menuModule.showToast) == "function" then
		self._menuModule.showToast(message)
	end
end

function GarageJamServiceClient._warnOnce(self: GarageJamServiceClient, key: string, message: string)
	if self._warnedMissing[key] then
		return
	end

	self._warnedMissing[key] = true
	Logger.warn("GarageJamServiceClient", message)
end

return setmetatable({} :: GarageJamServiceClient, GarageJamServiceClient)
