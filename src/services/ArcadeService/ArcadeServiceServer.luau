--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local ArcadeConfig = require(ReplicatedStorage.Shared.Modules.Game.ArcadeConfig)
local ArcadeServiceShared = require(ReplicatedStorage.Shared.Services.ArcadeService.ArcadeServiceShared)
local ArcadeWorld = require(ReplicatedStorage.Shared.Modules.Game.ArcadeWorld)
local DataServiceServer = require(ServerScriptService.Services.DataService.DataServiceServer)
local GameConfig = require(ReplicatedStorage.Shared.Modules.Game.GameConfig)
local LockerConfig = require(ReplicatedStorage.Shared.Modules.Game.LockerConfig)
local LockerDecorCatalog = require(ReplicatedStorage.Shared.Modules.Game.LockerDecorCatalog)
local LockerServiceServer = require(ServerScriptService.Services.LockerService.LockerServiceServer)
local Logger = require(ReplicatedStorage.Shared.Modules.Core.Logger)
local Networker = require(ReplicatedStorage.Packages.Networker)
local RhythmScoring = require(ReplicatedStorage.Shared.Modules.Game.RhythmScoring)
local RhythmSongCatalog = require(ReplicatedStorage.Shared.Modules.Game.RhythmSongCatalog)
local SessionServiceServer = require(ServerScriptService.Services.SessionService.SessionServiceServer)
local Validate = require(ReplicatedStorage.Shared.Modules.Core.Validate)

type ArcadeParticipant = {
	userId: number,
	displayName: string,
	score: number,
	accuracy: number,
	maxCombo: number,
	judgments: RhythmScoring.JudgmentCounts,
	ticketsAwarded: number,
}

type ArcadeMatch = {
	matchId: string,
	mode: string,
	songId: string,
	playerUserIds: { number },
	startedAt: number,
	results: { [number]: ArcadeParticipant },
}

local ArcadeServiceServer = {}
ArcadeServiceServer.__index = ArcadeServiceServer

export type ArcadeServiceServer = typeof(setmetatable(
	{} :: {
		_networker: Networker.Server?,
		_queue: { number },
		_spectators: { [number]: boolean },
		_activeMatch: ArcadeMatch?,
		_nextMatchId: number,
	},
	ArcadeServiceServer
))

local PROMPT_BOUND_ATTRIBUTE = "HinomoriArcadeBound"

local function getPlayerByUserId(userId: number): Player?
	return Players:GetPlayerByUserId(userId)
end

local function playerDisplayName(userId: number): string
	local player = getPlayerByUserId(userId)
	return if player then player.DisplayName else "Student"
end

local function containsUserId(list: { number }, userId: number): boolean
	for _, listedUserId in list do
		if listedUserId == userId then
			return true
		end
	end
	return false
end

local function removeUserId(list: { number }, userId: number)
	for index = #list, 1, -1 do
		if list[index] == userId then
			table.remove(list, index)
		end
	end
end

local function getQueueEntries(queue: { number }): { { userId: number, displayName: string } }
	local entries = {}
	for _, userId in queue do
		table.insert(entries, {
			userId = userId,
			displayName = playerDisplayName(userId),
		})
	end
	return entries
end

local function getSpectatorEntries(spectators: { [number]: boolean }): { { userId: number, displayName: string } }
	local entries = {}
	for userId, isWatching in spectators do
		if isWatching then
			table.insert(entries, {
				userId = userId,
				displayName = playerDisplayName(userId),
			})
		end
	end
	table.sort(entries, function(a, b)
		return a.displayName < b.displayName
	end)
	return entries
end

local function getFirstEmptyLockerSlot(profile: any): string?
	local occupied: { [string]: boolean } = {}
	for _, decor in profile.lockerDecor() do
		occupied[decor.slotId] = true
	end

	for _, slotId in LockerConfig.SLOT_IDS do
		if not occupied[slotId] then
			return slotId
		end
	end

	return nil
end

local function hasDecorItem(profile: any, itemId: string): boolean
	for _, decor in profile.lockerDecor() do
		if decor.itemId == itemId then
			return true
		end
	end
	return false
end

