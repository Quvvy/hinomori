--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local DataServiceServer = require(ServerScriptService.Services.DataService.DataServiceServer)
local LockerConfig = require(ReplicatedStorage.Shared.Modules.Game.LockerConfig)
local LockerDecorCatalog = require(ReplicatedStorage.Shared.Modules.Game.LockerDecorCatalog)
local LockerValidate = require(ReplicatedStorage.Shared.Modules.Core.LockerValidate)
local LockerWorld = require(ReplicatedStorage.Shared.Services.LockerService.LockerWorld)
local Logger = require(ReplicatedStorage.Shared.Modules.Core.Logger)
local Networker = require(ReplicatedStorage.Packages.Networker)
local SessionServiceServer = require(ServerScriptService.Services.SessionService.SessionServiceServer)
local Validate = require(ReplicatedStorage.Shared.Modules.Core.Validate)

local LockerServiceServer = {}
LockerServiceServer.__index = LockerServiceServer

export type LockerServiceServer = typeof(setmetatable(
	{} :: {
		_networker: Networker.Server?,
		_cooldowns: { [string]: number },
		_activeLockerOwners: { [string]: number },
		_userIdToLocker: { [number]: string },
	},
	LockerServiceServer
))

local instance: LockerServiceServer? = nil

local PROMPT_BOUND_ATTRIBUTE = "HinomoriLockerBound"

local function getDecorArray(profile: any): { { slotId: string, itemId: string } }
	local decor = profile.lockerDecor()
	local result: { { slotId: string, itemId: string } } = {}
	for _, entry in decor do
		table.insert(result, {
			slotId = entry.slotId,
			itemId = entry.itemId,
		})
	end
	return result
end

local function getNotesArray(profile: any): { { templateId: string, senderUserId: number, sentDayKey: string } }
	local notes = profile.strangerNotes()
	local result: { { templateId: string, senderUserId: number, sentDayKey: string } } = {}
	for _, note in notes do
		table.insert(result, {
			templateId = note.templateId,
			senderUserId = note.senderUserId,
			sentDayKey = note.sentDayKey,
		})
	end
	return result
end

local function setDecorEntry(profile: any, slotId: string, itemId: string?)
	local decor = profile.lockerDecor()
	local updated: { { slotId: string, itemId: string } } = {}
	local replaced = false

	for _, entry in decor do
		if entry.slotId == slotId then
			replaced = true
			if itemId then
				table.insert(updated, { slotId = slotId, itemId = itemId })
			end
		else
			table.insert(updated, { slotId = entry.slotId, itemId = entry.itemId })
		end
	end

	if not replaced and itemId then
		table.insert(updated, { slotId = slotId, itemId = itemId })
	end

	profile.lockerDecor(updated)
end

function LockerServiceServer.Init(self: LockerServiceServer)
	self._cooldowns = {}
	self._activeLockerOwners = {}
	self._userIdToLocker = {}
	self._networker = Networker.server.new("LockerService", self, {
		self.requestLockerSummary,
		self.requestLockerState,
		self.applyLockerDecor,
		self.clearLockerDecor,
		self.completeTransferSetup,
	})
	instance = self
end

function LockerServiceServer.Start(self: LockerServiceServer)
	Logger.info("LockerService", "Started")
	LockerWorld.ensureLockerIds()

	local function onPlayerAdded(player: Player)
		task.spawn(function()
			self:assignLockerOnJoin(player)
			self:syncAllLockerDecorToPlayer(player)
		end)
	end

	for _, player in Players:GetPlayers() do
		onPlayerAdded(player)
	end

	Players.PlayerAdded:Connect(onPlayerAdded)
	Players.PlayerRemoving:Connect(function(player: Player)
		self:releaseLocker(player)
	end)

	self:bindLockerPrompts()
end

