--!strict

local Players = game:GetService("Players")

local UiStyle = require(script.Parent.Parent.UiStyle)

local FirstDayGuide = {}

local rootGui: ScreenGui? = nil
local slip: Frame? = nil
local minimizedButton: TextButton? = nil
local bodyLabel: TextLabel? = nil
local currentStepId: string? = nil
local dismissedStepId: string? = nil

local STEP_TEXT: { [string]: string } = {
	namedSelf = "Write your name on the homeroom card.",
	openedLocker = "Check your locker.",
	decoratedLocker = "Put something small on your locker.",
	sentNote = "Leave a note for someone nearby.",
	sharedSnack = "Share a snack with another student.",
	reachedAfterSchool = "After school, stop by the arcade.",
	playedArcade = "Play one song, then check your locker later.",
}

local function playerGui(): PlayerGui
	return Players.LocalPlayer:WaitForChild("PlayerGui") :: PlayerGui
end

local function setSlipVisible(visible: boolean)
	if slip then
		slip.Visible = visible
	end
	if minimizedButton then
		minimizedButton.Visible = not visible and currentStepId ~= nil
	end
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

function FirstDayGuide.mount()
	if rootGui then
		rootGui:Destroy()
	end

	rootGui = Instance.new("ScreenGui")
	rootGui.Name = "FirstDayGuide"
	rootGui.ResetOnSpawn = false
	rootGui.IgnoreGuiInset = true
	rootGui.Parent = playerGui()

	slip = UiStyle.paperSurface(rootGui, "HomeroomNote", UDim2.fromOffset(280, 108), UDim2.new(0, 16, 1, -132))
	makeLabel(slip, "Homeroom note", UDim2.fromOffset(190, 18), UDim2.fromOffset(16, 12), 12).Font =
		Enum.Font.GothamMedium
	UiStyle.line(slip, UDim2.new(1, -32, 0, 1), UDim2.fromOffset(16, 36), UiStyle.Colors.PaperLine, 0.35)

	bodyLabel = makeLabel(slip, "", UDim2.new(1, -32, 0, 44), UDim2.fromOffset(16, 48), 14)

	local foldButton = Instance.new("TextButton")
	foldButton.Name = "Fold"
	foldButton.Size = UDim2.fromOffset(46, 22)
	foldButton.Position = UDim2.new(1, -60, 0, 10)
	foldButton.BackgroundTransparency = 1
	foldButton.TextColor3 = UiStyle.Colors.Pencil
	foldButton.Font = Enum.Font.GothamMedium
	foldButton.TextSize = 11
	foldButton.Text = "fold"
	foldButton.Parent = slip
	foldButton.MouseButton1Click:Connect(function()
		dismissedStepId = currentStepId
		setSlipVisible(false)
	end)

	minimizedButton = UiStyle.iconButton(rootGui, "Note", UDim2.fromOffset(54, 28), UDim2.new(0, 16, 1, -44))
	minimizedButton.MouseButton1Click:Connect(function()
		dismissedStepId = nil
		setSlipVisible(true)
	end)

	setSlipVisible(false)
end

function FirstDayGuide.updateState(state: { [string]: any })
	local nextStepId = state.nextFirstDayStep
	if typeof(nextStepId) ~= "string" or STEP_TEXT[nextStepId] == nil then
		currentStepId = nil
		dismissedStepId = nil
		if rootGui then
			rootGui.Enabled = false
		end
		return
	end

	if rootGui then
		rootGui.Enabled = true
	end

	local stepChanged = nextStepId ~= currentStepId
	currentStepId = nextStepId

	if bodyLabel then
		bodyLabel.Text = STEP_TEXT[nextStepId]
	end

	if stepChanged then
		dismissedStepId = nil
	end

	setSlipVisible(dismissedStepId ~= currentStepId)
end

return FirstDayGuide
