--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Janitor = require(ReplicatedStorage.Packages.Janitor)

local SessionHud = require(script.HUD.SessionHud)

local UI = {}
UI.__index = UI

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local janitor = Janitor.new()

local function mount()
	janitor:Cleanup()

	local root = Instance.new("ScreenGui")
	root.Name = "HinomoriUI"
	root.ResetOnSpawn = false
	root.IgnoreGuiInset = true
	root.Parent = playerGui
	janitor:Add(root)

	SessionHud.init(root)
end

mount()
player.CharacterAdded:Connect(mount)

return UI
