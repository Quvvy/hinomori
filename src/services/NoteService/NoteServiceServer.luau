--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local TextService = game:GetService("TextService")

local DataServiceServer = require(ServerScriptService.Services.DataService.DataServiceServer)
local GameConfig = require(ReplicatedStorage.Shared.Modules.Game.GameConfig)
local LockerServiceServer = require(ServerScriptService.Services.LockerService.LockerServiceServer)
local LockerValidate = require(ReplicatedStorage.Shared.Modules.Core.LockerValidate)
local Logger = require(ReplicatedStorage.Shared.Modules.Core.Logger)
local Networker = require(ReplicatedStorage.Packages.Networker)
local NoteServiceShared = require(ReplicatedStorage.Shared.Services.NoteService.NoteServiceShared)
local NoteTemplates = require(ReplicatedStorage.Shared.Modules.Game.NoteTemplates)
local SessionServiceServer = require(ServerScriptService.Services.SessionService.SessionServiceServer)
local Validate = require(ReplicatedStorage.Shared.Modules.Core.Validate)

local NoteServiceServer = {}
NoteServiceServer.__index = NoteServiceServer

export type NoteServiceServer = typeof(setmetatable(
	{} :: {
		_networker: Networker.Server?,
		_cooldowns: { [string]: number },
	},
	NoteServiceServer
))

local function getInGameDayKey(): string
	return os.date("%Y-%m-%d")
end

local function getOwnerProfileForLocker(lockerId: string)
	local lockerService = LockerServiceServer.GetInstance()
	if not lockerService then
		return nil, nil
	end

	local ownerUserId = lockerService:GetOwnerUserIdForLocker(lockerId)
	if not ownerUserId then
		return nil, nil
	end

	local ownerPlayer = game:GetService("Players"):GetPlayerByUserId(ownerUserId)
	if not ownerPlayer then
		return nil, nil
	end

	local ownerProfile = DataServiceServer:GetProfile(ownerPlayer)
	return ownerProfile, ownerPlayer
end

local function countSenderNotesToday(notes: { any }, senderUserId: number, dayKey: string): number
	local count = 0
	for _, note in notes do
		if note.senderUserId == senderUserId and note.sentDayKey == dayKey then
			count += 1
		end
	end
	return count
end

local function isSenderBlocked(profile: any, senderUserId: number): boolean
	local blockedSenderIds = profile.blockedNoteSenderUserIds()
	for _, blockedUserId in blockedSenderIds do
		if blockedUserId == senderUserId then
			return true
		end
	end
	return false
end

local function addBlockedSender(profile: any, senderUserId: number)
	local blockedSenderIds = profile.blockedNoteSenderUserIds()
	for _, blockedUserId in blockedSenderIds do
		if blockedUserId == senderUserId then
			return
		end
	end
	table.insert(blockedSenderIds, senderUserId)
	profile.blockedNoteSenderUserIds(blockedSenderIds)
end

local function removeNotesFromSender(profile: any, senderUserId: number)
	local notes = profile.strangerNotes()
	local updatedStranger = {}
	for _, note in notes do
		if note.senderUserId ~= senderUserId then
			table.insert(updatedStranger, note)
		end
	end
	profile.strangerNotes(updatedStranger)

	local friendNotes = profile.friendNotes()
	local updatedFriend = {}
	for _, note in friendNotes do
		if note.senderUserId ~= senderUserId then
			table.insert(updatedFriend, note)
		end
	end
	profile.friendNotes(updatedFriend)
end

local function trimText(rawText: string): string
	return (string.match(rawText, "^%s*(.-)%s*$") or "")
end

local function filterFriendText(player: Player, rawText: string): (string?, string?)
	local trimmed = trimText(rawText)
	if trimmed == "" then
		return nil, NoteServiceShared.SEND_REASON_TEXT_EMPTY
	end

	if #trimmed > GameConfig.NOTE_FRIEND_MAX_RAW_LENGTH then
		return nil, NoteServiceShared.SEND_REASON_TEXT_TOO_LONG
	end

	local ok, filtered = pcall(function()
		local result = TextService:FilterStringAsync(trimmed, player.UserId)
		return result:GetNonChatStringForBroadcastAsync()
	end)

	if not ok or typeof(filtered) ~= "string" or filtered == "" then
		return nil, NoteServiceShared.SEND_REASON_FILTER_FAILED
	end

	return filtered, nil
