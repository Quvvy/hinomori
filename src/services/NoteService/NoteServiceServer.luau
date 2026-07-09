--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local DataServiceServer = require(ServerScriptService.Services.DataService.DataServiceServer)
local GameConfig = require(ReplicatedStorage.Shared.Modules.Game.GameConfig)
local LockerServiceServer = require(ServerScriptService.Services.LockerService.LockerServiceServer)
local Logger = require(ReplicatedStorage.Shared.Modules.Core.Logger)
local Networker = require(ReplicatedStorage.Packages.Networker)
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
	local updated = {}
	for _, note in notes do
		if note.senderUserId ~= senderUserId then
			table.insert(updated, note)
		end
	end
	profile.strangerNotes(updated)
end

function NoteServiceServer.Init(self: NoteServiceServer)
	self._cooldowns = {}
	self._networker = Networker.server.new("NoteService", self, {
		self.getStrangerTemplates,
		self.getLockerNotes,
		self.sendStrangerNote,
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
): boolean
	if not Validate.isPlayerAlive(player) then
		return false
	end

	if not NoteTemplates.isValid(templateId) then
		return false
	end

	local lockerService = LockerServiceServer.GetInstance()
	if not lockerService then
		return false
	end

	local ownerUserId = lockerService:GetOwnerUserIdForLocker(targetLockerId)
	if not ownerUserId then
		return false
	end

	if ownerUserId == player.UserId then
		return false
	end

	local ownerProfile, ownerPlayer = getOwnerProfileForLocker(targetLockerId)
	if not ownerProfile or not ownerPlayer then
		return false
	end

	if not ownerProfile.lockerNotesSettings.strangerNotesEnabled() then
		return false
	end

	if isSenderBlocked(ownerProfile, player.UserId) then
		return false
	end

	local dayKey = getInGameDayKey()
	local notes = ownerProfile.strangerNotes()

	if countSenderNotesToday(notes, player.UserId, dayKey) >= GameConfig.NOTE_MAX_STRANGER_PER_SENDER_PER_DAY then
		return false
	end

	local maxVisible = ownerProfile.lockerNotesSettings.maxVisibleStrangerNotes()
	if #notes >= maxVisible then
		return false
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

	return true
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
