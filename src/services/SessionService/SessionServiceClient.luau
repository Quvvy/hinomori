--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Logger = require(ReplicatedStorage.Shared.Modules.Core.Logger)
local Networker = require(ReplicatedStorage.Packages.Networker)

local SessionServiceClient = {}
SessionServiceClient.__index = SessionServiceClient

local BOOTSTRAP_FETCH_ATTEMPTS = 40
local BOOTSTRAP_RETRY_SECONDS = 0.25

export type SessionServiceClient = typeof(setmetatable(
	{} :: {
		_networker: Networker.Client?,
		_menuModule: any?,
		_guideModule: any?,
		_currentState: { [string]: any }?,
	},
	SessionServiceClient
))

function SessionServiceClient.Init(self: SessionServiceClient)
	self._networker = Networker.client.new("SessionService", self)
end

function SessionServiceClient.Start(self: SessionServiceClient)
	Logger.info("SessionServiceClient", "Started")

	local ui = ReplicatedStorage:WaitForChild("UI")
	self._menuModule = require(ui.Menus.SessionFlowMenu)
	self._guideModule = require(ui.Menus.FirstDayGuide)
	self._menuModule.mount({
		refresh = function()
			return self:_applyRequestedState(
				self:FetchState(),
				"Session server is not ready yet. Restart Play, then press Refresh."
			)
		end,
		advancePhase = function()
			return self:_applyRequestedState(
				self:AdvancePhase(),
				"Cannot change the day phase until your character finishes joining."
			)
		end,
		setPhase = function(phase: string)
			return self:_applyRequestedState(
				self:SetPhase(phase),
				"Cannot change the day phase until your character finishes joining."
			)
		end,
	})
	self._guideModule.mount()

	task.spawn(function()
		self:_bootstrapState()
	end)
end

function SessionServiceClient.sessionStateChanged(self: SessionServiceClient, state: { [string]: any })
	self:_applyState(state)
end

function SessionServiceClient.GetPhase(self: SessionServiceClient): string?
	local state = self:FetchState()
	return if state then state.phase else nil
end

function SessionServiceClient.FetchState(self: SessionServiceClient): { [string]: any }?
	if not self._networker then
		return nil
	end

	local ok, state = pcall(function()
		return self._networker:fetch("requestSessionState")
	end)
	if not ok then
		Logger.warn("SessionServiceClient", `requestSessionState failed: {tostring(state)}`)
		return nil
	end

	return state
end

function SessionServiceClient.AdvancePhase(self: SessionServiceClient): { [string]: any }?
	if not self._networker then
		return nil
	end

	local ok, state = pcall(function()
		return self._networker:fetch("advancePhase")
	end)
	if not ok then
		Logger.warn("SessionServiceClient", `advancePhase failed: {tostring(state)}`)
		return nil
	end

	return state
end

function SessionServiceClient.SetPhase(self: SessionServiceClient, phase: string): { [string]: any }?
	if not self._networker then
		return nil
	end

	local ok, state = pcall(function()
		return self._networker:fetch("setSessionPhase", phase)
	end)
	if not ok then
		Logger.warn("SessionServiceClient", `setSessionPhase failed: {tostring(state)}`)
		return nil
	end

	return state
end

function SessionServiceClient._applyState(self: SessionServiceClient, state: { [string]: any })
	self._currentState = state

	if self._menuModule then
		self._menuModule.updateState(state)
	end

	if self._guideModule then
		self._guideModule.updateState(state)
	end
end

function SessionServiceClient._applyRequestedState(
	self: SessionServiceClient,
	state: { [string]: any }?,
	failureMessage: string
): { [string]: any }?
	if state then
		self:_applyState(state)
	elseif self._menuModule then
		self._menuModule.showStatus(failureMessage)
	end

	return state
end

function SessionServiceClient._bootstrapState(self: SessionServiceClient)
	for _ = 1, BOOTSTRAP_FETCH_ATTEMPTS do
		local state = self:FetchState()
		if state then
			self:_applyState(state)
			return
		end

		task.wait(BOOTSTRAP_RETRY_SECONDS)
	end

	if self._menuModule then
		self._menuModule.showStatus("Session server did not answer. Restart Play, then press Refresh.")
	end
end

return setmetatable({} :: SessionServiceClient, SessionServiceClient)