function LockerServiceServer.bindLockerPrompts(self: LockerServiceServer)
	local function bindLocker(lockerModel: Model, _lockerId: string)
		local promptPart = LockerWorld.getPromptPart(lockerModel)
		if not promptPart then
			return
		end

		local prompt = promptPart:FindFirstChildOfClass("ProximityPrompt")
		if not prompt or prompt:GetAttribute(PROMPT_BOUND_ATTRIBUTE) then
			return
		end

		prompt:SetAttribute(PROMPT_BOUND_ATTRIBUTE, true)
		prompt.Triggered:Connect(function(playerWhoTriggered: Player)
			local currentLockerId = lockerModel:GetAttribute(LockerConfig.ATTRIBUTE_LOCKER_ID)
			if typeof(currentLockerId) == "string" and currentLockerId ~= "" then
				self:onLockerPromptTriggered(playerWhoTriggered, currentLockerId)
			end
		end)
	end

	local function tryBindAll()
		LockerWorld.ensureLockerIds()
		LockerWorld.iterateLockers(bindLocker)
	end

	local lockersFolder = LockerWorld.getLockersFolder()
	if lockersFolder then
		tryBindAll()
		lockersFolder.ChildAdded:Connect(function(child)
			if child:IsA("Model") then
				task.defer(tryBindAll)
			end
		end)
	else
		task.spawn(function()
			for _ = 1, 30 do
				lockersFolder = LockerWorld.getLockersFolder()
				if lockersFolder then
					tryBindAll()
					lockersFolder.ChildAdded:Connect(function(child)
						if child:IsA("Model") then
							task.defer(tryBindAll)
						end
					end)
					return
				end
				task.wait(0.5)
			end
		end)
	end
end

function LockerServiceServer.onLockerPromptTriggered(self: LockerServiceServer, player: Player, lockerId: string)
	if not self._networker then
		return
	end

	if not Validate.isPlayerAlive(player) then
		Logger.warn("LockerService", `{player.Name} triggered {lockerId} but is not alive`)
		return
	end

	if not LockerWorld.isKnownLockerId(lockerId) then
		return
	end

	if not LockerValidate.isNearLocker(player, lockerId) then
		local distance = LockerValidate.getPlayerLockerDistance(player, lockerId)
		Logger.warn(
			"LockerService",
			`{player.Name} too far from {lockerId} (distance={distance}, max={LockerValidate.getInteractDistance(
				lockerId
			)})`
		)
		return
	end

	local sessionService = SessionServiceServer.GetInstance()
	if sessionService and self._activeLockerOwners[lockerId] == player.UserId then
		sessionService:MarkFirstDayStep(player, "openedLocker")
	end

	self._networker:fire(player, "openLockerMenu", lockerId)
end

function LockerServiceServer.GetInstance(): LockerServiceServer?
	return instance
end

function LockerServiceServer.GetOwnerUserIdForLocker(self: LockerServiceServer, lockerId: string): number?
	return self._activeLockerOwners[lockerId]
end

function LockerServiceServer.GetLockerIdForUserId(self: LockerServiceServer, userId: number): string?
	return self._userIdToLocker[userId]
end

function LockerServiceServer.getDecorForLocker(
	self: LockerServiceServer,
	lockerId: string
): { { slotId: string, itemId: string } }
	local ownerUserId = self._activeLockerOwners[lockerId]
	if not ownerUserId then
		return {}
	end

	local ownerPlayer = Players:GetPlayerByUserId(ownerUserId)
	if not ownerPlayer then
		return {}
	end

	local profile = DataServiceServer:GetProfile(ownerPlayer)
	if not profile then
		return {}
	end

	return getDecorArray(profile)
end

function LockerServiceServer.broadcastLockerDecor(self: LockerServiceServer, lockerId: string)
	if not self._networker then
		return
	end

	local decor = self:getDecorForLocker(lockerId)
	self._networker:fireAll("syncLockerDecor", lockerId, decor)
end

function LockerServiceServer.syncAllLockerDecorToPlayer(self: LockerServiceServer, player: Player)
	if not self._networker then
		return
	end

	for activeLockerId, _ in self._activeLockerOwners do
		local decor = self:getDecorForLocker(activeLockerId)
		self._networker:fire(player, "syncLockerDecor", activeLockerId, decor)
	end
end

