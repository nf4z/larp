-- TestHub: a local UI adapter built from BGSI's own cloned visuals and item APIs.
-- No native control is reparented or connected to the game's setting remotes.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local HttpService = game:GetService("HttpService")
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
local constants = safeRequire(path(shared, "Constants")) or {}
local nativeScreen = playerGui:FindFirstChild("ScreenGui") or playerGui:WaitForChild("ScreenGui", 10)
local nativeInventory = assert(nativeScreen and (nativeScreen:FindFirstChild("Inventory") or nativeScreen:WaitForChild("Inventory", 15)), "[@qtrzip] ScreenGui.Inventory is not loaded")
local inventoryFrame = assert(path(nativeInventory, "Frame"), "[@qtrzip] Inventory.Frame is missing")
local nativeSettings = path(nativeScreen, "Settings", "Frame")
local nativeButton = path(inventoryFrame, "Tray", "Buttons", "Buttons", "Best", "Button")
local nativeRow, nativeCategory
local settingsList = path(nativeSettings, "Main", "ScrollingFrame")
if settingsList then
	for _, object in ipairs(settingsList:GetDescendants()) do
		if object:IsA("Frame") and object:FindFirstChild("Information") and object:FindFirstChild("Action") then
			nativeRow = object
			local category = object.Parent and object.Parent.Parent
			if category and category:FindFirstChild("Items") and category:FindFirstChild("Label") then nativeCategory = category end
			nativeButton = path(object, "Action", "Dropdown", "Button") or nativeButton
			break
		end
	end
end
assert(nativeRow, "[@qtrzip] Native Settings rows are not loaded; open game Settings once and rerun")
assert(nativeCategory, "[@qtrzip] Native Settings category template is unavailable")
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
local library = { Version = "2026.11.05.13", Windows = {}, ModuleErrors = {} }
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
		if node:IsA("TextBox") then node.TextEditable = true end
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
local pickerGui = create("ScreenGui", {Name = "QtrzipPickers", ResetOnSpawn = false,
	DisplayOrder = root.DisplayOrder + 1, IgnoreGuiInset = root.IgnoreGuiInset, ZIndexBehavior = Enum.ZIndexBehavior.Sibling}, playerGui)
library.PickerGui = pickerGui
local overlay = create("Frame", {Name = "Overlay", BackgroundTransparency = 1, Active = false, Visible = false,
	Size = UDim2.fromScale(1, 1), ZIndex = 1}, pickerGui)

-- Data is required lazily, and only visible dropdown rows create icon instances.
local dataCache, descriptorCache, descriptorCount = {}, {}, 0
local ICON_CACHE_PATHS = {}
local iconCatalogs, iconCatalogPending = {}, {}
local function cachedImage(category, name, variant)
	local catalog = iconCatalogs[category]
	if catalog then
		local record = catalog[name]
		if record and record.images then return record.images[variant or "Image"] or record.images.Normal end
	end
	local remotePath = ICON_CACHE_PATHS[category]
	if remotePath and not iconCatalogPending[category] then
		iconCatalogPending[category] = true
		task.spawn(function()
			local ok, result = pcall(function()
				local disk = "QtrzipIconCache/" .. remotePath:match("([^/]+)$")
				local function decode(source)
					local value = HttpService:JSONDecode(source)
					assert(value.schema == 1 and value.category == category and type(value.entries) == "table")
					return value.entries
				end
				if isfile and readfile then
					local valid, entries = pcall(function() if isfile(disk) then return decode(readfile(disk)) end end)
					if valid and entries then return entries end
				end
				local source = game:HttpGet("https://raw.githubusercontent.com/nf4z/larp/main/" .. remotePath, true)
				local entries = decode(source)
				if makefolder and writefile then pcall(function() if not isfolder or not isfolder("QtrzipIconCache") then makefolder("QtrzipIconCache") end; writefile(disk, source) end) end
				return entries
			end)
			if ok then iconCatalogs[category] = result; table.clear(descriptorCache) end
		end)
	end
	local ready = iconCatalogs[category]
	local record = ready and ready[name]
	if record and record.images then return record.images[variant or "Image"] or record.images.Normal end
	return nil
end
local function data(name)
	if dataCache[name] == nil then dataCache[name] = safeRequire(path(shared, "Data", name)) or false end
	return dataCache[name] or nil
