--!strict

local Players = game:GetService("Players")

local UiStyle = require(script.Parent.Parent.UiStyle)

export type NearbyPlayer = {
	userId: number,
	displayName: string,
	distance: number,
}

export type HandOffItem = {
	id: string,
	displayName: string,
	kind: string,
	color: Color3,
}

export type MountContext = {
	getNearbyPlayers: () -> { NearbyPlayer },
	getSnackItems: () -> { HandOffItem },
	requestHandOff: (targetUserId: number, itemId: string) -> boolean,
	getPendingOutgoingOffer: () -> { [string]: any }?,
	cancelPendingHandOff: () -> boolean,
}

local HandOffMenu = {}

local rootGui: ScreenGui? = nil
local phoneFrame: Frame? = nil
local incomingGui: ScreenGui? = nil
local toastGui: ScreenGui? = nil

local selectedTargetUserId: number? = nil
local selectedItemId: string? = nil

local function playerGui(): PlayerGui
	return Players.LocalPlayer:WaitForChild("PlayerGui") :: PlayerGui
end

local function clearMenu()
	if phoneFrame then
		phoneFrame:Destroy()
		phoneFrame = nil
	end
end

local function clearIncoming()
	if incomingGui then
		incomingGui:Destroy()
		incomingGui = nil
	end
end

