--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LockerConfig = require(ReplicatedStorage.Shared.Modules.Game.LockerConfig)
local LockerDecorCatalog = require(ReplicatedStorage.Shared.Modules.Game.LockerDecorCatalog)
local NoteServiceShared = require(ReplicatedStorage.Shared.Services.NoteService.NoteServiceShared)
local UiStyle = require(script.Parent.Parent.UiStyle)

export type LockerMenuOpenContext = {
	lockerId: string,
	isOwner: boolean,
	canEdit: boolean,
	displayName: string,
	decor: { { slotId: string, itemId: string } },
	notes: { any },
	friendNotes: { any },
	isFriendOfOwner: boolean,
	strangerNotesEnabled: boolean,
	onClose: () -> (),
	onRefresh: () -> (),
	applyDecor: (slotId: string, itemId: string) -> boolean,
	clearDecor: (slotId: string) -> boolean,
	sendNote: (templateId: string) -> NoteServiceShared.SendStrangerNoteResult,
	sendFriendNote: (rawText: string) -> NoteServiceShared.SendFriendNoteResult,
	setStrangerNotesEnabled: (enabled: boolean) -> boolean,
	clearNotes: () -> boolean,
	blockNoteSender: (senderUserId: number) -> boolean,
	fetchTemplates: () -> { any },
}

local LockerMenu = {}

local currentGui: ScreenGui? = nil
local toastGui: ScreenGui? = nil
local selectedSlotId = LockerConfig.SLOT_IDS[1]
local selectedItemId: string? = nil

local SEND_REASON_MESSAGES = {
	[NoteServiceShared.SEND_REASON_SENT] = "Note left on locker.",
	[NoteServiceShared.SEND_REASON_OWNER_OFFLINE] = "Locker owner must be online.",
	[NoteServiceShared.SEND_REASON_NOTES_DISABLED] = "This locker isn't accepting notes.",
	[NoteServiceShared.SEND_REASON_BLOCKED] = "You can't leave a note here.",
	[NoteServiceShared.SEND_REASON_DAILY_LIMIT] = "You already left enough notes here today.",
	[NoteServiceShared.SEND_REASON_LOCKER_FULL] = "This locker has too many notes.",
	[NoteServiceShared.SEND_REASON_SELF] = "You can't leave a note on your own locker.",
	[NoteServiceShared.SEND_REASON_TOO_FAR] = "Move closer to the locker.",
	[NoteServiceShared.SEND_REASON_INVALID_TEMPLATE] = "That note template isn't available.",
	[NoteServiceShared.SEND_REASON_NOT_FRIENDS] = "Only friends can send personal notes.",
	[NoteServiceShared.SEND_REASON_TEXT_EMPTY] = "Write something first.",
	[NoteServiceShared.SEND_REASON_TEXT_TOO_LONG] = "That note is too long.",
	[NoteServiceShared.SEND_REASON_FILTER_FAILED] = "That message couldn't be sent.",
	[NoteServiceShared.SEND_REASON_UNKNOWN] = "Couldn't leave that note.",
}

local FRIEND_SENT_MESSAGE = "Friend note sent."

local function destroyGui()
	if currentGui then
		currentGui:Destroy()
		currentGui = nil
	end
end

local function playerGui(): PlayerGui
	return Players.LocalPlayer:WaitForChild("PlayerGui") :: PlayerGui
end

local function showToast(message: string, duration: number?)
	if toastGui then
		toastGui:Destroy()
	end

	local gui = UiStyle.toastSlip(
		playerGui(),
		"LockerNoteToast",
		message,
		UDim2.fromOffset(320, 52),
		UDim2.new(0.5, -160, 0.14, 0)
	)
	toastGui = gui

	task.delay(duration or 2.8, function()
		if gui.Parent then
			gui:Destroy()
		end
		if toastGui == gui then
			toastGui = nil
		end
	end)
end

local function sendReasonMessage(reason: string?, isFriend: boolean): string
	if reason == NoteServiceShared.SEND_REASON_SENT and isFriend then
		return FRIEND_SENT_MESSAGE
	end
	if reason and SEND_REASON_MESSAGES[reason] then
		return SEND_REASON_MESSAGES[reason]
	end
	return SEND_REASON_MESSAGES[NoteServiceShared.SEND_REASON_UNKNOWN]
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

