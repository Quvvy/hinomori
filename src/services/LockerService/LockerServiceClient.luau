--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DataServiceClient = require(ReplicatedStorage.Shared.Services.DataService.DataServiceClient)
local LockerVisuals = require(ReplicatedStorage.Shared.Services.LockerService.LockerVisuals)
local Logger = require(ReplicatedStorage.Shared.Modules.Core.Logger)
local Networker = require(ReplicatedStorage.Packages.Networker)
local NoteServiceClient = require(ReplicatedStorage.Shared.Services.NoteService.NoteServiceClient)
local NoteTemplates = require(ReplicatedStorage.Shared.Modules.Game.NoteTemplates)

export type LockerMenuContext = {
	lockerId: string,
	isOwner: boolean,
	canEdit: boolean,
	displayName: string,
	decor: { { slotId: string, itemId: string } },
	notes: { any },
	onClose: () -> (),
	onRefresh: () -> (),
}

local LockerServiceClient = {}
LockerServiceClient.__index = LockerServiceClient

export type LockerServiceClient = typeof(setmetatable(
	{} :: {
		_networker: Networker.Client?,
		_menuModule: any?,
		_transferPromptModule: any?,
	},
	LockerServiceClient
))

local instance: LockerServiceClient? = nil

function LockerServiceClient.Init(self: LockerServiceClient)
	self._networker = Networker.client.new("LockerService", self)
	instance = self
end

function LockerServiceClient.Start(self: LockerServiceClient)
	Logger.info("LockerServiceClient", "Started")

	local ui = ReplicatedStorage:WaitForChild("UI")
	self._menuModule = require(ui.Menus.LockerMenu)
	self._transferPromptModule = require(ui.Menus.TransferStudentPrompt)

	task.spawn(function()
		self:_waitForDataAndSetup()
	end)
end

function LockerServiceClient.GetInstance(): LockerServiceClient?
	return instance
end

function LockerServiceClient._waitForDataAndSetup(self: LockerServiceClient)
	local data = DataServiceClient:GetData()
	for _ = 1, 100 do
		local profileReady = false
		pcall(function()
			profileReady = data.studentProfile.hasCompletedTransferSetup ~= nil
		end)
		if profileReady then
			break
		end
		task.wait(0.1)
	end

	if self._transferPromptModule then
		if not data.studentProfile.hasCompletedTransferSetup() then
			self._transferPromptModule.tryShow(function(displayName: string)
				return self:CompleteTransferSetup(displayName)
			end)
		end
	end

	self:RefreshOwnedLockerVisuals()

	data.lockerDecor.Changed(function()
		self:RefreshOwnedLockerVisuals()
	end)
end

-- Called by server after authoritative ProximityPrompt trigger (multiplayer-safe).
function LockerServiceClient.openLockerMenu(self: LockerServiceClient, lockerId: string)
	self:OpenLocker(lockerId)
end

-- Server pushes world decor so all clients see the same locker stickers.
function LockerServiceClient.syncLockerDecor(
	_self: LockerServiceClient,
	lockerId: string,
	decor: { { slotId: string, itemId: string } }
)
	LockerVisuals.applyToLockerId(lockerId, decor)
end

