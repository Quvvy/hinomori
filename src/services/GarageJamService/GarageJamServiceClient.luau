--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GarageJamConfig = require(ReplicatedStorage.Shared.Modules.Game.GarageJamConfig)
local GarageSkillCatalog = require(ReplicatedStorage.Shared.Modules.Game.GarageSkillCatalog)
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
		_skillMenuModule: any?,
		_rhythmModule: any?,
		_boundPrompts: { [ProximityPrompt]: boolean },
		_stationPrompts: { [string]: ProximityPrompt },
		_playingStations: { [string]: Sound },
		_skillDuckedVolumes: { [Sound]: number },
		_warnedMissing: { [string]: boolean },
		_currentState: GarageState?,
		_activeSkillStationId: string?,
		_missAudioCleanup: (() -> ())?,
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
	self._skillDuckedVolumes = {}
	self._warnedMissing = {}
	self._currentState = nil
	self._activeSkillStationId = nil
	self._missAudioCleanup = nil
	self._syncLoopRunning = false
	self._retryBindingStarted = false
	self._garageChildWatcherBound = false
end

function GarageJamServiceClient.Start(self: GarageJamServiceClient)
	Logger.info("GarageJamServiceClient", "Started")

	local ui = ReplicatedStorage:WaitForChild("UI")
	self._menuModule = require(ui.Menus.GarageBoardMenu)
	self._skillMenuModule = require(ui.Menus.GarageSkillMenu)
	self._rhythmModule = require(ui.Menus.RhythmGame)
	self._menuModule.mount({
		enterPractice = function()
			return self:EnterPractice()
		end,
	})
	self._skillMenuModule.mount({
		playPart = function()
			self:StartSkillRun()
		end,
		leave = function()
			self:LeaveStation()
		end,
	})

	self:_bindWhenGarageExists()
	Players.LocalPlayer.CharacterAdded:Connect(function()
		self:_stopSkillRun(false)
	end)
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

	self:_stopSkillRun(false)
	return self._networker:fetch("leaveStation") == true
end

function GarageJamServiceClient.garageStateUpdated(self: GarageJamServiceClient, state: GarageState)
	self._currentState = state
	if self._activeSkillStationId and state.activeStationId ~= self._activeSkillStationId then
		self:_stopSkillRun(false)
	end
	self:_updatePrompts()
	self:_updateStemPlayback()
	self:_updateSkillMenu()
end

function GarageJamServiceClient.StartSkillRun(self: GarageJamServiceClient): boolean
	local state = self._currentState
	local stationId = state and state.activeStationId
	if not stationId then
		self:_showToast("Join an instrument first.")
		return false
	end

	local station = GarageJamConfig.getStation(stationId)
	local chart = GarageSkillCatalog.getForStation(stationId)
	if not station or not chart then
		self:_showToast("No practice part yet.")
		return false
	end

	if chart.soundKey ~= stationId then
		self:_warnOnce(chart.id .. ":soundKey", `Garage chart {chart.id} soundKey does not match {stationId}.`)
		self:_showToast("Practice part is miswired.")
		return false
	end

	local sourceSound = GarageJamConfig.getSoundForKey(chart.soundKey)
	if not sourceSound then
		self:_warnOnce(chart.soundKey .. ":skillSound", `Missing garage skill Sound for {chart.soundKey}.`)
		self:_showToast("Practice audio is missing.")
		return false
	end

	if self._activeSkillStationId then
		self:_stopSkillRun(false)
	end

	self._activeSkillStationId = stationId
	self:_updateSkillMenu()

	local song = table.clone(chart) :: any
	song.workspaceSoundName = sourceSound.Name
	song.soundId = sourceSound.SoundId

	if not self._rhythmModule then
		self:_showToast("Practice runner is unavailable.")
		self:_stopSkillRun()
		return false
	end

	self._rhythmModule.start(
		{
			matchId = `garage_{stationId}`,
			mode = station.displayName,
		},
		song,
		function(result: { [string]: any })
			self:_finishSkillRun(chart, result)
		end,
		{
			missAudioFeedback = self:_makeMissAudioFeedback(),
			onStop = function()
				if self._activeSkillStationId == stationId then
					self._activeSkillStationId = nil
					self:_cleanupSkillAudio()
					self:_updateSkillMenu()
				end
			end,
		}
	)
	self:_applySkillDucking(stationId)

	return true
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

	if self._activeSkillStationId then
		self:_applySkillDucking(self._activeSkillStationId)
	end
	self:_startSyncLoopIfNeeded()