local function makePhoneLabel(
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

local function makePhoneButton(parent: Instance, text: string, size: UDim2, position: UDim2): TextButton
	local button = Instance.new("TextButton")
	button.Size = size
	button.Position = position
	button.BackgroundColor3 = UiStyle.Colors.PhoneButton
	button.TextColor3 = UiStyle.Colors.Graphite
	button.Font = Enum.Font.GothamMedium
	button.TextSize = 12
	button.Text = text
	button.BorderSizePixel = 0
	button.Parent = parent
	UiStyle.corner(button, 4)
	return button
end

function HandOffMenu.mount(context: MountContext)
	if rootGui then
		rootGui:Destroy()
	end

	rootGui = Instance.new("ScreenGui")
	rootGui.Name = "HandOffUI"
	rootGui.ResetOnSpawn = false
	rootGui.IgnoreGuiInset = true
	rootGui.Parent = playerGui()

	local openButton = UiStyle.iconButton(rootGui, "Phone", UDim2.fromOffset(72, 34), UDim2.new(0.5, -36, 1, -58))
	openButton.MouseButton1Click:Connect(function()
		HandOffMenu.open(context)
	end)
end

function HandOffMenu.open(context: MountContext)
	if not rootGui then
		return
	end

	clearMenu()
	selectedTargetUserId = nil
	selectedItemId = nil

	local phone =
		UiStyle.phoneSurface(rootGui, "StudentPhone", UDim2.fromOffset(286, 514), UDim2.new(1, -306, 0.5, -257))
	phoneFrame = phone
	local screen = UiStyle.phoneScreen(phone)

	makePhoneLabel(
		screen,
		"Hinomori Phone",
		UDim2.new(1, -24, 0, 24),
		UDim2.fromOffset(12, 10),
		11,
		Enum.Font.GothamMedium
	).TextXAlignment =
		Enum.TextXAlignment.Center
	UiStyle.line(screen, UDim2.new(1, -20, 0, 1), UDim2.fromOffset(10, 38), Color3.fromRGB(170, 170, 166), 0.35)

	local pendingOffer = context.getPendingOutgoingOffer()
	if pendingOffer then
		local pendingText = `Waiting: {pendingOffer.targetDisplayName} / {pendingOffer.itemDisplayName}`
		makePhoneLabel(screen, pendingText, UDim2.new(1, -28, 0, 34), UDim2.fromOffset(14, 44), 11, Enum.Font.Gotham)
		makePhoneButton(screen, "Cancel offer", UDim2.fromOffset(118, 28), UDim2.fromOffset(14, 78)).MouseButton1Click:Connect(
			function()
				if context.cancelPendingHandOff() then
					HandOffMenu.showToast("Snack offer cancelled.")
					clearMenu()
				else
					HandOffMenu.showToast("Could not cancel offer.")
				end
			end
		)
	end

	local contentTop = if pendingOffer then 118 else 52

	makePhoneLabel(
		screen,
		"Messages",
		UDim2.new(1, -24, 0, 28),
		UDim2.fromOffset(14, contentTop),
		17,
		Enum.Font.GothamMedium
	)
	makePhoneLabel(
		screen,
		"Send a small snack note to someone nearby.",
		UDim2.new(1, -28, 0, 42),
		UDim2.fromOffset(14, contentTop + 26),
		12,
		Enum.Font.Gotham
	)

	makePhoneLabel(
		screen,
		"Nearby students",
		UDim2.new(1, -28, 0, 22),
		UDim2.fromOffset(14, contentTop + 74),
		12,
		Enum.Font.GothamMedium
	)
	local nearby = context.getNearbyPlayers()
	if #nearby == 0 then
		makePhoneLabel(
			screen,
			"No one close enough.",
			UDim2.new(1, -28, 0, 28),
			UDim2.fromOffset(14, contentTop + 98),
			12,
			nil
		)
	else
		for index, target in nearby do
			if index > 3 then
				break
			end
			local button = UiStyle.listRow(
				screen,
				`{target.displayName}  ({math.floor(target.distance)} st)`,
				UDim2.new(1, -28, 0, 30),
				UDim2.fromOffset(14, contentTop + 96 + (index - 1) * 34),
				false
			)
			button.MouseButton1Click:Connect(function()
				selectedTargetUserId = target.userId
				button.BackgroundColor3 = UiStyle.Colors.PaperWarm
			end)
		end
	end

	makePhoneLabel(
		screen,
		"Snack",
		UDim2.new(1, -28, 0, 22),
		UDim2.fromOffset(14, contentTop + 218),
		12,
		Enum.Font.GothamMedium
	)
	for index, item in context.getSnackItems() do
		local button = Instance.new("TextButton")
		button.Size = UDim2.new(1, -28, 0, 30)
		button.Position = UDim2.fromOffset(14, contentTop + 242 + (index - 1) * 34)
		button.BackgroundColor3 = item.color
		button.BackgroundTransparency = 0.12
		button.TextColor3 = Color3.fromRGB(28, 26, 22)
		button.Font = Enum.Font.GothamMedium
		button.TextSize = 12
		button.TextXAlignment = Enum.TextXAlignment.Left
		button.Text = `  {item.displayName}`
		button.BorderSizePixel = 0
		button.Parent = screen
		UiStyle.corner(button, 4)
		UiStyle.stroke(button, UiStyle.Colors.PaperLine, 0.55)
		button.MouseButton1Click:Connect(function()
			selectedItemId = item.id
			button.BackgroundTransparency = 0
		end)
	end

	makePhoneButton(screen, "Send", UDim2.fromOffset(100, 30), UDim2.fromOffset(14, contentTop + 374)).MouseButton1Click:Connect(
		function()
			if not selectedTargetUserId or not selectedItemId then
				HandOffMenu.showToast("Pick a student and snack first.")
				return
			end

			if context.requestHandOff(selectedTargetUserId, selectedItemId) then
				clearMenu()
			else
				HandOffMenu.showToast("Could not send snack offer.")
			end
		end
	)

	makePhoneButton(screen, "Close", UDim2.fromOffset(92, 30), UDim2.fromOffset(156, contentTop + 374)).MouseButton1Click:Connect(
		function()
			clearMenu()
		end
	)
end

function HandOffMenu.showIncomingOffer(offer: { [string]: any }, respond: (accepted: boolean) -> boolean)
	clearIncoming()

	local gui = Instance.new("ScreenGui")
	gui.Name = "IncomingHandOffOffer"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.Parent = playerGui()
	incomingGui = gui

	local phone = UiStyle.phoneSurface(gui, "IncomingPhone", UDim2.fromOffset(286, 238), UDim2.new(1, -306, 0.58, -119))
	local screen = UiStyle.phoneScreen(phone)

	makePhoneLabel(screen, "Message", UDim2.new(1, -24, 0, 24), UDim2.fromOffset(12, 10), 12, Enum.Font.GothamMedium).TextXAlignment =
		Enum.TextXAlignment.Center
	UiStyle.line(screen, UDim2.new(1, -20, 0, 1), UDim2.fromOffset(10, 38), Color3.fromRGB(170, 170, 166), 0.35)

	local message = `{offer.senderDisplayName} offers you {offer.itemDisplayName}.`
	makePhoneLabel(screen, message, UDim2.new(1, -28, 0, 78), UDim2.fromOffset(14, 58), 14, Enum.Font.GothamMedium)

	makePhoneButton(screen, "Accept", UDim2.fromOffset(104, 30), UDim2.fromOffset(24, 150)).MouseButton1Click:Connect(
		function()
			if respond(true) then
				clearIncoming()
			end
		end
	)

	makePhoneButton(screen, "Decline", UDim2.fromOffset(104, 30), UDim2.fromOffset(142, 150)).MouseButton1Click:Connect(
		function()
			respond(false)
			clearIncoming()
		end
	)
end

function HandOffMenu.showToast(message: string)
	if toastGui then
		toastGui:Destroy()
	end

	local gui = UiStyle.toastSlip(
		playerGui(),
		"HandOffToast",
		message,
		UDim2.fromOffset(320, 46),
		UDim2.new(0.5, -160, 0.82, 0)
	)
	toastGui = gui

	task.delay(2.5, function()
		if gui.Parent then
			gui:Destroy()
		end
		if toastGui == gui then
			toastGui = nil
		end
	end)
end

return HandOffMenu
