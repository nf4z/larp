-- Generated from larplite.lua; rebuild with tools/build_modules.py.
return {
function(...)
eggTab = scriptStateOG:AddTab({
	Title = "Eggs",
	Icon = "egg",
})
end,
function(...)
do
	local scriptStateVO = "(Click 'Load egg list' below)"
	local scriptStateRK = "(Select an egg first)"
	local scriptStateADI = "(No tracked locations)"
	local scriptStateND, locationDropdownOptions
	if type(Config.selectedEgg) == "string" and Config.selectedEgg ~= "" then
		scriptStateND = {
			Config.selectedEgg,
		}
		locationDropdownOptions = Config.selectedEgg
	else
		scriptStateND = {
			scriptStateVO,
		}
		locationDropdownOptions = scriptStateVO
	end
	local scriptStateXN, locationDropdown
	local scriptStateAFS = {}
	local function formatEggLocationOption(scriptStateLP)
		local locationPosition = scriptStateLP and scriptStateLP.position
		local posX = locationPosition and locationPosition.X or 0
		local posY = locationPosition and locationPosition.Y or 0
		local scriptStateWB = locationPosition and locationPosition.Z or 0
		return string.format("X %.1f,Y %.1f,Z %.1f", posX, posY, scriptStateWB)
	end
	local function refreshEggLocationDropdown(scriptStateDS)
		if not locationDropdown then
			return
		end
		scriptStateAFS = {}
		local scriptStateTO = Config.selectedEgg
		local scriptStateCJ, scriptStateEY = {}, scriptStateRK
		if type(scriptStateTO) ~= "string" or scriptStateTO == "" or scriptStateTO == scriptStateVO then
			scriptStateCJ = {
				scriptStateRK,
			}
		else
			local eggLocations = getEggLocationsByName(scriptStateTO, scriptStateDS == true)
			if #eggLocations == 0 then
				scriptStateCJ = {
					scriptStateADI,
				}
				scriptStateEY = scriptStateADI
			else
				local locationPriorities = type(Config.selectedEggLocationPriorities) == "table"
						and Config.selectedEggLocationPriorities
					or {}
				local scriptStateZX = locationPriorities[scriptStateTO]
				for loopSlotAZ, scriptStateUK in ipairs(eggLocations) do
					local scriptStateSQ = formatEggLocationOption(scriptStateUK)
					scriptStateAFS[scriptStateSQ] = scriptStateUK.key
					table.insert(scriptStateCJ, scriptStateSQ)
					if scriptStateUK.key == scriptStateZX then
						scriptStateEY = scriptStateSQ
					end
				end
				if scriptStateEY == scriptStateRK then
					scriptStateEY = scriptStateCJ[1]
				end
			end
		end
		if locationDropdown.SetValues then
			locationDropdown:SetValues(scriptStateCJ)
		end
		if locationDropdown.SetValue then
			pcall(function()
				locationDropdown:SetValue(scriptStateEY)
			end)
		end
	end
	local function refreshEggDropdownOptions(scriptStateMQ)
		local scriptStateTT = safeGetChildren(scriptStateMQ == true)
		if #scriptStateTT == 0 then
			Interface:Notify({
				Title = "Eggs",
				Content = "No tracked eggs found yet.",
				Duration = 4,
			})
			refreshEggLocationDropdown(scriptStateMQ)
			return
		end
		if scriptStateXN.SetValues then
			scriptStateXN:SetValues(scriptStateTT)
		end
		if
			type(Config.selectedEgg) ~= "string"
			or Config.selectedEgg == ""
			or not table.find(scriptStateTT, Config.selectedEgg)
		then
			Config.selectedEgg = scriptStateTT[1]
			saveConfig()
		end
		if scriptStateXN.SetValue then
			pcall(function()
				scriptStateXN:SetValue(Config.selectedEgg)
			end)
		end
		refreshEggLocationDropdown(scriptStateMQ)
	end
	scriptStateXN = eggTab:AddDropdown("SelectEgg", {
		Title = "Select Egg",
		Values = scriptStateND,
		Default = locationDropdownOptions,
		Multi = false,
		Search = true,
		Callback = function(selectedEggCallback)
			if selectedEggCallback and selectedEggCallback ~= scriptStateVO then
				Config.selectedEgg = selectedEggCallback
				activeStates.BGSI_Lite_ForceAutoHatchTeleport = true
				saveConfig()
				refreshEggLocationDropdown(true)
			end
		end,
	})
	locationDropdown = eggTab:AddDropdown("SelectEggLocation", {
		Title = "Prioritised Location",
		Values = {
			scriptStateRK,
		},
		Default = scriptStateRK,
		Multi = false,
		Search = true,
		Callback = function(scriptStateGM)
			local locationKeyFromDisplay = scriptStateAFS[scriptStateGM]
			local scriptStateVA = Config.selectedEgg
			if not locationKeyFromDisplay or type(scriptStateVA) ~= "string" or scriptStateVA == "" then
				return
			end
			Config.selectedEggLocationPriorities = type(Config.selectedEggLocationPriorities) == "table"
					and Config.selectedEggLocationPriorities
				or {}
			Config.selectedEggLocationPriorities[scriptStateVA] = locationKeyFromDisplay
			saveConfig()
		end,
	})
	activeStates.BGSI_Lite_RefreshEggLocationDropdown = refreshEggLocationDropdown
	eggTab:AddButton({
		Title = "Load egg list",
		Callback = function()
			refreshEggDropdownOptions(true)
		end,
	})
	eggTab:AddButton({
		Title = "Refresh egg locations",
		Callback = function()
			task.spawn(function()
				refreshEggScanNotification(false)
				refreshEggDropdownOptions(true)
			end)
		end,
	})
	task.defer(function()
		refreshEggDropdownOptions(false)
	end)
	eggTab:AddSection("Hatch")
	eggTab:AddToggle("AutoHatch", {
		Title = "Auto Hatch",
		Default = Config.autoHatch,
		Callback = function(scriptStateRG)
			Config.autoHatch = scriptStateRG == true
			if not Config.autoHatch then
				activeStates.BGSI_Lite_LastHatchRequestedEgg = nil
				activeStates.BGSI_Lite_ForceAutoHatchTeleport = false
			end
			if scriptStateRG then
				clearDisabledPriorityStates()
				activeStates.BGSI_Lite_ForceAutoHatchTeleport = true
				task.spawn(function()
					local selectedEggForTeleport = Config.selectedEgg
					if
						type(selectedEggForTeleport) == "string"
						and selectedEggForTeleport ~= ""
						and not isPriorityAutomationActive()
					then
						teleportToEggByName(selectedEggForTeleport)
					end
				end)
			end
			saveConfig()
		end,
	})
	eggTab:AddToggle("AdaptiveHatch", {
		Title = "Adaptive Hatch Timing",
		Default = Config.adaptiveHatch,
		Callback = function(isEnabled)
			Config.adaptiveHatch = isEnabled
			saveConfig()
		end,
	})
	eggTab:AddToggle("NoHatchAnim", {
		Title = "No Hatch Animation",
		Default = Config.noHatchAnim,
		Callback = function(scriptStateGQ)
			Config.noHatchAnim = scriptStateGQ
			saveConfig()
			activeStates.BGSI_Lite_ApplyHatchAnimationSetting()
		end,
	})
	eggTab:AddToggle("AutoSpamR", {
		Title = "Auto Spam R + E",
		Default = Config.autoSpamR,
		Callback = function(scriptStateFD)
			Config.autoSpamR = scriptStateFD
			saveConfig()
		end,
	})
	eggTab:AddSection("Bounty")
	eggTab:AddToggle("AutoBounty", {
		Title = "Auto Hatch Bounty Egg",
		Default = Config.autoBounty,
		Callback = function(scriptStateGH)
			Config.autoBounty = scriptStateGH == true
			if not Config.autoBounty then
				activeStates.BGSI_Lite_LastHatchRequestedEgg = nil
				activeStates.BGSI_Lite_BountyRiftActive = false
			end
			saveConfig()
		end,
	})
	eggTab:AddToggle("SpawnRift", {
		Title = "Spawn 25x Bounty Rift (1 hour)",
		Default = Config.spawnRift,
		Callback = function(scriptStateIZ)
			Config.spawnRift = scriptStateIZ == true
			activeStates.BGSI_Lite_BountyRiftReady = false
			saveConfig()
		end,
	})
	activeStates.BGSI_Lite_BountyInfoParagraph = eggTab:AddInput("CurrentBountyDisplay", {
		Title = "Current Bounty",
		Default = "Loading...",
		Callback = function()
		end,
	})
	activeStates.BGSI_Lite_BountyInfoParagraph:Lock("Read-only")
	eggTab:AddSection("Admin Abuse")
	eggTab:AddToggle("AutoLuckEgg", {
		Title = "Auto Hatch 4x Egg (AA)",
		Default = Config.autoLuckEgg,
		Callback = function(scriptStateGE)
			Config.autoLuckEgg = scriptStateGE
			saveConfig()
		end,
	})
	eggTab:AddToggle("AutoSpecialRift", {
		Title = "Auto Doodle Rift",
		Description = "Hatches doodle-rift when it appears.",
		Default = Config.autoSpecialRift,
		Callback = function(isEnabled)
			Config.autoSpecialRift = isEnabled
			if not isEnabled then
				activeStates.BGSI_Lite_SpecialRiftActive = false
			end
			saveConfig()
		end,
	})
end
end,
function(...)
do
	local function addUniqueRiftName(scriptStateBC, scriptStateFY, scriptStateOH)
		if type(scriptStateOH) == "string" and scriptStateOH ~= "" and not scriptStateFY[scriptStateOH] then
			scriptStateFY[scriptStateOH] = true
			table.insert(scriptStateBC, scriptStateOH)
		end
	end
	local function splitRiftNameAndIndex(scriptStateUO)
		local scriptStatePL, scriptStateKL = string.match(tostring(scriptStateUO or ""), "^(.-)%-(%d+)$")
		return scriptStatePL, tonumber(scriptStateKL)
	end
	local function normalizeRiftName(scriptStateWZ)
		local scriptStateKV = string.lower(tostring(scriptStateWZ or ""))
		scriptStateKV = string.gsub(scriptStateKV, "%-all$", "")
		scriptStateKV = string.gsub(scriptStateKV, "%-rift$", "")
		return scriptStateKV
	end
	local function getRiftEggOptions()
		local loopSlotCB, loopSlotAM = {}, {}
		local scriptStateLM = type(riftData) == "table" and next(riftData) ~= nil
		if type(riftData) == "table" then
			for loopSlotCU, scriptStateTH in pairs(riftData) do
				if type(scriptStateTH) == "table" and scriptStateTH.Type == "Egg" then
					addUniqueRiftName(loopSlotCB, loopSlotAM, loopSlotCU)
				end
			end
		end
		local scriptStateIX = getPotionList("Rifts")
		if scriptStateIX then
			for loopSlotAD, scriptStateZB in ipairs(scriptStateIX:GetChildren()) do
				local scriptStateNE = scriptStateLM and riftData[scriptStateZB.Name] or nil
				if not scriptStateLM or (type(scriptStateNE) == "table" and scriptStateNE.Type == "Egg") then
					addUniqueRiftName(loopSlotCB, loopSlotAM, scriptStateZB.Name)
				end
			end
		end
		local scriptStateOL = {}
		for loopSlotCC, scriptStateHK in ipairs(loopSlotCB) do
			local loopSlotDH, scriptStateTW = splitRiftNameAndIndex(scriptStateHK)
			if loopSlotDH and scriptStateTW then
				scriptStateOL[loopSlotDH] = (scriptStateOL[loopSlotDH] or 0) + 1
			end
		end
		for loopSlotAG, scriptStateQV in pairs(scriptStateOL) do
			if scriptStateQV > 1 then
				addUniqueRiftName(loopSlotCB, loopSlotAM, loopSlotAG .. "-all")
			end
		end
		table.sort(loopSlotCB)
		return loopSlotCB
	end
	local function getTargetRiftHopOptions()
		local options = {}
		if type(riftData) == "table" then
			for riftId, riftInfo in pairs(riftData) do
				if type(riftId) == "string" and type(riftInfo) == "table" and riftInfo.Type == "Egg" then
					table.insert(options, riftId)
				end
			end
		end
		table.sort(options)
		return options
	end
	activeStates.BGSI_Lite_GetTargetRiftHopOptions = getTargetRiftHopOptions
	local function getSelectedTargetRiftIds()
		local selectedSet = {}
		for riftKey, riftValue in pairs(type(Config.targetRiftIds) == "table" and Config.targetRiftIds or {}) do
			if type(riftKey) == "number" and type(riftValue) == "string" then
				selectedSet[riftValue] = true
			elseif type(riftKey) == "string" and riftValue == true then
				selectedSet[riftKey] = true
			elseif type(riftValue) == "string" then
				selectedSet[riftValue] = true
			end
		end
		local selectedRifts = {}
		for _, riftId in ipairs(getTargetRiftHopOptions()) do
			if selectedSet[riftId] then
				table.insert(selectedRifts, riftId)
			end
		end
		return selectedRifts
	end
	activeStates.BGSI_Lite_GetSelectedTargetRiftIds = getSelectedTargetRiftIds
	activeStates.BGSI_Lite_GetTargetRiftSelectionKey = function()
		return table.concat(getSelectedTargetRiftIds(), "|")
	end
	local function normalizeTargetRiftId(riftId)
		local normalizedId = string.lower(tostring(riftId or ""))
		normalizedId = string.gsub(normalizedId, "%-all$", "")
		normalizedId = string.gsub(normalizedId, "%-%d+$", "")
		return normalizedId
	end
	activeStates.BGSI_Lite_FindTargetedHopRift = function()
		if Config.autoHopTargetRifts ~= true then
			return nil
		end
		local selectedRifts = getSelectedTargetRiftIds()
		if #selectedRifts == 0 then
			return nil
		end
		local riftsFolder = getPotionList("Rifts")
		if not riftsFolder then
			return nil
		end
		for _, selectedRiftId in ipairs(selectedRifts) do
			local normalizedSelectedId = normalizeTargetRiftId(selectedRiftId)
			for _, riftObject in ipairs(riftsFolder:GetChildren()) do
				if normalizeTargetRiftId(riftObject.Name) == normalizedSelectedId then
					local riftInfoEntry = type(riftData) == "table"
						and (riftData[riftObject.Name] or riftData[normalizedSelectedId])
						or nil
					if type(riftInfoEntry) ~= "table" or riftInfoEntry.Type == "Egg" then
						return riftObject
					end
				end
			end
		end
		return nil
	end
	local function resolveAllRiftSelection(scriptStateHM)
		if type(scriptStateHM) ~= "string" or scriptStateHM == "" then
			return scriptStateHM
		end
		local baseNamePart = string.match(scriptStateHM, "^(.-)%-all$")
		if not baseNamePart then
			return scriptStateHM
		end
		local selectedRiftOption, scriptStateQS, scriptStateQP = nil, -1, normalizeRiftName(baseNamePart)
		for loopSlotDG, riftOption in ipairs(getRiftEggOptions()) do
			local loopSlotDN, riftIndexPart = splitRiftNameAndIndex(riftOption)
			if
				loopSlotDN
				and riftIndexPart
				and normalizeRiftName(loopSlotDN) == scriptStateQP
				and riftIndexPart > scriptStateQS
			then
				selectedRiftOption, scriptStateQS = riftOption, riftIndexPart
			end
		end
		return selectedRiftOption or scriptStateHM
	end
	local function getRiftEggName(scriptStateCN)
		if type(riftData) == "table" then
			local potionDataEntry = riftData[scriptStateCN]
			if
				type(potionDataEntry) == "table"
				and potionDataEntry.Type == "Egg"
				and type(potionDataEntry.Egg) == "string"
			then
				return potionDataEntry.Egg
			end
		end
		local scriptStateVF = tostring(scriptStateCN or ""):gsub("%-rift%-?%d*$", ""):gsub("-", " ")
		return scriptStateVF:gsub("(%a)([%w_']*)", function(firstLetter, scriptStateAFG)
			return firstLetter:upper() .. scriptStateAFG:lower()
		end) .. " Egg"
	end
	local function getRiftIconImage(riftDisplay)
		local displayChild = riftDisplay and riftDisplay:FindFirstChild("Display")
		local surfaceGuiChild = displayChild and displayChild:FindFirstChild("SurfaceGui")
		local scriptStateXP = surfaceGuiChild and surfaceGuiChild:FindFirstChild("Icon")
		local scriptStateDD = scriptStateXP and scriptStateXP:FindFirstChild("Luck")
		return scriptStateDD and (tonumber(tostring(scriptStateDD.Text):match("%d+")) or 0) or 0
	end
	local function findMatchingRift(riftSearchName)
		local riftsFolder = getPotionList("Rifts")
		if not riftsFolder then
			return nil
		end
		local riftDisplayName, scriptStateJG, scriptStateNQ = string.lower(riftSearchName or ""), nil, -1
		for loopSlotY, scriptStateCD in ipairs(riftsFolder:GetChildren()) do
			if string.lower(scriptStateCD.Name) == riftDisplayName then
				local riftIconLuck = getRiftIconImage(scriptStateCD)
				if riftIconLuck > scriptStateNQ then
					scriptStateJG, scriptStateNQ = scriptStateCD, riftIconLuck
				end
			end
		end
		return scriptStateJG
	end
	local function hatchSelectedRiftEgg()
		local scriptStateADM = resolveAllRiftSelection(Config.selectedRiftEgg)
		if type(scriptStateADM) ~= "string" or scriptStateADM == "" then
			return
		end
		if string.find(string.lower(scriptStateADM), "moon", 1, true) then
			pcall(function()
				remoteFunction:InvokeServer("SummonMoonRift", {
					Type = "Egg",
					Time = 5,
					Luck = 5,
				})
			end)
			return
		end
		local scriptStateFU = getRiftEggName(scriptStateADM)
		local scriptStateJY = (
			scriptStateFU == "Mining Egg"
			or scriptStateFU == "Neon Egg"
			or scriptStateFU == "Cyber Egg"
		)
				and "Minigame Paradise"
			or "The Overworld"
		pcall(function()
			remoteFunction:InvokeServer("SummonRift", {
				Type = "Egg",
				Name = scriptStateFU,
				World = scriptStateJY,
				Time = 5,
				Luck = 5,
			})
		end)
	end
	local riftEggOptions = getRiftEggOptions()
	if Config.selectedRiftEgg == "" or not table.find(riftEggOptions, Config.selectedRiftEgg) then
		Config.selectedRiftEgg = riftEggOptions[1] or ""
	end
	local scriptStateADK = 0
	eggTab:AddSection("Rift Eggs")
	local scriptStateFH = eggTab:AddDropdown("SelectRiftEgg", {
		Title = "Rift Egg",
		Values = #riftEggOptions > 0 and riftEggOptions or {
			"(No rifts found)",
		},
		Default = Config.selectedRiftEgg ~= "" and Config.selectedRiftEgg or "(No rifts found)",
		Multi = false,
		Search = true,
		Callback = function(riftEggCallback)
			if riftEggCallback and riftEggCallback ~= "(No rifts found)" then
				Config.selectedRiftEgg = riftEggCallback
				saveConfig()
			end
		end,
	})
	eggTab:AddButton({
		Title = "Refresh rift list",
		Callback = function()
			fireRemoteEventRepeatedly(scriptStateFH, getRiftEggOptions())
		end,
	})
	eggTab:AddToggle("AutoRiftEgg", {
		Title = "Auto Hatch Rift Egg",
		Default = Config.autoRiftEgg,
		Callback = function(scriptStateAAI)
			Config.autoRiftEgg = scriptStateAAI
			if not scriptStateAAI then
				activeStates.BGSI_Lite_RiftEggActive = false
			end
			saveConfig()
		end,
	})
	eggTab:AddToggle("AutoRiftEggSpawn", {
		Title = "Auto Spawn Rift Egg",
		Default = Config.autoRiftEggSpawn,
		Callback = function(scriptStateCG)
			Config.autoRiftEggSpawn = scriptStateCG
			if scriptStateCG then
				hatchSelectedRiftEgg()
				scriptStateADK = tick()
			end
			saveConfig()
		end,
	})
	task.spawn(function()
		while isCurrentRun() do
			task.wait(Config.autoRiftEggSpawn and 1 or 0.85)
			if Config.autoRiftEggSpawn then
				local scriptStateLT = tostring(Config.selectedRiftEgg or "")
				local scriptStateNP = string.find(string.lower(scriptStateLT), "moon", 1, true) and 14400 or 3600
				if tick() - scriptStateADK >= scriptStateNP then
					hatchSelectedRiftEgg()
					scriptStateADK = tick()
				end
			end
		end
	end)
	task.spawn(function()
		local riftActiveCooldown = 0
		while isCurrentRun() do
			task.wait(Config.autoRiftEgg and 0.1 or 0.85)
			if not Config.autoRiftEgg then
				activeStates.BGSI_Lite_RiftEggActive = false
				continue
			end
			local scriptStateON = resolveAllRiftSelection(Config.selectedRiftEgg)
			local scriptStateUN = scriptStateON and findMatchingRift(scriptStateON)
			activeStates.BGSI_Lite_RiftEggActive = scriptStateUN ~= nil
			if
				not scriptStateUN
				or isPriorityAutomationActive()
				or activeStates.BGSI_Lite_SpecialRiftActive
				or activeStates.BGSI_Lite_LuckEggActive
			then
				continue
			end
			if tick() - riftActiveCooldown >= 5 then
				local scriptStateCB = getPotionDisplayName(scriptStateUN)
				if scriptStateCB then
					teleportToCFrame(scriptStateCB + Vector3.new(3, 5, 0))
				end
				riftActiveCooldown = tick()
			end
			fireHatchEgg(getRiftEggName(scriptStateON))
		end
	end)
	local function findSpecialRift()
		if Config.autoSpecialRift ~= true then
			return nil
		end
		local riftsFolder = getPotionList("Rifts")
		if not riftsFolder then
			return nil
		end
		for _, riftObject in ipairs(riftsFolder:GetChildren()) do
			if string.lower(riftObject.Name) == "doodle-rift" then
				local riftInfoEntry = type(riftData) == "table" and riftData[riftObject.Name] or nil
				if type(riftInfoEntry) ~= "table" or riftInfoEntry.Type == "Egg" then
					return riftObject
				end
			end
		end
		return nil
	end
	task.spawn(function()
		local specialRiftTeleportAt = 0
		while isCurrentRun() do
			task.wait(Config.autoSpecialRift and 0.1 or 0.85)
			if Config.autoSpecialRift ~= true then
				activeStates.BGSI_Lite_SpecialRiftActive = false
				specialRiftTeleportAt = 0
				continue
			end
			if activeStates.BGSI_Lite_HasLiveFourXLuckEgg() then
				activeStates.BGSI_Lite_SpecialRiftActive = false
				specialRiftTeleportAt = 0
				continue
			end
			local specialRift = findSpecialRift()
			activeStates.BGSI_Lite_SpecialRiftActive = specialRift ~= nil
			if not specialRift then
				specialRiftTeleportAt = 0
				continue
			end
			local specialRiftEggName = getRiftEggName(specialRift.Name)
			if tick() - specialRiftTeleportAt >= 1.5 then
				teleportToEggByName(specialRiftEggName)
				specialRiftTeleportAt = tick()
			end
			fireHatchEgg(specialRiftEggName)
		end
	end)
