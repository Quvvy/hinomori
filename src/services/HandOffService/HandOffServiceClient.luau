--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CharacterUtil = require(ReplicatedStorage.Shared.Modules.Platform.CharacterUtil)
local GameConfig = require(ReplicatedStorage.Shared.Modules.Game.GameConfig)
local HandOffCatalog = require(ReplicatedStorage.Shared.Modules.Game.HandOffCatalog)
local HandOffServiceShared = require(ReplicatedStorage.Shared.Services.HandOffService.HandOffServiceShared)
local Logger = require(ReplicatedStorage.Shared.Modules.Core.Logger)
local Networker = require(ReplicatedStorage.Packages.Networker)

local HandOffServiceClient = {}
HandOffServiceClient.__index = HandOffServiceClient

export type HandOffServiceClient = typeof(setmetatable(
	{} :: {
		_networker: Networker.Client?,
		_menuModule: any?,
	},
	HandOffServiceClient
))

function HandOffServiceClient.Init(self: HandOffServiceClient)
	self._networker = Networker.client.new("HandOffService", self)
end

function HandOffServiceClient.Start(self: HandOffServiceClient)
	Logger.info("HandOffServiceClient", "Started")

	local ui = ReplicatedStorage:WaitForChild("UI")
	self._menuModule = require(ui.Menus.HandOffMenu)
	self._menuModule.mount({
		getNearbyPlayers = function()
			return self:GetNearbyPlayers()
		end,
		getSnackItems = function()
			return HandOffCatalog.getAll()
		end,
		requestHandOff = function(targetUserId: number, itemId: string)
			return self:RequestHandOff(targetUserId, itemId)
		end,
	})
end

function HandOffServiceClient.GetNearbyPlayers(
	_self: HandOffServiceClient
): { { userId: number, displayName: string, distance: number } }
	local localPlayer = Players.LocalPlayer
	local localRoot = CharacterUtil.getRootPart(localPlayer)
	if not localRoot then
		return {}
	end

	local nearby = {}
	for _, player in Players:GetPlayers() do
		if player ~= localPlayer then
			local root = CharacterUtil.getRootPart(player)
			if root then
				local distance = (localRoot.Position - root.Position).Magnitude
				if distance <= GameConfig.HANDOFF_MAX_DISTANCE then
					table.insert(nearby, {
						userId = player.UserId,
						displayName = player.DisplayName,
						distance = distance,
					})
				end
			end
		end
	end

	table.sort(nearby, function(a, b)
		return a.distance < b.distance
	end)

	return nearby
end

function HandOffServiceClient.RequestHandOff(self: HandOffServiceClient, targetUserId: number, itemId: string): boolean
	if not self._networker then
		return false
	end

	return self._networker:fetch("requestHandOff", targetUserId, itemId) == true
end

function HandOffServiceClient.RespondToHandOff(self: HandOffServiceClient, offerId: string, accept: boolean): boolean
	if not self._networker then
		return false
	end

	return self._networker:fetch("respondToHandOff", offerId, accept) == true
end

function HandOffServiceClient.CancelHandOff(self: HandOffServiceClient, offerId: string): boolean
	if not self._networker then
		return false
	end

	return self._networker:fetch("cancelHandOff", offerId) == true
end

function HandOffServiceClient.receiveHandOffOffer(self: HandOffServiceClient, offer: { [string]: any })
	if not self._menuModule then
		return
	end

	self._menuModule.showIncomingOffer(offer, function(accepted: boolean)
		return self:RespondToHandOff(offer.offerId, accepted)
	end)
end

function HandOffServiceClient.handOffOfferSent(self: HandOffServiceClient, offer: { [string]: any })
	if self._menuModule then
		self._menuModule.showToast(`Offered {offer.itemDisplayName} to {offer.targetDisplayName}.`)
	end
end

function HandOffServiceClient.handOffResult(self: HandOffServiceClient, result: { [string]: any })
	if not self._menuModule then
		return
	end

	local status = result.status
	local message = result.message or "Hand-off updated."
	if status == HandOffServiceShared.STATUS_ACCEPTED then
		self._menuModule.showToast(`Snack shared: {result.itemDisplayName}.`)
	else
		self._menuModule.showToast(message)
	end
end

function HandOffServiceClient.showHandOffVisual(_self: HandOffServiceClient, targetUserId: number, itemId: string)
	local item = HandOffCatalog.get(itemId)
	local target = Players:GetPlayerByUserId(targetUserId)
	if not item or not target then
		return
	end

	local root = CharacterUtil.getRootPart(target)
	if not root then
		return
	end

	local prop = Instance.new("Part")
	prop.Name = "SnackHandOffVisual"
	prop.Size = Vector3.new(0.55, 0.55, 0.18)
	prop.Shape = Enum.PartType.Block
	prop.Material = Enum.Material.SmoothPlastic
	prop.Color = item.color
	prop.CanCollide = false
	prop.CanTouch = false
	prop.CanQuery = false
	prop.Anchored = false
	prop.Massless = true
	prop.CFrame = root.CFrame * CFrame.new(1.2, 0.2, -0.4)
	prop.Parent = workspace

	local weld = Instance.new("WeldConstraint")
	weld.Part0 = root
	weld.Part1 = prop
	weld.Parent = prop

	local label = Instance.new("BillboardGui")
	label.Name = "SnackLabel"
	label.Size = UDim2.fromOffset(120, 32)
	label.StudsOffset = Vector3.new(0, 0.7, 0)
	label.AlwaysOnTop = true
	label.Parent = prop

	local text = Instance.new("TextLabel")
	text.Size = UDim2.fromScale(1, 1)
	text.BackgroundTransparency = 1
	text.TextColor3 = Color3.fromRGB(255, 255, 255)
	text.TextStrokeTransparency = 0.35
	text.Font = Enum.Font.GothamMedium
	text.TextSize = 12
	text.Text = item.displayName
	text.Parent = label

	task.delay(GameConfig.HANDOFF_VISUAL_DISPLAY_SECONDS, function()
		if prop.Parent then
			prop:Destroy()
		end
	end)
end

return setmetatable({} :: HandOffServiceClient, HandOffServiceClient)
