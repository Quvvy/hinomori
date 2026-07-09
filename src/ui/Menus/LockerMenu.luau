--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LockerConfig = require(ReplicatedStorage.Shared.Modules.Game.LockerConfig)
local LockerDecorCatalog = require(ReplicatedStorage.Shared.Modules.Game.LockerDecorCatalog)
local UiStyle = require(script.Parent.Parent.UiStyle)

export type LockerMenuOpenContext = {
	lockerId: string,
	isOwner: boolean,
	canEdit: boolean,
	displayName: string,
	decor: { { slotId: string, itemId: string } },
	notes: { any },
	strangerNotesEnabled: boolean,
	onClose: () -> (),
	onRefresh: () -> (),
	applyDecor: (slotId: string, itemId: string) -> boolean,
	clearDecor: (slotId: string) -> boolean,
	sendNote: (templateId: string) -> boolean,
	setStrangerNotesEnabled: (enabled: boolean) -> boolean,
	clearNotes: () -> boolean,
	blockNoteSender: (senderUserId: number) -> boolean,
	fetchTemplates: () -> { any },
}

local LockerMenu = {}

local currentGui: ScreenGui? = nil
local selectedSlotId = LockerConfig.SLOT_IDS[1]
local selectedItemId: string? = nil

local function destroyGui()
	if currentGui then
		currentGui:Destroy()
		currentGui = nil
	end
end

local function playerGui(): PlayerGui
	return Players.LocalPlayer:WaitForChild("PlayerGui") :: PlayerGui
end

local function makePaperLabel(
	parent: Instance,
	text: string,
	size: UDim2,
	position: UDim2,
	textSize: number,
	font: Enum.Font?
): TextLabel
	local label = Instance.new("TextLabel")
	label.Size = size
	label.Position = position
	label.BackgroundTransparency = 1
	label.Font = font or Enum.Font.Gotham
	label.TextSize = textSize
	label.TextColor3 = UiStyle.Colors.Graphite
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextYAlignment = Enum.TextYAlignment.Top
	label.TextWrapped = true
	label.Text = text
	label.Parent = parent
	return label
end

local function paperButton(parent: Instance, text: string, size: UDim2, position: UDim2): TextButton
	local button = UiStyle.listRow(parent, text, size, position, false)
	button.Font = Enum.Font.GothamMedium
	button.TextSize = 12
	return button
end

local function itemName(itemId: string): string
	local item = LockerDecorCatalog.get(itemId)
	return if item then item.displayName else itemId
end

local function decorForSlot(decor: { { slotId: string, itemId: string } }, slotId: string): string
	for _, entry in decor do
		if entry.slotId == slotId then
			return itemName(entry.itemId)
		end
	end
	return "empty"
end

local function templateText(templates: { any }, templateId: string): string
	for _, template in templates do
		if template.id == templateId then
			return template.text
		end
	end
	return templateId
end

