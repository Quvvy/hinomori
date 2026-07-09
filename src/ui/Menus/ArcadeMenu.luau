--!strict

local Players = game:GetService("Players")

local UiStyle = require(script.Parent.Parent.UiStyle)

export type MountContext = {
	open: () -> (),
	refresh: () -> { [string]: any }?,
	joinQueue: () -> boolean,
	leaveQueue: () -> boolean,
	joinSpectators: () -> boolean,
	leaveSpectators: () -> boolean,
	startSolo: (songId: string) -> boolean,
	startDuel: (songId: string) -> boolean,
	finishMatch: (matchId: string) -> boolean,
}

local ArcadeMenu = {}

local rootGui: ScreenGui? = nil
local menuFrame: Frame? = nil
local toastGui: ScreenGui? = nil
local context: MountContext? = nil
local currentState: { [string]: any }? = nil
local selectedSongId: string? = nil

local function playerGui(): PlayerGui
	return Players.LocalPlayer:WaitForChild("PlayerGui") :: PlayerGui
end

local function makeGlassLabel(parent: Instance, text: string, size: UDim2, position: UDim2, textSize: number): TextLabel
	local label = Instance.new("TextLabel")
	label.Size = size
	label.Position = position
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.Gotham
	label.TextSize = textSize
	label.TextColor3 = UiStyle.Colors.Paper
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextYAlignment = Enum.TextYAlignment.Top
	label.TextWrapped = true
	label.Text = text
	label.Parent = parent
	return label
end

local function makeGlassButton(parent: Instance, text: string, size: UDim2, position: UDim2): TextButton
	local button = UiStyle.button(parent, text, size, position)
	button.BackgroundTransparency = 0.12
	button.TextSize = 12
	return button
end

local function destroyMenu()
	if menuFrame then
		menuFrame:Destroy()
		menuFrame = nil
	end
end

local function firstSongId(state: { [string]: any }): string?
	for _, song in state.songs or {} do
		return song.id
	end
	return nil
end

local function selectedSongExists(state: { [string]: any }): boolean
	if not selectedSongId then
		return false
	end

	for _, song in state.songs or {} do
		if song.id == selectedSongId then
			return true
		end
	end

	return false
end

local function namesFromEntries(entries: { any }): string
	local names = {}
	for _, entry in entries do
		table.insert(names, entry.displayName or "Student")
	end
	if #names == 0 then
		return "(none)"
	end
	return table.concat(names, ", ")
end

local function rerender()
	if currentState then
		ArcadeMenu.open(currentState)
	end
end

function ArcadeMenu.mount(mountContext: MountContext)
	context = mountContext
	if rootGui then
		rootGui:Destroy()
	end

	rootGui = Instance.new("ScreenGui")
	rootGui.Name = "ArcadeUI"
	rootGui.ResetOnSpawn = false
	rootGui.IgnoreGuiInset = true
	rootGui.Parent = playerGui()
end