end
local lookupIndexes = {}
local function normalized(value) return tostring(value):lower():gsub("[%s%p]", "") end
local function findEntry(category, value)
	local entries = data(category)
	if not entries then return nil end
	entries = entries.Data or entries
	if entries[value] then return entries[value], value end
	local index = lookupIndexes[category]
	if not index then
		index = {}; lookupIndexes[category] = index
		for name, entry in pairs(entries) do
			if type(name) == "string" and type(entry) == "table" then index[normalized(name)] = name end
		end
	end
	local name = index[normalized(value)]
	return name and entries[name], name
end
local function resolve(value, context)
	if type(value) == "table" and value.Item then return {item = value.Item} end
	if type(value) == "table" and value.Icon then return {image = value.Icon} end
	local raw = tostring(type(value) == "table" and (value.Title or value.Value) or value)
	local key = tostring(context or "") .. ":" .. raw
	if descriptorCache[key] then return descriptorCache[key] end
	local descriptor
	local egg, eggName = findEntry("Eggs", raw)
	if egg then
		local image = egg.Image or cachedImage("Eggs", eggName)
		if type(image) == "string" and image ~= constants.UnknownImage and image ~= "" then descriptor = {image = image}
		else descriptor = {model = path(assets, "Eggs", eggName)} end
	end
	local rune, tier = raw:match("^(.-)%s+[Tt]ier%s*(%d+)$")
	if not descriptor and rune then
		local entry, name = findEntry("Runes", rune)
		if not entry then entry, name = findEntry("Runes", rune:gsub("%s*[Rr]une$", "")) end
		if entry then
			local tierData = entry.Tiers and entry.Tiers[tonumber(tier)]
			descriptor = {image = tierData and tierData.Icon or cachedImage("Runes", name, "Tier" .. tier),
				item = {Type = "Rune", Name = name, Tier = tonumber(tier)}}
		end
	end
	if not descriptor then
		for _, kind in ipairs({{"Potions", "Potion"}, {"Powerups", "Powerup"}, {"Pets", "Pet"}, {"PermanentBuffs", "PermanentBuff"}, {"FishingRods", "FishingRod"}, {"FishingBait", "Bait"}, {"FishingBobbers", "Bobber"}, {"Fish", "Fish"}}) do
			local entry, name = findEntry(kind[1], raw)
			local level
			if not entry and kind[2] == "Potion" then
				level = tonumber(raw:match("[Ll]evel%s*(%d+)$")) or tonumber(raw:match("%s+(%d+)$"))
				local base = raw:gsub("%s+[Ll]evel%s*%d+$", ""):gsub("%s+%d+$", "")
				entry, name = findEntry(kind[1], base)
			end
			if entry then
				local image = entry.Image or entry.Icon or (entry.Images and entry.Images.Normal) or cachedImage(kind[1], name)
				descriptor = {image = type(image) == "string" and image or nil, item = {Type = kind[2], Name = name, Level = level or 1}}
				break
			end
		end
	end
	if not descriptor then
		local currency, name = findEntry("Currency", raw)
		if currency then descriptor = {image = currency.Image or cachedImage("Currency", name), item = {Type = "Currency", Currency = name}} end
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
		Name = "Label", BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(1, 1),
		ScaleType = Enum.ScaleType.Fit, ZIndex = host.ZIndex + 1,
	}, host)
	if type(descriptor.image) == "string" and descriptor.image ~= "" and descriptor.image ~= constants.UnknownImage then
		image.Image = descriptor.image; return
	end
	if descriptor.item and itemUtil then

		local ok = pcall(itemUtil.UpdateIcon, itemUtil, host, descriptor.item)
		if ok then image.Position = UDim2.fromScale(0.5, 0.5); return end
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
library.RenderIcon = renderIcon