function LockerServiceServer.assignLockerOnJoin(self: LockerServiceServer, player: Player)
	local profile = nil
	for _ = 1, 50 do
		profile = DataServiceServer:GetProfile(player)
		if profile then
			break
		end
		task.wait(0.1)
	end

	if not profile then
		Logger.warn("LockerService", `Profile not ready for {player.Name}`)
		return
	end

	local lockerIds = {}
	for _ = 1, 30 do
		lockerIds = LockerWorld.ensureLockerIds()
		if #lockerIds > 0 then
			break
		end
		task.wait(0.5)
	end

	local preferredLockerId = profile.assignedLockerId()
	if
		preferredLockerId ~= ""
		and LockerWorld.isKnownLockerId(preferredLockerId)
		and self._activeLockerOwners[preferredLockerId] == nil
	then
		self:_claimLocker(player, preferredLockerId)
		return
	end

	for _, lockerId in lockerIds do
		if self._activeLockerOwners[lockerId] == nil then
			self:_claimLocker(player, lockerId)
			return
		end
	end

	Logger.warn("LockerService", `No free locker for {player.Name} ({#lockerIds} lockers discovered)`)
end

function LockerServiceServer._claimLocker(self: LockerServiceServer, player: Player, lockerId: string)
	if not LockerWorld.isKnownLockerId(lockerId) then
		return
	end

	local profile = DataServiceServer:GetProfile(player)
	if not profile then
		return
	end

	local previousLockerId = self._userIdToLocker[player.UserId]
	if previousLockerId then
		self._activeLockerOwners[previousLockerId] = nil
	end

	self._activeLockerOwners[lockerId] = player.UserId
	self._userIdToLocker[player.UserId] = lockerId
	profile.assignedLockerId(lockerId)
	self:broadcastLockerDecor(lockerId)
end

function LockerServiceServer.releaseLocker(self: LockerServiceServer, player: Player)
	local lockerId = self._userIdToLocker[player.UserId]
	if lockerId then
		self._activeLockerOwners[lockerId] = nil
		self._userIdToLocker[player.UserId] = nil
		self:broadcastLockerDecor(lockerId)
	end
end

function LockerServiceServer.requestLockerSummary(_self: LockerServiceServer, player: Player)
	if not Validate.isPlayerAlive(player) then
		return nil
	end

	local profile = DataServiceServer:GetProfile(player)
	if not profile then
		return nil
	end

	return {
		assignedLockerId = profile.assignedLockerId(),
		displayName = profile.studentProfile.displayName(),
		year = profile.studentProfile.year(),
		decorCount = #profile.lockerDecor(),
		hasCompletedTransferSetup = profile.studentProfile.hasCompletedTransferSetup(),
	}
end

function LockerServiceServer.requestLockerState(self: LockerServiceServer, player: Player, lockerId: string)
	if not Validate.isPlayerAlive(player) then
		Logger.warn("LockerService", `requestLockerState: {player.Name} not alive`)
		return nil
	end

	if not LockerWorld.isKnownLockerId(lockerId) then
		Logger.warn("LockerService", `requestLockerState: invalid locker id {lockerId}`)
		return nil
	end

	if not LockerValidate.isNearLocker(player, lockerId) then
		local distance = LockerValidate.getPlayerLockerDistance(player, lockerId)
		Logger.warn("LockerService", `requestLockerState: {player.Name} too far from {lockerId} (distance={distance})`)
		return nil
	end

	local profile = DataServiceServer:GetProfile(player)
	if not profile then
		Logger.warn("LockerService", `requestLockerState: no profile for {player.Name}`)
		return nil
	end

	local ownerUserId = self._activeLockerOwners[lockerId]
	local isOwner = ownerUserId == player.UserId

	local decor: { { slotId: string, itemId: string } } = {}
	local notes: { { templateId: string, senderUserId: number, sentDayKey: string } } = {}
	local displayName = "Unknown"
	local strangerNotesEnabled = true

	if isOwner then
		decor = getDecorArray(profile)
		notes = getNotesArray(profile)
		displayName = profile.studentProfile.displayName()
		strangerNotesEnabled = profile.lockerNotesSettings.strangerNotesEnabled()
	else
		local ownerPlayer = ownerUserId and Players:GetPlayerByUserId(ownerUserId)
		if ownerPlayer then
			local ownerProfile = DataServiceServer:GetProfile(ownerPlayer)
			if ownerProfile then
				decor = getDecorArray(ownerProfile)
				notes = getNotesArray(ownerProfile)
				displayName = ownerProfile.studentProfile.displayName()
				strangerNotesEnabled = ownerProfile.lockerNotesSettings.strangerNotesEnabled()
			else
				displayName = ownerPlayer.DisplayName
			end
		end
	end

	return {
		lockerId = lockerId,
		isOwner = isOwner,
		canEdit = isOwner,
		ownerUserId = ownerUserId,
		decor = decor,
		notes = notes,
		strangerNotesEnabled = strangerNotesEnabled,
		displayName = displayName,
	}
