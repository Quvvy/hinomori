--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GarageJamConfig = require(ReplicatedStorage.Shared.Modules.Game.GarageJamConfig)
local Logger = require(ReplicatedStorage.Shared.Modules.Core.Logger)
local UiStyle = require(script.Parent.Parent.UiStyle)

local GarageBoardMenu = {}

type MountContext = {
	enterPractice: (() -> boolean)?,
}

local rootGui: ScreenGui? = nil
local toastGui: ScreenGui? = nil
local boundPrompt: ProximityPrompt? = nil
local bindingTaskStarted = false
local warnedMissing = false
local context: MountContext? = nil

local function playerGui(): PlayerGui
	return Players.LocalPlayer:WaitForChild("PlayerGui") :: PlayerGui
end

local function warnMissingOnce(message: string)
	if warnedMissing then
		return
	end

	warnedMissing = true
	Logger.warn("GarageBoardMenu", message)
end

local function makeLabel(parent: Instance, text: string, size: UDim2, position: UDim2, textSize: number): TextLabel
	local label = Instance.new("TextLabel")
	label.Size = size
	label.Position = position
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.Gotham
	label.TextSize = textSize
	label.TextColor3 = UiStyle.Colors.Graphite
	label.TextWrapped = true
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextYAlignment = Enum.TextYAlignment.Top
	label.Text = text
	label.Parent = parent
	return label
end

local function closeMenu()
	if rootGui then
		rootGui:Destroy()
		rootGui = nil
	end
end

local function showToast(message: string, duration: number?)
	if toastGui then
		toastGui:Destroy()
	end

	local gui = UiStyle.toastSlip(
		playerGui(),
		"GarageBoardToast",
		message,
		UDim2.fromOffset(320, 48),
		UDim2.new(0.5, -160, 0.78, 0)
	)
	toastGui = gui

	task.delay(duration or 2.4, function()
		if gui.Parent then
			gui:Destroy()
		end
		if toastGui == gui then
			toastGui = nil
		end
	end)
end

local function styleDisabledRow(row: TextButton)
	row.AutoButtonColor = false
	row.BackgroundColor3 = Color3.fromRGB(230, 224, 207)
	row.TextColor3 = UiStyle.Colors.Pencil
	row.TextTransparency = 0.22

	local stroke = row:FindFirstChildOfClass("UIStroke")
	if stroke then
		stroke.Transparency = 0.65
	end
end

local function wireWarmHover(row: TextButton)
	local normalColor = row.BackgroundColor3
	row.MouseEnter:Connect(function()
		row.BackgroundColor3 = UiStyle.Colors.PaperWarm
	end)
	row.MouseLeave:Connect(function()
		row.BackgroundColor3 = normalColor
	end)
end

function GarageBoardMenu.open()
	closeMenu()

	rootGui = Instance.new("ScreenGui")
	rootGui.Name = "GarageBoardUI"
	rootGui.ResetOnSpawn = false
	rootGui.IgnoreGuiInset = true
	rootGui.Parent = playerGui()

	local frame = UiStyle.paperSurface(
		rootGui,
		"RehearsalBoardPaper",
		UDim2.fromOffset(360, 220),
		UDim2.new(0.5, -180, 0.5, -110)
	)

	makeLabel(frame, "REHEARSAL BOARD", UDim2.new(1, -60, 0, 28), UDim2.fromOffset(18, 16), 18).Font =
		Enum.Font.GothamBold
	makeLabel(frame, "Pick tonight.", UDim2.new(1, -36, 0, 22), UDim2.fromOffset(18, 46), 13).TextColor3 =
		UiStyle.Colors.Pencil
	UiStyle.line(frame, UDim2.new(1, -36, 0, 1), UDim2.fromOffset(18, 74), UiStyle.Colors.PaperLine, 0.42)

	local closeButton = Instance.new("TextButton")
	closeButton.Name = "CloseButton"
	closeButton.Size = UDim2.fromOffset(28, 28)
	closeButton.Position = UDim2.new(1, -38, 0, 12)
	closeButton.BackgroundTransparency = 1
	closeButton.TextColor3 = UiStyle.Colors.Pencil
	closeButton.Font = Enum.Font.GothamMedium
	closeButton.TextSize = 16
	closeButton.Text = "x"
	closeButton.Parent = frame
	closeButton.MouseButton1Click:Connect(closeMenu)

	local practiceRow = UiStyle.listRow(frame, "Practice", UDim2.new(1, -36, 0, 42), UDim2.fromOffset(18, 92), false)
	practiceRow.Name = "PracticeRow"
	wireWarmHover(practiceRow)
	practiceRow.MouseButton1Click:Connect(function()
		local ok = false
		if context and context.enterPractice then
			ok = context.enterPractice()
		end

		if ok then
			closeMenu()
			showToast("Doors are open.")
		else
			showToast("Practice is unavailable.")
		end
	end)

	local showRow = UiStyle.listRow(
		frame,
		"Show - no shows booked yet.",
		UDim2.new(1, -36, 0, 42),
		UDim2.fromOffset(18, 144),
		false
	)
	showRow.Name = "ShowRow"
	styleDisabledRow(showRow)
	showRow.MouseButton1Click:Connect(function()
		showToast("No shows booked yet.")
	end)
end

local function findBoardPrompt(): ProximityPrompt?
	local promptPart = GarageJamConfig.getBoardPromptPart()
	if not promptPart then
		return nil
	end

	local prompt = promptPart:FindFirstChildOfClass("ProximityPrompt")
	return prompt
end

local function bindPrompt(prompt: ProximityPrompt)
	if boundPrompt == prompt then
		return
	end

	boundPrompt = prompt
	prompt:SetAttribute(GarageJamConfig.BOARD_PROMPT_BOUND_ATTRIBUTE, true)
	prompt.Triggered:Connect(function()
		GarageBoardMenu.open()
	end)
end

function GarageBoardMenu.mount(mountContext: MountContext?)
	context = mountContext
	closeMenu()

	if boundPrompt and boundPrompt.Parent then
		return
	end

	if bindingTaskStarted then
		return
	end

	local prompt = findBoardPrompt()
	if prompt then
		bindPrompt(prompt)
		return
	end

	bindingTaskStarted = true
	task.spawn(function()
		for _ = 1, 40 do
			task.wait(0.25)
			prompt = findBoardPrompt()
			if prompt then
				bindPrompt(prompt)
				bindingTaskStarted = false
				return
			end
		end

		bindingTaskStarted = false
		warnMissingOnce("RehearsalBoard.PromptPart.ProximityPrompt not found; board menu unavailable.")
	end)
end

function GarageBoardMenu.showToast(message: string, duration: number?)
	showToast(message, duration)
end

return GarageBoardMenu
