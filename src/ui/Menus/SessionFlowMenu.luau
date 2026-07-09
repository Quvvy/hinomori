--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local SessionServiceShared = require(ReplicatedStorage.Shared.Services.SessionService.SessionServiceShared)
local UiStyle = require(script.Parent.Parent.UiStyle)

export type MountContext = {
	refresh: () -> { [string]: any }?,
	advancePhase: () -> { [string]: any }?,
	setPhase: (phase: string) -> { [string]: any }?,
}

local SessionFlowMenu = {}

local rootGui: ScreenGui? = nil
local phaseLabel: TextLabel? = nil
local schoolLabel: TextLabel? = nil
local statusLabel: TextLabel? = nil
local toolsButton: TextButton? = nil
local controlsPanel: Frame? = nil
local context: MountContext? = nil
local currentState: { [string]: any }? = nil
local statusText: string? = nil
local controlsVisible = false

local function playerGui(): PlayerGui
	return Players.LocalPlayer:WaitForChild("PlayerGui") :: PlayerGui
end

local function phaseText(state: { [string]: any }?): string
	if not state then
		return "Morning arrival"
	end
	if state.phase == SessionServiceShared.PHASE_BUS_PROLOGUE then
		return "Morning arrival"
	elseif state.phase == SessionServiceShared.PHASE_SCHOOL then
		return "School day"
	elseif state.phase == SessionServiceShared.PHASE_AFTER_SCHOOL then
		return "After school"
	end
	return "School day"
end

local function timeText(state: { [string]: any }?): string
	if not state then
		return "7:42 AM"
	end
	if state.phase == SessionServiceShared.PHASE_AFTER_SCHOOL then
		return "3:48 PM"
	elseif state.phase == SessionServiceShared.PHASE_SCHOOL then
		return "8:15 AM"
	end
	return "7:42 AM"
end

local function setControlsVisible(visible: boolean)
	controlsVisible = visible
	if controlsPanel then
		controlsPanel.Visible = controlsVisible
	end
	if toolsButton then
		toolsButton.Text = if controlsVisible then "Hide" else "Tools"
	end
end

local function updateLabels()
	if phaseLabel then
		phaseLabel.Text = phaseText(currentState)
	end
	if schoolLabel then
		schoolLabel.Text = `Hinomori High School\n{timeText(currentState)}`
	end
	if statusLabel then
		statusLabel.Text = statusText or (if currentState then "" else "Waiting for homeroom...")
	end
end

local function makeControlButton(parent: Instance, text: string, size: UDim2, position: UDim2): TextButton
	local button = UiStyle.button(parent, text, size, position)
	button.TextSize = 12
	return button
end

local function applyRequestedState(state: { [string]: any }?, failureMessage: string)
	if state then
		currentState = state
		statusText = nil
	else
		statusText = failureMessage
	end
	updateLabels()
end

local function addControls(parent: Frame)
	makeControlButton(parent, "Next", UDim2.fromOffset(72, 26), UDim2.fromOffset(10, 10)).MouseButton1Click:Connect(
		function()
			if context then
				applyRequestedState(context.advancePhase(), "The day is not ready yet.")
			end
		end
	)

	makeControlButton(parent, "School", UDim2.fromOffset(72, 26), UDim2.fromOffset(88, 10)).MouseButton1Click:Connect(
		function()
			if context then
				applyRequestedState(context.setPhase(SessionServiceShared.PHASE_SCHOOL), "The day is not ready yet.")
			end
		end
	)

	makeControlButton(parent, "After", UDim2.fromOffset(72, 26), UDim2.fromOffset(166, 10)).MouseButton1Click:Connect(
		function()
			if context then
				applyRequestedState(
					context.setPhase(SessionServiceShared.PHASE_AFTER_SCHOOL),
					"The day is not ready yet."
				)
			end
		end
	)

	makeControlButton(parent, "Morning", UDim2.fromOffset(96, 26), UDim2.fromOffset(10, 46)).MouseButton1Click:Connect(
		function()
			if context then
				applyRequestedState(
					context.setPhase(SessionServiceShared.PHASE_BUS_PROLOGUE),
					"The day is not ready yet."
				)
			end
		end
	)

	makeControlButton(parent, "Refresh", UDim2.fromOffset(96, 26), UDim2.fromOffset(114, 46)).MouseButton1Click:Connect(
		function()
			if context then
				applyRequestedState(context.refresh(), "Still waiting for homeroom.")
			end
		end
	)
end

function SessionFlowMenu.mount(mountContext: MountContext)
	context = mountContext
	if rootGui then
		rootGui:Destroy()
	end

	rootGui = Instance.new("ScreenGui")
	rootGui.Name = "SessionFlowUI"
	rootGui.ResetOnSpawn = false
	rootGui.IgnoreGuiInset = true
	rootGui.Parent = playerGui()
	currentState = nil
	statusText = nil
	controlsVisible = false

	phaseLabel =
		UiStyle.tinyHudLabel(rootGui, "Morning arrival", UDim2.fromOffset(230, 24), UDim2.fromOffset(16, 74), 16)
	phaseLabel.Font = Enum.Font.GothamMedium

	schoolLabel = UiStyle.tinyHudLabel(
		rootGui,
		"Hinomori High School\n7:42 AM",
		UDim2.fromOffset(230, 46),
		UDim2.fromOffset(16, 102),
		13
	)
	schoolLabel.Font = Enum.Font.Gotham

	statusLabel = UiStyle.tinyHudLabel(rootGui, "", UDim2.fromOffset(250, 34), UDim2.fromOffset(16, 158), 11)
	statusLabel.TextColor3 = Color3.fromRGB(226, 220, 204)

	if RunService:IsStudio() then
		toolsButton = UiStyle.iconButton(rootGui, "Tools", UDim2.fromOffset(56, 28), UDim2.fromOffset(16, 196))
		toolsButton.MouseButton1Click:Connect(function()
			setControlsVisible(not controlsVisible)
		end)

		controlsPanel =
			UiStyle.worldSurface(rootGui, "PrototypeTools", UDim2.fromOffset(248, 84), UDim2.fromOffset(16, 230))
		addControls(controlsPanel)
		setControlsVisible(false)
	end

	updateLabels()
end

function SessionFlowMenu.updateState(state: { [string]: any })
	currentState = state
	statusText = nil
	updateLabels()
end

function SessionFlowMenu.showStatus(message: string)
	statusText = message
	updateLabels()
end

return SessionFlowMenu
