-- TestHub: a local UI adapter built from BGSI's own cloned visuals and item APIs.
-- No native control is reparented or connected to the game's setting remotes.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
local assets = ReplicatedStorage:WaitForChild("Assets", 15)
local shared = ReplicatedStorage:WaitForChild("Shared", 15)
assert(assets and shared, "[TestHub] Game assets did not load")
local function path(root, ...)
	for _, name in ipairs({...}) do root = root and root:FindFirstChild(name) end
	return root
end
local function safeRequire(module)
	if not module then return nil end
	local ok, result = pcall(require, module)
	return ok and result or nil
end
local palette = safeRequire(path(shared, "Palette"))
local itemUtil = safeRequire(path(shared, "Utils", "Stats", "ItemUtil"))
local constants = safeRequire(path(shared, "Constants")) or {}
local nativeScreen = playerGui:FindFirstChild("ScreenGui") or playerGui:WaitForChild("ScreenGui", 10)
local nativeSettings = path(nativeScreen, "Settings", "Frame")
local nativeButton = path(assets, "Intro", "Play", "Button")
local nativeRow
local settingsList = path(nativeSettings, "Main", "ScrollingFrame")
if settingsList then
	for _, object in ipairs(settingsList:GetDescendants()) do
		if object:IsA("Frame") and object:FindFirstChild("Information") and object:FindFirstChild("Action") then
			nativeRow = object
			nativeButton = path(object, "Action", "Dropdown", "Button") or nativeButton
			break
		end
	end
end
local textSample = nativeRow and nativeRow:FindFirstChildWhichIsA("TextLabel", true)
	or path(assets, "Intro", "Play", "Button", "Label")
local nativeFont = textSample and textSample.FontFace or Font.fromEnum(Enum.Font.FredokaOne)
local colors = {
	panel = Color3.fromRGB(13, 48, 91), card = Color3.fromRGB(23, 66, 111),
	muted = Color3.fromRGB(174, 210, 239), text = Color3.new(1, 1, 1),
	stroke = Color3.fromRGB(5, 27, 61), cyan = Color3.fromRGB(0, 216, 236),
	green = Color3.fromRGB(82, 255, 51), red = Color3.fromRGB(255, 99, 100),
}
local connections = {}
local library = { Version = "2026.11.04.1", Windows = {} }
local function connect(signal, fn)
	local connection = signal:Connect(fn)
	table.insert(connections, connection)
	return connection
end
local function create(class, props, parent)
	local object = Instance.new(class)
	for key, value in pairs(props or {}) do object[key] = value end
	object.Parent = parent
	return object
end
local function corner(object, radius)
	local existing = object:FindFirstChildOfClass("UICorner")
	if existing then existing.CornerRadius = UDim.new(0, radius); return end
	create("UICorner", {CornerRadius = UDim.new(0, radius)}, object)
end
local function stroke(object, thickness, color)
	local existing = object:FindFirstChildOfClass("UIStroke")
	if existing then existing.Thickness = thickness; existing.Color = color; return end
	create("UIStroke", {Thickness = thickness, Color = color, ApplyStrokeMode = Enum.ApplyStrokeMode.Border}, object)
end
local function stripVisual(source, class)
	local object = source and source.Archivable and source:IsA(class) and source:Clone() or Instance.new(class)
	for _, child in ipairs(object:GetChildren()) do
		if not child:IsA("UICorner") and not child:IsA("UIStroke") and not child:IsA("UIGradient") then child:Destroy() end
	end
	object.Visible = true
	object.AutomaticSize = Enum.AutomaticSize.None
	object.AnchorPoint = Vector2.zero
	object.Rotation = 0
	return object
end
local function label(parent, text, size, color)
	return create("TextLabel", {
		BackgroundTransparency = 1, Text = tostring(text or ""), TextSize = size or 16,
		FontFace = nativeFont, TextColor3 = color or colors.text,
		TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Center,
		TextTruncate = Enum.TextTruncate.AtEnd, TextStrokeTransparency = 0.7,
		TextStrokeColor3 = colors.stroke, ZIndex = parent.ZIndex + 1,
	}, parent)