local function getProfile(player: Player): any?
	local ok, profile = pcall(function()
		return DataServiceServer:GetProfile(player)
	end)
	if not ok then
		return nil
	end
	return profile
end

function ArcadeServiceServer.Init(self: ArcadeServiceServer)
	self._queue = {}
	self._spectators = {}
	self._activeMatch = nil
	self._nextMatchId = 0
	self._networker = Networker.server.new("ArcadeService", self, {
		self.requestArcadeState,
		self.joinQueue,
		self.leaveQueue,
		self.joinSpectators,
		self.leaveSpectators,
		self.startSoloMatch,
		self.startDuelMatch,
		self.finishRhythmMatch,
		self.finishStubMatch,
	})
end

function ArcadeServiceServer.Start(self: ArcadeServiceServer)
	Logger.info("ArcadeService", "Started")

	Players.PlayerRemoving:Connect(function(player: Player)
		self:_removePlayer(player.UserId)
	end)

	self:_bindCabinetPrompt()
end

function ArcadeServiceServer.requestArcadeState(self: ArcadeServiceServer, player: Player): { [string]: any }?
	if not Validate.isPlayerAlive(player) then
		return nil
	end

	return self:_stateForPlayer(player)
end

function ArcadeServiceServer.joinQueue(self: ArcadeServiceServer, player: Player): boolean
	if not self:_canUseCabinet(player) then
		return false
	end

	if self._activeMatch and containsUserId(self._activeMatch.playerUserIds, player.UserId) then
		return false
	end

	if #self._queue >= GameConfig.ARCADE_QUEUE_MAX then
		return false
	end

	if containsUserId(self._queue, player.UserId) then
		return true
	end

	self._spectators[player.UserId] = nil
	table.insert(self._queue, player.UserId)
	self:_broadcastState()
	return true
end

function ArcadeServiceServer.leaveQueue(self: ArcadeServiceServer, player: Player): boolean
	removeUserId(self._queue, player.UserId)
	self:_broadcastState()
	return true
end

function ArcadeServiceServer.joinSpectators(self: ArcadeServiceServer, player: Player): boolean
	if not self:_canUseCabinet(player) then
		return false
	end

	if self._activeMatch and containsUserId(self._activeMatch.playerUserIds, player.UserId) then
		return false
	end

	if self:_spectatorCount() >= GameConfig.ARCADE_SPECTATOR_MAX and not self._spectators[player.UserId] then
		return false
	end

	removeUserId(self._queue, player.UserId)
	self._spectators[player.UserId] = true
	self:_broadcastState()
	return true
end

function ArcadeServiceServer.leaveSpectators(self: ArcadeServiceServer, player: Player): boolean
	self._spectators[player.UserId] = nil
	self:_broadcastState()
	return true
end

function ArcadeServiceServer.startSoloMatch(self: ArcadeServiceServer, player: Player, songId: string?): boolean
	if not self:_canStartMatch(player) then
		return false
	end

	if self._queue[1] ~= player.UserId then
		return false
	end

	local validSongId = self:_validSongId(songId)
	if not validSongId then
		return false
	end

	self:_startMatch(ArcadeServiceShared.MODE_SOLO, { player.UserId }, validSongId)
	return true
end

function ArcadeServiceServer.startDuelMatch(self: ArcadeServiceServer, player: Player, songId: string?): boolean
	if not self:_canStartMatch(player) then
		return false
	end

	if #self._queue < 2 then
		return false
	end

	local playerIds = { self._queue[1], self._queue[2] }
	if not containsUserId(playerIds, player.UserId) then
		return false
	end

	local validSongId = self:_validSongId(songId)
	if not validSongId then
		return false
	end

	self:_startMatch(ArcadeServiceShared.MODE_DUEL, playerIds, validSongId)
	return true
end

function ArcadeServiceServer.finishRhythmMatch(
	self: ArcadeServiceServer,
	player: Player,
	matchId: string,
	result: { [string]: any }
): boolean
	if not self._activeMatch or self._activeMatch.matchId ~= matchId then
		return false
	end

	local match = self._activeMatch
	if not containsUserId(match.playerUserIds, player.UserId) then
		return false
	end

	if match.results[player.UserId] then
		return true
	end

	match.results[player.UserId] = self:_sanitizeRhythmResult(player, match.songId, result)

	if self:_allMatchPlayersReported(match) then
		local results = self:_finishActiveMatchFromResults()
		self:_markPlayedArcade(results)
		if self._networker then
			self._networker:fireAll("arcadeMatchFinished", results)
		end
		self:_broadcastState()
	end

	return true