function LockerServiceClient.OpenLocker(self: LockerServiceClient, lockerId: string)
	if not self._menuModule then
		return
	end

	local function buildMenuContext()
		local state = self:FetchLockerStateWithRetry(lockerId, 3)
		if not state then
			return nil
		end

		local function refreshVisuals()
			local newState = self:FetchLockerState(lockerId)
			if newState then
				LockerVisuals.applyToLockerId(lockerId, newState.decor)
			end
		end

		return {
			lockerId = lockerId,
			isOwner = state.isOwner,
			canEdit = state.canEdit,
			displayName = state.displayName,
			decor = state.decor,
			notes = state.notes,
			friendNotes = state.friendNotes or {},
			isFriendOfOwner = state.isFriendOfOwner == true,
			strangerNotesEnabled = state.strangerNotesEnabled,
			onClose = function() end,
			onRefresh = function()
				refreshVisuals()
				local refreshed = buildMenuContext()
				if refreshed then
					self._menuModule.open(refreshed)
				end
			end,
			applyDecor = function(slotId: string, itemId: string)
				local ok = self:ApplyDecor(lockerId, slotId, itemId)
				if ok then
					refreshVisuals()
					local refreshed = buildMenuContext()
					if refreshed then
						self._menuModule.open(refreshed)
					end
				end
				return ok
			end,
			clearDecor = function(slotId: string)
				local ok = self:ClearDecor(lockerId, slotId)
				if ok then
					refreshVisuals()
					local refreshed = buildMenuContext()
					if refreshed then
						self._menuModule.open(refreshed)
					end
				end
				return ok
			end,
			sendNote = function(templateId: string)
				local result = NoteServiceClient:SendStrangerNote(lockerId, templateId)
				if result.ok then
					refreshVisuals()
					local refreshed = buildMenuContext()
					if refreshed then
						self._menuModule.open(refreshed)
					end
				end
				return result
			end,
			sendFriendNote = function(rawText: string)
				local result = NoteServiceClient:SendFriendNote(lockerId, rawText)
				if result.ok then
					refreshVisuals()
					local refreshed = buildMenuContext()
					if refreshed then
						self._menuModule.open(refreshed)
					end
				end
				return result
			end,
			setStrangerNotesEnabled = function(enabled: boolean)
				local ok = NoteServiceClient:SetStrangerNotesEnabled(enabled)
				if ok then
					local refreshed = buildMenuContext()
					if refreshed then
						self._menuModule.open(refreshed)
					end
				end
				return ok
			end,
			clearNotes = function()
				local ok = NoteServiceClient:ClearLockerNotes()
				if ok then
					local refreshed = buildMenuContext()
					if refreshed then
						self._menuModule.open(refreshed)
					end
				end
				return ok
			end,
			blockNoteSender = function(senderUserId: number)
				local ok = NoteServiceClient:BlockNoteSender(senderUserId)
				if ok then
					local refreshed = buildMenuContext()
					if refreshed then
						self._menuModule.open(refreshed)
					end
				end
				return ok
			end,
			fetchTemplates = function()
				return NoteServiceClient:FetchStrangerTemplates() or NoteTemplates.getAll()
			end,
		}
	end

	local context = buildMenuContext()
	if context then
		self._menuModule.open(context)
	else
		Logger.warn("LockerServiceClient", `Could not open locker menu for {lockerId} (server returned no state)`)
	end
end

function LockerServiceClient.RefreshOwnedLockerVisuals(self: LockerServiceClient)
	local summary = self:FetchSummary()
	if not summary or summary.assignedLockerId == "" then
		return
	end

	-- Prefer local profile decor (no proximity check); server broadcast handles other players.
	local data = DataServiceClient:GetData()
	local decor: { { slotId: string, itemId: string } } = {}
	for _, entry in data.lockerDecor() do
		table.insert(decor, {
			slotId = entry.slotId,
			itemId = entry.itemId,
		})
	end
	LockerVisuals.applyToLockerId(summary.assignedLockerId, decor)
end

function LockerServiceClient.FetchSummary(self: LockerServiceClient): { [string]: any }?
	if not self._networker then
		return nil
	end
	return self._networker:fetch("requestLockerSummary")
end

function LockerServiceClient.FetchLockerState(self: LockerServiceClient, lockerId: string): { [string]: any }?
	if not self._networker then
		return nil
	end
	return self._networker:fetch("requestLockerState", lockerId)
end

function LockerServiceClient.FetchLockerStateWithRetry(
	self: LockerServiceClient,
	lockerId: string,
	attempts: number
): { [string]: any }?
	for attempt = 1, attempts do
		local state = self:FetchLockerState(lockerId)
		if state then
			return state
		end
		if attempt < attempts then
			task.wait(0.15)
		end
	end
	return nil
end

function LockerServiceClient.ApplyDecor(
	self: LockerServiceClient,
	lockerId: string,
	slotId: string,
	itemId: string
): boolean
	if not self._networker then
		return false
	end
	return self._networker:fetch("applyLockerDecor", lockerId, slotId, itemId) == true
end

function LockerServiceClient.ClearDecor(self: LockerServiceClient, lockerId: string, slotId: string): boolean
	if not self._networker then
		return false
	end
	return self._networker:fetch("clearLockerDecor", lockerId, slotId) == true
end

function LockerServiceClient.CompleteTransferSetup(self: LockerServiceClient, displayName: string): boolean
	if not self._networker then
		return false
	end
	return self._networker:fetch("completeTransferSetup", displayName) == true
end

return setmetatable({} :: LockerServiceClient, LockerServiceClient)