end
local function button(parent, text, colorName)
	local result = stripVisual(nativeButton, "ImageButton")
	result.Name = "TestHubButton"
	result.BackgroundColor3 = Color3.new(1, 1, 1)
	result.BackgroundTransparency = 0
	result.Image = ""
	result.AutoButtonColor = true
	result.ZIndex = parent.ZIndex + 2
	result.Parent = parent
	corner(result, 9); stroke(result, 2, colors.stroke)
	local gradient = result:FindFirstChildOfClass("UIGradient") or create("UIGradient", {}, result)
	gradient.Rotation = 90
	local textLabel = label(result, text, 15)
	textLabel.Name = "Label"; textLabel.Size = UDim2.new(1, -12, 1, 0); textLabel.Position = UDim2.fromOffset(6, 0)
	textLabel.TextXAlignment = Enum.TextXAlignment.Center
	local function paint(name)
		local theme = palette and palette.Button and palette.Button[name]
		gradient.Color = theme and theme.Color or ColorSequence.new(colors.cyan, Color3.fromRGB(7, 135, 255))
	end
	paint(colorName or "Blue")
	return result, textLabel, paint
end
local root = create("ScreenGui", {
	Name = "TestHub", ResetOnSpawn = false, DisplayOrder = 1000100,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling, IgnoreGuiInset = false,
}, playerGui)
library.ScreenGui = root
-- Compatibility names in afbq's setup; all overlays use the same private root.
library.NotificationGui, library.DropdownGui, library.TooltipGui = root, root, root
function library:SetParent(parent) root.Parent = parent end
local overlay = create("Frame", {Name = "Overlay", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 40}, root)

-- Data is required lazily, and only visible dropdown rows create icon instances.
local dataCache, descriptorCache, descriptorCount = {}, {}, 0
local function data(name)
	if dataCache[name] == nil then dataCache[name] = safeRequire(path(shared, "Data", name)) or false end
	return dataCache[name] or nil
end
local function findEntry(name, value)
	local entries = data(name)
	if not entries then return nil end
	entries = entries.Data or entries
	return entries[value]
end
local function resolve(value, context)
	if type(value) == "table" and value.Item then return {item = value.Item} end
	if type(value) == "table" and value.Icon then return {image = value.Icon} end
	local raw = tostring(type(value) == "table" and (value.Title or value.Value) or value)
	local key = tostring(context or "") .. ":" .. raw
	if descriptorCache[key] then return descriptorCache[key] end
	local descriptor
	local egg = findEntry("Eggs", raw)
	if egg then
		local image = egg.Image
		if type(image) == "string" and image ~= constants.UnknownImage and image ~= "" then
			descriptor = {image = image}
		else
			descriptor = {model = path(assets, "Eggs", raw), image = image}
		end
	end
	local rune, tier = raw:match("^(.-) Tier (%d+)$")
	if not descriptor and rune and findEntry("Runes", rune) then
		descriptor = {item = {Type = "Rune", Name = rune, Tier = tonumber(tier)}}
	end
	if not descriptor then
		for _, kind in ipairs({{"Potions", "Potion"}, {"Powerups", "Powerup"}, {"Pets", "Pet"}, {"PermanentBuffs", "PermanentBuff"}, {"FishingRods", "FishingRod"}, {"FishingBait", "Bait"}, {"FishingBobbers", "Bobber"}, {"Fish", "Fish"}}) do
			local name = raw
			local level = tonumber(raw:match("[Ll]evel%s*(%d+)$")) or tonumber(raw:match("%s+(%d+)$"))
			if level then name = raw:gsub("%s+[Ll]evel%s*%d+$", ""):gsub("%s+%d+$", "") end
			if findEntry(kind[1], name) then
				descriptor = {item = {Type = kind[2], Name = name, Level = level or 1}}
				break
			end
		end
	end
	if not descriptor then
		local currency = findEntry("Currency", raw)
		if currency then descriptor = {item = {Type = "Currency", Currency = raw}} end
	end
	descriptor = descriptor or {fallback = raw:sub(1, 1):upper()}
	descriptorCount += 1
	if descriptorCount > 512 then table.clear(descriptorCache); descriptorCount = 1 end
	descriptorCache[key] = descriptor
	return descriptor