-- Keep the inventory's complete artwork and layout instead of rebuilding its shell.
-- The native Inventory wrapper contains the fullscreen dimmer/input backdrop.
-- Copy only its actual window into a fresh transparent, passive holder.
local function nativeSearchBox(parent, name, placeholder)
	-- A single compact field: no inventory wrapper, magnifier, or nested artwork.
	local shell = create("Frame", {Name = name, BackgroundColor3 = Color3.fromRGB(8, 75, 126),
		BorderSizePixel = 0, AnchorPoint = Vector2.zero, Position = UDim2.fromOffset(0, 3),
		Size = UDim2.new(1, 0, 1, -6), ClipsDescendants = true, Active = false,
		ZIndex = parent.ZIndex + 1}, parent)
	corner(shell, 8); stroke(shell, 2, colors.stroke)
	local input = create("TextBox", {Name = "TextBox", BackgroundTransparency = 1, BorderSizePixel = 0,
		AnchorPoint = Vector2.zero, Position = UDim2.fromOffset(10, 0), Size = UDim2.new(1, -20, 1, 0),
		AutomaticSize = Enum.AutomaticSize.None, Text = "", PlaceholderText = placeholder or "Search...",
		ClearTextOnFocus = false, TextEditable = true, Active = true, Interactable = true,
		FontFace = nativeFont, TextSize = 20, TextScaled = false, TextWrapped = false, MultiLine = false,
		TextColor3 = colors.text, PlaceholderColor3 = colors.muted, TextTransparency = 0, TextStrokeTransparency = 1,
		TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Center,
		TextTruncate = Enum.TextTruncate.None, ClipsDescendants = true, ZIndex = shell.ZIndex + 1}, shell)
	return shell, input
end

local holder = create("Frame", {Name = "QtrzipHolder", BackgroundTransparency = 1, Active = false,
	Size = UDim2.fromScale(1, 1), ZIndex = 2}, root)
local panel = cloneNative(nativeSettings, 2)
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
local heading = path(header, "Title", "Title") or path(header, "Title")
if not (heading and heading:IsA("TextLabel")) then heading = getLabel(header) end
assert(heading, "[@qtrzip] Native Settings title missing")
heading.Text = ""; heading.Visible = false; heading.TextScaled = false
header.Size = UDim2.new(1, 0, 0, 64)
local titleHost = heading.Parent == header and heading or heading.Parent
titleHost.AnchorPoint = Vector2.zero; titleHost.Position = UDim2.fromOffset(16, 8); titleHost.Size = UDim2.new(1, -100, 0, 72)
if titleHost ~= heading then heading.Size = UDim2.fromScale(1, 1) end
titleHost.Visible = false
local dragHandle = create("Frame", {Name = "DragHandle", BackgroundTransparency = 1, Active = true,
	Position = UDim2.fromOffset(170, 0), Size = UDim2.new(1, -240, 0, 64), ZIndex = header.ZIndex + 12}, panel)
local close = assert(path(header, "Close", "Button"), "[@qtrzip] Native close button missing")
close.Parent.AnchorPoint = Vector2.new(1, 0)
close.Parent.Position = UDim2.new(1, -16, 0, 10); close.Parent.Size = UDim2.fromOffset(40, 40)
for _, object in ipairs({close.Parent, close}) do
	for _, child in ipairs(object:GetChildren()) do
		if child:IsA("UISizeConstraint") or child:IsA("UIAspectRatioConstraint") then child:Destroy() end
	end
end
close.AnchorPoint = Vector2.zero; close.Position = UDim2.fromOffset(0, 0); close.Size = UDim2.fromScale(1, 1)
-- Separate the glyph from the red hit target so its X has breathing room.
if close:IsA("ImageButton") and type(close.Image) == "string" and close.Image ~= "" then
	local glyph = create("ImageLabel", {Name = "CloseGlyph", BackgroundTransparency = 1,
		Image = close.Image, ImageColor3 = close.ImageColor3, ImageRectOffset = close.ImageRectOffset, ImageRectSize = close.ImageRectSize,
		ScaleType = Enum.ScaleType.Fit, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(26, 26), Active = false, ZIndex = close.ZIndex + 2}, close)
	close.ImageTransparency = 1
end
for _, child in ipairs(close:GetChildren()) do
	if (child:IsA("ImageLabel") or child:IsA("TextLabel")) and child.Name ~= "Background" then
		child.AnchorPoint = Vector2.new(0.5, 0.5); child.Position = UDim2.fromScale(0.5, 0.5)
		child.Size = UDim2.fromOffset(26, 26)
		if child:IsA("TextLabel") then child.TextScaled = false; child.TextSize = 26 end
	end
end

autoButtonColor(close, palette.Button.Red)
local topLeft = path(header, "Left")
if topLeft then
	for _, child in ipairs(topLeft:GetChildren()) do if child:IsA("GuiObject") then child.Visible = false end end
