--!strict

local UiStyle = {}

UiStyle.Colors = {
	Ink = Color3.fromRGB(23, 27, 30),
	InkRaised = Color3.fromRGB(35, 40, 43),
	InkSoft = Color3.fromRGB(53, 58, 61),
	Paper = Color3.fromRGB(244, 238, 221),
	PaperWarm = Color3.fromRGB(232, 219, 194),
	PaperLine = Color3.fromRGB(174, 157, 127),
	Graphite = Color3.fromRGB(58, 53, 47),
	Pencil = Color3.fromRGB(106, 96, 82),
	Muted = Color3.fromRGB(154, 158, 159),
	Accent = Color3.fromRGB(118, 176, 160),
	AccentWarm = Color3.fromRGB(214, 156, 92),
	AccentSoft = Color3.fromRGB(224, 183, 190),
	Danger = Color3.fromRGB(190, 91, 87),
	PhoneShell = Color3.fromRGB(18, 20, 21),
	PhoneScreen = Color3.fromRGB(236, 236, 232),
	PhoneButton = Color3.fromRGB(202, 202, 198),
	Glass = Color3.fromRGB(13, 18, 23),
	GlassLine = Color3.fromRGB(166, 188, 196),
	ArcadeBlue = Color3.fromRGB(97, 156, 218),
	ArcadePink = Color3.fromRGB(216, 119, 155),
}

function UiStyle.corner(instance: GuiObject, radius: number?)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius or 6)
	corner.Parent = instance
	return corner
end

function UiStyle.stroke(instance: GuiObject, color: Color3?, transparency: number?, thickness: number?)
	local stroke = Instance.new("UIStroke")
	stroke.Color = color or UiStyle.Colors.PaperLine
	stroke.Transparency = transparency or 0.35
	stroke.Thickness = thickness or 1
	stroke.Parent = instance
	return stroke
end

function UiStyle.padding(instance: GuiObject, left: number, top: number?, right: number?, bottom: number?): UIPadding
	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, left)
	padding.PaddingTop = UDim.new(0, top or left)
	padding.PaddingRight = UDim.new(0, right or left)
	padding.PaddingBottom = UDim.new(0, bottom or top or left)
	padding.Parent = instance
	return padding
end

function UiStyle.line(parent: Instance, size: UDim2, position: UDim2, color: Color3?, transparency: number?): Frame
	local line = Instance.new("Frame")
	line.Size = size
	line.Position = position
	line.BackgroundColor3 = color or UiStyle.Colors.PaperLine
	line.BackgroundTransparency = transparency or 0.28
	line.BorderSizePixel = 0
	line.Parent = parent
	return line
end

function UiStyle.paperSurface(parent: Instance, name: string, size: UDim2, position: UDim2): Frame
	local frame = Instance.new("Frame")
	frame.Name = name
	frame.Size = size
	frame.Position = position
	frame.BackgroundColor3 = UiStyle.Colors.Paper
	frame.BorderSizePixel = 0
	frame.Parent = parent
	UiStyle.corner(frame, 5)
	UiStyle.stroke(frame, UiStyle.Colors.PaperLine, 0.22)
	return frame
end

function UiStyle.phoneSurface(parent: Instance, name: string, size: UDim2, position: UDim2): Frame
	local frame = Instance.new("Frame")
	frame.Name = name
	frame.Size = size
	frame.Position = position
	frame.BackgroundColor3 = UiStyle.Colors.PhoneShell
	frame.BorderSizePixel = 0
	frame.Parent = parent
	UiStyle.corner(frame, 22)
	UiStyle.stroke(frame, Color3.fromRGB(68, 68, 68), 0.18, 2)

	local screen = Instance.new("Frame")
	screen.Name = "PhoneScreen"
	screen.Size = UDim2.new(1, -18, 1, -34)
	screen.Position = UDim2.fromOffset(9, 18)
	screen.BackgroundColor3 = UiStyle.Colors.PhoneScreen
	screen.BorderSizePixel = 0
	screen.Parent = frame
	UiStyle.corner(screen, 8)
	UiStyle.stroke(screen, Color3.fromRGB(18, 18, 18), 0.72)

	return frame
end

function UiStyle.phoneScreen(phoneSurface: Frame): Frame
	local screen = phoneSurface:FindFirstChild("PhoneScreen")
	if screen and screen:IsA("Frame") then
		return screen
	end
	return phoneSurface
end

function UiStyle.worldSurface(parent: Instance, name: string, size: UDim2, position: UDim2): Frame
	local frame = Instance.new("Frame")
	frame.Name = name
	frame.Size = size
	frame.Position = position
	frame.BackgroundColor3 = UiStyle.Colors.Glass
	frame.BackgroundTransparency = 0.1
	frame.BorderSizePixel = 0
	frame.Parent = parent
	UiStyle.corner(frame, 6)
	UiStyle.stroke(frame, UiStyle.Colors.GlassLine, 0.5)
	return frame
