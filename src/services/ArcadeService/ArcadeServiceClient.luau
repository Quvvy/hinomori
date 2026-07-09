--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Logger = require(ReplicatedStorage.Shared.Modules.Core.Logger)
local Networker = require(ReplicatedStorage.Packages.Networker)
local RhythmSongCatalog = require(ReplicatedStorage.Shared.Modules.Game.RhythmSongCatalog)

local ArcadeServiceClient = {}
ArcadeServiceClient.__index = ArcadeServiceClient

export type ArcadeServiceClient = typeof(setmetatable(
	{} :: {
		_networker: Networker.Client?,
		_menuModule: any?,
		_rhythmModule: any?,
		_currentState: { [string]: any }?,
	},
	ArcadeServiceClient
))

function ArcadeServiceClient.Init(self: ArcadeServiceClient)
	self._networker = Networker.client.new("ArcadeService", self)
end

function ArcadeServiceClient.Start(self: ArcadeServiceClient)
	Logger.info("ArcadeServiceClient", "Started")

	local ui = ReplicatedStorage:WaitForChild("UI")
	self._menuModule = require(ui.Menus.ArcadeMenu)
	self._rhythmModule = require(ui.Menus.RhythmGame)
	self._menuModule.mount({
		open = function()
			self:OpenArcade()
		end,
		refresh = function()
			return self:FetchState()
		end,
		joinQueue = function()
			return self:JoinQueue()
		end,
		leaveQueue = function()
			return self:LeaveQueue()
		end,
		joinSpectators = function()
			return self:JoinSpectators()
		end,
		leaveSpectators = function()
			return self:LeaveSpectators()
		end,
		startSolo = function(songId: string)
			return self:StartSoloMatch(songId)
		end,
		startDuel = function(songId: string)
			return self:StartDuelMatch(songId)
		end,
		finishMatch = function(matchId: string)
			return self:FinishStubMatch(matchId)
		end,
	})
end

function ArcadeServiceClient.openArcadeMenu(self: ArcadeServiceClient)
	self:OpenArcade()
end

function ArcadeServiceClient.arcadeStateChanged(self: ArcadeServiceClient, state: { [string]: any })
	self._currentState = state
	if self._menuModule then
		self._menuModule.updateState(state)
	end
end

function ArcadeServiceClient.arcadeMatchStarted(self: ArcadeServiceClient, match: { [string]: any })
	if self:_localPlayerInMatch(match) then
		self:_startRhythmMatch(match)
	elseif self._menuModule then
		local song = match.song
		local songName = if song then song.displayName else "song"
		self._menuModule.showToast(`Now playing: {songName}`)
	end
end

function ArcadeServiceClient.arcadeMatchFinished(self: ArcadeServiceClient, result: { [string]: any })
	if self._rhythmModule then
		self._rhythmModule.stop()
	end

	if self._menuModule then
		self._menuModule.showMatchResult(result)
	end
end

function ArcadeServiceClient.arcadeMatchCancelled(self: ArcadeServiceClient, message: string)
	if self._rhythmModule then
		self._rhythmModule.stop()
	end

	if self._menuModule then
		self._menuModule.showToast(message)
	end
end

function ArcadeServiceClient.OpenArcade(self: ArcadeServiceClient)
	local state = self:FetchState()
	if not state then
		if self._menuModule then
			self._menuModule.showToast("Move closer to the arcade cabinet.")
		end
		return
	end

	if self._menuModule then
		self._menuModule.open(state)
	end
end

function ArcadeServiceClient.FetchState(self: ArcadeServiceClient): { [string]: any }?
	if not self._networker then
		return nil
	end

	local state = self._networker:fetch("requestArcadeState")
	self._currentState = state
	return state
end

function ArcadeServiceClient.JoinQueue(self: ArcadeServiceClient): boolean
	if not self._networker then
		return false
	end

	return self._networker:fetch("joinQueue") == true
end

function ArcadeServiceClient.LeaveQueue(self: ArcadeServiceClient): boolean
	if not self._networker then
		return false
	end

	return self._networker:fetch("leaveQueue") == true
end

function ArcadeServiceClient.JoinSpectators(self: ArcadeServiceClient): boolean
	if not self._networker then
		return false
	end

	return self._networker:fetch("joinSpectators") == true
end

function ArcadeServiceClient.LeaveSpectators(self: ArcadeServiceClient): boolean
	if not self._networker then
		return false
	end

	return self._networker:fetch("leaveSpectators") == true
end

function ArcadeServiceClient.StartSoloMatch(self: ArcadeServiceClient, songId: string): boolean
	if not self._networker then
		return false
	end

	return self._networker:fetch("startSoloMatch", songId) == true
end

function ArcadeServiceClient.StartDuelMatch(self: ArcadeServiceClient, songId: string): boolean
	if not self._networker then
		return false
	end

	return self._networker:fetch("startDuelMatch", songId) == true
end

function ArcadeServiceClient.FinishStubMatch(self: ArcadeServiceClient, matchId: string): boolean
	if not self._networker then
		return false
	end

	return self._networker:fetch("finishStubMatch", matchId) == true
end

function ArcadeServiceClient.FinishRhythmMatch(
	self: ArcadeServiceClient,
	matchId: string,
	result: { [string]: any }
): boolean
	if not self._networker then
		return false
	end

	return self._networker:fetch("finishRhythmMatch", matchId, result) == true
end

function ArcadeServiceClient._localPlayerInMatch(_self: ArcadeServiceClient, match: { [string]: any }): boolean
	for _, playerEntry in match.players or {} do
		if playerEntry.userId == Players.LocalPlayer.UserId then
			return true
		end
	end
	return false
end

function ArcadeServiceClient._startRhythmMatch(self: ArcadeServiceClient, match: { [string]: any })
	if not self._rhythmModule then
		return
	end

	local song = RhythmSongCatalog.get(match.songId)
	if not song then
		if self._menuModule then
			self._menuModule.showToast("Song data missing.")
		end
		return
	end

	if self._menuModule then
		self._menuModule.close()
	end

	self._rhythmModule.start(match, song, function(result: { [string]: any })
		local ok = self:FinishRhythmMatch(match.matchId, result)
		if not ok and self._menuModule then
			self._menuModule.showToast("Could not submit rhythm result.")
		end
	end)
end

return setmetatable({} :: ArcadeServiceClient, ArcadeServiceClient)
