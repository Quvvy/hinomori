--!strict

local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local RhythmMapParser = require(ReplicatedStorage.Shared.Modules.Game.RhythmMapParser)
local RhythmScoring = require(ReplicatedStorage.Shared.Modules.Game.RhythmScoring)
local RhythmSettings = require(script.Parent.Parent.RhythmSettings)
local UiStyle = require(script.Parent.Parent.UiStyle)

type RhythmSong = {
	id: string,
	displayName: string,
	artist: string,
	difficulty: string,
	laneCount: number,
	workspaceSoundName: string?,
	soundId: string,
	mapText: string,
}

type MissAudioFeedback = {
	onMiss: ((Sound) -> ())?,
	onRecover: ((Sound) -> ())?,
	onCleanup: ((Sound) -> ())?,
}

type RhythmGameOptions = {
	missAudioFeedback: MissAudioFeedback?,
	onStop: (() -> ())?,
}

type FinishResult = {
	score: number,
	maxCombo: number,
	accuracy: number,
	judgments: RhythmScoring.JudgmentCounts,
}

type RuntimeNote = RhythmMapParser.RhythmNote & {
	hit: boolean,
	missed: boolean,
	started: boolean,
	holding: boolean,
	startDeltaMs: number?,
	gui: Frame?,
}

type ActiveSession = {
	gui: ScreenGui,
	sound: Sound,
	startClock: number,
	audioStartMs: number,
	parsedMap: RhythmMapParser.ParsedMap,
	notes: { RuntimeNote },
	laneFrames: { Frame },
	keyLabels: { TextLabel },
	statsLabel: TextLabel,
	judgmentLabel: TextLabel,
	speedLabel: TextLabel,
	score: number,
	combo: number,
	maxCombo: number,
	judgments: RhythmScoring.JudgmentCounts,
	renderConnection: RBXScriptConnection?,
	finished: boolean,
	cleanedUp: boolean,
	onFinish: (FinishResult) -> (),
	options: RhythmGameOptions?,
}

local RhythmGame = {}

local ACTION_PREFIX = "HinomoriRhythmLane"
local INPUT_PRIORITY = 3000
local NOTE_WIDTH_SCALE = 0.76
local NOTE_HEIGHT = 18
local LANE_HEIGHT = 420
local HIT_Y = 352
local SPAWN_Y = 18
local TRAVEL_DISTANCE = HIT_Y - SPAWN_Y

local activeSession: ActiveSession? = nil

local function playerGui(): PlayerGui
	return Players.LocalPlayer:WaitForChild("PlayerGui") :: PlayerGui
end

local function makeTextLabel(parent: Instance, text: string, size: UDim2, position: UDim2, textSize: number): TextLabel
	local label = Instance.new("TextLabel")
	label.Size = size
	label.Position = position
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = UiStyle.Colors.Paper
	label.TextSize = textSize
	label.Font = Enum.Font.GothamMedium
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextYAlignment = Enum.TextYAlignment.Center
	label.Parent = parent
	return label
end

local function makeSmallButton(parent: Instance, text: string, size: UDim2, position: UDim2): TextButton
	local button = Instance.new("TextButton")
	button.Size = size
	button.Position = position
	button.BackgroundColor3 = UiStyle.Colors.InkSoft
	button.BackgroundTransparency = 0.08
	button.BorderSizePixel = 0
	button.Text = text
	button.TextColor3 = UiStyle.Colors.Paper
	button.TextSize = 13
	button.Font = Enum.Font.GothamBold
	button.AutoButtonColor = true
	button.Parent = parent
	return button
end

local function addCorner(instance: GuiObject, radius: number)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius)
	corner.Parent = instance
end

local function addStroke(instance: GuiObject, color: Color3, thickness: number, transparency: number?)
	local stroke = Instance.new("UIStroke")
	stroke.Color = color
	stroke.Thickness = thickness
	stroke.Transparency = transparency or 0
	stroke.Parent = instance
