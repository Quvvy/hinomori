--!strict

local CharacterUtil = {}

function CharacterUtil.getRootPart(player: Player): BasePart?
	local character = player.Character
	if not character then
		return nil
	end

	return character:FindFirstChild("HumanoidRootPart") :: BasePart?
end

return CharacterUtil
