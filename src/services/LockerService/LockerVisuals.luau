--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LockerConfig = require(ReplicatedStorage.Shared.Modules.Game.LockerConfig)
local LockerDecorCatalog = require(ReplicatedStorage.Shared.Modules.Game.LockerDecorCatalog)
local LockerWorld = require(ReplicatedStorage.Shared.Services.LockerService.LockerWorld)

export type DecorEntry = {
	slotId: string,
	itemId: string,
}

local LockerVisuals = {}

local function clearSlotVisual(slotPart: BasePart)
	local existing = slotPart:FindFirstChild("DecorVisual")
	if existing then
		existing:Destroy()
	end
end

local function applySlotVisual(slotPart: BasePart, itemId: string)
	clearSlotVisual(slotPart)

	local item = LockerDecorCatalog.get(itemId)
	if not item then
		return
	end

	local surfaceGui = Instance.new("SurfaceGui")
	surfaceGui.Name = "DecorVisual"
	surfaceGui.Face = Enum.NormalId.Front
	surfaceGui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	surfaceGui.PixelsPerStud = 50
	surfaceGui.Parent = slotPart

	local frame = Instance.new("Frame")
	frame.Size = UDim2.fromScale(1, 1)
	frame.BackgroundColor3 = item.color
	frame.BorderSizePixel = 0
	frame.Parent = surfaceGui

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.TextColor3 = Color3.fromRGB(30, 30, 30)
	label.Font = Enum.Font.GothamMedium
	label.TextScaled = true
	label.Text = item.displayName
	label.Parent = frame
end

function LockerVisuals.applyToLocker(lockerModel: Model, decorEntries: { DecorEntry })
	for _, slotId in LockerConfig.SLOT_IDS do
		local slotPart = LockerWorld.getDecorSlotPart(lockerModel, slotId)
		if slotPart then
			clearSlotVisual(slotPart)
		end
	end

	for _, entry in decorEntries do
		local slotPart = LockerWorld.getDecorSlotPart(lockerModel, entry.slotId)
		if slotPart then
			applySlotVisual(slotPart, entry.itemId)
		end
	end
end

function LockerVisuals.applyToLockerId(lockerId: string, decorEntries: { DecorEntry })
	local lockerModel = LockerWorld.findLockerById(lockerId)
	if lockerModel then
		LockerVisuals.applyToLocker(lockerModel, decorEntries)
	end
end

return LockerVisuals
