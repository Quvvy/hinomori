--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local DataServiceServer = require(ServerScriptService.Services.DataService.DataServiceServer)
local DeskWorld = require(ReplicatedStorage.Shared.Modules.Game.DeskWorld)
local Logger = require(ReplicatedStorage.Shared.Modules.Core.Logger)
local Networker = require(ReplicatedStorage.Packages.Networker)
local SessionServiceShared = require(ReplicatedStorage.Shared.Services.SessionService.SessionServiceShared)
local Validate = require(ReplicatedStorage.Shared.Modules.Core.Validate)

local SessionServiceServer = {}
SessionServiceServer.__index = SessionServiceServer

export type SessionServiceServer = typeof(setmetatable(
	{} :: {
		_networker: Networker.Server?,
		_phase: SessionServiceShared.SessionPhase,
		_dayKey: string,
		_firstDayProgress: { [number]: { [string]: boolean } },
	},
	SessionServiceServer
))

local instance: SessionServiceServer? = nil

local function isValidPhase(phase: string): boolean
	return phase == SessionServiceShared.PHASE_BUS_PROLOGUE
		or phase == SessionServiceShared.PHASE_SCHOOL
		or phase == SessionServiceShared.PHASE_AFTER_SCHOOL
end

local function getTodayKey(): string
	return os.date("%Y-%m-%d")
end

local function isValidFirstDayStep(stepId: string): boolean
	for _, knownStepId in SessionServiceShared.FIRST_DAY_STEPS do
		if stepId == knownStepId then
			return true
		end
	end
	return false
end

local function copyProgress(progress: { [string]: boolean }): { [string]: boolean }
	local result = {}
	for _, stepId in SessionServiceShared.FIRST_DAY_STEPS do
		result[stepId] = progress[stepId] == true
	end
	return result
end

function SessionServiceServer.Init(self: SessionServiceServer)
	self._phase = SessionServiceShared.DEFAULT_PHASE
	self._dayKey = getTodayKey()
	self._firstDayProgress = {}
	self._networker = Networker.server.new("SessionService", self, {
		self.getSessionPhase,
		self.getInGameDayKey,
		self.requestSessionState,
		self.advancePhase,
		self.setSessionPhase,
	})
	instance = self
end

function SessionServiceServer.Start(self: SessionServiceServer)
	Logger.info("SessionService", "Started")
	DeskWorld.ensureDeskIds()

	local desksFolder = DeskWorld.getDesksFolder()
	if desksFolder then
		desksFolder.ChildAdded:Connect(function(child)
			if child:IsA("Model") then
				task.defer(function()
					DeskWorld.ensureDeskIds()
				end)
			end
		end)
	end

	local function onPlayerAdded(player: Player)
		self:_sendState(player)
		task.spawn(function()
			self:_syncProfileBackedFirstDayState(player)
		end)
	end

	for _, player in Players:GetPlayers() do
		onPlayerAdded(player)
	end

	Players.PlayerAdded:Connect(onPlayerAdded)
	Players.PlayerRemoving:Connect(function(player: Player)
		self._firstDayProgress[player.UserId] = nil
	end)
end

function SessionServiceServer.GetInstance(): SessionServiceServer?
	return instance
end

function SessionServiceServer.getSessionPhase(self: SessionServiceServer, _player: Player): string
	return self._phase
end

function SessionServiceServer.getInGameDayKey(self: SessionServiceServer, _player: Player): string
	return self._dayKey
end

function SessionServiceServer._syncProfileBackedFirstDayState(self: SessionServiceServer, player: Player)
	for _ = 1, 50 do
		if not player.Parent then
			return
		end

		local profile = DataServiceServer:GetProfile(player)
		if profile then
			self:_progressForPlayer(player)
			self:_sendState(player)
			return
		end

		task.wait(0.1)
	end
end

function SessionServiceServer.requestSessionState(self: SessionServiceServer, player: Player): { [string]: any }?
	return self:_stateForPlayer(player)
end

