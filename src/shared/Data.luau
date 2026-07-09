--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Packages = ReplicatedStorage:WaitForChild("Packages")
local DataServiceTyped = require(Packages.DataServiceTyped)
local Shared = ReplicatedStorage:WaitForChild("Shared")
local DataServiceShared = require(Shared.Services.DataService.DataServiceShared)

return DataServiceTyped({
	template = DataServiceShared.PROFILE_TEMPLATE,
	profileStoreIndex = "Hinomori",
	profileStoreDataPrefix = "PLAYER_",
	useMock = RunService:IsStudio(),
})
