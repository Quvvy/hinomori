--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local CharacterUtil = require(ReplicatedStorage.Shared.Modules.Platform.CharacterUtil)
local GameConfig = require(ReplicatedStorage.Shared.Modules.Game.GameConfig)
local HandOffCatalog = require(ReplicatedStorage.Shared.Modules.Game.HandOffCatalog)
local HandOffServiceShared = require(ReplicatedStorage.Shared.Services.HandOffService.HandOffServiceShared)
local Logger = require(ReplicatedStorage.Shared.Modules.Core.Logger)
local Networker = require(ReplicatedStorage.Packages.Networker)
local SessionServiceServer = require(ServerScriptService.Services.SessionService.SessionServiceServer)
local Validate = require(ReplicatedStorage.Shared.Modules.Core.Validate)

type HandOffOffer = {
	offerId: string,
	senderUserId: number,
	targetUserId: number,
	itemId: string,
	kind: string,
	createdAt: number,
	expiresAt: number,
}

local HandOffServiceServer = {}
HandOffServiceServer.__index = HandOffServiceServer

export type HandOffServiceServer = typeof(setmetatable(
	{} :: {
		_networker: Networker.Server?,
		_cooldowns: { [string]: number },
		_pendingOffers: { [string]: HandOffOffer },
		_outgoingByUserId: { [number]: string },
		_incomingByUserId: { [number]: string },
		_nextOfferId: number,
	},
	HandOffServiceServer
))

local function getPlayerByUserId(userId: number): Player?
	return Players:GetPlayerByUserId(userId)
end

local function arePlayersWithinDistance(sender: Player, target: Player): boolean
	local senderRoot = CharacterUtil.getRootPart(sender)
	local targetRoot = CharacterUtil.getRootPart(target)
	if not senderRoot or not targetRoot then
		return false
	end

	return (senderRoot.Position - targetRoot.Position).Magnitude <= GameConfig.HANDOFF_MAX_DISTANCE
end

local function getItemDisplayName(itemId: string): string
	local item = HandOffCatalog.get(itemId)
	return if item then item.displayName else itemId
end

function HandOffServiceServer.Init(self: HandOffServiceServer)
	self._cooldowns = {}
	self._pendingOffers = {}
	self._outgoingByUserId = {}
	self._incomingByUserId = {}
	self._nextOfferId = 0
	self._networker = Networker.server.new("HandOffService", self, {
		self.requestHandOff,
		self.respondToHandOff,
		self.cancelHandOff,
	})
end

function HandOffServiceServer.Start(self: HandOffServiceServer)
	self:_ensureState()
	Logger.info("HandOffService", "Started")

	Players.PlayerRemoving:Connect(function(player: Player)
		self:_clearPlayerOffers(player.UserId, "Player left")
	end)
end

function HandOffServiceServer.requestHandOff(
	self: HandOffServiceServer,
	player: Player,
	targetUserId: number,
	itemId: string
): boolean
	self:_ensureState()
	self:_cleanupExpiredOffers()

	if not Validate.isPlayerAlive(player) then
		return false
	end

	if not HandOffCatalog.isValid(itemId) then
		return false
	end

	local target = getPlayerByUserId(targetUserId)
	if not target or target == player or not Validate.isPlayerAlive(target) then
		return false
	end

	if not arePlayersWithinDistance(player, target) then
		return false
	end

	if self._outgoingByUserId[player.UserId] or self._incomingByUserId[target.UserId] then
		return false
	end

	if not Validate.checkCooldown(self._cooldowns, `{player.UserId}:handoff`, GameConfig.HANDOFF_COOLDOWN_SECONDS) then
		return false
	end

	local offer = self:_createOffer(player, target, itemId)
	self._pendingOffers[offer.offerId] = offer
	self._outgoingByUserId[player.UserId] = offer.offerId
	self._incomingByUserId[target.UserId] = offer.offerId

	if self._networker then
		self._networker:fire(player, "handOffOfferSent", self:_publicOffer(offer))
		self._networker:fire(target, "receiveHandOffOffer", self:_publicOffer(offer))
	end

	task.delay(GameConfig.HANDOFF_OFFER_EXPIRE_SECONDS, function()
		self:_expireOffer(offer.offerId)
	end)

	Logger.info(
		"HandOffService",
		`{player.Name} offered {getItemDisplayName(itemId)} to {target.Name} ({offer.offerId})`
	)
	return true
end

function HandOffServiceServer.respondToHandOff(
	self: HandOffServiceServer,
	player: Player,
	offerId: string,
	accept: boolean
): boolean
	self:_ensureState()
	self:_cleanupExpiredOffers()

	local offer = self._pendingOffers[offerId]
	if not offer or offer.targetUserId ~= player.UserId then
		return false
	end

	if not Validate.isPlayerAlive(player) then
		self:_finishOffer(offer, HandOffServiceShared.STATUS_CANCELLED, "Offer cancelled.")
		return false
	end

	local sender = getPlayerByUserId(offer.senderUserId)
	if not sender or not Validate.isPlayerAlive(sender) then
		self:_finishOffer(offer, HandOffServiceShared.STATUS_CANCELLED, "Offer cancelled.")
		return false
	end

	if not accept then
		self:_finishOffer(offer, HandOffServiceShared.STATUS_DECLINED, `{player.DisplayName} declined.`)
		return true
	end

	if not arePlayersWithinDistance(sender, player) then
		self:_finishOffer(offer, HandOffServiceShared.STATUS_CANCELLED, "Offer failed: too far away.")
		return false
	end

	self:_finishOffer(offer, HandOffServiceShared.STATUS_ACCEPTED, `{player.DisplayName} accepted.`)

	local sessionService = SessionServiceServer.GetInstance()
	if sessionService then
		sessionService:MarkFirstDayStep(sender, "sharedSnack")
		sessionService:MarkFirstDayStep(player, "sharedSnack")
	end

	if self._networker then
		self._networker:fireAll("showHandOffVisual", player.UserId, offer.itemId)
	end

	return true