end
local tray = create("Frame", {Name = "ControlSearch", BackgroundTransparency = 1, ZIndex = panel.ZIndex + 5,
	AnchorPoint = Vector2.zero, Position = UDim2.new(0, 168, 1, -54), Size = UDim2.new(1, -190, 0, 40)}, panel)
local searchShell, search = nativeSearchBox(tray, "InventorySearch", "Search this tab...")
local body = assert(path(panel, "Main"), "[@qtrzip] Native Settings.Main missing")
local pagePrototype = path(body, "ScrollingFrame")
assert(pagePrototype and pagePrototype:IsA("ScrollingFrame"), "[@qtrzip] Native inventory scroll panel missing")
pagePrototype = cloneNative(pagePrototype, 3)
body.ScrollingFrame:Destroy()
body.AnchorPoint = Vector2.zero; body.Position = UDim2.fromOffset(168, 64); body.Size = UDim2.new(1, -184, 1, -126)
local side = assert(path(panel, "Sidebar"), "[@qtrzip] Native sidebar missing")
local nativeButtons = assert(side:FindFirstChild("Buttons"), "[@qtrzip] Native sidebar buttons missing")
local tabPrototypes = {}
for _, child in ipairs(nativeButtons:GetChildren()) do
	if child:IsA("GuiObject") and child:FindFirstChild("Button") then tabPrototypes[child.Name] = cloneNative(child, 4) end
end
local defaultTab = select(2, next(tabPrototypes))
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
side.AnchorPoint = Vector2.zero; side.Position = UDim2.fromOffset(12, 64); side.Size = UDim2.new(0, 144, 1, -80)
local reopen = button(root, "@qtrzip [K]", "Blue")
reopen.Size = UDim2.fromOffset(116, 36); reopen.AnchorPoint = Vector2.new(1, 0); reopen.Position = UDim2.new(1, -12, 0, 82); reopen.Visible = false
local window = {Tabs = {}, Native = panel, Opened = true, TabsByTitle = {}, Scale = panelScale}
local resizeGrip = create("TextButton", {Name = "ResizeGrip", Text = "//", FontFace = nativeFont, TextSize = 22,
	TextColor3 = colors.text, BackgroundTransparency = 1, Size = UDim2.fromOffset(32, 32),
	AnchorPoint = Vector2.new(1, 1), Position = UDim2.fromScale(1, 1), ZIndex = panel.ZIndex + 20}, panel)
window.DragHandle = dragHandle; window.ResizeGrip = resizeGrip; window.CloseButton = close
library.Window = window
local activeTab, popup, popupOwner
local function closePopup()
	if popup then popup.Visible = false end
	overlay.Visible = false
	if popupOwner then
		for _, icon in pairs(popupOwner.NativeIcons or {}) do clearIcon(icon) end
		popupOwner.NativeIcons = nil
		local chevron = popupOwner.Action and popupOwner.Action:FindFirstChild("Chevron")
		if chevron then chevron.Rotation = 0 end
		local nativePicker = popupOwner.NativePicker
		popupOwner.NativePicker = nil
		if nativePicker then nativePicker:Destroy(); popup = nil end
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
	if failed then warn("[@qtrzip] " .. tostring(message)) end
end
function library:ModuleFailed(message)
	table.insert(self.ModuleErrors, message)
	status("Load error: " .. tostring(message), true)