end

local function cloneWorkspaceSound(song: RhythmSong): Sound
	local source = if song.workspaceSoundName then workspace:FindFirstChild(song.workspaceSoundName) else nil
	if source and source:IsA("Sound") then
		local sound = source:Clone()
		sound.TimePosition = 0
		return sound
	end

	local sound = Instance.new("Sound")
	sound.SoundId = song.soundId
	sound.Volume = 0.55
	return sound
end

local function currentApproachSeconds(): number
	return RhythmScoring.approachSecondsForScrollSpeed(RhythmSettings.getScrollSpeed())
end

local function holdPixelHeight(holdMs: number, approachSeconds: number): number
	if holdMs <= 0 then
		return NOTE_HEIGHT
	end

	local holdPixels = TRAVEL_DISTANCE * (holdMs / (approachSeconds * 1000))
	return math.max(NOTE_HEIGHT, NOTE_HEIGHT + math.floor(holdPixels))
end

local function makeNoteGui(laneFrame: Frame, lane: number, holdMs: number): Frame
	local note = Instance.new("Frame")
	note.Name = `Note_{lane}`
	note.AnchorPoint = if holdMs > 0 then Vector2.new(0.5, 1) else Vector2.new(0.5, 0.5)
	note.Size = UDim2.new(NOTE_WIDTH_SCALE, 0, 0, holdPixelHeight(holdMs, currentApproachSeconds()))
	note.Position = UDim2.new(0.5, 0, 0, SPAWN_Y)
	note.BorderSizePixel = 0
	note.BackgroundColor3 = ({
		UiStyle.Colors.ArcadePink,
		UiStyle.Colors.AccentWarm,
		UiStyle.Colors.Accent,
		UiStyle.Colors.ArcadeBlue,
	})[lane] or UiStyle.Colors.Paper
	note.Parent = laneFrame
	addCorner(note, 5)
	return note
end

local function updateSpeedLabel(label: TextLabel)
	label.Text = `Speed {RhythmSettings.formatScrollSpeed()}`
end