end

function HandOffServiceServer.cancelHandOff(self: HandOffServiceServer, player: Player, offerId: string): boolean
	self:_ensureState()
	local offer = self._pendingOffers[offerId]
	if not offer or offer.senderUserId ~= player.UserId then
		return false
	end

	self:_finishOffer(offer, HandOffServiceShared.STATUS_CANCELLED, "Offer cancelled.")
	return true
end

function HandOffServiceServer._ensureState(self: HandOffServiceServer)
	self._cooldowns = self._cooldowns or {}
	self._pendingOffers = self._pendingOffers or {}
	self._outgoingByUserId = self._outgoingByUserId or {}
	self._incomingByUserId = self._incomingByUserId or {}
	self._nextOfferId = self._nextOfferId or 0
end

function HandOffServiceServer._createOffer(
	self: HandOffServiceServer,
	sender: Player,
	target: Player,
	itemId: string
): HandOffOffer
	self._nextOfferId += 1
	local now = os.clock()
	return {
		offerId = `offer_{self._nextOfferId}`,
		senderUserId = sender.UserId,
		targetUserId = target.UserId,
		itemId = itemId,
		kind = HandOffServiceShared.HANDOFF_KIND_SNACK,
		createdAt = now,
		expiresAt = now + GameConfig.HANDOFF_OFFER_EXPIRE_SECONDS,
	}
end

function HandOffServiceServer._publicOffer(_self: HandOffServiceServer, offer: HandOffOffer): { [string]: any }
	local sender = getPlayerByUserId(offer.senderUserId)
	local target = getPlayerByUserId(offer.targetUserId)

	return {
		offerId = offer.offerId,
		senderUserId = offer.senderUserId,
		senderDisplayName = if sender then sender.DisplayName else "Student",
		targetUserId = offer.targetUserId,
		targetDisplayName = if target then target.DisplayName else "Student",
		itemId = offer.itemId,
		itemDisplayName = getItemDisplayName(offer.itemId),
		kind = offer.kind,
		expiresAtServerTime = offer.expiresAt,
	}
end

function HandOffServiceServer._finishOffer(
	self: HandOffServiceServer,
	offer: HandOffOffer,
	status: string,
	message: string
)
	if self._pendingOffers[offer.offerId] ~= offer then
		return
	end

	self:_removeOffer(offer)

	if not self._networker then
		return
	end

	local result = {
		offerId = offer.offerId,
		status = status,
		message = message,
		itemId = offer.itemId,
		itemDisplayName = getItemDisplayName(offer.itemId),
		senderUserId = offer.senderUserId,
		targetUserId = offer.targetUserId,
	}

	local sender = getPlayerByUserId(offer.senderUserId)
	local target = getPlayerByUserId(offer.targetUserId)
	if sender then
		self._networker:fire(sender, "handOffResult", result)
	end
	if target then
		self._networker:fire(target, "handOffResult", result)
	end
end

function HandOffServiceServer._removeOffer(self: HandOffServiceServer, offer: HandOffOffer)
	self._pendingOffers[offer.offerId] = nil
	if self._outgoingByUserId[offer.senderUserId] == offer.offerId then
		self._outgoingByUserId[offer.senderUserId] = nil
	end
	if self._incomingByUserId[offer.targetUserId] == offer.offerId then
		self._incomingByUserId[offer.targetUserId] = nil
	end
end

function HandOffServiceServer._expireOffer(self: HandOffServiceServer, offerId: string)
	local offer = self._pendingOffers[offerId]
	if not offer then
		return
	end

	if os.clock() < offer.expiresAt then
		return
	end

	self:_finishOffer(offer, HandOffServiceShared.STATUS_EXPIRED, "Offer expired.")
end

function HandOffServiceServer._cleanupExpiredOffers(self: HandOffServiceServer)
	local now = os.clock()
	for _, offer in self._pendingOffers do
		if now >= offer.expiresAt then
			self:_finishOffer(offer, HandOffServiceShared.STATUS_EXPIRED, "Offer expired.")
		end
	end
end

function HandOffServiceServer._clearPlayerOffers(self: HandOffServiceServer, userId: number, message: string)
	local outgoingOfferId = self._outgoingByUserId[userId]
	if outgoingOfferId then
		local offer = self._pendingOffers[outgoingOfferId]
		if offer then
			self:_finishOffer(offer, HandOffServiceShared.STATUS_CANCELLED, message)
		end
	end

	local incomingOfferId = self._incomingByUserId[userId]
	if incomingOfferId then
		local offer = self._pendingOffers[incomingOfferId]
		if offer then
			self:_finishOffer(offer, HandOffServiceShared.STATUS_CANCELLED, message)
		end
	end
end

return setmetatable({} :: HandOffServiceServer, HandOffServiceServer)
