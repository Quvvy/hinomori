--!strict

local Players = game:GetService("Players")

local UiStyle = require(script.Parent.Parent.UiStyle)

local GarageSkillMenu = {}

type SkillSummary = {
	displayName: string,
	difficulty: string,
	noteCount: number,
	durationSeconds: number,
}

type MountContext = {
	playPart: (() -> ())?,
	leave: (() -> ())?,
}

local context: MountContext? = nil
local rootGui: ScreenGui? = nil
local currentStationId: string? = nil
local currentPlaying = false

local function playerGui(): PlayerGui
	return Players.LocalPlayer:WaitForChild("PlayerGui") :: PlayerGui
end

local function close()
	if rootGui then
		rootGui:Destroy()
		rootGui = nil
	end
	currentStationId = nil
	currentPlaying = false
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

local function render(stationId: string, stationName: string, chart: SkillSummary?, isPlaying: boolean)
	close()
	currentStationId = stationId
	currentPlaying = isPlaying

	rootGui = Instance.new("ScreenGui")
	rootGui.Name = "GarageSkillMenu"
	rootGui.ResetOnSpawn = false
	rootGui.IgnoreGuiInset = true
	rootGui.Parent = playerGui()

	local frame =
		UiStyle.paperSurface(rootGui, "GarageSkillSlip", UDim2.fromOffset(300, 132), UDim2.new(0.5, -150, 1, -168))
	frame.BackgroundTransparency = 0.02

	makeLabel(frame, stationName, UDim2.new(1, -24, 0, 22), UDim2.fromOffset(14, 12), 15).Font = Enum.Font.GothamBold

	local detail = if chart
		then `{chart.displayName} / {chart.difficulty} / {chart.noteCount} notes`
		else "No practice part."
	makeLabel(frame, detail, UDim2.new(1, -24, 0, 34), UDim2.fromOffset(14, 36), 12).TextColor3 = UiStyle.Colors.Pencil

	local playButton = UiStyle.listRow(
		frame,
		if isPlaying then "Playing..." else "Play Part",
		UDim2.fromOffset(132, 36),
		UDim2.fromOffset(14, 82),
		isPlaying
	)
	playButton.Name = "PlayPartButton"
	playButton.AutoButtonColor = chart ~= nil and not isPlaying
	playButton.Active = chart ~= nil and not isPlaying
	playButton.MouseButton1Click:Connect(function()
		if chart and not currentPlaying and context and context.playPart then
			context.playPart()
		end
	end)

	local leaveButton = UiStyle.listRow(frame, "Leave", UDim2.fromOffset(132, 36), UDim2.fromOffset(154, 82), false)
	leaveButton.Name = "LeaveButton"
	leaveButton.MouseButton1Click:Connect(function()
		if context and context.leave then
			context.leave()
		end
	end)
end

function GarageSkillMenu.mount(mountContext: MountContext?)
	context = mountContext
	close()
end

function GarageSkillMenu.update(stationId: string?, stationName: string?, chart: SkillSummary?, isPlaying: boolean?)
	if not stationId or not stationName then
		close()
		return
	end

	if rootGui and currentStationId == stationId and currentPlaying == (isPlaying == true) then
		return
	end

	render(stationId, stationName, chart, isPlaying == true)
end

function GarageSkillMenu.close()
	close()
end

return GarageSkillMenu