end
local function clearIcon(host)
	if itemUtil then pcall(itemUtil.UpdateIcon, itemUtil, host, nil) end
	for _, child in ipairs(host:GetChildren()) do child:Destroy() end
end
local function renderIcon(host, value, context)
	clearIcon(host)
	local descriptor = resolve(value, context)
	local image = create("ImageLabel", {
		Name = "Label", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1),
		ScaleType = Enum.ScaleType.Fit, ZIndex = host.ZIndex + 1,
	}, host)
	if descriptor.item and itemUtil then
		local ok = pcall(itemUtil.UpdateIcon, itemUtil, host, descriptor.item)
		if ok then return end
	end
	if descriptor.model then
		image.Visible = false
		local viewport = create("ViewportFrame", {BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = host.ZIndex + 1,
			Ambient = Color3.fromRGB(210, 210, 210), LightColor = Color3.new(1, 1, 1)}, host)
		local world = create("WorldModel", {}, viewport)
		local clone = descriptor.model:Clone()
		for _, child in ipairs(clone:GetDescendants()) do
			if child:IsA("BaseScript") or child:IsA("ModuleScript") or child:IsA("ParticleEmitter") or child:IsA("Trail") then child:Destroy()
			elseif child:IsA("BasePart") then child.Anchored = true; child.CanCollide = false end
		end
		clone.Parent = world
		local cf, size
		if clone:IsA("Model") then cf, size = clone:GetBoundingBox() else cf, size = clone.CFrame, clone.Size end
		local distance = math.max(size.X, size.Y, size.Z) * 1.9
		local camera = create("Camera", {FieldOfView = 36, CFrame = CFrame.lookAt(cf.Position + Vector3.new(distance * 0.2, distance * 0.15, distance), cf.Position)}, viewport)
		viewport.CurrentCamera = camera
	elseif type(descriptor.image) == "string" and descriptor.image ~= "" then image.Image = descriptor.image
	else
		image.Visible = false
		local initial = label(host, descriptor.fallback or "?", 18, colors.cyan)
		initial.Size = UDim2.fromScale(1, 1); initial.TextXAlignment = Enum.TextXAlignment.Center
	end
end
library.ResolveIcon = resolve

local panel = stripVisual(nativeSettings, "Frame")
panel.Name = "Window"; panel.BackgroundTransparency = 0; panel.BackgroundColor3 = colors.panel
panel.AnchorPoint = Vector2.new(0.5, 0.5); panel.Position = UDim2.fromScale(0.5, 0.5)
panel.Size = UDim2.fromOffset(780, 570); panel.ClipsDescendants = true; panel.ZIndex = 2; panel.Parent = root
corner(panel, 16); stroke(panel, 3, colors.stroke)
local header = create("Frame", {BackgroundColor3 = Color3.fromRGB(7, 135, 255), BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 66), ZIndex = 3, Active = true}, panel)
create("UIGradient", {Color = ColorSequence.new(colors.cyan, Color3.fromRGB(7, 135, 255)), Rotation = 15}, header)
local heading = label(header, "TestHub", 25)
heading.Position = UDim2.fromOffset(18, 5); heading.Size = UDim2.new(1, -130, 0, 31)
local subtitle = label(header, "BUBBLE GUM SIMULATOR INFINITY  /  NATIVE EDITION", 11)
subtitle.Position = UDim2.fromOffset(19, 37); subtitle.Size = UDim2.new(1, -86, 0, 20)
local close = button(header, "x", "Red"); close.Size = UDim2.fromOffset(36, 34); close.AnchorPoint = Vector2.new(1, 0); close.Position = UDim2.new(1, -14, 0, 14)
local sidebar = create("ScrollingFrame", {BackgroundTransparency = 1, BorderSizePixel = 0, Position = UDim2.fromOffset(12, 78), Size = UDim2.new(0, 158, 1, -120), CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollBarThickness = 3, ZIndex = 3}, panel)
create("UIListLayout", {Padding = UDim.new(0, 7), SortOrder = Enum.SortOrder.LayoutOrder}, sidebar)
create("UIPadding", {PaddingTop = UDim.new(0, 2), PaddingLeft = UDim.new(0, 2), PaddingRight = UDim.new(0, 6), PaddingBottom = UDim.new(0, 8)}, sidebar)
local search = create("TextBox", {Name = "Search", BackgroundColor3 = colors.card, BorderSizePixel = 0, Position = UDim2.fromOffset(184, 80), Size = UDim2.new(1, -198, 0, 36), FontFace = nativeFont, TextSize = 14, TextColor3 = colors.text, PlaceholderColor3 = colors.muted, PlaceholderText = "Search controls in this tab...", Text = "", ClearTextOnFocus = false, ZIndex = 4}, panel)
corner(search, 9)
local body = create("Frame", {BackgroundTransparency = 1, Position = UDim2.fromOffset(182, 126), Size = UDim2.new(1, -194, 1, -171), ZIndex = 3}, panel)
local footer = label(panel, "K  open / close   |   Game assets, your controls", 12, colors.muted)
footer.Position = UDim2.new(0, 16, 1, -34); footer.Size = UDim2.new(1, -32, 0, 24)
local reopen = button(root, "TestHub [K]", "Blue")
reopen.Size = UDim2.fromOffset(116, 36); reopen.AnchorPoint = Vector2.new(1, 0); reopen.Position = UDim2.new(1, -12, 0, 82); reopen.Visible = false
local window = {Tabs = {}, Native = panel, Opened = true}
library.Window = window
local activeTab, popup, popupOwner
local function closePopup()
	if popup then popup.Visible = false end
	if popupOwner then
		for _, cell in ipairs(popupOwner.pool or {}) do clearIcon(cell.icon); cell.button.Visible = false end
		popupOwner.pool = nil
	end
	popupOwner = nil