end

function LockerServiceServer.applyLockerDecor(
	self: LockerServiceServer,
	player: Player,
	lockerId: string,
	slotId: string,
	itemId: string
): boolean
	if not self:_canEditDecor(player, lockerId, slotId, itemId) then
		return false
	end

	if not Validate.checkCooldown(self._cooldowns, `{player.UserId}:decor`, LockerConfig.DECOR_COOLDOWN_SECONDS) then
		return false
	end

	local profile = DataServiceServer:GetProfile(player)
	if not profile then
		return false
	end

	setDecorEntry(profile, slotId, itemId)
	self:broadcastLockerDecor(lockerId)

	local sessionService = SessionServiceServer.GetInstance()
	if sessionService then
		sessionService:MarkFirstDayStep(player, "decoratedLocker")
	end

	return true
end

function LockerServiceServer.clearLockerDecor(
	self: LockerServiceServer,
	player: Player,
	lockerId: string,
	slotId: string
): boolean
	if not Validate.isPlayerAlive(player) then
		return false
	end

	if profileAssignedLockerMismatch(player, lockerId) then
		return false
	end

	if not LockerWorld.isKnownLockerId(lockerId) then
		return false
	end

	if not LockerValidate.isNearLocker(player, lockerId) then
		return false
	end

	if not LockerConfig.isValidSlotId(slotId) then
		return false
	end

	if not Validate.checkCooldown(self._cooldowns, `{player.UserId}:decor`, LockerConfig.DECOR_COOLDOWN_SECONDS) then
		return false
	end

	local profile = DataServiceServer:GetProfile(player)
	if not profile then
		return false
	end

	setDecorEntry(profile, slotId, nil)
	self:broadcastLockerDecor(lockerId)
	return true
end

function LockerServiceServer.completeTransferSetup(
	_self: LockerServiceServer,
	player: Player,
	displayName: string,
	_deprecatedTransferStyle: string?
): boolean
	if not Validate.isPlayerAlive(player) then
		return false
	end

	local trimmedName = string.gsub(displayName, "^%s+", "")
	trimmedName = string.gsub(trimmedName, "%s+$", "")
	if trimmedName == "" or #trimmedName > 24 then
		return false
	end

	local profile = DataServiceServer:GetProfile(player)
	if not profile then
		return false
	end

	profile.studentProfile.displayName(trimmedName)
	profile.studentProfile.year(1)
	profile.studentProfile.hasCompletedTransferSetup(true)

	local sessionService = SessionServiceServer.GetInstance()
	if sessionService then
		sessionService:MarkFirstDayStep(player, "namedSelf")
	end

	return true
end

function profileAssignedLockerMismatch(player: Player, lockerId: string): boolean
	local profile = DataServiceServer:GetProfile(player)
	if not profile then
		return true
	end
	return profile.assignedLockerId() ~= lockerId
end

function LockerServiceServer._canEditDecor(
	_self: LockerServiceServer,
	player: Player,
	lockerId: string,
	slotId: string,
	itemId: string
): boolean
	if not Validate.isPlayerAlive(player) then
		return false
	end

	if profileAssignedLockerMismatch(player, lockerId) then
		return false
	end

	if not LockerWorld.isKnownLockerId(lockerId) then
		return false
	end

	if not LockerValidate.isNearLocker(player, lockerId) then
		return false
	end

	if not LockerConfig.isValidSlotId(slotId) then
		return false
	end

	if not LockerDecorCatalog.isValid(itemId) then
		return false
	end

	return true
end

return setmetatable({} :: LockerServiceServer, LockerServiceServer)