end

function UiStyle.tinyHudLabel(
	parent: Instance,
	text: string,
	size: UDim2,
	position: UDim2,
	textSize: number?
): TextLabel
	local label = Instance.new("TextLabel")
	label.Size = size
	label.Position = position
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamMedium
	label.TextSize = textSize or 14
	label.TextColor3 = Color3.fromRGB(248, 246, 238)
	label.TextStrokeColor3 = Color3.fromRGB(15, 17, 18)
	label.TextStrokeTransparency = 0.45
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextYAlignment = Enum.TextYAlignment.Top
	label.TextWrapped = true
	label.Text = text
	label.Parent = parent
	return label
end

function UiStyle.iconButton(parent: Instance, text: string, size: UDim2, position: UDim2): TextButton
	local button = Instance.new("TextButton")
	button.Size = size
	button.Position = position
	button.BackgroundColor3 = Color3.fromRGB(13, 15, 16)
	button.BackgroundTransparency = 0.12
	button.TextColor3 = UiStyle.Colors.Paper
	button.Font = Enum.Font.GothamMedium
	button.TextSize = 12
	button.Text = text
	button.AutoButtonColor = true
	button.BorderSizePixel = 0
	button.Parent = parent
	UiStyle.corner(button, math.max(8, math.floor(size.Y.Offset / 2)))
	UiStyle.stroke(button, Color3.fromRGB(255, 255, 255), 0.82)
	return button
end

function UiStyle.listRow(parent: Instance, text: string, size: UDim2, position: UDim2, selected: boolean?): TextButton
	local row = Instance.new("TextButton")
	row.Size = size
	row.Position = position
	row.BackgroundColor3 = if selected then UiStyle.Colors.PaperWarm else Color3.fromRGB(238, 232, 215)
	row.TextColor3 = UiStyle.Colors.Graphite
	row.Font = Enum.Font.Gotham
	row.TextSize = 13
	row.TextXAlignment = Enum.TextXAlignment.Left
	row.Text = `  {text}`
	row.AutoButtonColor = true
	row.BorderSizePixel = 0
	row.Parent = parent
	UiStyle.corner(row, 4)
	UiStyle.stroke(row, UiStyle.Colors.PaperLine, if selected then 0.12 else 0.5)
	return row
end

function UiStyle.panel(parent: Instance, name: string, size: UDim2, position: UDim2): Frame
	return UiStyle.worldSurface(parent, name, size, position)
end

function UiStyle.button(parent: Instance, text: string, size: UDim2, position: UDim2): TextButton
	local button = Instance.new("TextButton")
	button.Size = size
	button.Position = position
	button.BackgroundColor3 = UiStyle.Colors.InkSoft
	button.TextColor3 = UiStyle.Colors.Paper
	button.Font = Enum.Font.GothamMedium
	button.TextSize = 13
	button.Text = text
	button.AutoButtonColor = true
	button.BorderSizePixel = 0
	button.Parent = parent
	UiStyle.corner(button, 5)
	return button
end

function UiStyle.label(parent: Instance, text: string, size: UDim2, position: UDim2, textSize: number?): TextLabel
	local label = Instance.new("TextLabel")
	label.Size = size
	label.Position = position
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.Gotham
	label.TextSize = textSize or 13
	label.TextColor3 = UiStyle.Colors.Paper
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextYAlignment = Enum.TextYAlignment.Top
	label.TextWrapped = true
	label.Text = text
	label.Parent = parent
	return label
end

function UiStyle.toastSlip(parent: Instance, name: string, message: string, size: UDim2, position: UDim2): ScreenGui
	local gui = Instance.new("ScreenGui")
	gui.Name = name
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.Parent = parent

	local slip = UiStyle.paperSurface(gui, "Slip", size, position)
	slip.BackgroundTransparency = 0.02

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, -20, 1, -14)
	label.Position = UDim2.fromOffset(10, 8)
	label.BackgroundTransparency = 1
	label.TextColor3 = UiStyle.Colors.Graphite
	label.Font = Enum.Font.GothamMedium
	label.TextSize = 13
	label.TextWrapped = true
	label.TextXAlignment = Enum.TextXAlignment.Center
	label.TextYAlignment = Enum.TextYAlignment.Center
	label.Text = message
	label.Parent = slip

	return gui
end

function UiStyle.toast(parent: Instance, name: string, message: string, size: UDim2, position: UDim2): ScreenGui
	return UiStyle.toastSlip(parent, name, message, size, position)
end

return UiStyle
