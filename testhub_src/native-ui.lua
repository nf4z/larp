-- TestHub: a local UI adapter built from BGSI's own cloned visuals and item APIs.
-- No native control is reparented or connected to the game's setting remotes.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
local assets = ReplicatedStorage:WaitForChild("Assets", 15)
local shared = ReplicatedStorage:WaitForChild("Shared", 15)
assert(assets and shared, "[@qtrzip] Game assets did not load")
local function path(root, ...)
	for _, name in ipairs({...}) do root = root and root:FindFirstChild(name) end
	return root
end
local function safeRequire(module)
	if not module then return nil end
	local ok, result = pcall(require, module)
	return ok and result or nil
end
local guiModules = path(ReplicatedStorage, "Client", "Gui")
local guiFrame = safeRequire(path(guiModules, "GuiFrame"))
if guiFrame then
	guiFrame:Initialize("Inventory")
	guiFrame:Initialize("Settings")
end
local palette = assert(safeRequire(path(shared, "Palette")), "[@qtrzip] Shared.Palette unavailable")
local autoButtonColor = assert(safeRequire(path(guiModules, "Utils", "AutoButtonColor")), "[@qtrzip] Native button styling unavailable")
local dropdownComponent = assert(safeRequire(path(guiModules, "Components", "Dropdown")), "[@qtrzip] Native Dropdown component unavailable")
local itemUtil = safeRequire(path(shared, "Utils", "Stats", "ItemUtil"))
local itemFrameBuilder = safeRequire(path(guiModules, "Utils", "ItemFrame"))
local constants = safeRequire(path(shared, "Constants")) or {}
local nativeScreen = playerGui:FindFirstChild("ScreenGui") or playerGui:WaitForChild("ScreenGui", 10)
local nativeInventory = assert(nativeScreen and (nativeScreen:FindFirstChild("Inventory") or nativeScreen:WaitForChild("Inventory", 15)), "[@qtrzip] ScreenGui.Inventory is not loaded")
local inventoryFrame = assert(path(nativeInventory, "Frame"), "[@qtrzip] Inventory.Frame is missing")
local nativeSettings = path(nativeScreen, "Settings", "Frame")
local nativeButton = path(inventoryFrame, "Tray", "Buttons", "Buttons", "Best", "Button")
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
assert(nativeRow, "[@qtrzip] Native Settings rows are not loaded; open game Settings once and rerun")
assert(nativeButton, "[@qtrzip] Native action button is unavailable")
local prototypeDropdown = dropdownComponent.new(nativeButton, {Items = {"@qtrzip"}, DefaultValue = 1, Width = "Target", MaxItemsVisible = 6})
local dropdownShell = prototypeDropdown._floater:Clone()
local dropdownRow = prototypeDropdown._frames[1]:Clone()
prototypeDropdown:Destroy()
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
local library = { Version = "2026.11.04.4", Windows = {}, ModuleErrors = {} }
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
local function cloneNative(source, zIndex)
	assert(source and source.Archivable, "[@qtrzip] Native template cannot be cloned")
	local object = source:Clone()
	local function clean(node, depth)
		if node:IsA("BaseScript") or node:IsA("ModuleScript") then node:Destroy(); return end
		if node:IsA("GuiObject") then
			node.ZIndex = (zIndex or 1) + depth
			node.Interactable = true
			node.Active = node:IsA("GuiButton") or node:IsA("TextBox") or node:IsA("ScrollingFrame")
		end
		if node:IsA("GuiButton") then
			for _, key in ipairs({"BaseAutoColor", "PressAutoColor", "EnterAutoColor", "Pressed", "ButtonActivated"}) do node:SetAttribute(key, nil) end
			node.Active = true
			node.Modal = false
		end
		if node:IsA("UIScale") then node.Scale = 1 end
		for _, child in ipairs(node:GetChildren()) do clean(child, depth + 1) end
	end
	clean(object, 0)
	if object:IsA("GuiObject") then object.Visible = true end
	return object
end
local function clearContent(object)
	for _, child in ipairs(object:GetChildren()) do if child:IsA("GuiObject") then child:Destroy() end end