end
function library:ModulesReady()
	if not self.UnloadControl then
		local misc = window:Tab({Title = "Misc"})
		misc:Section({Title = "Session"})
		self.UnloadControl = misc:Button({Title = "Unload Script", Desc = "Stops this hub and restores tracked local changes. Your config stays saved.", Callback = function()
			if type(onTestHubUnload) == "function" then onTestHubUnload() else library:Destroy() end
		end})
	end
	-- Startup diagnostics are recorded in ModuleErrors and the console.
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
	-- Window dimensions change independently of native font/control scale.
	local scale = math.max(0.25, math.min(600 / baseWidth, (viewport.X - 24) / baseWidth))
	local logicalHeight = math.clamp(desiredHeight / scale, 360, math.max(360, (viewport.Y - 60) / scale))
	panelScale.Scale = scale
	local logicalWidth = math.min(desiredWidth, viewport.X - 24) / scale
	panel.Size = UDim2.fromOffset(logicalWidth, logicalHeight)
	window.Width = logicalWidth * scale; window.Height = logicalHeight * scale
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
	if self.Kind == "Section" then return end
	local actionable = self.Kind ~= "Paragraph" and self.Kind ~= "Section"
	local height = self.Description ~= "" and 75 or 50
	local width = (self.Kind == "Dropdown" or self.Kind == "Input") and 250 or (self.Kind == "Toggle" and 80 or 200)
	self.Frame.Size = UDim2.new(1, 0, 0, height)
	self.Information.AnchorPoint = Vector2.zero; self.Information.Position = UDim2.fromOffset(12, 4)
	self.Information.Size = UDim2.new(1, actionable and -width - 36 or -28, 1, -8)
	self.Information.ClipsDescendants = true
	self.Label.AnchorPoint = Vector2.zero; self.Label.Position = UDim2.fromOffset(3, 0)
	self.Label.TextScaled = false; self.Label.TextSize = 22
	self.Label.TextWrapped = false; self.Label.TextTruncate = Enum.TextTruncate.AtEnd
	self.Label.Size = self.Description ~= "" and UDim2.new(1, -6, 0, 27) or UDim2.new(1, -6, 1, 0)
	self.Label.TextYAlignment = Enum.TextYAlignment.Center
	local outline = self.Label:FindFirstChildOfClass("UIStroke"); if outline then outline.Thickness = 1.5 end
	if self.Desc then
		self.Desc.AnchorPoint = Vector2.zero; self.Desc.Position = UDim2.fromOffset(3, 28)
		self.Desc.Size = UDim2.new(1, -6, 1, -28)
		self.Desc.TextScaled = false; self.Desc.TextSize = 18; self.Desc.TextWrapped = true
		self.Desc.TextYAlignment = Enum.TextYAlignment.Top
		local border = self.Desc:FindFirstChildOfClass("UIStroke"); if border then border.Thickness = 1 end
	end
	if self.ActionHost then
		self.ActionHost.Visible = actionable
		self.ActionHost.AnchorPoint = Vector2.new(1, 0.5)
		self.ActionHost.Position = UDim2.new(1, -12, 0.5, 0)
		self.ActionHost.Size = UDim2.fromOffset(width, 40)
	end
end
local row
row = function(tab, kind, props)
	props = props or {}
	if kind == "Section" then
		local category = cloneNative(nativeCategory, 4)
		category.Name = props.Title or "General"; category.LayoutOrder = #tab.Controls + 1; category.Parent = tab.Page
		category.Label.Text = (props.Title or "General"):gsub("^%s*%-+%s*", ""):gsub("%s*%-+%s*$", "")
		category.Label.TextScaled = false; category.Label.TextSize = 24
		category.Label.AnchorPoint = Vector2.zero; category.Label.Position = UDim2.fromOffset(6, 6)
		category.Label.Size = UDim2.new(1, -12, 0, 30); category.Label.TextTruncate = Enum.TextTruncate.AtEnd
		clearContent(category.Items)
		local list = assert(category.Items:FindFirstChildOfClass("UIListLayout"), "[@qtrzip] Settings category layout missing")
		local function updateSize()
			category.Size = UDim2.new(1, 0, 0, math.ceil(list.AbsoluteContentSize.Y / panelScale.Scale) + 50)
		end
		connect(list:GetPropertyChangedSignal("AbsoluteContentSize"), updateSize)
		connect(panelScale:GetPropertyChangedSignal("Scale"), updateSize); updateSize()
		local control = setmetatable({Kind = kind, Frame = category, Label = category.Label,
			Title = props.Title or "General", Description = "", Tab = tab}, methods)
		tab.CurrentCategory = category
		table.insert(tab.Controls, control); table.insert(controls, control)
		return control
	end
	if not tab.CurrentCategory then row(tab, "Section", {Title = tab.Title}) end
	local frame = cloneNative(nativeRow, 4)
	frame.Name = kind; frame.LayoutOrder = #tab.Controls + 1; frame.Parent = tab.CurrentCategory.Items
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
	title.TextScaled = false
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
	local shell, input = nativeSearchBox(control.ActionHost, "InventoryInput", props.Placeholder or "Enter value...")
	input.Text = tostring(props.Value or "")
	control.Action = input; control.SearchShell = shell
	function control:Set(value, silent) input.Text = tostring(value or ""); if not silent then invoke(self, input.Text) end end
	control.SetValue = control.Set
	connect(input.FocusLost, function() if not control.Locked then invoke(control, input.Text) end end)
	return control
end

