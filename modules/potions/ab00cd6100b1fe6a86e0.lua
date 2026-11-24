-- Generated from larplite.lua; rebuild with tools/build_modules.py.
return {
function(...)
scriptStateYT = scriptStateOG:AddTab({
	Title = "Potions",
	Icon = "beaker",
})
end,
function(...)
do
	local function getPotionNames()
		local scriptStateKC = {}
		if type(potionData) == "table" then
			for loopSlotCX, scriptStateUF in pairs(potionData) do
				if type(loopSlotCX) == "string" and type(scriptStateUF) == "table" then
					table.insert(scriptStateKC, {
						name = loopSlotCX,
						order = tonumber(scriptStateUF.LayoutOrder) or 9999,
					})
				end
			end
		end
		table.sort(scriptStateKC, function(scriptStateHA, scriptStateQF)
			return scriptStateHA.order == scriptStateQF.order and scriptStateHA.name < scriptStateQF.name
				or scriptStateHA.order < scriptStateQF.order
		end)
		local loopSlotCE = {}
		for loopSlotBS, scriptStatePS in ipairs(scriptStateKC) do
			table.insert(loopSlotCE, scriptStatePS.name)
		end
		if #loopSlotCE == 0 then
			loopSlotCE = {
				"Speed",
				"Lucky",
				"Mythic",
				"Coins",
				"Secret Elixir",
				"Infinity Elixir",
				"Egg Elixir",
			}
		end
		return loopSlotCE
	end
	local function getPotionLevels(scriptStateJ)
		local scriptStateRU = type(potionData) == "table" and potionData[scriptStateJ] or nil
		if type(scriptStateRU) == "table" then
			if scriptStateRU.OneLevel == true then
				return {
					"1",
				}
			end
			local potionBuffExpiry = scriptStateRU.Buff and scriptStateRU.Buff.Expiry
			if type(potionBuffExpiry) == "table" and #potionBuffExpiry > 0 then
				local scriptStateNA = {}
				for loopSlotAJ = 1, #potionBuffExpiry do
					scriptStateNA[loopSlotAJ] = tostring(loopSlotAJ)
				end
				return scriptStateNA
			end
		end
		return {
			"1",
			"2",
			"3",
			"4",
			"5",
			"6",
			"7",
		}
	end
	local function getSelectedPotions()
		local selected = {}
		for key, value in pairs(type(Config.selectedPotions) == "table" and Config.selectedPotions or {}) do
			local label = type(key) == "number" and value or (value == true and key or nil)
			if type(label) == "string" then
				local name, levelText = label:match("^(.-) | Level (%d+)$")
				name = name or label
				if type(potionData) == "table" and type(potionData[name]) == "table" then
					table.insert(selected, { Name = name, Level = tonumber(levelText), Label = label })
				end
			end
		end
		table.sort(selected, function(left, right) return left.Label < right.Label end)
		return selected
	end
	local function getPotionStock(potion, playerData)
		if type(playerData) ~= "table" then return 0 end
		local ok, amount = pcall(itemUtil.GetOwnedAmount, itemUtil, playerData, {
			Type = "Potion", Name = potion.Name, Level = potion.Level,
		})
		return ok and math.max(0, math.floor(tonumber(amount) or 0)) or 0
	end
	local function getPotionQuantityCap()
		local playerData = profileStore:IsReady() and profileStore:Get() or nil
		local selected = getSelectedPotions()
		if #selected == 0 then return 0 end
		local cap = math.huge
		for _, potion in ipairs(selected) do
			cap = math.min(cap, getPotionStock(potion, playerData))
		end
		return cap
	end
	local potionDropdown
	local potionQuantitySlider
	local potionStockText
	local lastPotionCap
	local function refreshPotionQuantity()
		local cap = getPotionQuantityCap()
		local previousAmount = Config.potionUseAmount
		Config.potionUseAmount = math.clamp(math.floor(tonumber(Config.potionUseAmount) or 1), 1, math.max(1, cap))
		if cap == lastPotionCap and Config.potionUseAmount == previousAmount then return cap end
		lastPotionCap = cap
		if potionQuantitySlider then
			pcall(function()
				potionQuantitySlider:SetRange(1, math.max(1, cap))
				potionQuantitySlider:SetValue(Config.potionUseAmount)
			end)
		end
		if potionStockText then
			pcall(function()
				potionStockText:SetDesc("Available for every selected potion: " .. tostring(cap))
			end)
		end
		return cap
	end
	local function getOwnedPotionOptions()
		local playerData = profileStore:IsReady() and profileStore:Get() or nil
		local options = {}
		for _, name in ipairs(getPotionNames()) do
			local oneLevel = type(potionData) == "table" and type(potionData[name]) == "table"
				and potionData[name].OneLevel == true
			for _, levelText in ipairs(getPotionLevels(name)) do
				local level
				if not oneLevel then level = tonumber(levelText) end
				local label = oneLevel and name or (name .. " | Level " .. levelText)
				if getPotionStock({ Name = name, Level = level }, playerData) > 0 then
					table.insert(options, label)
				end
			end
		end
		return options
	end
	if type(Config.selectedPotions) ~= "table" then Config.selectedPotions = {} end
	if Config.potionSelectionMigrated ~= true and type(Config.potionType) == "string" then
		local oneLevel = type(potionData) == "table" and type(potionData[Config.potionType]) == "table"
			and potionData[Config.potionType].OneLevel == true
		Config.selectedPotions = { oneLevel and Config.potionType or (Config.potionType .. " | Level " .. tostring(Config.potionLevel or 1)) }
		Config.potionSelectionMigrated = true
		saveConfig()
	end
	scriptStateYT:AddSection("Use Potions")
	potionDropdown = scriptStateYT:AddDropdown("SelectedPotions", {
		Title = "Potions to Use",
		Description = "Select several owned potions. Each receives the same quantity.",
		Values = getOwnedPotionOptions(),
		Default = Config.selectedPotions,
		Multi = true,
		Search = true,
		Callback = function(selected)
			Config.selectedPotions = type(selected) == "table" and selected or {}
			refreshPotionQuantity()
			saveConfig()
		end,
	})
	potionStockText = scriptStateYT:AddParagraph({
		Title = "Potion Stock", Content = "Select potions to see how many you can use.",
	})
	scriptStateYT:AddButton({
		Title = "Refresh Potion Stock",
		Callback = function()
			fireRemoteEventRepeatedly(potionDropdown, getOwnedPotionOptions())
			refreshPotionQuantity()
		end,
	})
	potionQuantitySlider = scriptStateYT:AddSlider("PotionUseAmount", {
		Title = "Quantity Per Potion",
		Description = "Capped by the least-owned selected potion; refreshes as stock changes.",
		Min = 1,
		Max = math.max(1, getPotionQuantityCap()),
		Default = math.clamp(tonumber(Config.potionUseAmount) or 1, 1, math.max(1, getPotionQuantityCap())),
		Rounding = 0,
		Callback = function(amount)
			Config.potionUseAmount = math.clamp(math.floor(tonumber(amount) or 1), 1, math.max(1, getPotionQuantityCap()))
			saveConfig()
		end,
	})
	refreshPotionQuantity()
	scriptStateYT:AddButton({
		Title = "Use Selected Now",
		Callback = function()
			local quantity = math.min(getPotionQuantityCap(), Config.potionUseAmount)
			if quantity < 1 then return end
			task.spawn(function()
				for _, potion in ipairs(getSelectedPotions()) do
					activeStates.BGSI_Lite_UsePotionAmount(potion.Name, potion.Level, quantity)
				end
				refreshPotionQuantity()
			end)
		end,
	})
	scriptStateYT:AddSlider("PotionMaintainSeconds", {
		Title = "Refresh Before Expiry",
		Min = 0,
		Max = 120,
		Default = Config.potionMaintainSeconds,
		Rounding = 0,
		Callback = function(seconds)
			Config.potionMaintainSeconds = math.clamp(math.floor(tonumber(seconds) or 30), 0, 120)
			saveConfig()
		end,
	})
	scriptStateYT:AddToggle("AutoUsePotions", {
		Title = "Auto Use Potions",
		Default = Config.potionAuto,
		Callback = function(scriptStateGS)
			Config.potionAuto = scriptStateGS
			saveConfig()
		end,
	})
	scriptStateYT:AddToggle("AutoEventPotions", {
		Title = "Auto Event Potions",
		Description = "Uses the matching event potion for the egg currently being hatched.",
		Default = Config.autoEventPotions,
		Callback = function(enabled)
			Config.autoEventPotions = enabled
			saveConfig()
		end,
	})
	activeStates.BGSI_Lite_EventPotionSources = {
		{
			potionName = "Halloween Elixir",
			constantName = "HalloweenEggs",
			eventTokens = { "halloween" },
		},
		{
			potionName = "Festive Elixir",
			constantName = "ChristmasEggs",
			eventTokens = { "christmas", "festive" },
		},
		{
			potionName = "2026 Elixir",
			constantName = "NewYearsEgg",
			eventTokens = { "nyc", "2026" },
		},
		{
			potionName = "600M Elixir",
			constantName = "Egg600M",
			eventTokens = { "600m" },
		},
		{
			potionName = "Circus Elixir",
			constantName = "CircusEggs",
			eventTokens = { "circus" },
		},
		{
			potionName = "Hell Elixir",
			eggNames = { "Hellish Egg" },
			eventTokens = { "hellish", "hell" },
		},
		{
			potionName = "Heaven Elixir",
			eggNames = { "Azure Egg" },
			eventTokens = { "heaven" },
		},
		{
			potionName = "Valentine's Elixir",
			eggNames = { "Valentine's Egg" },
			eventTokens = { "valentines", "valentine" },
		},
		{
			potionName = "Heartbreak Elixir",
			eggNames = { "Heartbreak Egg" },
			eventTokens = { "heartbreak" },
		},
		{
			potionName = "Lunar New Years Lantern",
			eggNames = { "Lunar New Years Egg" },
			eventTokens = { "lunarnewyears", "lunarnewyear" },
		},
		{
			potionName = "Flowers",
			constantName = "SpringEggs",
			eventTokens = { "spring" },
		},
		{
			potionName = "St Patricks Elixir",
			constantName = "StPatsEggs",
			eventTokens = { "stpatricks", "stpats" },
		},
		{
			potionName = "Easter Elixir",
			constantName = "EasterEventEggs",
			eventTokens = { "easter" },
		},
		{
			potionName = "Anniversary Elixir",
			constantName = "AnnivEgg",
			eventTokens = { "anniversary", "anniv" },
		},
		{
			potionName = "Wonderland Elixir",
			eggNames = { "Wonderland Egg" },
			eventTokens = { "wonderland" },
		},
		{
			potionName = "Summer Elixir",
			constantName = "SummerEgg",
			eventTokens = { "summer" },
		},
		{
			potionName = "Fire Elixir",
			constantName = "FirePotionEggs",
			eventTokens = { "fire" },
		},
		{
			potionName = "Ice Elixir",
			constantName = "IcePotionEggs",
			eventTokens = { "ice" },
		},
		{
			potionName = "Obsidian Elixir",
			constantName = "ObsidianEgg",
			eventTokens = { "obsidian" },
		},
		{
			potionName = "Carnival Elixir",
			constantName = "CarnivalEggs",
			eventTokens = { "ultracarnival", "carnival" },
		},
		{
			potionName = "Patriotic Elixir",
			constantName = "July4thEgg",
			eventTokens = { "july4th", "patriotic" },
		},
	}
	activeStates.BGSI_Lite_GetEventPotionForEgg = function(eggName)
		local eggInfo = type(eggDataModule) == "table" and eggDataModule[eggName] or nil
		local eventName = type(eggInfo) == "table" and eggInfo.Event or nil
		if type(eventName) ~= "string" or eventName == "" then
			return nil
		end
		for _, potionSource in ipairs(activeStates.BGSI_Lite_EventPotionSources) do
			local eventEggs = type(sharedConstants) == "table"
					and potionSource.constantName
					and sharedConstants[potionSource.constantName]
				or nil
			if
				(type(potionSource.eggNames) == "table" and table.find(potionSource.eggNames, eggName))
				or (type(eventEggs) == "string" and eventEggs == eggName)
				or (type(eventEggs) == "table" and table.find(eventEggs, eggName))
			then
				local potionInfo = type(potionData) == "table" and potionData[potionSource.potionName] or nil
				if type(potionInfo) == "table" and potionInfo.IsEvent == true then
					return potionSource.potionName
				end
			end
		end
		local normalizedEventName = string.lower(eventName):gsub("[^%w]", "")
		for _, potionSource in ipairs(activeStates.BGSI_Lite_EventPotionSources) do
			for _, eventToken in ipairs(potionSource.eventTokens) do
				if string.find(normalizedEventName, eventToken, 1, true) then
					local potionInfo = type(potionData) == "table" and potionData[potionSource.potionName] or nil
					if type(potionInfo) == "table" and potionInfo.IsEvent == true then
						return potionSource.potionName
					end
				end
			end
		end
		return nil
	end
	activeStates.BGSI_Lite_GetHighestOwnedPotionLevel = function(playerData, potionName)
		local potionLevels = getPotionLevels(potionName)
		for levelIndex = #potionLevels, 1, -1 do
			local potionLevel = tonumber(potionLevels[levelIndex]) or 1
			local amountOk, ownedAmount = pcall(itemUtil.GetOwnedAmount, itemUtil, playerData, {
				Type = "Potion",
				Name = potionName,
				Level = potionLevel,
			})
			if amountOk and (tonumber(ownedAmount) or 0) > 0 then
				return potionLevel
			end
		end
		return nil
	end
	activeStates.BGSI_Lite_GetPotionRemainingSeconds = function(playerData, potionType, potionLevel)
		local activePotions = type(playerData) == "table" and playerData.ActivePotions or nil
		if type(activePotions) ~= "table" then
			return 0
		end
		local remainingSeconds = 0
		for potionKey, potionInfo in pairs(activePotions) do
			local potionName = type(potionInfo) == "table"
					and tostring(potionInfo.Type or potionInfo.Name or potionInfo.Potion or potionKey)
				or tostring(potionKey)
			local level = type(potionInfo) == "table"
					and tonumber(potionInfo.Level or potionInfo.Tier)
				or tonumber(string.match(potionName, "%d+"))
			if
				string.find(string.lower(potionName), string.lower(tostring(potionType)), 1, true)
				and (level == nil or level >= (tonumber(potionLevel) or 1))
			then
				local expiresAt = type(potionInfo) == "table"
						and tonumber(
							potionInfo.ExpiresAt
								or potionInfo.ExpireAt
								or potionInfo.EndTime
								or potionInfo.Time
								or potionInfo.Duration
						)
					or tonumber(potionInfo)
				if expiresAt then
					local remaining = expiresAt > getCurrentTimestamp() and expiresAt - getCurrentTimestamp() or expiresAt
					remainingSeconds = math.max(remainingSeconds, remaining)
				end
			end
		end
		return math.max(0, remainingSeconds)
	end
	-- Auto hatch fires HatchEgg every few milliseconds, and the game silently drops a
	-- player's other requests while it does - which is why dashboard potion uses (and
	-- some shop buys) did nothing with no reason given. Hatching pauses briefly around
	-- each potion request instead.
	if type(fireHatchEgg) == "function" and not activeStates.BGSI_Lite_HatchPauseWrapped then
		local originalFireHatchEgg = fireHatchEgg
		fireHatchEgg = function(...)
			if tick() < (tonumber(activeStates.BGSI_Lite_HatchPauseUntil) or 0) then
				return false
			end
			return originalFireHatchEgg(...)
		end
		activeStates.BGSI_Lite_HatchPauseWrapped = true
	end
	-- Learn the game's potion request: record what the game itself sends when a potion
	-- is used by hand, so dashboard uses can copy a format the game changed.
	local potionFormatFile = "larplite_potion_format.json"
	if activeStates.BGSI_Lite_PotionFormat == nil then
		activeStates.BGSI_Lite_PotionFormat = false
		pcall(function()
			if isfile and isfile(potionFormatFile) then
				local saved = HttpService:JSONDecode(readfile(potionFormatFile))
				if type(saved) == "table" and type(saved.action) == "string" then activeStates.BGSI_Lite_PotionFormat = saved end
			end
		end)
	end
	local function describeArg(value, depth)
		local kind = typeof(value)
		if kind == "table" and (depth or 0) < 2 then
			local fields = {}
			for key, inner in pairs(value) do
				fields[tostring(key)] = describeArg(inner, (depth or 0) + 1)
			end
			return { t = "table", v = fields }
		elseif kind == "string" or kind == "number" or kind == "boolean" then
			return { t = kind, v = value }
		end
		return { t = kind }
	end
	activeStates.BGSI_Lite_RecordPotionRequest = function(method, action, args)
		local described = {}
		for index = 1, args.n do described[index] = describeArg(args[index]) end
		local format = { method = method, action = action, args = described, at = os.time() }
		activeStates.BGSI_Lite_PotionFormat = format
		pcall(function()
			if writefile then writefile(potionFormatFile, HttpService:JSONEncode(format)) end
		end)
		print("[" .. LocalPlayer.Name .. "] Learned the game's potion request: " .. method .. " " .. action .. " (" .. HttpService:JSONEncode(described):sub(1, 300) .. ")")
	end
	if not activeStates.BGSI_Lite_PotionSpyInstalled and type(hookmetamethod) == "function"
		and type(getnamecallmethod) == "function" and type(checkcaller) == "function" then
		activeStates.BGSI_Lite_PotionSpyInstalled = true
		pcall(function()
			local originalNamecall
			local handler = function(self, ...)
				if not checkcaller() then
					local method = getnamecallmethod()
					if method == "FireServer" or method == "InvokeServer" then
						local action = ...
						if type(action) == "string" and string.find(string.lower(action), "potion", 1, true) then
							local packed = table.pack(...)
							task.defer(function()
								local record = activeStates.BGSI_Lite_RecordPotionRequest
								if type(record) == "function" then
									pcall(record, method, action, { n = packed.n - 1, table.unpack(packed, 2, packed.n) })
								end
							end)
						end
					end
				end
				return originalNamecall(self, ...)
			end
			originalNamecall = hookmetamethod(game, "__namecall", type(newcclosure) == "function" and newcclosure(handler) or handler)
		end)
	end
	-- Rebuild a learned request for another potion: swap the learned potion's name,
	-- level and amount for the ones wanted (in plain arguments and inside tables).
	local function buildLearnedPotionArgs(format, name, level, amount)
		local learnedName, learnedLevel, learnedAmount
		for _, arg in ipairs(format.args) do
			if arg.t == "string" and not learnedName then learnedName = arg.v end
			if arg.t == "table" and type(arg.v) == "table" then
				for key, inner in pairs(arg.v) do
					if key == "Name" and inner.t == "string" then learnedName = inner.v end
					if key == "Level" and inner.t == "number" then learnedLevel = inner.v end
					if key == "Amount" and inner.t == "number" then learnedAmount = inner.v end
				end
			end
		end
		local numberIndex = 0
		local function rebuild(arg)
			if arg.t == "string" then return arg.v == learnedName and name or arg.v end
			if arg.t == "number" then
				numberIndex += 1
				-- Plain numbers follow the game's old order: level first, then amount.
				if learnedLevel == nil and numberIndex == 1 then return level or 1 end
				return amount
			end
			if arg.t == "boolean" then return arg.v end
			if arg.t == "table" and type(arg.v) == "table" then
				local result = {}
				for key, inner in pairs(arg.v) do
					if key == "Name" then result[key] = name
					elseif key == "Level" then result[key] = level
					elseif key == "Amount" then result[key] = amount
					else result[key] = rebuild(inner) end
				end
				return result
			end
			return nil
		end
		local built = {}
		for index, arg in ipairs(format.args) do built[index] = rebuild(arg) end
		return built, #format.args
	end
	-- Local remote probe (developer tool): when larplite_probe_<UserId>.json exists in the
	-- executor workspace, fire the request it describes once, then write what changed to
	-- larplite_probe_<UserId>_result.json. Only files on this PC can drive it.
	task.spawn(function()
		local probeFile = "larplite_probe_" .. tostring(LocalPlayer.UserId) .. ".json"
		local resultFile = "larplite_probe_" .. tostring(LocalPlayer.UserId) .. "_result.json"
		local lastId
		local function decodeArg(value)
			if type(value) == "table" then
				if value["$nil"] then return nil end
				local result = {}
				for key, inner in pairs(value) do result[key] = decodeArg(inner) end
				return result
			end
			return value
		end
		while isCurrentRun() do
			task.wait(2)
			local ok, probe = pcall(function()
				return isfile and isfile(probeFile) and HttpService:JSONDecode(readfile(probeFile)) or nil
			end)
			-- Inspection actions: "$tree" lists remotes, "$decompile" saves named modules'
			-- source, "$grep" searches every client module's source for a string.
			if ok and type(probe) == "table" and probe.id ~= nil and probe.id ~= lastId and type(probe.action) == "string"
				and probe.action:sub(1, 1) == "$" then
				lastId = probe.id
				local output = { id = probe.id, action = probe.action, items = {}, at = os.time() }
				local roots = { ReplicatedStorage, LocalPlayer:FindFirstChild("PlayerScripts"), LocalPlayer:FindFirstChild("PlayerGui"), game:GetService("StarterPlayer") }
				local decompiler = type(decompile) == "function" and decompile or nil
				output.canDecompile = decompiler ~= nil
				if probe.action == "$ui" then
					-- Steps: open a GuiFrame, fire a button's handlers (client-only), press a
					-- button for real (selected + Enter, so the engine raises Activated), set
					-- text, wait, or dump a subtree. Paths start at PlayerGui.ScreenGui.
					local screenGui = LocalPlayer.PlayerGui:FindFirstChild("ScreenGui")
					local GuiService = game:GetService("GuiService")
					local function resolve(step)
						local node = screenGui
						for part in tostring(step.path or ""):gmatch("[^%.]+") do
							node = node and node:FindFirstChild(part)
						end
						if node and step.find then node = node:FindFirstChild(step.find, true) end
						return node
					end
					local check = type(probe.check) == "table" and { Type = "Potion", Name = probe.check.Name, Level = probe.check.Level } or nil
					local function owned()
						if not check then return nil end
						local data = profileStore:IsReady() and profileStore:Get() or nil
						local good, amount = pcall(itemUtil.GetOwnedAmount, itemUtil, data, check)
						return good and amount or nil
					end
					output.before = owned()
					for index, step in ipairs(type(probe.steps) == "table" and probe.steps or {}) do
						local good, note = pcall(function()
							if step.op == "open" then
								require(ReplicatedStorage.Client.Gui.GuiFrame):Open(step.frame)
								return "opened " .. tostring(step.frame)
							elseif step.op == "wait" then
								task.wait(tonumber(step.s) or 0.5)
								return "waited"
							end
							local node = resolve(step)
							if not node then return "missing " .. tostring(step.path) .. "/" .. tostring(step.find) end
							local button = node
							if not (button:IsA("GuiButton")) then
								button = node:FindFirstChild("Activation") or node:FindFirstChildWhichIsA("GuiButton", true) or node
							end
							if step.op == "fire" then
								local fired = 0
								for _, connection in ipairs(getconnections(button.Activated)) do
									pcall(function() connection:Fire() end)
									fired += 1
								end
								return "fired " .. fired .. " on " .. button:GetFullName()
							elseif step.op == "press" then
								GuiService.SelectedObject = button
								task.wait(0.1)
								for _, key in ipairs({ Enum.KeyCode.Return, Enum.KeyCode.ButtonA }) do
									VirtualInputManager:SendKeyEvent(true, key, false, game)
									task.wait(0.05)
									VirtualInputManager:SendKeyEvent(false, key, false, game)
									task.wait(0.1)
								end
								local selected = GuiService.SelectedObject
								GuiService.SelectedObject = nil
								return "pressed " .. button:GetFullName() .. " (selected=" .. tostring(selected) .. ")"
							elseif step.op == "click" then
								local inset = game:GetService("GuiService"):GetGuiInset()
								local center = button.AbsolutePosition + button.AbsoluteSize / 2 + inset
								VirtualInputManager:SendMouseButtonEvent(center.X, center.Y, 0, true, game, 0)
								task.wait(0.05)
								VirtualInputManager:SendMouseButtonEvent(center.X, center.Y, 0, false, game, 0)
								return "clicked " .. button:GetFullName() .. " at " .. tostring(center) .. " visible=" .. tostring(button.Visible)
							elseif step.op == "text" then
								local box = node:IsA("TextBox") and node or node:FindFirstChildWhichIsA("TextBox", true)
								if not box then return "no textbox" end
								box.Text = tostring(step.value)
								return "text " .. box:GetFullName()
							elseif step.op == "dump" then
								local lines = {}
								local function walk(item, depth)
									if #lines > 120 or depth > (tonumber(step.depth) or 4) then return end
									local extra = item:IsA("GuiObject") and (" vis=" .. tostring(item.Visible)) or ""
									if item:IsA("TextLabel") or item:IsA("TextButton") or item:IsA("TextBox") then extra ..= " text=" .. tostring(item.Text):sub(1, 40) end
									table.insert(lines, string.rep(" ", depth) .. item.Name .. " [" .. item.ClassName .. "]" .. extra)
									for _, child in ipairs(item:GetChildren()) do walk(child, depth + 1) end
								end
								walk(node, 0)
								return table.concat(lines, "\n")
							end
							return "unknown op"
						end)
						table.insert(output.items, index .. ": " .. tostring(step.op) .. " -> " .. (good and tostring(note) or ("error " .. tostring(note))))
					end
					task.wait(tonumber(probe.wait) or 2)
					output.after = owned()
				elseif probe.action == "$state" then
					local character = LocalPlayer.Character
					local humanoid = character and character:FindFirstChildOfClass("Humanoid")
					local root = character and character:FindFirstChild("HumanoidRootPart")
					output.values = {
						character = character and character:GetFullName() or "none",
						characterParent = character and tostring(character.Parent) or "none",
						humanoid = humanoid and (tostring(humanoid.Health) .. "/" .. tostring(humanoid.MaxHealth) .. " " .. tostring(humanoid:GetState())) or "none",
						root = root and tostring(root.Position) or "none",
						anchored = root and tostring(root.Anchored) or "none",
						safeMode = tostring(Config.safeMode),
						rendering = tostring(Config.disableRendering),
						attributes = HttpService:JSONEncode(LocalPlayer:GetAttributes()),
					}
				elseif probe.action == "$data" then
					local data = profileStore:IsReady() and profileStore:Get() or nil
					for key in pairs(type(data) == "table" and data or {}) do table.insert(output.items, tostring(key)) end
					table.sort(output.items)
					output.values = {}
					for _, key in ipairs(type(probe.keys) == "table" and probe.keys or {}) do
						local good, text = pcall(HttpService.JSONEncode, HttpService, type(data) == "table" and data[key] or nil)
						output.values[key] = good and text:sub(1, 6000) or "?"
					end
				elseif probe.action == "$tree" then
					for _, root in ipairs(roots) do
						for _, instance in ipairs(root and root:GetDescendants() or {}) do
							if instance:IsA("RemoteEvent") or instance:IsA("RemoteFunction") or instance.ClassName == "UnreliableRemoteEvent" then
								table.insert(output.items, instance.ClassName .. " " .. instance:GetFullName())
							end
						end
					end
				elseif probe.action == "$decompile" and decompiler then
					for _, root in ipairs(roots) do
						for _, instance in ipairs(root and root:GetDescendants() or {}) do
							if (instance:IsA("ModuleScript") or instance:IsA("LocalScript")) and instance.Name == probe.name then
								local good, source = pcall(decompiler, instance)
								local fileName = "larplite_src_" .. probe.name .. "_" .. (#output.items + 1) .. ".lua"
								pcall(writefile, fileName, "-- " .. instance:GetFullName() .. "\n" .. tostring(good and source or ("decompile failed: " .. tostring(source))))
								table.insert(output.items, instance:GetFullName() .. " -> " .. fileName)
								task.wait()
							end
						end
					end
				elseif probe.action == "$grep" and decompiler and type(probe.text) == "string" then
					local scanned = 0
					for _, root in ipairs(roots) do
						for _, instance in ipairs(root and root:GetDescendants() or {}) do
							if (instance:IsA("ModuleScript") or instance:IsA("LocalScript")) and scanned < (tonumber(probe.limit) or 1500) then
								scanned += 1
								local good, source = pcall(decompiler, instance)
								if good and type(source) == "string" then
									local at = source:find(probe.text, 1, true)
									while at and #output.items < 60 do
										table.insert(output.items, instance:GetFullName() .. " :: " .. source:sub(math.max(1, at - 300), at + 300))
										at = source:find(probe.text, at + #probe.text, true)
									end
								end
								if scanned % 10 == 0 then task.wait() end
							end
						end
					end
					output.scanned = scanned
				end
				pcall(writefile, resultFile, HttpService:JSONEncode(output))
			elseif ok and type(probe) == "table" and probe.id ~= nil and probe.id ~= lastId and type(probe.action) == "string" then
				lastId = probe.id
				local check = type(probe.check) == "table" and { Type = probe.check.Type or "Potion", Name = probe.check.Name, Level = probe.check.Level } or nil
				local function owned()
					if not check then return nil end
					local data = profileStore:IsReady() and profileStore:Get() or nil
					local good, amount = pcall(itemUtil.GetOwnedAmount, itemUtil, data, check)
					return good and amount or nil
				end
				local events = {}
				local connection = remoteEvent.OnClientEvent:Connect(function(action, ...)
					if #events < 12 and type(action) == "string" and action ~= "HatchEgg" then
						local first = ...
						table.insert(events, action .. (type(first) == "string" and (": " .. first:sub(1, 80)) or ""))
					end
				end)
				activeStates.BGSI_Lite_PauseHatching(6)
				task.wait(0.5)
				local function snapshot()
					local data = profileStore:IsReady() and profileStore:Get() or nil
					local result = {}
					for _, key in ipairs(type(probe.dataKeys) == "table" and probe.dataKeys or {}) do
						local good, text = pcall(HttpService.JSONEncode, HttpService, type(data) == "table" and data[key] or nil)
						result[key] = good and text:sub(1, 3000) or "?"
					end
					return result
				end
				local dataBefore = snapshot()
				local before = owned()
				local args = {}
				local count = 0
				for index, value in ipairs(type(probe.args) == "table" and probe.args or {}) do
					args[index] = decodeArg(value)
					count = index
				end
				local returned
				local fired, fireError = pcall(function()
					local via = probe.via or "event"
					if via == "identity2" then
						local setIdentity = (type(setthreadidentity) == "function" and setthreadidentity)
							or (type(set_thread_identity) == "function" and set_thread_identity)
							or (type(setidentity) == "function" and setidentity)
						local getIdentity = (type(getthreadidentity) == "function" and getthreadidentity)
							or (type(get_thread_identity) == "function" and get_thread_identity)
							or (type(getidentity) == "function" and getidentity)
						local previous = getIdentity and getIdentity() or nil
						returned = "identity " .. tostring(previous) .. " -> 2" .. (setIdentity and "" or " (no setter)")
						if setIdentity then setIdentity(2) end
						remoteEvent:FireServer(probe.action, table.unpack(args, 1, count))
						if setIdentity and previous then setIdentity(previous) end
					elseif via == "heartbeat" then
						local done = false
						RunService.Heartbeat:Once(function()
							remoteEvent:FireServer(probe.action, table.unpack(args, 1, count))
							done = true
						end)
						local waitUntil = tick() + 2
						while not done and tick() < waitUntil do task.wait() end
						returned = "heartbeat " .. tostring(done)
					elseif via == "module" then
						-- The game's own Remote module, the path its scripts use.
						local module = require(networkRemote)
						if probe.method == "InvokeServer" then
							returned = module:InvokeServer(probe.action, table.unpack(args, 1, count))
						else
							module:FireServer(probe.action, table.unpack(args, 1, count))
						end
					elseif via == "fresh" then
						-- A fresh lookup of the instance, in case the cached one went stale.
						local live = ReplicatedStorage.Shared.Framework.Network.Remote:FindFirstChild(probe.method == "InvokeServer" and "RemoteFunction" or "RemoteEvent")
						if probe.method == "InvokeServer" then
							returned = live:InvokeServer(probe.action, table.unpack(args, 1, count))
						else
							live:FireServer(probe.action, table.unpack(args, 1, count))
						end
						returned = returned or (live == remoteEvent or live == remoteFunction) and "same-instance" or "different-instance"
					elseif probe.method == "InvokeServer" then
						returned = remoteFunction:InvokeServer(probe.action, table.unpack(args, 1, count))
					else
						remoteEvent:FireServer(probe.action, table.unpack(args, 1, count))
					end
				end)
				local after = before
				local deadline = tick() + (tonumber(probe.wait) or 3)
				repeat
					task.wait(0.1)
					after = owned()
				until tick() >= deadline or (before and after and after ~= before)
				connection:Disconnect()
				activeStates.BGSI_Lite_HatchPauseUntil = 0
				local returnedText
				pcall(function() returnedText = HttpService:JSONEncode({ returned }) end)
				pcall(writefile, resultFile, HttpService:JSONEncode({
					id = probe.id, fired = fired, error = fireError and tostring(fireError) or nil,
					before = before, after = after, events = events, returned = returnedText, at = os.time(),
					dataBefore = dataBefore, dataAfter = snapshot(),
				}))
			end
		end
	end)
	-- Potions through the game's own inventory buttons. On this executor the server
	-- ignores requests sent from the script's threads (potions, favorites, teleports all
	-- verified to do nothing), while a real button press - the button selected, then
	-- Enter - makes the engine run the game's own handler, which the server accepts.
	-- Verified live: one press of Use took Leaf Elixir IV from 228 to 227.
	activeStates.BGSI_Lite_UsePotionViaInventory = function(potionName, potionLevel, requestedAmount, potionItem)
		local GuiService = game:GetService("GuiService")
		local screenGui = LocalPlayer.PlayerGui:FindFirstChild("ScreenGui")
		local GuiFrame = require(ReplicatedStorage.Client.Gui.GuiFrame)
		if not screenGui or not screenGui:FindFirstChild("Inventory") then return 0, "The inventory isn't loaded" end
		if type(getconnections) ~= "function" or not VirtualInputManager then return 0, "This executor can't press game buttons" end
		local function ownedNow()
			local data = profileStore:IsReady() and profileStore:Get() or nil
			local good, amount = pcall(itemUtil.GetOwnedAmount, itemUtil, data, potionItem)
			return good and math.max(0, math.floor(tonumber(amount) or 0)) or 0
		end
		local function buttonOf(node)
			if not node then return nil end
			if node:IsA("GuiButton") then return node end
			return node:FindFirstChild("Activation") or node:FindFirstChildWhichIsA("GuiButton", true)
		end
		local function fireLocal(node)
			local button = buttonOf(node)
			if not button then return false end
			for _, connection in ipairs(getconnections(button.Activated)) do pcall(function() connection:Fire() end) end
			return true
		end
		local function press(node)
			local button = buttonOf(node)
			if not button then return false end
			GuiService.SelectedObject = button
			task.wait(0.08)
			VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Return, false, game)
			task.wait(0.04)
			VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Return, false, game)
			task.wait(0.1)
			if GuiService.SelectedObject == button then GuiService.SelectedObject = nil end
			return true
		end
		local inventory = screenGui.Inventory
		local frameName = potionLevel and (tostring(potionName) .. "/" .. tostring(potionLevel)) or tostring(potionName)
		local function selectPotion()
			pcall(function() GuiFrame:Open("Inventory") end)
			task.wait(0.3)
			fireLocal(inventory.Frame.Sidebar.Buttons:FindFirstChild("Items"))
			task.wait(0.2)
			local entry = inventory.Frame.Inner.Items:FindFirstChild(frameName, true)
			if not entry then return false end
			return fireLocal(entry:FindFirstChild("Inner") and entry.Inner:FindFirstChild("Button") or entry)
		end
		local details = inventory.Frame.Inner.Items.Details.Buttons
		local before = ownedNow()
		local target = math.max(0, before - requestedAmount)
		local stalls = 0
		local lastError
		while isCurrentRun() and ownedNow() > target and stalls < 3 do
			local current = ownedNow()
			local chunk = math.min(current - target, 250, current)
			if not selectPotion() then
				lastError = "Couldn't find " .. frameName .. " in the inventory"
				break
			end
			if chunk <= 1 then
				press(details.Use)
			else
				press(details.Multi)
				local prompt
				local promptDeadline = tick() + 3
				repeat
					task.wait(0.1)
					prompt = screenGui:FindFirstChild("Prompt")
				until prompt or tick() >= promptDeadline
				if not prompt then
					lastError = "The Use Multiple window didn't open"
					stalls += 1
					continue
				end
				local box = prompt:FindFirstChild("TextBox", true)
				if box then box.Text = tostring(chunk) end
				task.wait(0.25)
				local useButton
				local buttons = prompt.Frame.Main:FindFirstChild("Buttons")
				for _, option in ipairs(buttons and buttons:GetChildren() or {}) do
					local label = option:FindFirstChild("Label", true)
					if label and label:IsA("TextLabel") and label.Text == ("Use " .. tostring(chunk)) then
						useButton = option
						break
					end
				end
				if not useButton then
					lastError = "The Use Multiple window had no 'Use " .. tostring(chunk) .. "' button"
					stalls += 1
					pcall(function() prompt:Destroy() end)
					continue
				end
				press(useButton)
			end
			local deadline = tick() + 4
			repeat task.wait(0.1) until ownedNow() < current or tick() >= deadline
			if ownedNow() < current then stalls = 0 else stalls += 1; lastError = "The game didn't take the potion" end
		end
		local leftover = screenGui:FindFirstChild("Prompt")
		if leftover then pcall(function() leftover:Destroy() end) end
		pcall(function() GuiFrame:Close("Inventory") end)
		GuiService.SelectedObject = nil
		local used = math.max(0, before - ownedNow())
		return used, used < requestedAmount and lastError or nil
	end
	activeStates.BGSI_Lite_PauseHatching = function(seconds)
		activeStates.BGSI_Lite_HatchPauseUntil = math.max(tonumber(activeStates.BGSI_Lite_HatchPauseUntil) or 0, tick() + seconds)
	end
	activeStates.BGSI_Lite_UsePotionAmount = function(potionType, potionLevel, requestedAmount)
		local waitDeadline = tick() + 2
		while activeStates.BGSI_Lite_PotionUseActive and tick() < waitDeadline do
			task.wait(0.05)
		end
		if activeStates.BGSI_Lite_PotionUseActive then
			return 0, "Another potion use is still running"
		end
		activeStates.BGSI_Lite_PotionUseActive = true
		-- The server explains a refused potion with a "Notification" event; keep what it
		-- says so a failure reports the game's reason instead of just "used 0".
		local gameMessages = {}
		local diag = { sent = 0, forms = {}, before = nil, after = nil, run = isCurrentRun(), safe = Config.safeMode == true }
		local messageConnection = remoteEvent.OnClientEvent:Connect(function(action, ...)
			if action ~= "Notification" or #gameMessages >= 3 then return end
			for _, value in ipairs({ ... }) do
				local text = type(value) == "string" and value
					or type(value) == "table" and (value.Text or value.Message or value.Title)
				if type(text) == "string" and text ~= "" then
					text = text:gsub("<[^>]->", ""):gsub("%s+", " ")
					if not table.find(gameMessages, text) then table.insert(gameMessages, text:sub(1, 140)) end
					break
				end
			end
		end)
		local useOk, usedAmount = pcall(function()
			local playerData = profileStore:IsReady() and profileStore:Get() or nil
			-- The game matches a stored potion on Name AND Level, comparing Level by
			-- equality - so an item held with no level is only found by a lookup that
			-- also has no level. Defaulting a missing level to 1 made every levelless
			-- elixir (Circus, Infinity, Secret, Egg) look like you owned none of it,
			-- which is why using one reported "the game only used 0 of 1".
			local potionItem = {
				Type = "Potion",
				Name = tostring(potionType or ""),
				Level = tonumber(potionLevel),
			}
			local amountOk, amountBefore = pcall(itemUtil.GetOwnedAmount, itemUtil, playerData, potionItem)
			amountBefore = amountOk and math.max(0, math.floor(tonumber(amountBefore) or 0)) or 0
			diag.before = amountBefore
			local targetAmount = math.max(0, amountBefore - math.max(1, math.floor(tonumber(requestedAmount) or 1)))
			local currentAmount = amountBefore
			-- The game's own "Use Multiple" button sends UsePotion(name, level, amount), up to
			-- Constants.MultiPotionMaxAmount (250) per request, with level 1 for potions that
			-- have none. Single requests (name, level) consume one each and are the fallback.
			local multiMax = tonumber(sharedConstants and sharedConstants.MultiPotionMaxAmount) or 250
			local uiUsed, uiError = activeStates.BGSI_Lite_UsePotionViaInventory(potionItem.Name, potionItem.Level, amountBefore - targetAmount, potionItem)
			diag.ui = tostring(uiUsed) .. (uiError and (" (" .. uiError .. ")") or "")
			currentAmount = math.max(0, amountBefore - (tonumber(uiUsed) or 0))
			if currentAmount <= targetAmount then
				diag.after = currentAmount
				return amountBefore - currentAmount
			end
			local attempts = {}
			local learned = activeStates.BGSI_Lite_PotionFormat
			if type(learned) == "table" and type(learned.args) == "table" then
				table.insert(attempts, { learned = learned })
			end
			table.insert(attempts, { bulk = true, level = potionItem.Level or 1 })
			if potionItem.Level == nil then table.insert(attempts, { bulk = true, level = nil }) end
			table.insert(attempts, { bulk = false, level = potionItem.Level })
			local attemptIndex = 1
			local stalled = 0
			local useDeadline = tick() + 12 + math.ceil((amountBefore - targetAmount) / multiMax) * 4
			activeStates.BGSI_Lite_PauseHatching(1.5)
			task.wait(0.4)
			while isCurrentRun() and currentAmount > targetAmount and tick() < useDeadline and attemptIndex <= #attempts do
				local attempt = attempts[attemptIndex]
				local remaining = currentAmount - targetAmount
				activeStates.BGSI_Lite_PauseHatching(3)
				diag.sent += 1
				diag.forms[attempt.learned and ("learned:" .. attempt.learned.action) or ((attempt.bulk and "bulk" or "single") .. ":" .. tostring(attempt.level))] = true
				-- Straight to the RemoteEvent, exactly as the game's Remote module does.
				if attempt.learned then
					local args, count = buildLearnedPotionArgs(attempt.learned, potionItem.Name, potionItem.Level, math.min(multiMax, remaining))
					if attempt.learned.method == "InvokeServer" then
						task.spawn(function() pcall(remoteFunction.InvokeServer, remoteFunction, attempt.learned.action, table.unpack(args, 1, count)) end)
					else
						remoteEvent:FireServer(attempt.learned.action, table.unpack(args, 1, count))
					end
				elseif attempt.bulk then
					remoteEvent:FireServer("UsePotion", potionItem.Name, attempt.level, math.min(multiMax, remaining))
				else
					remoteEvent:FireServer("UsePotion", potionItem.Name, attempt.level)
				end
				local previousAmount = currentAmount
				local replicationDeadline = tick() + (attempt.bulk and 2.5 or 0.75)
				repeat
					task.wait(0.05)
					playerData = profileStore:IsReady() and profileStore:Get() or nil
					local updatedOk, updatedAmount = pcall(itemUtil.GetOwnedAmount, itemUtil, playerData, potionItem)
					if updatedOk then
						currentAmount = math.max(0, math.floor(tonumber(updatedAmount) or previousAmount))
					end
				until not isCurrentRun() or currentAmount < previousAmount or tick() >= replicationDeadline
				if currentAmount < previousAmount then
					stalled = 0
					task.wait(attempt.bulk and 0.15 or 0.05)
				else
					stalled += 1
					-- Two silent requests in a row: this form isn't accepted, try the next one.
					if stalled >= 2 then
						attemptIndex += 1
						stalled = 0
					end
					task.wait(0.15)
				end
			end
			diag.after = currentAmount
			return amountBefore - currentAmount
		end)
		activeStates.BGSI_Lite_PotionUseActive = false
		activeStates.BGSI_Lite_HatchPauseUntil = 0
		messageConnection:Disconnect()
		if not useOk then
			return 0, tostring(usedAmount)
		end
		usedAmount = math.max(0, tonumber(usedAmount) or 0)
		if usedAmount < math.max(1, math.floor(tonumber(requestedAmount) or 1)) then
			local reason = "The game only used " .. tostring(usedAmount) .. " of " .. tostring(requestedAmount) .. " " .. tostring(potionType)
			if #gameMessages > 0 then
				reason = reason .. ". Game said: " .. table.concat(gameMessages, " / ")
			else
				reason = reason .. " (the game gave no reason)"
			end
			local forms = {}
			for form in pairs(diag.forms) do table.insert(forms, form) end
			reason = reason .. string.format(" [inventory: %s; sent %d: %s; owned %s -> %s]", tostring(diag.ui), diag.sent,
				table.concat(forms, ","), tostring(diag.before), tostring(diag.after))
			local learned = activeStates.BGSI_Lite_PotionFormat
			if type(learned) == "table" then
				local ok, text = pcall(HttpService.JSONEncode, HttpService, learned.args)
				reason = reason .. " [game format: " .. tostring(learned.method) .. " " .. tostring(learned.action) .. " " .. (ok and text:sub(1, 400) or "?") .. "]"
			elseif activeStates.BGSI_Lite_PotionSpyInstalled then
				reason = reason .. " [Use one potion by hand in game on this account, then try again: the script will copy how the game does it.]"
			else
				reason = reason .. " [This executor can't watch game requests (no hookmetamethod).]"
			end
			return usedAmount, reason
		end
		return usedAmount
	end
	task.spawn(function()
		while isCurrentRun() do
			task.wait((Config.potionAuto or Config.autoEventPotions) and 1 or 0.85)
			if Config.autoEventPotions then
				local playerData = profileStore:IsReady() and profileStore:Get() or nil
				local eggName = tostring(activeStates.BGSI_Lite_LastHatchRequestedEgg or Config.selectedEgg or "")
				local eventPotionName = activeStates.BGSI_Lite_GetEventPotionForEgg(eggName)
				local eventPotionLevel = eventPotionName
						and activeStates.BGSI_Lite_GetHighestOwnedPotionLevel(playerData, eventPotionName)
					or nil
				activeStates.BGSI_Lite_CurrentEventEgg = eggName
				activeStates.BGSI_Lite_CurrentEventPotion = eventPotionName
				if eventPotionName and eventPotionLevel then
					local eventPotionInfo = potionData[eventPotionName]
					local eventPotionBuff = eventPotionInfo.Buff and eventPotionInfo.Buff.Name or eventPotionName
					local remainingSeconds = activeStates.BGSI_Lite_GetPotionRemainingSeconds(
						playerData,
						eventPotionBuff,
						eventPotionLevel
					)
					local maintainSeconds = math.max(5, tonumber(Config.potionMaintainSeconds) or 30)
					local potionAmount = math.max(1, math.floor(tonumber(Config.potionUseAmount) or 1))
					local potionDuration = eventPotionInfo.Buff
							and type(eventPotionInfo.Buff.Expiry) == "table"
							and tonumber(eventPotionInfo.Buff.Expiry[eventPotionLevel])
						or 120
					if
						remainingSeconds <= maintainSeconds
						and tick() >= (tonumber(activeStates.BGSI_Lite_NextAutoEventPotionUseAt) or 0)
					then
						local usedAmount =
							activeStates.BGSI_Lite_UsePotionAmount(eventPotionName, eventPotionLevel, potionAmount)
						activeStates.BGSI_Lite_NextAutoEventPotionUseAt = tick()
							+ (
								usedAmount > 0
										and math.max(5, potionDuration * usedAmount - maintainSeconds)
									or 5
							)
						if
							usedAmount > 0
							and type(activeStates.BGSI_Lite_LogDashboardAction) == "function"
						then
							activeStates.BGSI_Lite_LogDashboardAction(
								"Using "
									.. tostring(usedAmount)
									.. "x "
									.. eventPotionName
									.. " "
									.. tostring(eventPotionLevel)
									.. " for "
									.. eggName,
								"collect"
							)
						end
					end
				end
			end
			if Config.potionAuto then
				local playerData = profileStore:IsReady() and profileStore:Get() or nil
				local maintainSeconds = math.max(5, tonumber(Config.potionMaintainSeconds) or 30)
				for _, potion in ipairs(getSelectedPotions()) do
					local stock = getPotionStock(potion, playerData)
					local nextUses = activeStates.BGSI_Lite_NextAutoPotionUseAt
					if type(nextUses) ~= "table" then
						nextUses = {}
						activeStates.BGSI_Lite_NextAutoPotionUseAt = nextUses
					end
					local potionInfo = potionData[potion.Name]
					local buffName = type(potionInfo) == "table" and type(potionInfo.Buff) == "table"
						and potionInfo.Buff.Name or potion.Name
					local remaining = activeStates.BGSI_Lite_GetPotionRemainingSeconds(playerData, buffName, potion.Level)
					if stock > 0 and remaining <= maintainSeconds and tick() >= (nextUses[potion.Label] or 0) then
						local quantity = math.min(stock, math.max(1, math.floor(tonumber(Config.potionUseAmount) or 1)))
						local used = activeStates.BGSI_Lite_UsePotionAmount(potion.Name, potion.Level, quantity)
						local expiry = type(potionInfo) == "table" and type(potionInfo.Buff) == "table"
							and type(potionInfo.Buff.Expiry) == "table"
							and tonumber(potionInfo.Buff.Expiry[potion.Level or 1])
							or 120
						nextUses[potion.Label] = tick() + (used > 0 and math.max(5, expiry * used - maintainSeconds) or 5)
					end
				end
			end
			refreshPotionQuantity()
		end
	end)
end
end
}
