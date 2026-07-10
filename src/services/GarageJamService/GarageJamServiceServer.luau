--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CharacterUtil = require(ReplicatedStorage.Shared.Modules.Platform.CharacterUtil)
local GameConfig = require(ReplicatedStorage.Shared.Modules.Game.GameConfig)
local GarageJamConfig = require(ReplicatedStorage.Shared.Modules.Game.GarageJamConfig)
local Logger = require(ReplicatedStorage.Shared.Modules.Core.Logger)
local Networker = require(ReplicatedStorage.Packages.Networker)
local Validate = require(ReplicatedStorage.Shared.Modules.Core.Validate)

type MovementLock = {
	walkSpeed: number,
	jumpPower: number,
	jumpHeight: number,
	useJumpPower: boolean,
	autoRotate: boolean,
}

local GarageJamServiceServer = {}
GarageJamServiceServer.__index = GarageJamServiceServer

export type GarageJamServiceServer = typeof(setmetatable(
	{} :: {
		_networker: Networker.Server?,
		_practiceReadyByUserId: { [number]: boolean },
		_stationOccupants: { [string]: number },
		_activeStationByUserId: { [number]: string },
		_movementLocks: { [number]: MovementLock },
		_warnedMissing: { [string]: boolean },
		_jamStartedAtServerTime: number?,
	},
	GarageJamServiceServer
))

local function getPlayerByUserId(userId: number): Player?
	return Players:GetPlayerByUserId(userId)
end

local function playerDisplayName(userId: number): string
	local player = getPlayerByUserId(userId)
	return if player then player.DisplayName else "Student"
end

function GarageJamServiceServer.Init(self: GarageJamServiceServer)
	self._practiceReadyByUserId = {}
	self._stationOccupants = {}
	self._activeStationByUserId = {}
	self._movementLocks = {}
	self._warnedMissing = {}
	self._jamStartedAtServerTime = nil
	self._networker = Networker.server.new("GarageJamService", self, {
		self.requestGarageState,
		self.enterPractice,
		self.joinStation,
		self.leaveStation,
	})
end

function GarageJamServiceServer.Start(self: GarageJamServiceServer)
	Logger.info("GarageJamService", "Started")

	for _, player in Players:GetPlayers() do
		self:_watchPlayer(player)
	end

	Players.PlayerAdded:Connect(function(player: Player)
		self:_watchPlayer(player)
	end)

	Players.PlayerRemoving:Connect(function(player: Player)
		self:_removePlayer(player)
	end)
end

function GarageJamServiceServer.requestGarageState(self: GarageJamServiceServer, player: Player): { [string]: any }
	return self:_stateForPlayer(player)
end

function GarageJamServiceServer.enterPractice(self: GarageJamServiceServer, player: Player): boolean
	if not Validate.isPlayerAlive(player) then
		return false
	end

	local boardPromptPart = GarageJamConfig.getBoardPromptPart()
	if not boardPromptPart then
		self:_warnOnce("boardPromptPart", "RehearsalBoard.PromptPart missing; Practice cannot start.")
		return false
	end

	if not Validate.isWithinDistance(player, boardPromptPart.Position, GameConfig.GARAGE_INTERACT_DISTANCE) then
		return false
	end

	self._practiceReadyByUserId[player.UserId] = true
	self:_broadcastState()
	return true
end

function GarageJamServiceServer.joinStation(self: GarageJamServiceServer, player: Player, stationId: string): boolean
	if typeof(stationId) ~= "string" then
		return false
	end

	local station = GarageJamConfig.getStation(stationId)
	if not station then
		return false
	end

	if not self._practiceReadyByUserId[player.UserId] then
		return false
	end

	if not Validate.isPlayerAlive(player) then
		return false
	end

	local activeStationId = self._activeStationByUserId[player.UserId]
	if activeStationId then
		return activeStationId == stationId
	end

	local occupantUserId = self._stationOccupants[stationId]
	if occupantUserId and occupantUserId ~= player.UserId then
		return false
	end

	local promptPart = GarageJamConfig.getStationPromptPart(station)
	if not promptPart then
		self:_warnOnce(station.id .. ":promptPart", `Missing garage PromptPart for {station.modelName}`)
		return false
	end

	if not Validate.isWithinDistance(player, promptPart.Position, GameConfig.GARAGE_INTERACT_DISTANCE) then
		return false
	end

	local anchor = GarageJamConfig.getStationPlayerAnchor(station)
	if not anchor then
		self:_warnOnce(station.id .. ":anchor", `Missing PlayerAnchor for {station.modelName}`)
		return false
	end

	if not self:_lockPlayerAtAnchor(player, anchor) then
		return false
	end

	self._stationOccupants[stationId] = player.UserId
	self._activeStationByUserId[player.UserId] = stationId
	if not self._jamStartedAtServerTime then
		self._jamStartedAtServerTime = workspace:GetServerTimeNow()
	end

	self:_broadcastState()
	return true