end

function NoteServiceServer.Init(self: NoteServiceServer)
	self._cooldowns = {}
	self._networker = Networker.server.new("NoteService", self, {
		self.getStrangerTemplates,
		self.getLockerNotes,
		self.sendStrangerNote,
		self.sendFriendNote,
		self.setStrangerNotesEnabled,
		self.clearLockerNotes,
		self.blockNoteSender,
	})
end

function NoteServiceServer.Start(_self: NoteServiceServer)
	Logger.info("NoteService", "Started")
end

function NoteServiceServer.getInGameDayKey(): string
	return getInGameDayKey()
end

function NoteServiceServer.getStrangerTemplates(self: NoteServiceServer, player: Player)
	if not Validate.isPlayerAlive(player) then
		return nil
	end

	if not Validate.checkCooldown(self._cooldowns, `{player.UserId}:templates`, 1) then
		return nil
	end

	return NoteTemplates.getAll()
end

function NoteServiceServer.getLockerNotes(_self: NoteServiceServer, player: Player, lockerId: string)
	if not Validate.isPlayerAlive(player) then
		return nil
	end

	local ownerProfile, _ownerPlayer = getOwnerProfileForLocker(lockerId)
	if not ownerProfile then
		return {}
	end

	return ownerProfile.strangerNotes()
end

-- Active online owners only. Offline locker delivery is future work.
function NoteServiceServer.sendStrangerNote(
	_self: NoteServiceServer,
	player: Player,
	targetLockerId: string,
	templateId: string
): NoteServiceShared.SendStrangerNoteResult
	if not Validate.isPlayerAlive(player) then
		return NoteServiceShared.failure(NoteServiceShared.SEND_REASON_UNKNOWN)
	end

	if not NoteTemplates.isValid(templateId) then
		return NoteServiceShared.failure(NoteServiceShared.SEND_REASON_INVALID_TEMPLATE)
	end

	if not LockerValidate.isNearLocker(player, targetLockerId) then
		return NoteServiceShared.failure(NoteServiceShared.SEND_REASON_TOO_FAR)
	end

	local lockerService = LockerServiceServer.GetInstance()
	if not lockerService then
		return NoteServiceShared.failure(NoteServiceShared.SEND_REASON_UNKNOWN)
	end

	local ownerUserId = lockerService:GetOwnerUserIdForLocker(targetLockerId)
	if not ownerUserId then
		return NoteServiceShared.failure(NoteServiceShared.SEND_REASON_OWNER_OFFLINE)
	end

	if ownerUserId == player.UserId then
		return NoteServiceShared.failure(NoteServiceShared.SEND_REASON_SELF)
	end

	local ownerProfile, ownerPlayer = getOwnerProfileForLocker(targetLockerId)
	if not ownerProfile or not ownerPlayer then
		return NoteServiceShared.failure(NoteServiceShared.SEND_REASON_OWNER_OFFLINE)
	end

	if not ownerProfile.lockerNotesSettings.strangerNotesEnabled() then
		return NoteServiceShared.failure(NoteServiceShared.SEND_REASON_NOTES_DISABLED)
	end

	if isSenderBlocked(ownerProfile, player.UserId) then
		return NoteServiceShared.failure(NoteServiceShared.SEND_REASON_BLOCKED)
	end

	local dayKey = getInGameDayKey()
	local notes = ownerProfile.strangerNotes()

	if countSenderNotesToday(notes, player.UserId, dayKey) >= GameConfig.NOTE_MAX_STRANGER_PER_SENDER_PER_DAY then
		return NoteServiceShared.failure(NoteServiceShared.SEND_REASON_DAILY_LIMIT)
	end

	local maxVisible = ownerProfile.lockerNotesSettings.maxVisibleStrangerNotes()
	if #notes >= maxVisible then
		return NoteServiceShared.failure(NoteServiceShared.SEND_REASON_LOCKER_FULL)
	end

	ownerProfile.strangerNotes.Insert({
		templateId = templateId,
		senderUserId = player.UserId,
		sentDayKey = dayKey,
	})

	local sessionService = SessionServiceServer.GetInstance()
	if sessionService then
		sessionService:MarkFirstDayStep(player, "sentNote")
	end

	return NoteServiceShared.success()