end

function ArcadeServiceServer.finishStubMatch(self: ArcadeServiceServer, player: Player, matchId: string): boolean
	if not self._activeMatch or self._activeMatch.matchId ~= matchId then
		return false
	end

	if not containsUserId(self._activeMatch.playerUserIds, player.UserId) then
		return false
	end

	local results = self:_finishActiveStubMatch()
	self:_markPlayedArcade(results)
	if self._networker then
		self._networker:fireAll("arcadeMatchFinished", results)
	end
	self:_broadcastState()
	return true
end

function ArcadeServiceServer._canUseCabinet(_self: ArcadeServiceServer, player: Player): boolean
	if not Validate.isPlayerAlive(player) then
		return false
	end

	return ArcadeWorld.isNearCabinet(player)
end

function ArcadeServiceServer._canStartMatch(self: ArcadeServiceServer, player: Player): boolean
	if self._activeMatch ~= nil then
		return false
	end

	return self:_canUseCabinet(player)
end

function ArcadeServiceServer._bindCabinetPrompt(self: ArcadeServiceServer)
	local promptPart = ArcadeWorld.getPromptPart()
	if not promptPart then
		task.spawn(function()
			for _ = 1, 30 do
				task.wait(0.5)
				promptPart = ArcadeWorld.getPromptPart()
				if promptPart then
					self:_bindCabinetPrompt()
					return
				end
			end
			Logger.warn("ArcadeService", "Arcade cabinet prompt not found; use Studio checklist to create it.")
		end)
		return
	end

	local prompt = promptPart:FindFirstChildOfClass("ProximityPrompt")
	if not prompt or prompt:GetAttribute(PROMPT_BOUND_ATTRIBUTE) then
		return
	end

	prompt:SetAttribute(PROMPT_BOUND_ATTRIBUTE, true)
	prompt.Triggered:Connect(function(player: Player)
		if self._networker and self:_canUseCabinet(player) then
			self._networker:fire(player, "openArcadeMenu")
		end
	end)
end

function ArcadeServiceServer._startMatch(
	self: ArcadeServiceServer,
	mode: string,
	playerUserIds: { number },
	songId: string
)
	self._nextMatchId += 1
	local match: ArcadeMatch = {
		matchId = `arcade_{self._nextMatchId}`,
		mode = mode,
		songId = songId,
		playerUserIds = playerUserIds,
		startedAt = os.clock(),
		results = {},
	}

	for _, userId in playerUserIds do
		removeUserId(self._queue, userId)
		self._spectators[userId] = nil
	end

	self._activeMatch = match
	self:_scheduleMatchTimeout(match.matchId, songId)

	if self._networker then
		self._networker:fireAll("arcadeMatchStarted", self:_publicMatch(match))
	end
	self:_broadcastState()
end

function ArcadeServiceServer._finishActiveStubMatch(self: ArcadeServiceServer): { [string]: any }
	local match = self._activeMatch
	if not match then
		return {}
	end

	local participants: { ArcadeParticipant } = {}
	local ticketReward = if match.mode == ArcadeServiceShared.MODE_DUEL
		then ArcadeConfig.DUEL_TICKET_REWARD
		else ArcadeConfig.SOLO_TICKET_REWARD

	for index, userId in match.playerUserIds do
		local player = getPlayerByUserId(userId)
		local score = self:_generateStubScore(userId, index, match.startedAt)
		if player then
			self:_awardPlayer(player, ticketReward)
		end

		table.insert(participants, {
			userId = userId,
			displayName = playerDisplayName(userId),
			score = score,
			accuracy = 0,
			maxCombo = 0,
			judgments = RhythmScoring.emptyJudgments(),
			ticketsAwarded = if player then ticketReward else 0,
		})
	end

	table.sort(participants, function(a, b)
		return a.score > b.score
	end)

	self._activeMatch = nil

	return {
		matchId = match.matchId,
		mode = match.mode,
		songId = match.songId,
		song = RhythmSongCatalog.getSummary(match.songId),
		participants = participants,
	}