end
function window:Open()
	self.Opened = true; panel.Visible = true; reopen.Visible = false
	if activeTab then for _, control in ipairs(activeTab.Controls) do if control.UpdateIcon then control:UpdateIcon() end end end
end
function window:Close()
	closePopup(); self.Opened = false; panel.Visible = false; reopen.Visible = true
	if activeTab then for _, control in ipairs(activeTab.Controls) do if control.Icon then clearIcon(control.Icon) end end end
end
function window:Toggle() if self.Opened then self:Close() else self:Open() end end
function window:SetToggleKey(key) self.ToggleKey = key end
function window:EditOpenButton(_) end
connect(close.Activated, function() window:Close() end)
connect(reopen.Activated, function() window:Open() end)
local function status(message, failed)
	footer.Text = tostring(message); footer.TextColor3 = failed and colors.red or colors.muted
end
local function invoke(control, value)
	if not control.Callback then return end
	task.spawn(function()
		local ok, err = pcall(control.Callback, value)
		if not ok then warn("[TestHub] " .. control.Title .. ": " .. tostring(err)); status("Error in " .. control.Title .. " (see console)", true) end
	end)
end
local function applyFilter()
	if not activeTab then return end
	local query = search.Text:lower()
	local section, sectionMatches
	for _, control in ipairs(activeTab.Controls) do
		if control.Kind == "Section" then
			if section then section.Frame.Visible = query == "" or sectionMatches end
			section = control; sectionMatches = false
			control.Frame.Visible = query == ""
		else
			local matches = query == "" or (control.Title .. " " .. control.Description):lower():find(query, 1, true) ~= nil
			control.Frame.Visible = matches
			sectionMatches = sectionMatches or matches
		end
	end
	if section then section.Frame.Visible = query == "" or sectionMatches end
end
connect(search:GetPropertyChangedSignal("Text"), applyFilter)
local controls = {}
local function resize()
	local camera = workspace.CurrentCamera
	if not camera then return end
	local viewport = camera.ViewportSize
	local w, h = math.min(780, viewport.X - 22), math.min(570, viewport.Y - 64)
	w, h = math.max(260, w), math.max(260, h)
	panel.Size = UDim2.fromOffset(w, h)
	local narrow = w < 570
	local rail = narrow and 103 or 170
	sidebar.Size = UDim2.new(0, rail - 12, 1, -120)
	search.Position = UDim2.fromOffset(rail + 14, 80); search.Size = UDim2.new(1, -rail - 28, 0, 36)
	body.Position = UDim2.fromOffset(rail + 12, 126); body.Size = UDim2.new(1, -rail - 24, 1, -171)
	subtitle.Visible = w >= 420
	for _, control in ipairs(controls) do if control.Layout then control:Layout(narrow) end end
	closePopup()