function SessionServiceServer.advancePhase(self: SessionServiceServer, player: Player): { [string]: any }?
	if not Validate.isPlayerAlive(player) then
		return nil
	end

	if self._phase == SessionServiceShared.PHASE_BUS_PROLOGUE then
		self:_setPhase(SessionServiceShared.PHASE_SCHOOL)
	elseif self._phase == SessionServiceShared.PHASE_SCHOOL then
		self:_setPhase(SessionServiceShared.PHASE_AFTER_SCHOOL)
	else
		self:_setPhase(SessionServiceShared.PHASE_BUS_PROLOGUE)
	end

	return self:_stateForPlayer(player)
end

function SessionServiceServer.setSessionPhase(
	self: SessionServiceServer,
	player: Player,
	phase: string
): { [string]: any }?
	if not Validate.isPlayerAlive(player) or not isValidPhase(phase) then
		return nil
	end

	self:_setPhase(phase :: SessionServiceShared.SessionPhase)

	return self:_stateForPlayer(player)
end

function SessionServiceServer._setPhase(self: SessionServiceServer, phase: SessionServiceShared.SessionPhase)
	self._phase = phase
	self._dayKey = getTodayKey()

	if phase == SessionServiceShared.PHASE_AFTER_SCHOOL then
		for _, player in Players:GetPlayers() do
			self:_markFirstDayStep(player, SessionServiceShared.FIRST_DAY_STEP_REACHED_AFTER_SCHOOL, false)
		end
	end

	self:_broadcastState()
end

function SessionServiceServer.MarkFirstDayStep(
	self: SessionServiceServer,
	player: Player,
	stepId: SessionServiceShared.FirstDayStep
)
	self:_markFirstDayStep(player, stepId, true)
end

function SessionServiceServer._markFirstDayStep(
	self: SessionServiceServer,
	player: Player,
	stepId: SessionServiceShared.FirstDayStep,
	shouldSendState: boolean
)
	if not isValidFirstDayStep(stepId) then
		return
	end

	local progress = self:_progressForPlayer(player)
	if progress[stepId] then
		return
	end

	progress[stepId] = true
	if shouldSendState then
		self:_sendState(player)
	end
end

function SessionServiceServer._progressForPlayer(self: SessionServiceServer, player: Player): { [string]: boolean }
	local progress = self._firstDayProgress[player.UserId]
	if not progress then
		progress = {}
		self._firstDayProgress[player.UserId] = progress
	end

	local profile = DataServiceServer:GetProfile(player)
	if profile and profile.studentProfile.hasCompletedTransferSetup() then
		progress[SessionServiceShared.FIRST_DAY_STEP_NAMED_SELF] = true
	end

	if self._phase == SessionServiceShared.PHASE_AFTER_SCHOOL then
		progress[SessionServiceShared.FIRST_DAY_STEP_REACHED_AFTER_SCHOOL] = true
	end

	return progress
end

function SessionServiceServer._nextFirstDayStep(self: SessionServiceServer, player: Player): string?
	local progress = self:_progressForPlayer(player)
	for _, stepId in SessionServiceShared.FIRST_DAY_STEPS do
		if not progress[stepId] then
			return stepId
		end
	end
	return nil
end

function SessionServiceServer._stateForPlayer(self: SessionServiceServer, player: Player): { [string]: any }
	local progress = self:_progressForPlayer(player)
	return {
		phase = self._phase,
		dayKey = self._dayKey,
		firstDayProgress = copyProgress(progress),
		nextFirstDayStep = self:_nextFirstDayStep(player),
	}
end

function SessionServiceServer._sendState(self: SessionServiceServer, player: Player)
	if self._networker then
		self._networker:fire(player, "sessionStateChanged", self:_stateForPlayer(player))
	end
end

function SessionServiceServer._broadcastState(self: SessionServiceServer)
	if not self._networker then
		return
	end

	for _, player in Players:GetPlayers() do
		self._networker:fire(player, "sessionStateChanged", self:_stateForPlayer(player))
	end
end

return setmetatable({} :: SessionServiceServer, SessionServiceServer)