end

function GarageJamServiceServer.leaveStation(self: GarageJamServiceServer, player: Player): boolean
	self:_clearPlayerOccupation(player, true)
	return true
end

function GarageJamServiceServer._watchPlayer(self: GarageJamServiceServer, player: Player)
	local function watchCharacter(character: Model)
		self:_clearPlayerOccupation(player, false)

		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if not humanoid then
			humanoid = character:WaitForChild("Humanoid", 5) :: Humanoid?
		end

		if humanoid then
			humanoid.Died:Connect(function()
				self:_clearPlayerOccupation(player, true)
			end)
		end
	end

	player.CharacterAdded:Connect(watchCharacter)
	if player.Character then
		watchCharacter(player.Character)
	end
end

function GarageJamServiceServer._lockPlayerAtAnchor(
	self: GarageJamServiceServer,
	player: Player,
	anchor: BasePart
): boolean
	local character = player.Character
	if not character then
		return false
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local root = CharacterUtil.getRootPart(player)
	if not humanoid or not root then
		return false
	end

	self:_restoreMovement(player)
	self._movementLocks[player.UserId] = {
		walkSpeed = humanoid.WalkSpeed,
		jumpPower = humanoid.JumpPower,
		jumpHeight = humanoid.JumpHeight,
		useJumpPower = humanoid.UseJumpPower,
		autoRotate = humanoid.AutoRotate,
	}

	root.CFrame = anchor.CFrame
	root.AssemblyLinearVelocity = Vector3.zero
	root.AssemblyAngularVelocity = Vector3.zero
	humanoid.WalkSpeed = 0
	humanoid.JumpPower = 0
	humanoid.JumpHeight = 0
	humanoid.AutoRotate = false
	return true
end

function GarageJamServiceServer._restoreMovement(self: GarageJamServiceServer, player: Player)
	local lock = self._movementLocks[player.UserId]
	if not lock then
		return
	end

	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.UseJumpPower = lock.useJumpPower
		humanoid.WalkSpeed = lock.walkSpeed
		humanoid.JumpPower = lock.jumpPower
		humanoid.JumpHeight = lock.jumpHeight
		humanoid.AutoRotate = lock.autoRotate
	end

	self._movementLocks[player.UserId] = nil
end

function GarageJamServiceServer._clearPlayerOccupation(
	self: GarageJamServiceServer,
	player: Player,
	restoreMovement: boolean
)
	local stationId = self._activeStationByUserId[player.UserId]
	if stationId and self._stationOccupants[stationId] == player.UserId then
		self._stationOccupants[stationId] = nil
	end

	self._activeStationByUserId[player.UserId] = nil
	if restoreMovement then
		self:_restoreMovement(player)
	else
		self._movementLocks[player.UserId] = nil
	end

	self:_resetJamClockIfEmpty()
	self:_broadcastState()
end

function GarageJamServiceServer._removePlayer(self: GarageJamServiceServer, player: Player)
	self:_clearPlayerOccupation(player, true)
	self._practiceReadyByUserId[player.UserId] = nil
	self._movementLocks[player.UserId] = nil
	self:_broadcastState()
end

function GarageJamServiceServer._resetJamClockIfEmpty(self: GarageJamServiceServer)
	for _, userId in self._stationOccupants do
		if userId then
			return
		end
	end

	self._jamStartedAtServerTime = nil
end

function GarageJamServiceServer._stateForPlayer(self: GarageJamServiceServer, player: Player): { [string]: any }
	return {
		practiceReady = self._practiceReadyByUserId[player.UserId] == true,
		stationOccupants = self:_publicStationOccupants(),
		activeStationId = self._activeStationByUserId[player.UserId],
		activeStationByUserId = self:_publicActiveStationByUserId(),
		jamStartedAtServerTime = self._jamStartedAtServerTime,
	}
end

function GarageJamServiceServer._publicStationOccupants(
	self: GarageJamServiceServer
): { [string]: { userId: number, displayName: string } }
	local occupants = {}
	for stationId, userId in self._stationOccupants do
		occupants[stationId] = {
			userId = userId,
			displayName = playerDisplayName(userId),
		}
	end
	return occupants
end

function GarageJamServiceServer._publicActiveStationByUserId(self: GarageJamServiceServer): { [number]: string }
	return table.clone(self._activeStationByUserId)
end

function GarageJamServiceServer._broadcastState(self: GarageJamServiceServer)
	if not self._networker then
		return
	end

	for _, player in Players:GetPlayers() do
		self._networker:fire(player, "garageStateUpdated", self:_stateForPlayer(player))
	end
end

function GarageJamServiceServer._warnOnce(self: GarageJamServiceServer, key: string, message: string)
	if self._warnedMissing[key] then
		return
	end

	self._warnedMissing[key] = true
	Logger.warn("GarageJamService", message)
end

return setmetatable({} :: GarageJamServiceServer, GarageJamServiceServer)