local function optionValue(value) return type(value) == "table" and (value.Value or value.Title) or value end
local function optionTitle(value) return tostring(type(value) == "table" and (value.Title or value.Value) or value) end
local function dropdownValues(values)
	local result, seen = {}, {}
	for _, value in ipairs(values or {}) do
		local key = tostring(optionValue(value) or "")
		if key ~= "" and not normalized(key):find("visualegglock", 1, true) and not seen[key] then
			seen[key] = true; table.insert(result, value)
		end
	end
	return result
end
function tabMethods:Dropdown(props)
	local control = row(self, "Dropdown", props)
	control.Values = dropdownValues(props.Values); control.Value = props.Value; control.Multi = props.Multi == true
	local action, title = rowButton(control)
	control.Action = action
	title.TextScaled = false; title.TextSize = 22; title.TextTruncate = Enum.TextTruncate.AtEnd
	title.AnchorPoint = Vector2.zero; title.Position = UDim2.fromOffset(8, 0); title.Size = UDim2.new(1, -40, 1, 0)
	local nativeLabelPosition, nativeLabelSize, nativeLabelAnchor = title.Position, title.Size, title.AnchorPoint
	control.Icon = create("Frame", {BackgroundTransparency = 1, Position = UDim2.fromOffset(5, 3), Size = UDim2.fromOffset(32, 32), ZIndex = 7}, action)
	function control:UpdateIcon()
		if window.Opened and self.Tab == activeTab and self.Value ~= nil and not self.Multi then
			local descriptor = resolve(self.Value, self.Title)
			local hasIcon = descriptor.item ~= nil or descriptor.model ~= nil or descriptor.image ~= nil
			self.Icon.Visible = hasIcon
			if hasIcon then
				title.AnchorPoint = Vector2.zero; title.Position = UDim2.fromOffset(43, 0); title.Size = UDim2.new(1, -65, 1, 0)
				title.TextXAlignment = Enum.TextXAlignment.Left
				local ok, err = pcall(renderIcon, self.Icon, self.Value, self.Title)
				if not ok then warn("[@qtrzip] Icon: " .. tostring(err)) end
			else
				clearIcon(self.Icon)
				title.AnchorPoint = nativeLabelAnchor; title.Position = nativeLabelPosition; title.Size = nativeLabelSize
				title.TextXAlignment = Enum.TextXAlignment.Center
			end
		end
	end
	function control:Select(value, silent)
		self.Value = value
		if self.Multi and type(value) == "table" then
			title.Text = #value == 0 and "None selected" or (#value == 1 and optionTitle(value[1]) or (#value .. " selected"))
		else title.Text = value ~= nil and optionTitle(value) or "Choose..." end
		self:UpdateIcon()
		if not silent then invoke(self, value) end
	end
	control.Set, control.SetValue = control.Select, control.Select
	function control:OpenNativePicker()
		closePopup()
		local items = {}
		for _, value in ipairs(self.Values) do table.insert(items, optionTitle(value)) end
		if #items == 0 then return end
		local selected = 1
		local selectedItems = {}
		for index, value in ipairs(self.Values) do if optionValue(value) == self.Value then selected = index end end
		if self.Multi and type(self.Value) == "table" then
			for index, value in ipairs(self.Values) do selectedItems[index] = table.find(self.Value, optionValue(value)) ~= nil end
		end
		local picker = dropdownComponent.new(action, {Items = items, DefaultValue = selected,
			Width = "Target", MaxItemsVisible = 6, Multiple = self.Multi, SelectedItems = selectedItems})
		picker._floater.Parent = overlay
		picker._floater.AnchorPoint = Vector2.zero
		for _, option in ipairs(picker._frames) do
			local text = option.Label
			text.TextScaled = false; text.TextSize = 20; text.TextWrapped = false
			text.TextTruncate = Enum.TextTruncate.AtEnd
			text.AnchorPoint = Vector2.zero; text.Position = UDim2.fromOffset(8, 0)
			text.Size = UDim2.new(1, -16, 1, 0); text.TextXAlignment = Enum.TextXAlignment.Left
		end
		local scale = create("UIScale", {Scale = panelScale.Scale}, picker._floater)
		function picker:_observeSize()
			local function update()
				local s = scale.Scale
				local p = action.AbsolutePosition - overlay.AbsolutePosition
				local viewport = overlay.AbsoluteSize
				local height = math.min(self._height * s, viewport.Y - 16)
				local y = p.Y + action.AbsoluteSize.Y + 4
				if y + height > viewport.Y - 8 then y = math.max(4, p.Y - height - 4) end
				y = math.clamp(y, 8, math.max(8, viewport.Y - height - 8))
				self._floater.Size = UDim2.fromOffset(action.AbsoluteSize.X / s, height / s)
				self._floater.Position = UDim2.fromOffset(math.clamp(p.X, 8, math.max(8, viewport.X - action.AbsoluteSize.X - 8)), y)
			end
			update()
			self._renderTrove:Add(action:GetPropertyChangedSignal("AbsolutePosition"):Connect(update))
			self._renderTrove:Add(action:GetPropertyChangedSignal("AbsoluteSize"):Connect(update))
		end
		overlay.Visible = true
		popup = picker._floater; popupOwner = self
		self.NativePicker = picker
		local icons = {}
		self.NativeIcons = icons
		local list = picker._floater.Items
		local layout = list:FindFirstChildOfClass("UIListLayout")
		local padding = layout and layout.Padding and layout.Padding.Offset or 0
		local stride = math.max(1, dropdownRow.Size.Y.Offset + padding)
		self.NativeStride = stride
		local function updateIcons()
			-- CanvasPosition and template offsets can use different units under UIScale.
			-- Find visible rows from their actual screen geometry instead.
			local top = list.AbsolutePosition.Y
			local low, high = 1, #picker._frames
			while low < high do
				local middle = math.floor((low + high) / 2)
				local frame = picker._frames[middle]
				if frame.AbsolutePosition.Y + frame.AbsoluteSize.Y < top then low = middle + 1 else high = middle end
			end
			local first = low
			local rowHeight = math.max(1, picker._frames[first].AbsoluteSize.Y)
			local last = math.min(#self.Values, first + math.min(15, math.ceil(list.AbsoluteSize.Y / rowHeight) + 1))
			for index, icon in pairs(icons) do
				if index < first or index > last then clearIcon(icon); icon.Visible = false end
			end
			for index = first, last do
				local value = self.Values[index]
				local descriptor = resolve(value, self.Title)
				if descriptor.item or descriptor.image or descriptor.model then
					local nativeRow = picker._frames[index]
					local icon = icons[index]
					if not icon then
						icon = create("Frame", {Name = "ItemIcon", BackgroundTransparency = 1, Active = false,
							AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 6, 0.5, 0),
							Size = UDim2.fromOffset(28, 28), ZIndex = nativeRow.ZIndex + 1}, nativeRow)
						icons[index] = icon
						local text = nativeRow.Label
						text.AnchorPoint = Vector2.zero; text.Position = UDim2.fromOffset(42, 0)
						text.Size = UDim2.new(1, -50, 1, 0); text.TextXAlignment = Enum.TextXAlignment.Left
					end
					if not icon.Visible or #icon:GetChildren() == 0 then
						icon.Visible = true; pcall(renderIcon, icon, value, self.Title)
					end
				end
			end
		end
		picker._trove:Add(list:GetPropertyChangedSignal("CanvasPosition"):Connect(updateIcons))
		picker._trove:Add(list:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateIcons))
		picker._trove:Add(picker._frames[1]:GetPropertyChangedSignal("AbsolutePosition"):Connect(updateIcons))
		picker.OnSelectionChanged:Connect(function(value, index, checked)
			if self.Multi then
				local values = type(self.Value) == "table" and table.clone(self.Value) or {}
				local chosen = optionValue(self.Values[index])
				local previous = table.find(values, chosen)
				if checked and not previous then table.insert(values, chosen)
				elseif not checked and previous then table.remove(values, previous) end
				self:Select(values)
			else self:Select(optionValue(self.Values[index]) or value); closePopup() end
		end)
		picker.Closed:Connect(function()
			-- Native row clicks close first and then fire selection. Keep its signal
			-- alive until SelectItem has delivered the chosen value.
			if self.NativePicker == picker then
				overlay.Visible = false
				task.defer(function() if self.NativePicker == picker then closePopup() end end)
			end
		end)
		picker:SetOpened(true)
		updateIcons()
	end
	function control:Refresh(values)
		self.Values = dropdownValues(values)
		if popupOwner == self then closePopup() end
		local available = {}
		for _, option in ipairs(self.Values) do available[optionValue(option)] = true end
		if self.Multi then
			local kept = {}
			for _, value in ipairs(type(self.Value) == "table" and self.Value or {}) do
				if available[value] then table.insert(kept, value) end
			end
			if #kept ~= #(type(self.Value) == "table" and self.Value or {}) then self:Select(kept) end
		elseif self.Value ~= nil and not available[self.Value] then
			self:Select(optionValue(self.Values[1]))
		end
	end
	control:Select(props.Value, true)
	connect(action.Activated, function()
		if control.Locked then return end
		if popupOwner == control then closePopup(); return end
		control:OpenNativePicker()
	end)
	return control
