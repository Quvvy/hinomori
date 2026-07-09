--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Logger = require(ReplicatedStorage.Shared.Modules.Core.Logger)
local Networker = require(ReplicatedStorage.Packages.Networker)

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
): boolean
	if not self._networker then
		return false
	end

	return self._networker:fetch("sendStrangerNote", targetLockerId, templateId) == true
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