end

function ArcadeServiceServer._finishActiveMatchFromResults(self: ArcadeServiceServer): { [string]: any }
	local match = self._activeMatch
	if not match then
		return {}
	end

	local participants: { ArcadeParticipant } = {}
	local ticketReward = if match.mode == ArcadeServiceShared.MODE_DUEL
		then ArcadeConfig.DUEL_TICKET_REWARD
		else ArcadeConfig.SOLO_TICKET_REWARD

	for _, userId in match.playerUserIds do
		local player = getPlayerByUserId(userId)
		local participant = match.results[userId]
		if not participant then
			participant = self:_emptyRhythmResult(userId, match.songId)
		end

		if player then
			self:_awardPlayer(player, ticketReward)
			participant.ticketsAwarded = ticketReward
		end

		table.insert(participants, participant)
	end

	table.sort(participants, function(a, b)
		return a.score > b.score
	end)

	self._activeMatch = nil

	return {
		matchId = match.matchId,
		mode = match.mode,
		songId = match.songId,
		song = RhythmSongCatalog.getSummary(match.songId),
		participants = participants,
	}
end

function ArcadeServiceServer._awardPlayer(_self: ArcadeServiceServer, player: Player, ticketReward: number)
	local profile = getProfile(player)
	if not profile then
		return
	end

	profile.arcadeTickets(profile.arcadeTickets() + ticketReward)

	local rewardItemId = ArcadeConfig.LOCKER_REWARD_ITEM_ID
	if LockerDecorCatalog.isValid(rewardItemId) and not hasDecorItem(profile, rewardItemId) then
		local emptySlot = getFirstEmptyLockerSlot(profile)
		if emptySlot then
			local decor = profile.lockerDecor()
			table.insert(decor, {
				slotId = emptySlot,
				itemId = rewardItemId,
			})
			profile.lockerDecor(decor)

			local lockerService = LockerServiceServer.GetInstance()
			local lockerId = profile.assignedLockerId()
			if lockerService and lockerId ~= "" then
				lockerService:broadcastLockerDecor(lockerId)
			end
		end
	end
end

function ArcadeServiceServer._generateStubScore(
	_self: ArcadeServiceServer,
	userId: number,
	index: number,
	startedAt: number
): number
	local elapsed = math.max(os.clock() - startedAt, 1)
	local base = 82000 + (userId % 4000) + (index * 137)
	local elapsedBonus = math.floor(elapsed * 97) % 2500
	return math.clamp(base + elapsedBonus, 0, 99999)
end

function ArcadeServiceServer._publicMatch(_self: ArcadeServiceServer, match: ArcadeMatch): { [string]: any }
	local players = {}
	for _, userId in match.playerUserIds do
		table.insert(players, {
			userId = userId,
			displayName = playerDisplayName(userId),
		})
	end

	return {
		matchId = match.matchId,
		mode = match.mode,
		songId = match.songId,
		song = RhythmSongCatalog.getSummary(match.songId),
		players = players,
		startedAt = match.startedAt,
	}
end

function ArcadeServiceServer._stateForPlayer(self: ArcadeServiceServer, player: Player): { [string]: any }
	local profile = getProfile(player)
	return {
		cabinetId = ArcadeConfig.CABINET_ID,
		queue = getQueueEntries(self._queue),
		spectators = getSpectatorEntries(self._spectators),
		activeMatch = if self._activeMatch then self:_publicMatch(self._activeMatch) else nil,
		ticketCount = if profile then profile.arcadeTickets() else 0,
		songs = RhythmSongCatalog.getSummaries(),
	}
end

function ArcadeServiceServer._broadcastState(self: ArcadeServiceServer)
	if not self._networker then
		return
	end

	for _, player in Players:GetPlayers() do
		self._networker:fire(player, "arcadeStateChanged", self:_stateForPlayer(player))
	end
end

function ArcadeServiceServer._spectatorCount(self: ArcadeServiceServer): number
	local count = 0
	for _, isWatching in self._spectators do
		if isWatching then
			count += 1
		end
	end
	return count
end