local function updateStats(session: ActiveSession)
	local accuracy = RhythmScoring.accuracyFromJudgments(session.judgments, #session.notes)
	session.statsLabel.Text =
		`Score {session.score}    Combo {session.combo}    Accuracy {math.floor(accuracy * 1000) / 10}%`
	updateSpeedLabel(session.speedLabel)
end

local function flashLane(session: ActiveSession, lane: number, pressed: boolean)
	local label = session.keyLabels[lane]
	local laneFrame = session.laneFrames[lane]
	if not label or not laneFrame then
		return
	end

	label.BackgroundColor3 = if pressed then UiStyle.Colors.Paper else UiStyle.Colors.InkSoft
	label.TextColor3 = if pressed then Color3.fromRGB(24, 28, 32) else UiStyle.Colors.Paper
	laneFrame.BackgroundTransparency = if pressed then 0.08 else 0.22
end

local function setJudgmentText(session: ActiveSession, text: string, color: Color3)
	session.judgmentLabel.Text = text
	session.judgmentLabel.TextColor3 = color
end

local function chartTimeMs(session: ActiveSession): number
	if session.sound.IsPlaying then
		return math.max(0, (session.sound.TimePosition * 1000) - session.audioStartMs)
	end

	return (os.clock() - session.startClock) * 1000
end

local function safeCall(callback: (...any) -> (), ...: any)
	local ok, err = pcall(callback, ...)
	if not ok then
		warn(`[Hinomori] RhythmGame callback failed: {err}`)
	end
end

local function recoverMissAudio(session: ActiveSession)
	local feedback = session.options and session.options.missAudioFeedback
	if feedback and feedback.onRecover then
		safeCall(feedback.onRecover, session.sound)
	end
end

local function triggerMissAudio(session: ActiveSession)
	local feedback = session.options and session.options.missAudioFeedback
	if feedback and feedback.onMiss then
		safeCall(feedback.onMiss, session.sound)
	end
end

local function cleanupSession(session: ActiveSession)
	if session.cleanedUp then
		return
	end

	session.cleanedUp = true

	local feedback = session.options and session.options.missAudioFeedback
	if feedback and feedback.onCleanup then
		safeCall(feedback.onCleanup, session.sound)
	end

	if session.options and session.options.onStop then
		safeCall(session.options.onStop)
	end
end

local function finishSession(session: ActiveSession)
	if session.finished then
		return
	end
	session.finished = true

	local accuracy = RhythmScoring.accuracyFromJudgments(session.judgments, #session.notes)
	setJudgmentText(session, "Complete", UiStyle.Colors.Accent)
	updateStats(session)

	session.onFinish({
		score = session.score,
		maxCombo = session.maxCombo,
		accuracy = accuracy,
		judgments = session.judgments,
	})
	cleanupSession(session)

	task.delay(1.25, function()
		if activeSession == session then
			RhythmGame.stop()
		end
	end)
end

local function destroyNoteGui(note: RuntimeNote)
	if note.gui then
		note.gui:Destroy()
		note.gui = nil
	end
end

local function markMiss(session: ActiveSession, note: RuntimeNote)
	if note.hit or note.missed then
		return
	end

	note.missed = true
	note.holding = false
	session.combo = 0
	session.judgments.miss += 1
	destroyNoteGui(note)
	setJudgmentText(session, "Miss", UiStyle.Colors.Danger)
	updateStats(session)
	triggerMissAudio(session)
end

local function addJudgment(session: ActiveSession, judgmentName: string, scoreValue: number)
	recoverMissAudio(session)
	session.score += scoreValue
	session.combo += 1
	session.maxCombo = math.max(session.maxCombo, session.combo)

	if judgmentName == "Perfect" then
		session.judgments.perfect += 1
		setJudgmentText(session, "Perfect", UiStyle.Colors.Paper)
	elseif judgmentName == "Great" then
		session.judgments.great += 1
		setJudgmentText(session, "Great", UiStyle.Colors.Accent)
	else
		session.judgments.good += 1
		setJudgmentText(session, "Good", UiStyle.Colors.AccentWarm)
	end

	updateStats(session)
end

local function completeNote(session: ActiveSession, note: RuntimeNote, judgmentName: string, scoreValue: number)
	if note.hit or note.missed then
		return
	end

	note.hit = true
	note.holding = false
	destroyNoteGui(note)
	addJudgment(session, judgmentName, scoreValue)
end

local function completeHold(session: ActiveSession, note: RuntimeNote)
	local judgmentName, scoreValue = RhythmScoring.judgeDelta(note.startDeltaMs or 0)
	if not judgmentName then
		markMiss(session, note)
		return
	end

	completeNote(session, note, judgmentName, scoreValue)
end

local function findNearestPressableNote(session: ActiveSession, lane: number, nowMs: number): RuntimeNote?
	local nearestNote: RuntimeNote? = nil
	local nearestDelta = RhythmScoring.MISS_WINDOW_MS + 1

	for _, note in session.notes do
		if note.lane == lane and not note.hit and not note.missed and not note.started then
			local delta = nowMs - note.timeMs
			local absoluteDelta = math.abs(delta)
			if absoluteDelta < nearestDelta then
				nearestNote = note
				nearestDelta = absoluteDelta
			end
		end
	end

	return nearestNote
end

local function hitLane(session: ActiveSession, lane: number)
	if session.finished then
		return
	end

	local nowMs = chartTimeMs(session)
	local nearestNote = findNearestPressableNote(session, lane, nowMs)
	if not nearestNote then
		setJudgmentText(session, "Early", UiStyle.Colors.AccentWarm)
		return
	end

	local deltaMs = nowMs - nearestNote.timeMs
	local judgmentName, scoreValue = RhythmScoring.judgeDelta(deltaMs)
	if not judgmentName then
		setJudgmentText(session, "Early", UiStyle.Colors.AccentWarm)
		return
	end

	if nearestNote.holdMs > 0 then
		nearestNote.started = true
		nearestNote.holding = true
		nearestNote.startDeltaMs = deltaMs
		if nearestNote.gui then
			nearestNote.gui.BackgroundTransparency = 0.15
		end
		setJudgmentText(session, "Hold", UiStyle.Colors.PaperWarm)
		return
	end

	completeNote(session, nearestNote, judgmentName, scoreValue)
end

local function releaseLane(session: ActiveSession, lane: number)
	if session.finished then
		return
	end

	local nowMs = chartTimeMs(session)
	for _, note in session.notes do
		if note.lane == lane and note.holding and not note.hit and not note.missed then
			local endMs = note.timeMs + note.holdMs
			if nowMs < endMs - RhythmScoring.HOLD_RELEASE_WINDOW_MS then
				setJudgmentText(session, "Dropped", UiStyle.Colors.Danger)
				markMiss(session, note)
			else
				completeHold(session, note)
			end
			return
		end
	end
end

local function bindInputs(session: ActiveSession)
	for lane, keyCode in RhythmScoring.KEY_CODES do
		ContextActionService:BindActionAtPriority(
			`{ACTION_PREFIX}{lane}`,
			function(_actionName: string, inputState: Enum.UserInputState)
				if inputState == Enum.UserInputState.Begin then
					flashLane(session, lane, true)
					hitLane(session, lane)
				elseif inputState == Enum.UserInputState.End then
					flashLane(session, lane, false)
					releaseLane(session, lane)
				end
				return Enum.ContextActionResult.Sink
			end,
			false,
			INPUT_PRIORITY,
			keyCode
		)
	end
end

local function unbindInputs()
	for lane = 1, RhythmScoring.LANE_COUNT do
		ContextActionService:UnbindAction(`{ACTION_PREFIX}{lane}`)
	end
end

local function updateHoldGui(note: RuntimeNote, y: number, remainingHoldMs: number?)
	if not note.gui then
		return
	end

	local approachSeconds = currentApproachSeconds()
	if note.holdMs > 0 then
		note.gui.Size =
			UDim2.new(NOTE_WIDTH_SCALE, 0, 0, holdPixelHeight(remainingHoldMs or note.holdMs, approachSeconds))
		note.gui.Position = UDim2.new(0.5, 0, 0, y)
	else
		note.gui.Position = UDim2.new(0.5, 0, 0, y)
	end
end

local function renderSession(session: ActiveSession)
	local nowMs = chartTimeMs(session)
	local approachSeconds = currentApproachSeconds()

	for _, note in session.notes do
		if not note.hit and not note.missed then
			if note.holding then
				local endMs = note.timeMs + note.holdMs
				if nowMs >= endMs then
					completeHold(session, note)
				else
					updateHoldGui(note, HIT_Y, endMs - nowMs)
				end
			elseif nowMs > note.timeMs + RhythmScoring.MISS_WINDOW_MS then
				markMiss(session, note)
			else
				local timeUntilSeconds = (note.timeMs - nowMs) / 1000
				if timeUntilSeconds <= approachSeconds then
					local laneFrame = session.laneFrames[note.lane]
					if not note.gui then
						note.gui = makeNoteGui(laneFrame, note.lane, note.holdMs)
					end

					local progress = 1 - math.clamp(timeUntilSeconds / approachSeconds, 0, 1)
					local y = SPAWN_Y + (TRAVEL_DISTANCE * progress)
					updateHoldGui(note, y)
				end
			end
		end
	end

	if nowMs >= session.parsedMap.durationMs + (RhythmScoring.FINISH_PADDING_SECONDS * 1000) then
		finishSession(session)
	end
end

local function makeSessionGui(
	song: RhythmSong,
	parsedMap: RhythmMapParser.ParsedMap
): (ScreenGui, { Frame }, { TextLabel }, TextLabel, TextLabel, TextLabel)
	local gui = Instance.new("ScreenGui")
	gui.Name = "RhythmGameUI"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.Parent = playerGui()

	local shade = Instance.new("Frame")
	shade.Size = UDim2.fromScale(1, 1)
	shade.BackgroundColor3 = Color3.fromRGB(7, 9, 11)
	shade.BackgroundTransparency = 0.42
	shade.BorderSizePixel = 0
	shade.Parent = gui

	local frame = Instance.new("Frame")
	frame.Name = "ArcadeCabinetRhythmView"
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.Position = UDim2.fromScale(0.5, 0.5)
	frame.Size = UDim2.fromOffset(474, 572)
	frame.BackgroundColor3 = UiStyle.Colors.Glass
	frame.BackgroundTransparency = 0.04
	frame.BorderSizePixel = 0
	frame.Parent = gui
	addCorner(frame, 8)
	addStroke(frame, UiStyle.Colors.GlassLine, 1, 0.42)

	makeTextLabel(frame, song.displayName, UDim2.new(1, -24, 0, 28), UDim2.fromOffset(12, 10), 17).Font =
		Enum.Font.GothamBold
	makeTextLabel(
		frame,
		`{song.difficulty}  /  {#parsedMap.notes} notes`,
		UDim2.new(1, -24, 0, 24),
		UDim2.fromOffset(12, 36),
		12
	)

	local statsLabel = makeTextLabel(
		frame,
		"Score 0    Combo 0    Accuracy 0%",
		UDim2.new(1, -180, 0, 24),
		UDim2.fromOffset(12, 62),
		12
	)
	local speedLabel = makeTextLabel(
		frame,
		`Speed {RhythmSettings.formatScrollSpeed()}`,
		UDim2.fromOffset(78, 24),
		UDim2.fromOffset(288, 62),
		12
	)
	updateSpeedLabel(speedLabel)

	local slowerButton = makeSmallButton(frame, "-", UDim2.fromOffset(28, 24), UDim2.fromOffset(368, 62))
	addCorner(slowerButton, 5)
	slowerButton.MouseButton1Click:Connect(function()
		RhythmSettings.adjustScrollSpeed(-RhythmSettings.SCROLL_SPEED_STEP)
		updateSpeedLabel(speedLabel)
	end)

	local fasterButton = makeSmallButton(frame, "+", UDim2.fromOffset(28, 24), UDim2.fromOffset(402, 62))
	addCorner(fasterButton, 5)
	fasterButton.MouseButton1Click:Connect(function()
		RhythmSettings.adjustScrollSpeed(RhythmSettings.SCROLL_SPEED_STEP)
		updateSpeedLabel(speedLabel)
	end)

	local judgmentLabel = makeTextLabel(frame, "Ready", UDim2.new(1, -24, 0, 34), UDim2.fromOffset(12, 86), 22)
	judgmentLabel.Font = Enum.Font.GothamBold
	judgmentLabel.TextXAlignment = Enum.TextXAlignment.Center

	local laneRoot = Instance.new("Frame")
	laneRoot.Name = "Lanes"
	laneRoot.Size = UDim2.fromOffset(426, LANE_HEIGHT)
	laneRoot.Position = UDim2.fromOffset(24, 126)
	laneRoot.BackgroundTransparency = 1
	laneRoot.Parent = frame

	local laneFrames = {}
	local keyLabels = {}
	local laneWidth = 426 / RhythmScoring.LANE_COUNT
	for lane = 1, RhythmScoring.LANE_COUNT do
		local laneFrame = Instance.new("Frame")
		laneFrame.Name = `Lane_{lane}`
		laneFrame.Size = UDim2.fromOffset(laneWidth - 6, LANE_HEIGHT)
		laneFrame.Position = UDim2.fromOffset((lane - 1) * laneWidth + 3, 0)
		laneFrame.BackgroundColor3 = Color3.fromRGB(20, 25, 31)
		laneFrame.BackgroundTransparency = 0.16
		laneFrame.BorderSizePixel = 0
		laneFrame.ClipsDescendants = true
		laneFrame.Parent = laneRoot
		addCorner(laneFrame, 6)

		local hitLine = Instance.new("Frame")
		hitLine.Size = UDim2.new(1, -10, 0, 4)
		hitLine.Position = UDim2.fromOffset(5, HIT_Y)
		hitLine.BackgroundColor3 = UiStyle.Colors.Paper
		hitLine.BorderSizePixel = 0
		hitLine.Parent = laneFrame
		addCorner(hitLine, 2)

		local keyLabel = Instance.new("TextLabel")
		keyLabel.Name = `Key_{lane}`
		keyLabel.AnchorPoint = Vector2.new(0.5, 0.5)
		keyLabel.Size = UDim2.fromOffset(42, 32)
		keyLabel.Position = UDim2.new(0.5, 0, 0, HIT_Y + 36)
		keyLabel.BackgroundColor3 = UiStyle.Colors.Ink
		keyLabel.TextColor3 = UiStyle.Colors.Paper
		keyLabel.Font = Enum.Font.GothamBold
		keyLabel.TextSize = 16
		keyLabel.Text = RhythmScoring.KEY_LABELS[lane]
		keyLabel.Parent = laneFrame
		addCorner(keyLabel, 6)

		laneFrames[lane] = laneFrame
		keyLabels[lane] = keyLabel
	end

	return gui, laneFrames, keyLabels, statsLabel, judgmentLabel, speedLabel
end

function RhythmGame.start(
	match: { [string]: any },
	song: RhythmSong,
	onFinish: (FinishResult) -> (),
	options: RhythmGameOptions?
)
	RhythmGame.stop()

	local parsedMap = RhythmMapParser.parse(song.mapText)
	local audioStartMs = tonumber(parsedMap.metadata.audiostartms) or 0
	local gui, laneFrames, keyLabels, statsLabel, judgmentLabel, speedLabel = makeSessionGui(song, parsedMap)
	local sound = cloneWorkspaceSound(song)
	sound.Name = "RhythmPlayback"
	sound.Parent = gui
	if audioStartMs > 0 then
		sound.TimePosition = audioStartMs / 1000
	end

	local notes = {}
	for _, note in parsedMap.notes do
		table.insert(notes, {
			timeMs = note.timeMs,
			lane = note.lane,
			holdMs = note.holdMs,
			hit = false,
			missed = false,
			started = false,
			holding = false,
			startDeltaMs = nil,
			gui = nil,
		})
	end

	local session: ActiveSession = {
		gui = gui,
		sound = sound,
		startClock = os.clock(),
		audioStartMs = audioStartMs,
		parsedMap = parsedMap,
		notes = notes,
		laneFrames = laneFrames,
		keyLabels = keyLabels,
		statsLabel = statsLabel,
		judgmentLabel = judgmentLabel,
		speedLabel = speedLabel,
		score = 0,
		combo = 0,
		maxCombo = 0,
		judgments = RhythmScoring.emptyJudgments(),
		renderConnection = nil,
		finished = false,
		cleanedUp = false,
		onFinish = onFinish,
		options = options,
	}

	activeSession = session
	bindInputs(session)
	updateStats(session)

	sound:Play()
	setJudgmentText(session, `Playing {match.mode or "Solo"}`, UiStyle.Colors.Paper)
	session.renderConnection = RunService.RenderStepped:Connect(function()
		renderSession(session)
	end)
end

function RhythmGame.stop()
	local session = activeSession
	if not session then
		return
	end

	activeSession = nil
	unbindInputs()

	if session.renderConnection then
		session.renderConnection:Disconnect()
	end

	cleanupSession(session)

	if session.sound.Parent then
		session.sound:Stop()
	end

	if session.gui.Parent then
		session.gui:Destroy()
	end
end

return RhythmGame
