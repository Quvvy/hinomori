--!strict

local Validate = {}

function Validate.isPlayerAlive(player: Player): boolean
	local character = player.Character
	if not character then
		return false
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	return humanoid ~= nil and humanoid.Health > 0
end

function Validate.isWithinDistance(player: Player, position: Vector3, maxDistance: number): boolean
	local character = player.Character
	if not character then
		return false
	end

	local root = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root then
		return false
	end

	return (root.Position - position).Magnitude <= maxDistance
end

function Validate.areFriends(player: Player, otherUserId: number): boolean
	if otherUserId == player.UserId then
		return false
	end

	local ok, isFriend = pcall(function()
		return player:IsFriendsWith(otherUserId)
	end)

	return ok and isFriend == true
end

function Validate.checkCooldown(cooldowns: { [string]: number }, key: string, cooldownSeconds: number): boolean
	local now = os.clock()
	local last = cooldowns[key]

	if last and now - last < cooldownSeconds then
		return false
	end

	cooldowns[key] = now
	return true
end

return Validate