end

-- Active online owners only. Offline locker delivery is future work.
function NoteServiceServer.sendFriendNote(
	_self: NoteServiceServer,
	player: Player,
	targetLockerId: string,
	rawText: string
): NoteServiceShared.SendFriendNoteResult
	if not Validate.isPlayerAlive(player) then
		return NoteServiceShared.failure(NoteServiceShared.SEND_REASON_UNKNOWN)
	end

	if not LockerValidate.isNearLocker(player, targetLockerId) then
		return NoteServiceShared.failure(NoteServiceShared.SEND_REASON_TOO_FAR)
	end

	local lockerService = LockerServiceServer.GetInstance()
	if not lockerService then
		return NoteServiceShared.failure(NoteServiceShared.SEND_REASON_UNKNOWN)
	end

	local ownerUserId = lockerService:GetOwnerUserIdForLocker(targetLockerId)
	if not ownerUserId then
		return NoteServiceShared.failure(NoteServiceShared.SEND_REASON_OWNER_OFFLINE)
	end

	if ownerUserId == player.UserId then
		return NoteServiceShared.failure(NoteServiceShared.SEND_REASON_SELF)
	end

	if not Validate.areFriends(player, ownerUserId) then
		return NoteServiceShared.failure(NoteServiceShared.SEND_REASON_NOT_FRIENDS)
	end

	local ownerProfile, ownerPlayer = getOwnerProfileForLocker(targetLockerId)
	if not ownerProfile or not ownerPlayer then
		return NoteServiceShared.failure(NoteServiceShared.SEND_REASON_OWNER_OFFLINE)
	end

	if isSenderBlocked(ownerProfile, player.UserId) then
		return NoteServiceShared.failure(NoteServiceShared.SEND_REASON_BLOCKED)
	end

	local filteredText, filterReason = filterFriendText(player, rawText)
	if not filteredText then
		return NoteServiceShared.failure(filterReason or NoteServiceShared.SEND_REASON_FILTER_FAILED)
	end

	local dayKey = getInGameDayKey()
	local friendNotes = ownerProfile.friendNotes()

	if countSenderNotesToday(friendNotes, player.UserId, dayKey) >= GameConfig.NOTE_MAX_FRIEND_PER_SENDER_PER_DAY then
		return NoteServiceShared.failure(NoteServiceShared.SEND_REASON_DAILY_LIMIT)
	end

	if #friendNotes >= GameConfig.NOTE_MAX_VISIBLE_FRIEND then
		return NoteServiceShared.failure(NoteServiceShared.SEND_REASON_LOCKER_FULL)
	end

	ownerProfile.friendNotes.Insert({
		text = filteredText,
		senderUserId = player.UserId,
		sentDayKey = dayKey,
	})

	local sessionService = SessionServiceServer.GetInstance()
	if sessionService then
		sessionService:MarkFirstDayStep(player, "sentNote")
	end

	return NoteServiceShared.success()
end

function NoteServiceServer.setStrangerNotesEnabled(_self: NoteServiceServer, player: Player, enabled: boolean): boolean
	if not Validate.isPlayerAlive(player) then
		return false
	end

	local profile = DataServiceServer:GetProfile(player)
	if not profile then
		return false
	end

	profile.lockerNotesSettings.strangerNotesEnabled(enabled)
	return true
end

function NoteServiceServer.clearLockerNotes(_self: NoteServiceServer, player: Player): boolean
	if not Validate.isPlayerAlive(player) then
		return false
	end

	local profile = DataServiceServer:GetProfile(player)
	if not profile then
		return false
	end

	profile.strangerNotes({})
	profile.friendNotes({})
	return true
end

function NoteServiceServer.blockNoteSender(_self: NoteServiceServer, player: Player, senderUserId: number): boolean
	if not Validate.isPlayerAlive(player) or senderUserId == player.UserId then
		return false
	end

	local profile = DataServiceServer:GetProfile(player)
	if not profile then
		return false
	end

	addBlockedSender(profile, senderUserId)
	removeNotesFromSender(profile, senderUserId)
	return true
end

return setmetatable({} :: NoteServiceServer, NoteServiceServer)