function LockerMenu.open(context: LockerMenuOpenContext)
	destroyGui()
	selectedSlotId = selectedSlotId or LockerConfig.SLOT_IDS[1]

	local gui = Instance.new("ScreenGui")
	gui.Name = "LockerMenu"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.Parent = playerGui()
	currentGui = gui

	local shade = Instance.new("Frame")
	shade.Size = UDim2.fromScale(1, 1)
	shade.BackgroundColor3 = Color3.fromRGB(18, 16, 14)
	shade.BackgroundTransparency = 0.58
	shade.BorderSizePixel = 0
	shade.Parent = gui

	local paper =
		UiStyle.paperSurface(gui, "LockerNotebook", UDim2.fromOffset(430, 590), UDim2.new(0.5, -215, 0.5, -295))
	UiStyle.line(paper, UDim2.new(1, -40, 0, 1), UDim2.fromOffset(20, 74), UiStyle.Colors.PaperLine, 0.28)
	UiStyle.line(paper, UDim2.new(1, -40, 0, 1), UDim2.fromOffset(20, 304), UiStyle.Colors.PaperLine, 0.28)
	UiStyle.line(paper, UDim2.new(1, -40, 0, 1), UDim2.fromOffset(20, 446), UiStyle.Colors.PaperLine, 0.28)

	local title =
		makePaperLabel(paper, "Locker", UDim2.new(1, -40, 0, 30), UDim2.fromOffset(20, 18), 20, Enum.Font.Garamond)
	title.TextXAlignment = Enum.TextXAlignment.Center
	makePaperLabel(
		paper,
		`{context.displayName}  /  {context.lockerId}`,
		UDim2.new(1, -40, 0, 22),
		UDim2.fromOffset(20, 48),
		12,
		Enum.Font.Gotham
	).TextXAlignment =
		Enum.TextXAlignment.Center

	makePaperLabel(paper, "Decor slots", UDim2.new(1, -40, 0, 22), UDim2.fromOffset(22, 92), 13, Enum.Font.GothamMedium)

	local slotButtons: { [string]: TextButton } = {}
	local function refreshSlotButtons()
		for slotId, button in slotButtons do
			local selected = slotId == selectedSlotId
			button.BackgroundColor3 = if selected then UiStyle.Colors.PaperWarm else Color3.fromRGB(238, 232, 215)
			local stroke = button:FindFirstChildOfClass("UIStroke")
			if stroke then
				stroke.Transparency = if selected then 0.12 else 0.5
			end
		end
	end

	for index, slotId in LockerConfig.SLOT_IDS do
		local button = UiStyle.listRow(
			paper,
			`{slotId}: {decorForSlot(context.decor, slotId)}`,
			UDim2.new(1, -44, 0, 30),
			UDim2.fromOffset(22, 120 + (index - 1) * 36),
			slotId == selectedSlotId
		)
		slotButtons[slotId] = button
		button.MouseButton1Click:Connect(function()
			selectedSlotId = slotId
			refreshSlotButtons()
		end)
	end

	makePaperLabel(
		paper,
		"Starter decor",
		UDim2.new(1, -40, 0, 22),
		UDim2.fromOffset(22, 236),
		13,
		Enum.Font.GothamMedium
	)

	local itemButtons: { [string]: TextButton } = {}
	local function refreshItemButtons()
		for itemId, button in itemButtons do
			local selected = itemId == selectedItemId
			button.BackgroundTransparency = if selected then 0.04 else 0.18
			local stroke = button:FindFirstChildOfClass("UIStroke")
			if stroke then
				stroke.Transparency = if selected then 0.1 else 0.42
			end
		end
	end

	for index, item in LockerDecorCatalog.getStarterItems() do
		local button = Instance.new("TextButton")
		button.Size = UDim2.fromOffset(120, 32)
		button.Position = UDim2.fromOffset(22 + ((index - 1) % 3) * 130, 262)
		button.BackgroundColor3 = item.color
		button.BackgroundTransparency = 0.18
		button.TextColor3 = Color3.fromRGB(28, 26, 22)
		button.Font = Enum.Font.GothamMedium
		button.TextSize = 11
		button.TextWrapped = true
		button.Text = item.displayName
		button.BorderSizePixel = 0
		button.Parent = paper
		UiStyle.corner(button, 5)
		UiStyle.stroke(button, UiStyle.Colors.PaperLine, 0.42)
		itemButtons[item.id] = button
		button.MouseButton1Click:Connect(function()
			selectedItemId = item.id
			refreshItemButtons()
		end)
	end

	if context.canEdit then
		paperButton(paper, "Apply", UDim2.fromOffset(96, 30), UDim2.fromOffset(22, 324)).MouseButton1Click:Connect(
			function()
				if selectedItemId then
					context.applyDecor(selectedSlotId, selectedItemId)
				end
			end
		)

		paperButton(paper, "Clear slot", UDim2.fromOffset(112, 30), UDim2.fromOffset(128, 324)).MouseButton1Click:Connect(
			function()
				context.clearDecor(selectedSlotId)
			end
		)
	end

	makePaperLabel(paper, "Notes", UDim2.new(1, -40, 0, 22), UDim2.fromOffset(22, 368), 13, Enum.Font.GothamMedium)

	local templates = context.fetchTemplates()
	if #context.notes == 0 then
		makePaperLabel(paper, "No notes yet.", UDim2.new(1, -44, 0, 24), UDim2.fromOffset(22, 398), 12, nil)
	else
		for index, note in context.notes do
			if index > 3 then
				break
			end
			local slip = Instance.new("Frame")
			slip.Size = UDim2.fromOffset(122, 52)
			slip.Position = UDim2.fromOffset(22 + (index - 1) * 130, 394)
			slip.BackgroundColor3 = if index % 2 == 0
				then Color3.fromRGB(222, 232, 235)
				else Color3.fromRGB(238, 212, 216)
			slip.BorderSizePixel = 0
			slip.Parent = paper
			UiStyle.corner(slip, 3)
			UiStyle.stroke(slip, UiStyle.Colors.PaperLine, 0.45)

			makePaperLabel(
				slip,
				`{templateText(templates, note.templateId)}\nfrom {note.senderUserId}`,
				UDim2.new(1, -12, 1, -8),
				UDim2.fromOffset(6, 5),
				10,
				Enum.Font.Gotham
			)
		end
	end

	if context.isOwner then
		local toggleText = if context.strangerNotesEnabled then "Close notes" else "Open notes"
		paperButton(paper, toggleText, UDim2.fromOffset(104, 30), UDim2.fromOffset(22, 466)).MouseButton1Click:Connect(
			function()
				context.setStrangerNotesEnabled(not context.strangerNotesEnabled)
			end
		)

		paperButton(paper, "Clear notes", UDim2.fromOffset(112, 30), UDim2.fromOffset(136, 466)).MouseButton1Click:Connect(
			function()
				context.clearNotes()
			end
		)

		local firstNote = context.notes[1]
		if firstNote then
			paperButton(paper, "Block sender", UDim2.fromOffset(126, 30), UDim2.fromOffset(260, 466)).MouseButton1Click:Connect(
				function()
					context.blockNoteSender(firstNote.senderUserId)
				end
			)
		end
	else
		local firstTemplate = templates[1]
		if firstTemplate then
			paperButton(paper, "Leave note", UDim2.fromOffset(120, 30), UDim2.fromOffset(22, 466)).MouseButton1Click:Connect(
				function()
					context.sendNote(firstTemplate.id)
				end
			)
			makePaperLabel(
				paper,
				`Template: {firstTemplate.text}`,
				UDim2.fromOffset(230, 30),
				UDim2.fromOffset(150, 470),
				11,
				Enum.Font.Gotham
			)
		end
	end

	local close = Instance.new("TextButton")
	close.Size = UDim2.fromOffset(82, 30)
	close.Position = UDim2.fromOffset(326, 542)
	close.BackgroundColor3 = UiStyle.Colors.Graphite
	close.TextColor3 = UiStyle.Colors.Paper
	close.Font = Enum.Font.GothamMedium
	close.TextSize = 12
	close.Text = "Close"
	close.BorderSizePixel = 0
	close.Parent = paper
	UiStyle.corner(close, 4)
	close.MouseButton1Click:Connect(function()
		destroyGui()
		context.onClose()
	end)
end

function LockerMenu.close()
	destroyGui()
end

return LockerMenu
