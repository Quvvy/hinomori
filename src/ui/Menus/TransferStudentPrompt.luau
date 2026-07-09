--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DataServiceClient = require(ReplicatedStorage.Shared.Services.DataService.DataServiceClient)
local UiStyle = require(script.Parent.Parent.UiStyle)

local TransferStudentPrompt = {}

local currentGui: ScreenGui? = nil

local function destroyGui()
	if currentGui then
		currentGui:Destroy()
		currentGui = nil
	end
end

local function makePaperLabel(
	parent: Instance,
	text: string,
	size: UDim2,
	position: UDim2,
	textSize: number,
	font: Enum.Font?
): TextLabel
	local label = Instance.new("TextLabel")
	label.Size = size
	label.Position = position
	label.BackgroundTransparency = 1
	label.Font = font or Enum.Font.Gotham
	label.TextSize = textSize
	label.TextColor3 = UiStyle.Colors.Graphite
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextYAlignment = Enum.TextYAlignment.Top
	label.TextWrapped = true
	label.Text = text
	label.Parent = parent
	return label
end

function TransferStudentPrompt.tryShow(onComplete: (displayName: string) -> boolean)
	local data = DataServiceClient:GetData()
	if data.studentProfile.hasCompletedTransferSetup() then
		return
	end

	if currentGui then
		return
	end

	local player = Players.LocalPlayer
	local playerGui = player:WaitForChild("PlayerGui")

	local gui = Instance.new("ScreenGui")
	gui.Name = "TransferStudentPrompt"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.Parent = playerGui
	currentGui = gui

	local shade = Instance.new("Frame")
	shade.Size = UDim2.fromScale(1, 1)
	shade.BackgroundColor3 = Color3.fromRGB(24, 20, 16)
	shade.BackgroundTransparency = 0.42
	shade.BorderSizePixel = 0
	shade.Parent = gui

	local card =
		UiStyle.paperSurface(gui, "TransferHomeroomCard", UDim2.fromOffset(390, 350), UDim2.new(0.5, -195, 0.5, -175))
	UiStyle.line(card, UDim2.new(1, -44, 0, 1), UDim2.fromOffset(22, 98), UiStyle.Colors.PaperLine, 0.28)
	UiStyle.line(card, UDim2.new(1, -44, 0, 1), UDim2.fromOffset(22, 184), UiStyle.Colors.PaperLine, 0.28)
	UiStyle.line(card, UDim2.new(1, -44, 0, 1), UDim2.fromOffset(22, 254), UiStyle.Colors.PaperLine, 0.28)

	local title =
		makePaperLabel(card, "HINOMORI", UDim2.new(1, -44, 0, 34), UDim2.fromOffset(22, 22), 22, Enum.Font.Garamond)
	title.TextXAlignment = Enum.TextXAlignment.Center

	local subtitle = makePaperLabel(
		card,
		"Transfer / Homeroom Card",
		UDim2.new(1, -44, 0, 24),
		UDim2.fromOffset(22, 56),
		15,
		Enum.Font.Gotham
	)
	subtitle.TextXAlignment = Enum.TextXAlignment.Center

	makePaperLabel(card, "Welcome to Hinomori.", UDim2.new(1, -44, 0, 22), UDim2.fromOffset(22, 78), 12, nil).TextXAlignment =
		Enum.TextXAlignment.Center

	makePaperLabel(card, "Name", UDim2.fromOffset(72, 22), UDim2.fromOffset(34, 116), 12, nil)

	local nameBox = Instance.new("TextBox")
	nameBox.Size = UDim2.fromOffset(238, 32)
	nameBox.Position = UDim2.fromOffset(106, 108)
	nameBox.BackgroundColor3 = Color3.fromRGB(238, 232, 215)
	nameBox.TextColor3 = UiStyle.Colors.Graphite
	nameBox.Font = Enum.Font.Gotham
	nameBox.TextSize = 16
	nameBox.ClearTextOnFocus = false
	nameBox.Text = player.DisplayName
	nameBox.BorderSizePixel = 0
	nameBox.Parent = card
	UiStyle.corner(nameBox, 3)
	UiStyle.stroke(nameBox, UiStyle.Colors.PaperLine, 0.5)

	makePaperLabel(card, "Grade", UDim2.fromOffset(70, 22), UDim2.fromOffset(34, 152), 12, nil)
	makePaperLabel(card, "1", UDim2.fromOffset(68, 24), UDim2.fromOffset(106, 150), 15, Enum.Font.GothamMedium)
	makePaperLabel(card, "Class", UDim2.fromOffset(70, 22), UDim2.fromOffset(198, 152), 12, nil)
	makePaperLabel(card, "B", UDim2.fromOffset(68, 24), UDim2.fromOffset(270, 150), 15, Enum.Font.GothamMedium)

	makePaperLabel(card, "Homeroom Teacher", UDim2.fromOffset(128, 22), UDim2.fromOffset(34, 204), 12, nil)
	makePaperLabel(
		card,
		"Mr. Takeda",
		UDim2.fromOffset(190, 24),
		UDim2.fromOffset(170, 202),
		15,
		Enum.Font.GothamMedium
	)

	local stamp =
		makePaperLabel(card, "MORI", UDim2.fromOffset(58, 34), UDim2.fromOffset(296, 266), 16, Enum.Font.GothamBold)
	stamp.TextColor3 = Color3.fromRGB(166, 64, 55)
	stamp.TextXAlignment = Enum.TextXAlignment.Center
	UiStyle.stroke(stamp, Color3.fromRGB(166, 64, 55), 0.25)

	makePaperLabel(
		card,
		"Let's have a good day.",
		UDim2.fromOffset(220, 22),
		UDim2.fromOffset(34, 270),
		12,
		Enum.Font.Gotham
	)

	local save = Instance.new("TextButton")
	save.Size = UDim2.fromOffset(150, 34)
	save.Position = UDim2.fromOffset(22, 302)
	save.BackgroundColor3 = UiStyle.Colors.Graphite
	save.TextColor3 = UiStyle.Colors.Paper
	save.Font = Enum.Font.GothamMedium
	save.TextSize = 13
	save.Text = "Start school"
	save.BorderSizePixel = 0
	save.Parent = card
	UiStyle.corner(save, 4)

	save.MouseButton1Click:Connect(function()
		local ok = onComplete(nameBox.Text)
		if ok then
			destroyGui()
		end
	end)
end

return TransferStudentPrompt