end
local function getLabel(object)
	local candidate = object:FindFirstChild("Label")
	if candidate and candidate:IsA("TextLabel") then return candidate end
	return object:FindFirstChildWhichIsA("TextLabel", true)
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
local function button(parent, text, colorName, prototype)
	local parentZ = parent:IsA("GuiObject") and parent.ZIndex or 1
	local result = cloneNative(prototype or nativeButton, parentZ + 2)
	result.Name = "QtrzipButton"
	result.Parent = parent
	local textLabel = assert(getLabel(result), "[@qtrzip] Native button label missing")
	textLabel.Text = text
	local function paint(name)
		autoButtonColor(result, palette.Button[name] or palette.Button.Blue)
	end
	paint(colorName or "Blue")
	return result, textLabel, paint
end
local root = create("ScreenGui", {
	Name = "@qtrzip", ResetOnSpawn = false, DisplayOrder = 1000100,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling, IgnoreGuiInset = false,
}, playerGui)
library.ScreenGui = root
if type(onTestHubUiCreated) == "function" then onTestHubUiCreated(library) end
-- Compatibility names in afbq's setup; all overlays use the same private root.
library.NotificationGui, library.DropdownGui, library.TooltipGui = root, root, root
function library:SetParent(parent) root.Parent = parent end
local overlay = create("Frame", {Name = "Overlay", BackgroundTransparency = 1, Active = false, Visible = false,
	Size = UDim2.fromScale(1, 1), ZIndex = 40}, root)

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
		if type(itemFrameBuilder) == "function" then
			local ok, card = pcall(itemFrameBuilder, descriptor.item, false, true)
			if ok and card then
				image:Destroy()
				card.Name = "NativeItemIcon"; card.AnchorPoint = Vector2.zero; card.Position = UDim2.fromOffset(0, 0)
				card.Size = UDim2.fromScale(1, 1); card.Parent = host
				local inner = path(card, "Button", "Inner")
				if inner then for _, name in ipairs({"Label", "Bottom", "Secret", "XL"}) do local text = inner:FindFirstChild(name); if text then text.Visible = false end end end
				local cardButton = card:FindFirstChild("Button")
				if cardButton then cardButton.Active = false; cardButton.Interactable = false; cardButton.Selectable = false end
				local function raise(node, depth)
					if node:IsA("GuiObject") then node.ZIndex = host.ZIndex + depth end
					for _, child in ipairs(node:GetChildren()) do raise(child, depth + 1) end
				end
				raise(card, 1)
				return
			end
		end
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

-- Keep the inventory's complete artwork and layout instead of rebuilding its shell.
-- The native Inventory wrapper contains the fullscreen dimmer/input backdrop.
-- Copy only its actual window into a fresh transparent, passive holder.
local holder = create("Frame", {Name = "QtrzipHolder", BackgroundTransparency = 1, Active = false,
	Size = UDim2.fromScale(1, 1), ZIndex = 2}, root)
local panel = cloneNative(inventoryFrame, 2)
panel.Parent = holder
panel.Name = "Window"; panel.Visible = true
for _, target in ipairs({holder, panel}) do
	for _, child in ipairs(target:GetChildren()) do
		if child:IsA("UIAspectRatioConstraint") or child:IsA("UISizeConstraint") then child:Destroy() end
	end
end
local baseWidth, baseHeight = 760, 532
local desiredWidth, desiredHeight = 600, 420
panel.Size = UDim2.fromOffset(baseWidth, baseHeight)
panel.AnchorPoint = Vector2.new(0.5, 0.5); panel.Position = UDim2.fromScale(0.5, 0.5)
local panelScale = panel:FindFirstChildOfClass("UIScale") or create("UIScale", {Scale = 1}, panel)
local header = assert(path(panel, "Top"), "[@qtrzip] Native Inventory.Top missing")
header.Active = true
header.AnchorPoint = Vector2.zero; header.Position = UDim2.fromOffset(0, 0)
local heading = assert(path(header, "Title", "Title"), "[@qtrzip] Native Inventory title missing")
heading.Text = "@qtrzip"; heading.TextSize = 32
header.Size = UDim2.new(1, 0, 0, 66)
local titleHost = heading.Parent
titleHost.AnchorPoint = Vector2.zero; titleHost.Position = UDim2.fromOffset(18, 10); titleHost.Size = UDim2.new(1, -90, 0, 46)
heading.Size = UDim2.fromScale(1, 1)
local dragHandle = create("Frame", {Name = "DragHandle", BackgroundTransparency = 1, Active = true,
	Size = UDim2.new(1, -72, 0, 66), ZIndex = header.ZIndex + 12}, panel)