function ArcadeMenu.open(state: { [string]: any })
	currentState = state
	if not rootGui or not context then
		return
	end

	if not selectedSongExists(state) then
		selectedSongId = firstSongId(state)
	end

	destroyMenu()

	local frame =
		UiStyle.worldSurface(rootGui, "ArcadeCabinetMenu", UDim2.fromOffset(452, 510), UDim2.new(0.5, -226, 0.5, -255))
	menuFrame = frame

	makeGlassLabel(frame, "HINOMORI ARCADE", UDim2.new(1, -24, 0, 28), UDim2.fromOffset(12, 12), 18).Font =
		Enum.Font.GothamBold
	makeGlassLabel(frame, `Tickets: {state.ticketCount or 0}`, UDim2.new(1, -24, 0, 20), UDim2.fromOffset(12, 42), 12)

	makeGlassLabel(frame, "Song select", UDim2.new(1, -24, 0, 20), UDim2.fromOffset(12, 72), 13).Font =
		Enum.Font.GothamMedium
	local songList = Instance.new("ScrollingFrame")
	songList.Name = "SongList"
	songList.Size = UDim2.new(1, -24, 0, 116)
	songList.Position = UDim2.fromOffset(12, 96)
	songList.BackgroundColor3 = Color3.fromRGB(20, 25, 31)
	songList.BackgroundTransparency = 0.06
	songList.BorderSizePixel = 0
	songList.ScrollBarThickness = 4
	songList.CanvasSize = UDim2.fromOffset(0, math.max(1, #(state.songs or {})) * 36)
	songList.Parent = frame
	UiStyle.corner(songList, 5)
	UiStyle.stroke(songList, UiStyle.Colors.GlassLine, 0.72)

	for index, song in state.songs or {} do
		local selected = song.id == selectedSongId
		local button = makeGlassButton(
			songList,
			`{song.displayName}  /  {song.difficulty}  /  {song.noteCount} notes`,
			UDim2.new(1, -8, 0, 30),
			UDim2.fromOffset(4, 4 + (index - 1) * 36)
		)
		button.TextXAlignment = Enum.TextXAlignment.Left
		button.BackgroundColor3 = if selected then UiStyle.Colors.ArcadeBlue else UiStyle.Colors.InkSoft
		button.TextColor3 = if selected then Color3.fromRGB(12, 18, 24) else UiStyle.Colors.Paper
		button.MouseButton1Click:Connect(function()
			selectedSongId = song.id
			rerender()
		end)
	end

	makeGlassLabel(frame, "Queue", UDim2.fromOffset(196, 20), UDim2.fromOffset(12, 228), 13).Font =
		Enum.Font.GothamMedium
	makeGlassLabel(frame, namesFromEntries(state.queue or {}), UDim2.fromOffset(196, 48), UDim2.fromOffset(12, 252), 12)

	makeGlassLabel(frame, "Watching", UDim2.fromOffset(196, 20), UDim2.fromOffset(236, 228), 13).Font =
		Enum.Font.GothamMedium
	makeGlassLabel(
		frame,
		namesFromEntries(state.spectators or {}),
		UDim2.fromOffset(196, 48),
		UDim2.fromOffset(236, 252),
		12
	)

	local activeText = "No active match."
	if state.activeMatch then
		local songName = if state.activeMatch.song then state.activeMatch.song.displayName else "song"
		activeText = `{state.activeMatch.mode} / {songName}\n{namesFromEntries(state.activeMatch.players or {})}`
	end
	makeGlassLabel(frame, "Current cabinet", UDim2.new(1, -24, 0, 20), UDim2.fromOffset(12, 314), 13).Font =
		Enum.Font.GothamMedium
	makeGlassLabel(frame, activeText, UDim2.new(1, -24, 0, 48), UDim2.fromOffset(12, 338), 12)

	makeGlassButton(frame, "Join queue", UDim2.fromOffset(128, 30), UDim2.fromOffset(12, 398)).MouseButton1Click:Connect(
		function()
			if context and context.joinQueue() then
				task.defer(function()
					if context then
						currentState = context.refresh()
						rerender()
					end
				end)
			else
				ArcadeMenu.showToast("Could not join queue.")
			end
		end
	)

	makeGlassButton(frame, "Leave queue", UDim2.fromOffset(128, 30), UDim2.fromOffset(156, 398)).MouseButton1Click:Connect(
		function()
			if context and context.leaveQueue() then
				currentState = context.refresh()
				rerender()
			end
		end
	)

	makeGlassButton(frame, "Watch", UDim2.fromOffset(96, 30), UDim2.fromOffset(224, 398)).MouseButton1Click:Connect(
		function()
			if context and context.joinSpectators() then
				currentState = context.refresh()
				rerender()
			else
				ArcadeMenu.showToast("Could not watch from here.")
			end
		end
	)

	makeGlassButton(frame, "Stop watching", UDim2.fromOffset(108, 30), UDim2.fromOffset(326, 398)).MouseButton1Click:Connect(
		function()
			if context and context.leaveSpectators() then
				currentState = context.refresh()
				rerender()
			else
				ArcadeMenu.showToast("You are not watching.")
			end
		end
	)

	makeGlassButton(frame, "Solo", UDim2.fromOffset(128, 30), UDim2.fromOffset(12, 438)).MouseButton1Click:Connect(
		function()
			if context and selectedSongId and context.startSolo(selectedSongId) then
				currentState = context.refresh()
				rerender()
			else
				ArcadeMenu.showToast("Solo starts from the front of queue.")
			end
		end
	)

	makeGlassButton(frame, "1v1", UDim2.fromOffset(128, 30), UDim2.fromOffset(156, 438)).MouseButton1Click:Connect(
		function()
			if context and selectedSongId and context.startDuel(selectedSongId) then
				currentState = context.refresh()
				rerender()
			else
				ArcadeMenu.showToast("1v1 needs the first two queued players.")
			end
		end
	)

	makeGlassButton(frame, "Refresh", UDim2.fromOffset(100, 30), UDim2.fromOffset(300, 438)).MouseButton1Click:Connect(
		function()
			if context then
				currentState = context.refresh()
				rerender()
			end
		end
	)

	makeGlassButton(frame, "Close", UDim2.fromOffset(100, 30), UDim2.fromOffset(328, 466)).MouseButton1Click:Connect(
		function()
			destroyMenu()
		end
	)
end

function ArcadeMenu.close()
	destroyMenu()
end

function ArcadeMenu.updateState(state: { [string]: any })
	currentState = state
	if menuFrame then
		ArcadeMenu.open(state)
	end
end

function ArcadeMenu.showMatchResult(result: { [string]: any })
	local songName = if result.song then result.song.displayName else "Song"
	local lines = { `-- Match result --`, `{songName}` }
	for _, participant in result.participants or {} do
		local accuracy = math.floor((participant.accuracy or 0) * 1000) / 10
		table.insert(
			lines,
			`{participant.displayName}: {participant.score} / {accuracy}% / combo {participant.maxCombo or 0}`
		)
	end
	ArcadeMenu.showToast(table.concat(lines, "\n"), 3.6)
end

function ArcadeMenu.showToast(message: string, duration: number?)
	if toastGui then
		toastGui:Destroy()
	end

	local gui =
		UiStyle.toastSlip(playerGui(), "ArcadeToast", message, UDim2.fromOffset(430, 92), UDim2.new(0.5, -215, 0.76, 0))
	toastGui = gui

	task.delay(duration or 3, function()
		if gui.Parent then
			gui:Destroy()
		end
		if toastGui == gui then
			toastGui = nil
		end
	end)
end

return ArcadeMenu
