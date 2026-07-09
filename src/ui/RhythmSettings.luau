--!strict

local RhythmSettings = {}

RhythmSettings.DEFAULT_SCROLL_SPEED = 1.4
RhythmSettings.MIN_SCROLL_SPEED = 0.8
RhythmSettings.MAX_SCROLL_SPEED = 3.0
RhythmSettings.SCROLL_SPEED_STEP = 0.1

local scrollSpeed = RhythmSettings.DEFAULT_SCROLL_SPEED

function RhythmSettings.getScrollSpeed(): number
	return scrollSpeed
end

function RhythmSettings.setScrollSpeed(value: number): number
	scrollSpeed = math.clamp(math.floor((value * 10) + 0.5) / 10, RhythmSettings.MIN_SCROLL_SPEED, RhythmSettings.MAX_SCROLL_SPEED)
	return scrollSpeed
end

function RhythmSettings.adjustScrollSpeed(delta: number): number
	return RhythmSettings.setScrollSpeed(scrollSpeed + delta)
end

function RhythmSettings.formatScrollSpeed(value: number?): string
	local speed = value or scrollSpeed
	return string.format("%.1fx", speed)
end

return RhythmSettings
