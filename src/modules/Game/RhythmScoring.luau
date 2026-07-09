--!strict

local RhythmScoring = {}

RhythmScoring.LANE_COUNT = 4
RhythmScoring.BASE_APPROACH_SECONDS = 1.65
RhythmScoring.FINISH_PADDING_SECONDS = 1.2
RhythmScoring.MAX_NOTE_SCORE = 1000
RhythmScoring.HOLD_RELEASE_WINDOW_MS = 140

RhythmScoring.KEY_LABELS = { "D", "F", "J", "K" }
RhythmScoring.KEY_CODES = {
	Enum.KeyCode.D,
	Enum.KeyCode.F,
	Enum.KeyCode.J,
	Enum.KeyCode.K,
}

RhythmScoring.JUDGMENTS = {
	{
		name = "Perfect",
		windowMs = 60,
		score = 1000,
		weight = 1,
	},
	{
		name = "Great",
		windowMs = 115,
		score = 700,
		weight = 0.72,
	},
	{
		name = "Good",
		windowMs = 180,
		score = 400,
		weight = 0.42,
	},
}

RhythmScoring.MISS_WINDOW_MS = 230

export type JudgmentCounts = {
	perfect: number,
	great: number,
	good: number,
	miss: number,
}

function RhythmScoring.approachSecondsForScrollSpeed(scrollSpeed: number): number
	return RhythmScoring.BASE_APPROACH_SECONDS / math.max(scrollSpeed, 0.1)
end

function RhythmScoring.judgeDelta(deltaMs: number): (string?, number, number)
	local absoluteDelta = math.abs(deltaMs)
	for _, judgment in RhythmScoring.JUDGMENTS do
		if absoluteDelta <= judgment.windowMs then
			return judgment.name, judgment.score, judgment.weight
		end
	end

	return nil, 0, 0
end

function RhythmScoring.emptyJudgments(): JudgmentCounts
	return {
		perfect = 0,
		great = 0,
		good = 0,
		miss = 0,
	}
end

function RhythmScoring.scoreFromJudgments(judgments: JudgmentCounts): number
	return (judgments.perfect * 1000) + (judgments.great * 700) + (judgments.good * 400)
end

function RhythmScoring.accuracyFromJudgments(judgments: JudgmentCounts, noteCount: number): number
	if noteCount <= 0 then
		return 0
	end

	local weightedHits = judgments.perfect + (judgments.great * 0.72) + (judgments.good * 0.42)
	return math.clamp(weightedHits / noteCount, 0, 1)
end

function RhythmScoring.maxScore(noteCount: number): number
	return math.max(noteCount, 0) * RhythmScoring.MAX_NOTE_SCORE
end

return RhythmScoring