local close = assert(path(header, "Close", "Button"), "[@qtrzip] Native close button missing")
close.Parent.AnchorPoint = Vector2.new(1, 0); close.Parent.Position = UDim2.new(1, -12, 0, 12); close.Parent.Size = UDim2.fromOffset(40, 40)
close.Size = UDim2.fromScale(1, 1)
autoButtonColor(close, palette.Button.Red)
local topLeft = path(header, "Left")
if topLeft then
	for _, child in ipairs(topLeft:GetChildren()) do if child:IsA("GuiObject") then child.Visible = false end end
end
local tray = assert(path(panel, "Tray"), "[@qtrzip] Native Inventory.Tray missing")
tray.Visible = true
local trayButtons = tray:FindFirstChild("Buttons")
if trayButtons then trayButtons.Visible = false end
local searchHost = assert(path(tray, "Search"), "[@qtrzip] Native inventory search missing")
searchHost.Visible = true
local search = assert(path(searchHost, "Search", "Bar", "TextBox"), "[@qtrzip] Native search TextBox missing")
search.Text = ""; search.PlaceholderText = "Search @qtrzip..."; search.ClearTextOnFocus = false
search.TextSize = 18
tray.AnchorPoint = Vector2.zero; tray.Position = UDim2.new(0, 168, 1, -62); tray.Size = UDim2.new(1, -184, 0, 34)
searchHost.AnchorPoint = Vector2.zero; searchHost.Position = UDim2.fromOffset(0, 0); searchHost.Size = UDim2.fromScale(1, 1)
local nativeSearch = searchHost:FindFirstChild("Search")
nativeSearch.AnchorPoint = Vector2.zero; nativeSearch.Position = UDim2.fromOffset(0, 0); nativeSearch.Size = UDim2.fromScale(1, 1)
nativeSearch.Bar.Size = UDim2.fromScale(1, 1)
local body = assert(path(panel, "Inner"), "[@qtrzip] Native Inventory.Inner missing")
local pagePrototype = path(body, "Items", "Main", "ScrollingFrame") or path(body, "Pets", "Main", "ScrollingFrame")
assert(pagePrototype and pagePrototype:IsA("ScrollingFrame"), "[@qtrzip] Native inventory scroll panel missing")
pagePrototype = cloneNative(pagePrototype, 3)
clearContent(body)
body.AnchorPoint = Vector2.zero; body.Position = UDim2.fromOffset(168, 74); body.Size = UDim2.new(1, -184, 1, -144)
local side = assert(path(panel, "Sidebar"), "[@qtrzip] Native sidebar missing")
local nativeButtons = assert(side:FindFirstChild("Buttons"), "[@qtrzip] Native sidebar buttons missing")
local tabPrototypes = {}
for _, child in ipairs(nativeButtons:GetChildren()) do
	if child:IsA("GuiObject") and child:FindFirstChild("Button") then tabPrototypes[child.Name] = cloneNative(child, 4) end
end
local defaultTab = tabPrototypes.Pets or select(2, next(tabPrototypes))
assert(defaultTab, "[@qtrzip] Native sidebar tab template missing")
local sidebar = create("ScrollingFrame", {Name = "QtrzipTabs", BackgroundTransparency = 1, BorderSizePixel = 0,
	Size = UDim2.fromScale(1, 1), CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y,
	ScrollBarThickness = 3, ClipsDescendants = true, ZIndex = nativeButtons.ZIndex}, side)
