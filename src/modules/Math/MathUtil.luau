--!strict

local MathUtil = {}

function MathUtil.clamp(value: number, minValue: number, maxValue: number): number
	return math.clamp(value, minValue, maxValue)
end

return MathUtil
