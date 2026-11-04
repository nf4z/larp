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
	activeStates.BGSI_Lite_UsePotionAmount = function(potionType, potionLevel, requestedAmount)
		local waitDeadline = tick() + 2
		while activeStates.BGSI_Lite_PotionUseActive and tick() < waitDeadline do
			task.wait(0.05)
		end
		if activeStates.BGSI_Lite_PotionUseActive then
			return 0, "Another potion use is still running"
		end
		activeStates.BGSI_Lite_PotionUseActive = true
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
			local targetAmount = math.max(0, amountBefore - math.max(1, math.floor(tonumber(requestedAmount) or 1)))
			local currentAmount = amountBefore
			local stalledAttempts = 0
			-- One request per potion, so the budget has to scale with how many were
			-- asked for. 250 is a normal request and needs well over the old 90s cap.
			local useDeadline = tick() + math.max(8, 6 + (amountBefore - targetAmount) * 0.9)
			while
				isCurrentRun()
				and currentAmount > targetAmount
				and tick() < useDeadline
				and stalledAttempts < 4
			do
				-- UsePotion takes the name and the level, and consumes exactly one. There
				-- is no bulk form anywhere in the game, so using 250 means firing 250
				-- times. The old third argument was invented here and ignored by the
				-- server, while the loop assumed a call had consumed up to ten - so it
				-- fired a tenth of the requests needed and then gave up.
				activeStates.BGSI_Lite_FireGameRemote("UsePotion", potionItem.Name, potionItem.Level)
				local previousAmount = currentAmount
				local replicationDeadline = tick() + 0.75
				repeat
					task.wait(0.05)
					playerData = profileStore:IsReady() and profileStore:Get() or nil
					local updatedOk, updatedAmount =
						pcall(itemUtil.GetOwnedAmount, itemUtil, playerData, potionItem)
					if updatedOk then
						currentAmount = math.max(0, math.floor(tonumber(updatedAmount) or previousAmount))
					end
				until
					not isCurrentRun()
					or currentAmount < previousAmount
					or tick() >= replicationDeadline
				if currentAmount < previousAmount then
					stalledAttempts = 0
					task.wait(0.05)
				else
					stalledAttempts = stalledAttempts + 1
					task.wait(0.12)
				end
			end
			return amountBefore - currentAmount
		end)
		activeStates.BGSI_Lite_PotionUseActive = false
		if not useOk then
			return 0, tostring(usedAmount)
		end
		return math.max(0, tonumber(usedAmount) or 0)
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