nativeButtons.Visible = false
local nativeLayout = nativeButtons:FindFirstChildOfClass("UIListLayout")
local sidebarLayout = nativeLayout and nativeLayout:Clone() or create("UIListLayout", {}, nil)
sidebarLayout.SortOrder = Enum.SortOrder.LayoutOrder; sidebarLayout.Parent = sidebar
sidebarLayout.Padding = UDim.new(0, 6)
create("UIPadding", {PaddingTop = UDim.new(0, 12), PaddingBottom = UDim.new(0, 12), PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 6)}, sidebar)
side.AnchorPoint = Vector2.zero; side.Position = UDim2.fromOffset(12, 74); side.Size = UDim2.new(0, 144, 1, -106)
local footer = cloneNative(heading, 10)
footer.Name = "TestHubStatus"; footer.Text = "Loading features..."; footer.TextSize = math.min(footer.TextSize, 18)
footer.AnchorPoint = Vector2.zero; footer.Position = UDim2.new(0, 20, 1, -30)
footer.Size = UDim2.new(1, -40, 0, 24); footer.Parent = panel
local reopen = button(root, "@qtrzip [K]", "Blue")
reopen.Size = UDim2.fromOffset(116, 36); reopen.AnchorPoint = Vector2.new(1, 0); reopen.Position = UDim2.new(1, -12, 0, 82); reopen.Visible = false
local window = {Tabs = {}, Native = panel, Opened = true, TabsByTitle = {}, Scale = panelScale}
local resizeGrip = create("TextButton", {Name = "ResizeGrip", Text = "//", FontFace = nativeFont, TextSize = 22,
	TextColor3 = colors.text, BackgroundTransparency = 1, Size = UDim2.fromOffset(32, 32),
	AnchorPoint = Vector2.new(1, 1), Position = UDim2.fromScale(1, 1), ZIndex = panel.ZIndex + 20}, panel)
window.DragHandle = dragHandle; window.ResizeGrip = resizeGrip
library.Window = window
local activeTab, popup, popupOwner
local function closePopup()
	if popup then popup.Visible = false end
	overlay.Visible = false
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
function library:ModuleFailed(message)
	table.insert(self.ModuleErrors, message)
	status("Load error: " .. tostring(message), true)
