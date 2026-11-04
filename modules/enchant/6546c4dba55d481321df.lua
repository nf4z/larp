-- Generated from larplite.lua; rebuild with tools/build_modules.py.
return {
function(...)
scriptStateTJ = scriptStateOG:AddTab({
	Title = "Enchant",
	Icon = "wand-sparkles",
})
end,
function(...)
do
	-- Auto enchant UI: builds the enchant dropdowns from the game enchant data.
	local function getEnchantNames()
		local scriptStateDL = {}
		if type(enchantData) == "table" then
			for scriptStateME in pairs(enchantData) do
				if type(scriptStateME) == "string" and not scriptStateME:lower():find("^super%-") then
					table.insert(scriptStateDL, scriptStateME)
				end
			end
			table.sort(scriptStateDL)
		end
		if #scriptStateDL == 0 then
			scriptStateDL = {
				"secret-hunter",
				"ultra-roller",
			}
		end
		return scriptStateDL
	end
	local enchantNameList = getEnchantNames()
	local targetEnchantDropdownValues = {
		"(None - single target)",
	}
	for loopSlotDC, scriptStateG in ipairs(enchantNameList) do
		table.insert(targetEnchantDropdownValues, scriptStateG)
	end
	-- Published so the dashboard renders the same choices this dropdown offers,
	-- rather than keeping a second copy of the list that drifts when this one changes.
	local enchantCurrencyOptions = {
		"Auto (Secret = Crystals,Normal = Gems)",
		"Auto (Secret = Crystals,Normal = Reroll Orbs)",
		"Gems",
		"Reroll Orbs",
	}
	scriptStateTJ:AddSection("Auto Enchant Equipped Pets")
	scriptStateTJ:AddToggle("AutoEnchant", {
		Title = "Auto Enchant",
		Default = Config.autoEnchant,
		Callback = function(scriptStateADD)
			Config.autoEnchant = scriptStateADD
			activeStates.BGSI_Lite_AutoEnchantBlockedUntil = 0
			activeStates.BGSI_Lite_LastAutoEnchantTeamAttempt = 0
			saveConfig()
		end,
	})
	scriptStateTJ:AddDropdown("TargetEnchant1", {
		Title = "Target Enchant 1",
		Values = enchantNameList,
		Default = Config.equippedTargetEnchant,
		Multi = false,
		Callback = function(scriptStateXJ)
			if scriptStateXJ then
				Config.equippedTargetEnchant = scriptStateXJ
				saveConfig()
			end
		end,
	})
	scriptStateTJ:AddDropdown("TargetEnchant2", {
		Title = "Target Enchant 2",
		Values = targetEnchantDropdownValues,
		Default = (Config.equippedTargetEnchant2 ~= "" and Config.equippedTargetEnchant2) or "(None - single target)",
		Multi = false,
		Callback = function(scriptStateHT)
			if scriptStateHT then
				Config.equippedTargetEnchant2 = (scriptStateHT == "(None - single target)") and "" or scriptStateHT
				saveConfig()
			end
		end,
	})
	scriptStateTJ:AddInput("TargetEnchantLevel", {
		Title = "Target Level (0  =  any)",
		Default = tostring(Config.equippedTargetEnchantLevel or 0),
		Numeric = true,
		Callback = function(scriptStateRT)
			local scriptStateABH = tonumber(scriptStateRT)
			Config.equippedTargetEnchantLevel = (scriptStateABH and scriptStateABH >= 0) and scriptStateABH or 0
			saveConfig()
		end,
	})
	scriptStateTJ:AddInput("ReenchantThreshold", {
		Title = "Re-enchant Below Level (0 = off)",
		Description = "A pet that already has both targets but at this level or lower gets fully re-rolled on both slots again, instead of being left alone - useful for picking up a level increase on a pet enchanted a while ago.",
		Default = tostring(Config.equippedReenchantThreshold or 0),
		Numeric = true,
		Callback = function(value)
			local parsedValue = tonumber(value)
			Config.equippedReenchantThreshold = (parsedValue and parsedValue >= 0) and parsedValue or 0
			saveConfig()
		end,
	})
	activeStates.BGSI_Lite_EnchantCurrencyOptions = enchantCurrencyOptions
	scriptStateTJ:AddDropdown("EnchantCurrency", {
		Title = "Currency",
		Values = enchantCurrencyOptions,
		Default = Config.equippedEnchantCurrency,
		Multi = false,
		Callback = function(scriptStateDV)
			if scriptStateDV then
				Config.equippedEnchantCurrency = scriptStateDV
				saveConfig()
			end
		end,
	})
end
end,
function(...)
do
	scriptStateTJ:AddSection("Auto Setup Team")
	scriptStateTJ:AddToggle("AutoSetupTeamKeepUpdated", {
		Title = "Auto Setup Team",
		Description = 'Keeps the equipped Hatch team updated as pets are hatched. Fills up to three Super Legendary priority slots, then uses shiny Celestial and Secret pets. Blocked while Safe Mode is on.',
		Default = Config.autoSetupTeamEnabled,
		Callback = function(isEnabled)
			Config.autoSetupTeamEnabled = isEnabled == true
			saveConfig()
			if Config.autoSetupTeamEnabled and Config.safeMode ~= true then
				activeStates.BGSI_Lite_RequestAutoSetupTeamRefresh()
			end
		end,
	})
	scriptStateTJ:AddToggle("AutoSetupTeamIncludeSupers", {
		Title = "Also Equip Super Legendaries",
		Description = "Reserves up to 3 team slots for Super Legendaries matching the enchant counts below.",
		Default = Config.autoSetupTeamIncludeSupers,
		Callback = function(isEnabled)
			Config.autoSetupTeamIncludeSupers = isEnabled == true
			saveConfig()
			if Config.autoSetupTeamEnabled and Config.safeMode ~= true then
				activeStates.BGSI_Lite_RequestAutoSetupTeamRefresh()
			end
		end,
	})
	scriptStateTJ:AddToggle("AutoSetupTeamAABlessingSupers", {
		Title = "4x Egg: Hatch Blessing Supers",
		Description = "While auto-hatching the 4x AA egg, equip up to three Hatch Blessing+ supers, then Hatch Blessing. If none are owned, use Luck Boost+ then Luck Boost. Overrides the Super count sliders only while at that egg.",
		Default = Config.autoSetupTeamAABlessingSupers,
		Callback = function(isEnabled)
			Config.autoSetupTeamAABlessingSupers = isEnabled == true
			saveConfig()
			if Config.autoSetupTeamEnabled and Config.safeMode ~= true then
				activeStates.BGSI_Lite_RequestAutoSetupTeamRefresh()
			end
		end,
	})
	scriptStateTJ:AddButton({
		Title = "Force Update",
		Description = "Immediately rebuilds and equips the current Auto Setup Team configuration, including the selected Super Legendary combination.",
		Callback = function()
			task.spawn(function()
				if Config.safeMode == true then
					Interface:Notify({
						Title = "Auto Setup Team",
						Content = "Force Update is blocked while Safe Mode is enabled.",
						Duration = 5,
					})
					return
				end
				if not isEquippedTeamNamedHatch() then
					Interface:Notify({
						Title = "Auto Setup Team",
						Content = 'Only the team named "Hatch" is ever touched - switch to it in-game first.',
						Duration = 6,
					})
					return
				end
				local ok, found = pcall(activeStates.BGSI_Lite_RunAutoSetupTeam)
				if not ok then
					Interface:Notify({
						Title = "Auto Setup Team",
						Content = "Force Update failed: " .. tostring(found),
						Duration = 6,
					})
				elseif found then
					Interface:Notify({
						Title = "Auto Setup Team",
						Content = "Hatch team is up to date.",
						Duration = 4,
					})
				else
					Interface:Notify({
						Title = "Auto Setup Team",
						Content = "No eligible pets were found for the current configuration.",
						Duration = 5,
					})
				end
			end)
		end,
	})
	-- All 8 Super Legendary pairs the game has (see SUPER_LEGENDARY_ENCHANT_KEY_BY_ID
	-- above for where these are confirmed from).
	local superEnchantCountSpecs = {
		{ key = "luck-boost", title = "Luck Boost Count" },
		{ key = "luck-boost-plus", title = "Luck Boost+ Count" },
		{ key = "hatch-blessing", title = "Hatch Blessing Count" },
		{ key = "hatch-blessing-plus", title = "Hatch Blessing+ Count" },
		{ key = "bubble-machine", title = "Bubble Machine Count" },
		{ key = "bubble-machine-plus", title = "Bubble Machine+ Count" },
		{ key = "burst-blessing", title = "Burst Blessing Count" },
		{ key = "burst-blessing-plus", title = "Burst Blessing+ Count" },
		{ key = "shiny-blessing", title = "Shiny Blessing Count" },
		{ key = "shiny-blessing-plus", title = "Shiny Blessing+ Count" },
		{ key = "mythic-blessing", title = "Mythic Blessing Count" },
		{ key = "mythic-blessing-plus", title = "Mythic Blessing+ Count" },
		{ key = "infinity-blessing", title = "Infinity Blessing Count" },
		{ key = "infinity-blessing-plus", title = "Infinity Blessing+ Count" },
		{ key = "duplication", title = "Duplication Count" },
		{ key = "duplication-plus", title = "Duplication+ Count" },
	}
	Config.autoSetupTeamSuperCounts = type(Config.autoSetupTeamSuperCounts) == "table"
			and Config.autoSetupTeamSuperCounts
		or {}
	for _, spec in ipairs(superEnchantCountSpecs) do
		scriptStateTJ:AddSlider("AutoSetupTeamSuperCount_" .. spec.key, {
			Title = spec.title,
			Description = "e.g. 2 Luck Boost + 1 Hatch Blessing = 3 Super Legendaries total.",
			Min = 0,
			Max = 3,
			Default = math.clamp(math.floor(tonumber(Config.autoSetupTeamSuperCounts[spec.key]) or 0), 0, 3),
			Rounding = 0,
			Callback = function(value)
				local newCount = math.clamp(math.floor(tonumber(value) or 0), 0, 3)
				Config.autoSetupTeamSuperCounts[spec.key] = newCount
				-- Persist the complete nested Super Legendary configuration immediately.
				-- The next apply reads Config directly, so it cannot keep using the old
				-- slider value cached by the UI.
				saveConfig()
				if Config.autoSetupTeamEnabled and Config.safeMode ~= true then
					activeStates.BGSI_Lite_RequestAutoSetupTeamRefresh()
				end
			end,
		})
	end
end
end
}