local function senderLabel(note: any): string
	if typeof(note.senderDisplayName) == "string" and note.senderDisplayName ~= "" then
		return note.senderDisplayName
	end
	return "Student"
end

local function renderNoteSlip(
	parent: Instance,
	index: number,
	y: number,
	bodyText: string,
	context: LockerMenuOpenContext,
	note: any
)
	local slip = Instance.new("Frame")
	slip.Size = UDim2.fromOffset(122, if context.isOwner then 68 else 52)
	slip.Position = UDim2.fromOffset(22 + (index - 1) * 130, y)
	slip.BackgroundColor3 = if index % 2 == 0 then Color3.fromRGB(222, 232, 235) else Color3.fromRGB(238, 212, 216)
	slip.BorderSizePixel = 0
	slip.Parent = parent
	UiStyle.corner(slip, 3)
	UiStyle.stroke(slip, UiStyle.Colors.PaperLine, 0.45)

	makePaperLabel(
		slip,
		bodyText,
		UDim2.new(1, -12, 0, if context.isOwner then 40 else 44),
		UDim2.fromOffset(6, 5),
		10,
		Enum.Font.Gotham
	)

	if context.isOwner then
		local blockButton = Instance.new("TextButton")
		blockButton.Size = UDim2.fromOffset(52, 18)
		blockButton.Position = UDim2.fromOffset(64, 46)
		blockButton.BackgroundColor3 = UiStyle.Colors.Graphite
		blockButton.TextColor3 = UiStyle.Colors.Paper
		blockButton.Font = Enum.Font.GothamMedium
		blockButton.TextSize = 9
		blockButton.Text = "Block"
		blockButton.BorderSizePixel = 0
		blockButton.Parent = slip
		UiStyle.corner(blockButton, 3)
		blockButton.MouseButton1Click:Connect(function()
			if context.blockNoteSender(note.senderUserId) then
				showToast(`Blocked {senderLabel(note)}.`)
			end
		end)
	end
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
		UiStyle.paperSurface(gui, "LockerNotebook", UDim2.fromOffset(430, 660), UDim2.new(0.5, -215, 0.5, -330))
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

	local notesTop = 368
	makePaperLabel(
		paper,
		"Friend notes",
		UDim2.new(1, -40, 0, 18),
		UDim2.fromOffset(22, notesTop),
		12,
		Enum.Font.GothamMedium
	)

	local friendSlipY = notesTop + 22
	if #context.friendNotes == 0 then
		makePaperLabel(
			paper,
			"No friend notes yet.",
			UDim2.new(1, -44, 0, 20),
			UDim2.fromOffset(22, friendSlipY),
			11,
			nil
		)
	else
		for index, note in context.friendNotes do
			if index > 3 then
				break
			end
			renderNoteSlip(paper, index, friendSlipY, `{note.text}\nfrom {senderLabel(note)}`, context, note)
		end
	end

	local strangerTop = friendSlipY + 78
	makePaperLabel(
		paper,
		"Stranger notes",
		UDim2.new(1, -40, 0, 18),
		UDim2.fromOffset(22, strangerTop),
		12,
		Enum.Font.GothamMedium
	)

	local templates = context.fetchTemplates()
	local strangerSlipY = strangerTop + 22
	if #context.notes == 0 then
		makePaperLabel(
			paper,
			"No stranger notes yet.",
			UDim2.new(1, -44, 0, 20),
			UDim2.fromOffset(22, strangerSlipY),
			11,
			nil
		)
	else
		for index, note in context.notes do
			if index > 3 then
				break
			end
			renderNoteSlip(
				paper,
				index,
				strangerSlipY,
				`{templateText(templates, note.templateId)}\nfrom {senderLabel(note)}`,
				context,
				note
			)
		end
	end

	local controlsTop = strangerSlipY + 78

	if context.isOwner then
		local toggleText = if context.strangerNotesEnabled then "Close stranger notes" else "Open stranger notes"
		paperButton(paper, toggleText, UDim2.fromOffset(132, 30), UDim2.fromOffset(22, controlsTop)).MouseButton1Click:Connect(
			function()
				context.setStrangerNotesEnabled(not context.strangerNotesEnabled)
			end
		)

		paperButton(paper, "Clear notes", UDim2.fromOffset(112, 30), UDim2.fromOffset(164, controlsTop)).MouseButton1Click:Connect(
			function()
				context.clearNotes()
			end
		)
	else
		local visitorTop = controlsTop

		if context.isFriendOfOwner then
			makePaperLabel(
				paper,
				"Leave a friend note",
				UDim2.new(1, -44, 0, 18),
				UDim2.fromOffset(22, visitorTop),
				11,
				Enum.Font.GothamMedium
			)

			local friendInput = Instance.new("TextBox")
			friendInput.Size = UDim2.new(1, -44, 0, 30)
			friendInput.Position = UDim2.fromOffset(22, visitorTop + 22)
			friendInput.BackgroundColor3 = Color3.fromRGB(238, 232, 215)
			friendInput.TextColor3 = UiStyle.Colors.Graphite
			friendInput.PlaceholderText = "Write a short note..."
			friendInput.PlaceholderColor3 = Color3.fromRGB(120, 112, 104)
			friendInput.Font = Enum.Font.Gotham
			friendInput.TextSize = 12
			friendInput.TextXAlignment = Enum.TextXAlignment.Left
			friendInput.ClearTextOnFocus = false
			friendInput.Text = ""
			friendInput.Parent = paper
			UiStyle.corner(friendInput, 4)
			UiStyle.stroke(friendInput, UiStyle.Colors.PaperLine, 0.45)

			paperButton(paper, "Send friend note", UDim2.fromOffset(132, 28), UDim2.fromOffset(22, visitorTop + 58)).MouseButton1Click:Connect(
				function()
					local result = context.sendFriendNote(friendInput.Text)
					showToast(sendReasonMessage(result.reason, true))
					if result.ok then
						friendInput.Text = ""
					end
				end
			)

			visitorTop += 96
		end

		if context.strangerNotesEnabled then
			makePaperLabel(
				paper,
				"Pick a stranger note",
				UDim2.new(1, -44, 0, 18),
				UDim2.fromOffset(22, visitorTop),
				11,
				Enum.Font.GothamMedium
			)

			local templateList = Instance.new("ScrollingFrame")
			templateList.Name = "TemplatePicker"
			templateList.Size = UDim2.new(1, -44, 0, 58)
			templateList.Position = UDim2.fromOffset(22, visitorTop + 20)
			templateList.BackgroundColor3 = Color3.fromRGB(238, 232, 215)
			templateList.BackgroundTransparency = 0.08
			templateList.BorderSizePixel = 0
			templateList.ScrollBarThickness = 4
			templateList.CanvasSize = UDim2.fromOffset(0, math.max(1, #templates) * 26)
			templateList.Parent = paper
			UiStyle.corner(templateList, 4)
			UiStyle.stroke(templateList, UiStyle.Colors.PaperLine, 0.45)

			for index, template in templates do
				local button = paperButton(
					templateList,
					template.text,
					UDim2.new(1, -8, 0, 22),
					UDim2.fromOffset(4, 4 + (index - 1) * 26)
				)
				button.TextXAlignment = Enum.TextXAlignment.Left
				button.TextSize = 10
				button.MouseButton1Click:Connect(function()
					local result = context.sendNote(template.id)
					showToast(sendReasonMessage(result.reason, false))
				end)
			end
		else
			makePaperLabel(
				paper,
				"Stranger notes are closed.",
				UDim2.new(1, -44, 0, 20),
				UDim2.fromOffset(22, visitorTop),
				11,
				nil
			)
		end
	end

	local close = Instance.new("TextButton")
	close.Size = UDim2.fromOffset(82, 30)
	close.Position = UDim2.fromOffset(326, 612)
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
	if toastGui then
		toastGui:Destroy()
		toastGui = nil
	end
end

return LockerMenu