end
function window:Tab(props)
	if self.TabsByTitle[props.Title] then return self.TabsByTitle[props.Title] end
	local page = cloneNative(pagePrototype, 3)
	clearContent(page)
	for _, child in ipairs(page:GetChildren()) do if child:IsA("UIGridLayout") then child:Destroy() end end
	page.Name = props.Title; page.Position = UDim2.fromOffset(0, 0); page.Size = UDim2.fromScale(1, 1)
	page.AutomaticCanvasSize = Enum.AutomaticSize.Y; page.CanvasSize = UDim2.new(); page.Visible = false; page.Parent = body
	local pagePadding = page:FindFirstChildOfClass("UIPadding") or create("UIPadding", {}, page)
	pagePadding.PaddingLeft = UDim.new(0, 6); pagePadding.PaddingRight = UDim.new(0, 8)
	pagePadding.PaddingTop = UDim.new(0, 4); pagePadding.PaddingBottom = UDim.new(0, 12)
	local pageList = page:FindFirstChildOfClass("UIListLayout") or create("UIListLayout", {}, page)
	pageList.SortOrder = Enum.SortOrder.LayoutOrder
	local tab = setmetatable({Title = props.Title, Page = page, Controls = {}}, {__index = tabMethods})
	local entry = create("Frame", {Name = props.Title, LayoutOrder = #self.Tabs + 1,
		BackgroundTransparency = 1, Size = UDim2.new(1, -4, 0, 40), ZIndex = sidebar.ZIndex + 1}, sidebar)
	local tabButton, tabTitle, paint = button(entry, props.Title, "Blue", dropdownRow)
	tabButton.AnchorPoint = Vector2.zero; tabButton.Position = UDim2.fromOffset(0, 0); tabButton.Size = UDim2.fromScale(1, 1)
	tabTitle.TextScaled = false; tabTitle.TextSize = 20; tabTitle.TextWrapped = false
	tabTitle.TextTruncate = Enum.TextTruncate.AtEnd
	tabTitle.AnchorPoint = Vector2.zero; tabTitle.Position = UDim2.fromOffset(6, 0); tabTitle.Size = UDim2.new(1, -12, 1, 0)
	tabTitle.TextYAlignment = Enum.TextYAlignment.Center
	tab.Paint = paint; tab.NavigationButton = tabButton
	function tab:Select()
		closePopup()
		if activeTab then
			activeTab.Page.Visible = false; activeTab.Paint("Blue")
			for _, control in ipairs(activeTab.Controls) do if control.Icon then clearIcon(control.Icon) end end
		end
		activeTab = self; page.Visible = true; paint("Green"); search.Text = ""; applyFilter()
		heading.Text = ""
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
	heading.Text = ""
	window.ToggleKey = props.ToggleKey or Enum.KeyCode.K
	-- Register navigation before feature code, so failures stay visible and diagnosable.
	for _, title in ipairs({"Info", "Activity Info", "Webhook", "Auto", "Eggs", "Rift", "Event", "Enchant", "Potions", "Pets", "Shrine", "Quest", "Dice Board", "Trade", "Teleport", "Misc", "Server"}) do window:Tab({Title = title}) end
	table.insert(self.Windows, window)
	return window
end
function library:Destroy()
	if self.Destroyed then return end
	self.Destroyed = true
	closePopup()
	for _, control in ipairs(controls) do if control.Icon then clearIcon(control.Icon) end end
	for _, connection in ipairs(connections) do connection:Disconnect() end
	table.clear(connections); root:Destroy(); pickerGui:Destroy()
	pagePrototype:Destroy(); dropdownShell:Destroy(); dropdownRow:Destroy()
	for _, prototype in pairs(tabPrototypes) do prototype:Destroy() end
end
function library:Notify(props) status(props.Content or props.Title or "") end
return library