end
function library:ModulesReady()
	status(#self.ModuleErrors == 0 and "Ready  /  K to hide" or (tostring(#self.ModuleErrors) .. " modules failed; check console"), #self.ModuleErrors > 0)
end
local function invoke(control, value)
	if not control.Callback then return end
	task.spawn(function()
		local ok, err = pcall(control.Callback, value)
		if not ok then warn("[@qtrzip] " .. control.Title .. ": " .. tostring(err)); status("Error in " .. control.Title .. " (see console)", true) end
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
	local scale = math.max(0.25, math.min(desiredWidth / baseWidth, (viewport.X - 24) / baseWidth))
	local logicalHeight = math.clamp(desiredHeight / scale, 360, math.max(360, (viewport.Y - 60) / scale))
	panelScale.Scale = scale
	panel.Size = UDim2.fromOffset(baseWidth, logicalHeight)
	window.Width = baseWidth * scale; window.Height = logicalHeight * scale
	for _, control in ipairs(controls) do if control.Layout then control:Layout(false) end end
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
local resizing, resizeInput, resizeStart, resizeWidth, resizeHeight
local function containsPoint(object, point)
	local p, s = object.AbsolutePosition, object.AbsoluteSize
	return point.X >= p.X and point.Y >= p.Y and point.X <= p.X + s.X and point.Y <= p.Y + s.Y
end
local function startDrag(input)
	drag = true; dragInput = input; dragStart = input.Position; panelStart = panel.Position
end
local function startResize(input)
	resizing = true; resizeInput = input; resizeStart = input.Position
	resizeWidth, resizeHeight = window.Width, window.Height; closePopup()
end
connect(dragHandle.InputBegan, function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		startDrag(input)
	end
end)
connect(resizeGrip.InputBegan, function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		startResize(input)
	end
end)
connect(UserInputService.InputChanged, function(input)
	if resizing and (input.UserInputType == Enum.UserInputType.MouseMovement or input == resizeInput) then
		local viewport = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(800, 600)
		local delta = input.Position - resizeStart
		desiredWidth = math.clamp(resizeWidth + delta.X, math.min(340, viewport.X - 24), math.max(340, viewport.X - 24))
		desiredHeight = math.clamp(resizeHeight + delta.Y, 240, math.max(240, viewport.Y - 60))
		resize(); return
	end
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
	if input == resizeInput or input.UserInputType == Enum.UserInputType.MouseButton1 then resizing = false end
end)
connect(UserInputService.InputBegan, function(input, processed)
	if not processed and not UserInputService:GetFocusedTextBox() and input.KeyCode == (window.ToggleKey or Enum.KeyCode.K) then window:Toggle() end
	if input.KeyCode == Enum.KeyCode.Escape and popupOwner then closePopup() end
	local pointer = input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch
	-- Route our own header/nav hit regions directly; native decorative children
	-- must not swallow dragging or selection before Activated reaches the button.
	if pointer and window.Opened and input.Position and not (popupOwner and containsPoint(popup, input.Position)) then
		if containsPoint(resizeGrip, input.Position) then startResize(input)
		elseif containsPoint(dragHandle, input.Position) then startDrag(input)
		elseif containsPoint(sidebar, input.Position) then
			for _, tab in ipairs(window.Tabs) do
				if tab.NavigationButton.Visible and containsPoint(tab.NavigationButton, input.Position) then tab:Select(); break end
			end
		end
	end
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
function methods:SetDesc(text)
	self.Description = tostring(text)
	if self.Desc then self.Desc.Text = self.Description; self.Desc.Visible = self.Description ~= "" end
	self:Layout(false); applyFilter()
end
function methods:Lock() self.Locked = true; if self.Action then self.Action.Active = false end end
function methods:Unlock() self.Locked = false; if self.Action then self.Action.Active = true end end
function methods:Layout(narrow)
	local actionable = self.Kind ~= "Paragraph" and self.Kind ~= "Section"
	local height = self.Kind == "Section" and 38 or (self.Description ~= "" and 86 or 54)
	self.Frame.Size = UDim2.new(1, -12, 0, height)
	self.Information.Size = UDim2.new(1, actionable and -200 or -16, 1, 0)
	self.Label.TextSize = self.Kind == "Section" and 22 or 20
	if self.Desc then self.Desc.TextSize = 15 end
	if self.ActionHost then
		self.ActionHost.Visible = actionable
		self.ActionHost.AnchorPoint = Vector2.new(1, 0.5)
		self.ActionHost.Position = UDim2.new(1, -12, 0.5, 0)
		self.ActionHost.Size = UDim2.fromOffset(180, 38)
	end
end
local function row(tab, kind, props)
	props = props or {}
	local frame = cloneNative(nativeRow, 4)
	frame.Name = kind; frame.LayoutOrder = #tab.Controls + 1; frame.Parent = tab.Page
	local information = assert(frame:FindFirstChild("Information"), "[@qtrzip] Native row Information missing")
	local title = assert(information:FindFirstChild("Label"), "[@qtrzip] Native row title missing")
	title.Text = props.Title or kind
	local favorite = title:FindFirstChild("Favorite"); if favorite then favorite.Visible = false end
	local description = information:FindFirstChild("Description")
	if description then description.Text = props.Desc or ""; description.TextWrapped = true; description.Visible = kind ~= "Section" and description.Text ~= "" end
	local actionHost = assert(frame:FindFirstChild("Action"), "[@qtrzip] Native row Action missing")
	for _, child in ipairs(actionHost:GetChildren()) do if child:IsA("GuiObject") then child.Visible = false end end
	local control = setmetatable({Kind = kind, Frame = frame, Label = title, Desc = description,
		Information = information, ActionHost = actionHost,
		Title = props.Title or kind, Description = props.Desc or "", Callback = props.Callback, Tab = tab}, methods)
	table.insert(tab.Controls, control); table.insert(controls, control)
	control:Layout(false)
	return control
end
local function rowButton(control)
	local host = assert(control.ActionHost:FindFirstChild("Dropdown"), "[@qtrzip] Native Dropdown action missing")
	host.Visible = true
	host.AnchorPoint = Vector2.zero; host.Position = UDim2.fromOffset(0, 0); host.Size = UDim2.fromScale(1, 1)
	local action = assert(host:FindFirstChild("Button"), "[@qtrzip] Native Dropdown button missing")
	action.AnchorPoint = Vector2.zero; action.Position = UDim2.fromOffset(0, 0); action.Size = UDim2.fromScale(1, 1)
	local title = assert(getLabel(action), "[@qtrzip] Native Dropdown label missing")
	autoButtonColor(action, palette.Button.Blue)
	control.Action = action
	return action, title
end
local tabMethods = {}
function tabMethods:Section(props) return row(self, "Section", props) end
function tabMethods:Paragraph(props) return row(self, "Paragraph", props) end
function tabMethods:Button(props)
	local control = row(self, "Button", props)
	local action, title = rowButton(control); title.Text = "Run"
	local chevron = action:FindFirstChild("Chevron"); if chevron then chevron.Visible = false end
	connect(control.Action.Activated, function() if not control.Locked then invoke(control) end end)
	return control
end
function tabMethods:Toggle(props)
	local control = row(self, "Toggle", props)
	local action = assert(control.ActionHost:FindFirstChild("Toggle"), "[@qtrzip] Native Toggle action missing")
	action.Visible = true
	control.Action = action
	function control:Set(value, silent)
		self.Value = value == true
		local blob = assert(action:FindFirstChild("Blob"), "[@qtrzip] Native toggle Blob missing")
		blob.AnchorPoint = Vector2.new(self.Value and 1 or 0, 0)
		blob.Position = UDim2.fromScale(self.Value and 1 or 0, 0)
		local gradient = assert(action:FindFirstChildOfClass("UIGradient"), "[@qtrzip] Native toggle gradient missing")
		gradient.Color = palette.Button[self.Value and "Green" or "Inactive"].Color
		if not silent then invoke(self, self.Value) end
	end
	control.SetValue = control.Set
	control:Set(props.Value, true)
	connect(action.Activated, function() if not control.Locked then control:Set(not control.Value) end end)
	return control
end
function tabMethods:Input(props)
	local control = row(self, "Input", props)
	local keybind = assert(control.ActionHost:FindFirstChild("Keybind"), "[@qtrzip] Native input action missing")
	keybind.Visible = true
	keybind.AnchorPoint = Vector2.zero; keybind.Position = UDim2.fromOffset(0, 0); keybind.Size = UDim2.fromScale(1, 1)
	local clear = keybind:FindFirstChild("Clear"); if clear then clear.Visible = false end
	local input = assert(keybind:FindFirstChild("InputBox"), "[@qtrzip] Native InputBox missing")
	input.Text = tostring(props.Value or ""); input.PlaceholderText = props.Placeholder or "Enter value..."; input.ClearTextOnFocus = false
	input.Size = UDim2.new(1, 0, 1, 0)
	local display = input:FindFirstChild("Label")
	if display then
		-- The native input renders through its child label above its Background frame.
		input.TextTransparency = 1; input.PlaceholderText = ""; display.Visible = true
		input.ClipsDescendants = true
		display.AutomaticSize = Enum.AutomaticSize.None; display.AnchorPoint = Vector2.zero
		display.Position = UDim2.fromOffset(6, 0); display.Size = UDim2.new(1, -12, 1, 0)
		display.TextSize = 18; display.TextTruncate = Enum.TextTruncate.AtEnd
		local function mirrorText()
			display.Text = input.Text ~= "" and input.Text or (props.Placeholder or "Enter value...")
			display.TextTransparency = input.Text ~= "" and 0 or 0.4
		end
		connect(input:GetPropertyChangedSignal("Text"), mirrorText); mirrorText()
	end
	control.Action = input
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
	local action, title = rowButton(control)
	control.Action = action; title.TextXAlignment = Enum.TextXAlignment.Left
	title.Position = UDim2.fromOffset(43, 0); title.Size = UDim2.new(1, -65, 1, 0)
	control.Icon = create("Frame", {BackgroundTransparency = 1, Position = UDim2.fromOffset(5, 3), Size = UDim2.fromOffset(32, 32), ZIndex = 7}, action)
	function control:UpdateIcon()
		if window.Opened and self.Tab == activeTab and self.Value ~= nil and not self.Multi then
			local ok, err = pcall(renderIcon, self.Icon, self.Value, self.Title)
			if not ok then warn("[@qtrzip] Icon: " .. tostring(err)) end
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
	control:Select(props.Value, true)
	connect(action.Activated, function()
		if control.Locked then return end
		if popupOwner == control then closePopup(); return end
		closePopup()
		if popup then popup:Destroy() end
		popup = cloneNative(dropdownShell, 40)
		overlay.Visible = true
		popup.Name = "IconPicker"; popup.AnchorPoint = Vector2.zero; popup.Visible = true; popup.Parent = overlay
		local popupTitle = cloneNative(nativeRow.Information.Label, 42)
		popupTitle.Text = control.Title .. "  /  " .. #control.Values; popupTitle.Parent = popup
		popupTitle.Position = UDim2.fromOffset(12, 8); popupTitle.Size = UDim2.new(1, -52, 0, 26)
		local done = button(popup, "x", "Red"); done.Size = UDim2.fromOffset(28, 26); done.Position = UDim2.new(1, -38, 0, 8)
		local queryHost = cloneNative(searchHost, 42); queryHost.Parent = popup
		queryHost.Position = UDim2.fromOffset(10, 43); queryHost.Size = UDim2.new(1, -20, 0, 40)
		local query = assert(path(queryHost, "Search", "Bar", "TextBox"), "[@qtrzip] Native picker search missing")
		query.Text = ""; query.PlaceholderText = "Search names..."; query.ClearTextOnFocus = false
		local list = assert(popup:FindFirstChild("Items"), "[@qtrzip] Native picker Items missing")
		clearContent(list)
		for _, child in ipairs(list:GetChildren()) do if child:IsA("UIListLayout") or child:IsA("UIPadding") then child:Destroy() end end
		list.Position = UDim2.fromOffset(10, 90); list.Size = UDim2.new(1, -20, 1, -102); list.ScrollBarThickness = 5
		list.CanvasPosition = Vector2.zero; list.ScrollingEnabled = true
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
			local cellButton, cellTitle, paint = button(list, "", "Blue", dropdownRow)
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
	if self.TabsByTitle[props.Title] then return self.TabsByTitle[props.Title] end
	local page = cloneNative(pagePrototype, 3)
	clearContent(page)
	for _, child in ipairs(page:GetChildren()) do if child:IsA("UIListLayout") or child:IsA("UIGridLayout") then child:Destroy() end end
	page.Name = props.Title; page.Position = UDim2.fromOffset(0, 0); page.Size = UDim2.fromScale(1, 1)
	page.AutomaticCanvasSize = Enum.AutomaticSize.Y; page.CanvasSize = UDim2.new(); page.Visible = false; page.Parent = body
	create("UIListLayout", {Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder}, page)
	local tab = setmetatable({Title = props.Title, Page = page, Controls = {}}, {__index = tabMethods})
	local entry = create("Frame", {Name = props.Title, LayoutOrder = #self.Tabs + 1,
		BackgroundTransparency = 1, Size = UDim2.new(1, -4, 0, 40), ZIndex = sidebar.ZIndex + 1}, sidebar)
	local tabButton, tabTitle, paint = button(entry, props.Title, "Inactive", dropdownRow)
	tabButton.AnchorPoint = Vector2.zero; tabButton.Position = UDim2.fromOffset(0, 0); tabButton.Size = UDim2.fromScale(1, 1)
	tabTitle.TextSize = 18; tabTitle.TextWrapped = true
	tabTitle.Position = UDim2.fromOffset(2, 0); tabTitle.Size = UDim2.new(1, -4, 1, 0)
	tab.Paint = paint; tab.NavigationButton = tabButton
	function tab:Select()
		closePopup()
		if activeTab then
			activeTab.Page.Visible = false; activeTab.Paint("Blue")
			for _, control in ipairs(activeTab.Controls) do if control.Icon then clearIcon(control.Icon) end end
		end
		activeTab = self; page.Visible = true; paint("Green"); search.Text = ""; applyFilter()
		heading.Text = "@qtrzip  /  " .. self.Title
		for _, control in ipairs(self.Controls) do if control.UpdateIcon then control:UpdateIcon() end end
	end
	connect(tabButton.Activated, function() tab:Select() end)
	connect(page:GetPropertyChangedSignal("CanvasPosition"), closePopup)
	table.insert(self.Tabs, tab)
	self.TabsByTitle[props.Title] = tab
	if not activeTab then tab:Select() end
	return tab
end
function library:CreateWindow(props)
	heading.Text = "@qtrzip"
	window.ToggleKey = props.ToggleKey or Enum.KeyCode.K
	-- Register navigation before feature code, so failures stay visible and diagnosable.
	for _, title in ipairs({"Info", "Activity Info", "Webhook", "Auto", "Eggs", "Rift", "Event", "Enchant", "Potions", "Pets", "Shrine", "Quest", "Dice Board", "Trade", "Teleport", "Misc"}) do window:Tab({Title = title}) end
	table.insert(self.Windows, window)
	return window
end
function library:Destroy()
	closePopup()
	for _, control in ipairs(controls) do if control.Icon then clearIcon(control.Icon) end end
	for _, connection in ipairs(connections) do connection:Disconnect() end
	table.clear(connections); root:Destroy()
	pagePrototype:Destroy(); dropdownShell:Destroy(); dropdownRow:Destroy()
	for _, prototype in pairs(tabPrototypes) do prototype:Destroy() end
end
function library:Notify(props) status(props.Content or props.Title or "") end
return library