function ArcadeServiceServer._removePlayer(self: ArcadeServiceServer, userId: number)
	removeUserId(self._queue, userId)
	self._spectators[userId] = nil

	if self._activeMatch and containsUserId(self._activeMatch.playerUserIds, userId) then
		self._activeMatch = nil
		if self._networker then
			self._networker:fireAll("arcadeMatchCancelled", "Player left.")
		end
	end

	self:_broadcastState()
end

function ArcadeServiceServer._validSongId(_self: ArcadeServiceServer, songId: string?): string?
	if not songId or songId == "" then
		return RhythmSongCatalog.DEFAULT_SONG_ID
	end

	return if RhythmSongCatalog.isValid(songId) then songId else nil
end

function ArcadeServiceServer._songNoteCount(_self: ArcadeServiceServer, songId: string): number
	local parsed = RhythmSongCatalog.parseSong(songId)
	return if parsed then #parsed.notes else 0
end

function ArcadeServiceServer._sanitizeRhythmResult(
	self: ArcadeServiceServer,
	player: Player,
	songId: string,
	result: { [string]: any }
): ArcadeParticipant
	if typeof(result) ~= "table" then
		return self:_emptyRhythmResult(player.UserId, songId)
	end

	local noteCount = self:_songNoteCount(songId)
	local rawJudgments = if typeof(result.judgments) == "table" then result.judgments else {}
	local perfect = math.clamp(math.floor(tonumber(rawJudgments.perfect) or 0), 0, noteCount)
	local great = math.clamp(math.floor(tonumber(rawJudgments.great) or 0), 0, noteCount - perfect)
	local good = math.clamp(math.floor(tonumber(rawJudgments.good) or 0), 0, noteCount - perfect - great)
	local miss = noteCount - perfect - great - good
	local judgments = {
		perfect = perfect,
		great = great,
		good = good,
		miss = miss,
	}

	return {
		userId = player.UserId,
		displayName = player.DisplayName,
		score = RhythmScoring.scoreFromJudgments(judgments),
		accuracy = RhythmScoring.accuracyFromJudgments(judgments, noteCount),
		maxCombo = math.clamp(math.floor(tonumber(result.maxCombo) or 0), 0, noteCount),
		judgments = judgments,
		ticketsAwarded = 0,
	}
end

function ArcadeServiceServer._emptyRhythmResult(
	_self: ArcadeServiceServer,
	userId: number,
	songId: string
): ArcadeParticipant
	local noteCount = 0
	local parsed = RhythmSongCatalog.parseSong(songId)
	if parsed then
		noteCount = #parsed.notes
	end

	local judgments = {
		perfect = 0,
		great = 0,
		good = 0,
		miss = noteCount,
	}

	return {
		userId = userId,
		displayName = playerDisplayName(userId),
		score = 0,
		accuracy = 0,
		maxCombo = 0,
		judgments = judgments,
		ticketsAwarded = 0,
	}
end

function ArcadeServiceServer._allMatchPlayersReported(_self: ArcadeServiceServer, match: ArcadeMatch): boolean
	for _, userId in match.playerUserIds do
		if not match.results[userId] then
			return false
		end
	end
	return true
end

function ArcadeServiceServer._scheduleMatchTimeout(self: ArcadeServiceServer, matchId: string, songId: string)
	local summary = RhythmSongCatalog.getSummary(songId)
	local timeoutSeconds = (if summary then summary.durationSeconds else 20) + 12
	task.delay(timeoutSeconds, function()
		if not self._activeMatch or self._activeMatch.matchId ~= matchId then
			return
		end

		local results = self:_finishActiveMatchFromResults()
		self:_markPlayedArcade(results)
		if self._networker then
			self._networker:fireAll("arcadeMatchFinished", results)
		end
		self:_broadcastState()
	end)
end

function ArcadeServiceServer._markPlayedArcade(_self: ArcadeServiceServer, results: { [string]: any })
	local sessionService = SessionServiceServer.GetInstance()
	if not sessionService then
		return
	end

	for _, participant in results.participants or {} do
		local player = getPlayerByUserId(participant.userId)
		if player then
			sessionService:MarkFirstDayStep(player, "playedArcade")
		end
	end
end

return setmetatable({} :: ArcadeServiceServer, ArcadeServiceServer)
