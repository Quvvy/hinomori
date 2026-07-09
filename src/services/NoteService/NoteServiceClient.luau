--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Logger = require(ReplicatedStorage.Shared.Modules.Core.Logger)
local Networker = require(ReplicatedStorage.Packages.Networker)
local NoteServiceShared = require(ReplicatedStorage.Shared.Services.NoteService.NoteServiceShared)

local NoteServiceClient = {}
NoteServiceClient.__index = NoteServiceClient

export type NoteServiceClient = typeof(setmetatable(
	{} :: {
		_networker: Networker.Client?,
	},
	NoteServiceClient
))

function NoteServiceClient.Init(self: NoteServiceClient)
	self._networker = Networker.client.new("NoteService", self)
end

function NoteServiceClient.Start(_self: NoteServiceClient)
	Logger.info("NoteServiceClient", "Started")
end

function NoteServiceClient.FetchStrangerTemplates(self: NoteServiceClient): { any }?
	if not self._networker then
		return nil
	end

	return self._networker:fetch("getStrangerTemplates")
end

function NoteServiceClient.FetchLockerNotes(self: NoteServiceClient, lockerId: string): { any }?
	if not self._networker then
		return nil
	end

	return self._networker:fetch("getLockerNotes", lockerId)
end

function NoteServiceClient.SendStrangerNote(
	self: NoteServiceClient,
	targetLockerId: string,
	templateId: string
): NoteServiceShared.SendStrangerNoteResult
	if not self._networker then
		return NoteServiceShared.failure(NoteServiceShared.SEND_REASON_UNKNOWN)
	end

	local result = self._networker:fetch("sendStrangerNote", targetLockerId, templateId)
	if typeof(result) == "table" and typeof(result.ok) == "boolean" then
		return result :: NoteServiceShared.SendStrangerNoteResult
	end

	return if result == true
		then NoteServiceShared.success()
		else NoteServiceShared.failure(NoteServiceShared.SEND_REASON_UNKNOWN)
end

function NoteServiceClient.SendFriendNote(
	self: NoteServiceClient,
	targetLockerId: string,
	rawText: string
): NoteServiceShared.SendFriendNoteResult
	if not self._networker then
		return NoteServiceShared.failure(NoteServiceShared.SEND_REASON_UNKNOWN)
	end

	local result = self._networker:fetch("sendFriendNote", targetLockerId, rawText)
	if typeof(result) == "table" and typeof(result.ok) == "boolean" then
		return result :: NoteServiceShared.SendFriendNoteResult
	end

	return if result == true
		then NoteServiceShared.success()
		else NoteServiceShared.failure(NoteServiceShared.SEND_REASON_UNKNOWN)
end

function NoteServiceClient.SetStrangerNotesEnabled(self: NoteServiceClient, enabled: boolean): boolean
	if not self._networker then
		return false
	end

	return self._networker:fetch("setStrangerNotesEnabled", enabled) == true
end

function NoteServiceClient.ClearLockerNotes(self: NoteServiceClient): boolean
	if not self._networker then
		return false
	end

	return self._networker:fetch("clearLockerNotes") == true
end

function NoteServiceClient.BlockNoteSender(self: NoteServiceClient, senderUserId: number): boolean
	if not self._networker then
		return false
	end

	return self._networker:fetch("blockNoteSender", senderUserId) == true
end

return setmetatable({} :: NoteServiceClient, NoteServiceClient)