end
do
	-- Inventory Eggs: eggs held as an owned Powerup count (Elite Egg, Superhero Egg, the
	-- Series N Eggs, Prismatic Egg, seasonal event eggs, etc.) rather than a physical world
	-- spawn - hatched directly via HatchPowerupEgg with an amount, no positioning needed.
	-- Confirmed straight from the game's own data: ReplicatedStorage.Shared.Data.Powerups
	-- (already loaded here as giftData) - every entry with Type == "Egg" is one of these,
	-- so the list below is read from that data instead of a hardcoded name list.
	local function getInventoryEggNames()
		local eggNames = {}
		if type(giftData) == "table" then
			for powerupName, powerupInfo in pairs(giftData) do
				if type(powerupName) == "string" and type(powerupInfo) == "table" and powerupInfo.Type == "Egg" then
					table.insert(eggNames, powerupName)
				end
			end
		end
		table.sort(eggNames)
		return eggNames
	end

	local inventoryEggOptions = getInventoryEggNames()
	if Config.selectedInventoryEgg == "" or not table.find(inventoryEggOptions, Config.selectedInventoryEgg) then
		Config.selectedInventoryEgg = inventoryEggOptions[1] or ""
	end

	eggTab:AddSection("Inventory Eggs")
	local inventoryEggDropdown = eggTab:AddDropdown("SelectInventoryEgg", {
		Title = "Inventory Egg",
		Description = "Eggs held as an item (Elite Egg, Superhero Egg, Series eggs, event eggs, etc.), hatched straight from your inventory instead of the world.",
		Values = #inventoryEggOptions > 0 and inventoryEggOptions or { "(None found)" },
		Default = Config.selectedInventoryEgg ~= "" and Config.selectedInventoryEgg or "(None found)",
		Multi = false,
		Search = true,
		Callback = function(selectedEggCallback)
			if selectedEggCallback and selectedEggCallback ~= "(None found)" then
				Config.selectedInventoryEgg = selectedEggCallback
				saveConfig()
			end
		end,
	})
	eggTab:AddButton({
		Title = "Refresh inventory egg list",
		Callback = function()
			fireRemoteEventRepeatedly(inventoryEggDropdown, getInventoryEggNames())
		end,
	})
	eggTab:AddToggle("AutoHatchInventoryEgg", {
		Title = "Auto Hatch Inventory Egg",
		Description = "Fires HatchPowerupEgg back to back while you own any. The 'No Hatch Animation' toggle above speeds this up further, since it's the same hatch effect that would otherwise gate each request.",
		Default = Config.autoHatchInventoryEgg,
		Callback = function(isEnabled)
			Config.autoHatchInventoryEgg = isEnabled == true
			saveConfig()
		end,
	})

	-- Inventory egg hatching. Keep the runner completely self-contained and
	-- defensive: this section must never be able to stop the rest of the script.
	local function runInventoryEggHatch()
		local selectedEggName = tostring(Config.selectedInventoryEgg or "")
		if selectedEggName == "" then
			return 0
		end

		local playerData
		local dataOk = pcall(function()
			if profileStore and type(profileStore.Get) == "function" then
				playerData = profileStore:Get()
			end
		end)
		if not dataOk or type(playerData) ~= "table" then
			return 0
		end

		local powerups = playerData.Powerups
		if type(powerups) ~= "table" then
			return 0
		end

		local totalRequested = 0
		while true do
			local continueOk, shouldContinue = pcall(function()
				return isCurrentRun()
					and Config.autoHatchInventoryEgg == true
					and Config.safeMode ~= true
					and tostring(Config.selectedInventoryEgg or "") == selectedEggName
			end)
			if not continueOk or not shouldContinue then
				break
			end

			local ownedAmount = tonumber(powerups[selectedEggName]) or 0
			ownedAmount = math.floor(ownedAmount)
			if ownedAmount <= 0 then
				break
			end

			local batchAmount = math.min(12, ownedAmount)
			local fireOk = pcall(function()
				local fire = activeStates.BGSI_Lite_FireGameRemote
				if type(fire) ~= "function" then
					error("game remote helper unavailable")
				end
				fire("HatchPowerupEgg", selectedEggName, batchAmount)
			end)
			if not fireOk then
				break
			end

			totalRequested += batchAmount
			task.wait(0.2)

			-- Do not call HatchEgg:IsHatching() here. Some game builds expose a
			-- different effect API, and this check is not required for the request
			-- itself. The game's 0.2 second Auto Exclusive Egg pacing is sufficient.
		end

		return totalRequested
	end

	activeStates.BGSI_Lite_RunInventoryEggHatch = function()
		local ok, result = pcall(runInventoryEggHatch)
		return ok and (tonumber(result) or 0) or 0
	end

	task.spawn(function()
		while true do
			local runOk, running = pcall(isCurrentRun)
			if not runOk or not running then
				break
			end

			if Config.autoHatchInventoryEgg == true and Config.safeMode ~= true then
				pcall(runInventoryEggHatch)
			end

			task.wait(Config.autoHatchInventoryEgg == true and 0.05 or 0.5)
		end
	end)
end
end
}