end

function GarageJamServiceClient._updateSkillMenu(self: GarageJamServiceClient)
	if not self._skillMenuModule then
		return
	end

	local state = self._currentState
	local activeStationId = state and state.activeStationId
	if not activeStationId then
		self._skillMenuModule.close()
		return
	end

	local station = GarageJamConfig.getStation(activeStationId)
	if not station then
		self._skillMenuModule.close()
		return
	end

	local chart = GarageSkillCatalog.getForStation(activeStationId)
	local summary = if chart then GarageSkillCatalog.getSummary(chart.id) else nil
	self._skillMenuModule.update(
		activeStationId,
		station.displayName,
		summary,
		self._activeSkillStationId == activeStationId
	)
end

function GarageJamServiceClient._finishSkillRun(self: GarageJamServiceClient, chart: any, result: { [string]: any })
	if self._activeSkillStationId ~= chart.stationId then
		return
	end

	self._activeSkillStationId = nil
	self:_cleanupSkillAudio()
	self:_updateSkillMenu()

	local accuracy = math.floor((tonumber(result.accuracy) or 0) * 1000) / 10
	self:_showToast(`{chart.resultText} {accuracy}%`)
end

function GarageJamServiceClient._stopSkillRun(self: GarageJamServiceClient, updateMenu: boolean?)
	if not self._activeSkillStationId then
		self:_cleanupSkillAudio()
		if updateMenu ~= false then
			self:_updateSkillMenu()
		end
		return
	end

	self._activeSkillStationId = nil
	if self._rhythmModule then
		self._rhythmModule.stop()
	end
	self:_cleanupSkillAudio()
	if updateMenu ~= false then
		self:_updateSkillMenu()
	end
end

function GarageJamServiceClient._applySkillDucking(self: GarageJamServiceClient, activeStationId: string)
	for _, station in GarageJamConfig.STATIONS do
		local sound = self._playingStations[station.id]
		if sound then
			if self._skillDuckedVolumes[sound] == nil then
				self._skillDuckedVolumes[sound] = sound.Volume
			end

			local originalVolume = self._skillDuckedVolumes[sound]
			sound.Volume = if station.id == activeStationId then 0 else math.max(originalVolume * 0.35, 0.08)
		end
	end
end

function GarageJamServiceClient._cleanupSkillAudio(self: GarageJamServiceClient)
	for sound, volume in self._skillDuckedVolumes do
		if sound.Parent then
			sound.Volume = volume
		end
	end
	table.clear(self._skillDuckedVolumes)

	local missAudioCleanup = self._missAudioCleanup
	self._missAudioCleanup = nil
	if missAudioCleanup then
		missAudioCleanup()
	end
end

function GarageJamServiceClient._makeMissAudioFeedback(self: GarageJamServiceClient): { [string]: (Sound) -> () }
	local originalVolume: number? = nil
	local activeSound: Sound? = nil
	local restoreToken = 0
	local cleanedUp = false

	local function restore(sound: Sound?)
		if cleanedUp and not sound then
			return
		end

		local targetSound = sound or activeSound
		if targetSound and originalVolume ~= nil and targetSound.Parent then
			targetSound.Volume = originalVolume
		end
	end

	local function cleanup()
		if cleanedUp then
			return
		end

		cleanedUp = true
		restore(activeSound)
	end

	self._missAudioCleanup = cleanup

	return {
		onMiss = function(sound: Sound)
			if cleanedUp then
				return
			end

			activeSound = sound
			if originalVolume == nil then
				originalVolume = sound.Volume
			end

			restoreToken += 1
			local token = restoreToken
			sound.Volume = math.max((originalVolume :: number) * 0.18, 0.05)
			task.delay(0.45, function()
				if not cleanedUp and token == restoreToken then
					restore(sound)
				end
			end)
		end,
		onRecover = function(sound: Sound)
			if cleanedUp then
				return
			end

			restoreToken += 1
			restore(sound)
		end,
		onCleanup = function(sound: Sound)
			activeSound = sound
			cleanup()
		end,
	}
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