end
local cameraConnection
local function bindCamera()
	if cameraConnection then cameraConnection:Disconnect() end
	if workspace.CurrentCamera then cameraConnection = connect(workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"), resize) end
	resize()
end
connect(workspace:GetPropertyChangedSignal("CurrentCamera"), bindCamera)
bindCamera()
local drag, dragInput, dragStart, panelStart
connect(header.InputBegan, function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		drag = true; dragInput = input; dragStart = input.Position; panelStart = panel.Position
	end
end)
connect(UserInputService.InputChanged, function(input)
	if not drag then return end
	if input.UserInputType ~= Enum.UserInputType.MouseMovement and input ~= dragInput then return end
	local delta = input.Position - dragStart
	local viewport = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(800, 600)
	local half = panel.AbsoluteSize / 2
	local center = Vector2.new(panelStart.X.Scale * viewport.X + panelStart.X.Offset + delta.X, panelStart.Y.Scale * viewport.Y + panelStart.Y.Offset + delta.Y)
	center = Vector2.new(math.clamp(center.X, half.X, math.max(half.X, viewport.X - half.X)), math.clamp(center.Y, half.Y, math.max(half.Y, viewport.Y - half.Y - 36)))
	panel.Position = UDim2.fromOffset(center.X, center.Y)
end)
connect(UserInputService.InputEnded, function(input)
	if input == dragInput or input.UserInputType == Enum.UserInputType.MouseButton1 then drag = false end
end)
connect(UserInputService.InputBegan, function(input, processed)
	if not processed and not UserInputService:GetFocusedTextBox() and input.KeyCode == (window.ToggleKey or Enum.KeyCode.K) then window:Toggle() end
	if input.KeyCode == Enum.KeyCode.Escape and popupOwner then closePopup() end
	if popupOwner and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
		local point = Vector2.new(input.Position.X, input.Position.Y)
		local function contains(object)
			local p, s = object.AbsolutePosition, object.AbsoluteSize
			return point.X >= p.X and point.Y >= p.Y and point.X <= p.X + s.X and point.Y <= p.Y + s.Y
		end
		if not contains(popup) and not contains(popupOwner.Action) then closePopup() end
	end
end)

local methods = {}
methods.__index = methods
function methods:SetTitle(text) self.Title = tostring(text); self.Label.Text = self.Title; applyFilter() end
function methods:SetDesc(text) self.Description = tostring(text); if self.Desc then self.Desc.Text = self.Description end; applyFilter() end
function methods:Lock() self.Locked = true; if self.Action then self.Action.Active = false end end
function methods:Unlock() self.Locked = false; if self.Action then self.Action.Active = true end end
function methods:Layout(narrow)
	local actionable = self.Kind ~= "Paragraph" and self.Kind ~= "Section"
	local stacked = narrow and actionable
	local height = self.Kind == "Section" and 32 or (stacked and 126 or 88)
	self.Frame.Size = UDim2.new(1, -4, 0, height)
	self.Label.Position = UDim2.fromOffset(12, self.Kind == "Section" and 0 or 8)
	self.Label.Size = UDim2.new(1, actionable and not stacked and -224 or -24, 0, 25)
	if self.Desc then
		self.Desc.Position = UDim2.fromOffset(12, 35); self.Desc.Size = UDim2.new(1, actionable and not stacked and -224 or -24, 0, self.Kind == "Paragraph" and 0 or 43)
	end
	if self.Action then
		self.Action.AnchorPoint = stacked and Vector2.zero or Vector2.new(1, 0.5)
		self.Action.Position = stacked and UDim2.fromOffset(12, 84) or UDim2.new(1, -12, 0.5, 0)
		self.Action.Size = stacked and UDim2.new(1, -24, 0, 32) or UDim2.fromOffset(192, 38)
	end
end
local function row(tab, kind, props)
	props = props or {}
	local frame = stripVisual(kind ~= "Section" and nativeRow or nil, "Frame")
	frame.Name = kind; frame.BackgroundColor3 = colors.card
	frame.BackgroundTransparency = kind == "Section" and 1 or 0.1
	frame.LayoutOrder = #tab.Controls + 1; frame.ZIndex = 4; frame.Parent = tab.Page
	if kind ~= "Section" then corner(frame, 10) end
	local title = label(frame, props.Title or kind, kind == "Section" and 17 or 15, kind == "Section" and colors.cyan or colors.text)
	local description
	if kind ~= "Section" then description = label(frame, props.Desc or "", 12, colors.muted); description.TextWrapped = true; description.TextTruncate = Enum.TextTruncate.None; description.TextYAlignment = Enum.TextYAlignment.Top end
	if kind == "Paragraph" then frame.AutomaticSize = Enum.AutomaticSize.Y; description.AutomaticSize = Enum.AutomaticSize.Y end
	local control = setmetatable({Kind = kind, Frame = frame, Label = title, Desc = description,
		Title = props.Title or kind, Description = props.Desc or "", Callback = props.Callback, Tab = tab}, methods)
	table.insert(tab.Controls, control); table.insert(controls, control)
	control:Layout(panel.Size.X.Offset < 570)
	return control
end
local tabMethods = {}
function tabMethods:Section(props) return row(self, "Section", props) end
function tabMethods:Paragraph(props) return row(self, "Paragraph", props) end
function tabMethods:Button(props)
	local control = row(self, "Button", props)
	control.Action = button(control.Frame, "Run", "Blue")
	control:Layout(panel.Size.X.Offset < 570)
	connect(control.Action.Activated, function() if not control.Locked then invoke(control) end end)
	return control
end
function tabMethods:Toggle(props)
	local control = row(self, "Toggle", props)
	local action, title, paint = button(control.Frame, "", "Inactive")
	control.Action = action
	function control:Set(value, silent)
		self.Value = value == true; title.Text = self.Value and "ON" or "OFF"; paint(self.Value and "Green" or "Inactive")
		if not silent then invoke(self, self.Value) end
	end
	control.SetValue = control.Set
	control:Set(props.Value, true); control:Layout(panel.Size.X.Offset < 570)
	connect(action.Activated, function() if not control.Locked then control:Set(not control.Value) end end)
	return control
end
function tabMethods:Input(props)
	local control = row(self, "Input", props)
	local input = create("TextBox", {BackgroundColor3 = colors.panel, BorderSizePixel = 0, Text = tostring(props.Value or ""), PlaceholderText = props.Placeholder or "Enter value...", PlaceholderColor3 = colors.muted, TextColor3 = colors.text, FontFace = nativeFont, TextSize = 13, ClearTextOnFocus = false, TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 6}, control.Frame)
	corner(input, 8); stroke(input, 1, colors.cyan)
	control.Action = input; control:Layout(panel.Size.X.Offset < 570)
	function control:Set(value, silent) input.Text = tostring(value or ""); if not silent then invoke(self, input.Text) end end
	control.SetValue = control.Set
	connect(input.FocusLost, function() if not control.Locked then invoke(control, input.Text) end end)
	return control
end

local function optionValue(value) return type(value) == "table" and (value.Value or value.Title) or value end
local function optionTitle(value) return tostring(type(value) == "table" and (value.Title or value.Value) or value) end
function tabMethods:Dropdown(props)
	local control = row(self, "Dropdown", props)
	control.Values = table.clone(props.Values or {}); control.Value = props.Value; control.Multi = props.Multi == true
	local action, title = button(control.Frame, "", "Blue")
	control.Action = action; title.TextXAlignment = Enum.TextXAlignment.Left
	title.Position = UDim2.fromOffset(43, 0); title.Size = UDim2.new(1, -65, 1, 0)
	local chevron = label(action, "v", 14); chevron.Position = UDim2.new(1, -22, 0, 0); chevron.Size = UDim2.new(0, 18, 1, 0)
	control.Icon = create("Frame", {BackgroundTransparency = 1, Position = UDim2.fromOffset(5, 3), Size = UDim2.fromOffset(32, 32), ZIndex = 7}, action)
	function control:UpdateIcon()
		if window.Opened and self.Tab == activeTab and self.Value ~= nil and not self.Multi then
			local ok, err = pcall(renderIcon, self.Icon, self.Value, self.Title)
			if not ok then warn("[TestHub] Icon: " .. tostring(err)) end
		end
	end
	function control:Select(value, silent)
		self.Value = value
		title.Text = self.Multi and type(value) == "table" and (#value .. " selected") or (value ~= nil and optionTitle(value) or "Choose...")
		self:UpdateIcon()
		if not silent then invoke(self, value) end
	end
	control.Set, control.SetValue = control.Select, control.Select
	function control:Refresh(values)
		self.Values = table.clone(values or {})
		if popupOwner == self then closePopup() end
	end
	control:Select(props.Value, true); control:Layout(panel.Size.X.Offset < 570)
	connect(action.Activated, function()
		if control.Locked then return end
		if popupOwner == control then closePopup(); return end
		closePopup()
		if popup then popup:Destroy() end
		popup = create("Frame", {Name = "IconPicker", BackgroundColor3 = colors.panel, BorderSizePixel = 0, Size = UDim2.fromOffset(360, 390), ZIndex = 40}, overlay)
		corner(popup, 12); stroke(popup, 3, colors.cyan)
		local popupTitle = label(popup, control.Title .. "  /  " .. #control.Values, 16)
		popupTitle.Position = UDim2.fromOffset(12, 8); popupTitle.Size = UDim2.new(1, -52, 0, 26)
		local done = button(popup, "x", "Red"); done.Size = UDim2.fromOffset(28, 26); done.Position = UDim2.new(1, -38, 0, 8)
		local query = create("TextBox", {Text = "", PlaceholderText = "Search names...", ClearTextOnFocus = false, BackgroundColor3 = colors.card, TextColor3 = colors.text, PlaceholderColor3 = colors.muted, FontFace = nativeFont, TextSize = 14, BorderSizePixel = 0, Position = UDim2.fromOffset(10, 43), Size = UDim2.new(1, -20, 0, 32), ZIndex = 42}, popup)
		corner(query, 8)
		local list = create("ScrollingFrame", {BackgroundTransparency = 1, BorderSizePixel = 0, Position = UDim2.fromOffset(10, 83), Size = UDim2.new(1, -20, 1, -95), ScrollBarThickness = 5, CanvasSize = UDim2.new(), ZIndex = 42}, popup)
		local empty = label(popup, "No matches", 15, colors.muted); empty.Position = UDim2.fromOffset(12, 90); empty.Size = UDim2.new(1, -24, 0, 40); empty.Visible = false
		local pool, filtered = {}, {}
		control.pool = pool
		local function draw()
			local first = math.floor(list.CanvasPosition.Y / 52) + 1
			for offset, cell in ipairs(pool) do
				local index = filtered[first + offset - 1]
				cell.index = index; cell.button.Visible = index ~= nil
				if index then
					cell.button.Position = UDim2.fromOffset(0, (first + offset - 2) * 52)
					local value = control.Values[index]; cell.title.Text = optionTitle(value)
					local selected = control.Multi and type(control.Value) == "table" and table.find(control.Value, optionValue(value)) ~= nil or control.Value == optionValue(value)
					cell.paint(selected and "Green" or "Blue")
					if cell.value ~= value then
						cell.value = value
						pcall(renderIcon, cell.icon, value, control.Title)
					end
				else cell.value = nil; clearIcon(cell.icon) end
			end
		end
		-- Nine reusable rows bound the number of potion animations and egg models.
		for _ = 1, 9 do
			local cellButton, cellTitle, paint = button(list, "", "Blue")
			cellButton.Size = UDim2.new(1, -7, 0, 46)
			cellTitle.Position = UDim2.fromOffset(52, 0); cellTitle.Size = UDim2.new(1, -60, 1, 0); cellTitle.TextXAlignment = Enum.TextXAlignment.Left
			local icon = create("Frame", {BackgroundTransparency = 1, Size = UDim2.fromOffset(40, 40), Position = UDim2.fromOffset(4, 3), ZIndex = 46}, cellButton)
			local cell = {button = cellButton, title = cellTitle, paint = paint, icon = icon}
			table.insert(pool, cell)
			-- Instance-owned events disconnect when the popup is destroyed.
			cellButton.Activated:Connect(function()
				if not cell.index then return end
				local value = optionValue(control.Values[cell.index])
				if control.Multi then
					local selected = type(control.Value) == "table" and table.clone(control.Value) or {}
					local existing = table.find(selected, value)
					if existing then table.remove(selected, existing) else table.insert(selected, value) end
					control:Select(selected); draw()
				else control:Select(value); closePopup() end
			end)
		end
		local function filter()
			table.clear(filtered)
			local needle = query.Text:lower()
			for index, value in ipairs(control.Values) do if optionTitle(value):lower():find(needle, 1, true) then table.insert(filtered, index) end end
			list.CanvasSize = UDim2.fromOffset(0, #filtered * 52); list.CanvasPosition = Vector2.zero
			empty.Visible = #filtered == 0; draw()
		end
		query:GetPropertyChangedSignal("Text"):Connect(filter)
		list:GetPropertyChangedSignal("CanvasPosition"):Connect(draw)
		done.Activated:Connect(closePopup)
		local viewport = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(800, 600)
		local inset = GuiService:GetGuiInset()
		local width = math.min(380, viewport.X - 24)
		local height = math.min(390, viewport.Y - inset.Y - 30)
		popup.Size = UDim2.fromOffset(width, height)
		local p = action.AbsolutePosition - overlay.AbsolutePosition
		local y = p.Y + action.AbsoluteSize.Y + 6
		if y + height > viewport.Y - inset.Y - 8 then y = math.max(8, p.Y - height - 6) end
		popup.Position = UDim2.fromOffset(math.clamp(p.X, 12, math.max(12, viewport.X - width - 12)), y)
		popupOwner = control; filter()
	end)
	return control
end
function window:Tab(props)
	local page = create("ScrollingFrame", {Name = props.Title, BackgroundTransparency = 1, BorderSizePixel = 0, Size = UDim2.fromScale(1, 1), AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(), ScrollBarThickness = 4, ScrollBarImageColor3 = colors.cyan, Visible = false, ZIndex = 3}, body)
	create("UIListLayout", {Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder}, page)
	create("UIPadding", {PaddingBottom = UDim.new(0, 8), PaddingLeft = UDim.new(0, 2)}, page)
	local tab = setmetatable({Title = props.Title, Page = page, Controls = {}}, {__index = tabMethods})
	local tabButton, tabTitle, paint = button(sidebar, props.Title, "Blue")
	tabButton.Size = UDim2.new(1, -4, 0, 35); tabButton.LayoutOrder = #self.Tabs + 1; tabTitle.TextSize = 13
	tab.Paint = paint; tab.NavigationButton = tabButton
	function tab:Select()
		closePopup()
		if activeTab then
			activeTab.Page.Visible = false; activeTab.Paint("Blue")
			for _, control in ipairs(activeTab.Controls) do if control.Icon then clearIcon(control.Icon) end end
		end
		activeTab = self; page.Visible = true; paint("Green"); search.Text = ""; applyFilter()
		heading.Text = "TestHub  /  " .. self.Title
		for _, control in ipairs(self.Controls) do if control.UpdateIcon then control:UpdateIcon() end end
	end
	connect(tabButton.Activated, function() tab:Select() end)
	connect(page:GetPropertyChangedSignal("CanvasPosition"), closePopup)
	table.insert(self.Tabs, tab)
	if not activeTab then tab:Select() end
	return tab
end
function library:CreateWindow(props)
	heading.Text = "TestHub"
	window.ToggleKey = props.ToggleKey or Enum.KeyCode.K
	table.insert(self.Windows, window)
	return window
end
function library:Destroy()
	closePopup()
	for _, control in ipairs(controls) do if control.Icon then clearIcon(control.Icon) end end
	for _, connection in ipairs(connections) do connection:Disconnect() end
	table.clear(connections); root:Destroy()
end
function library:Notify(props) status(props.Content or props.Title or "") end
return library
