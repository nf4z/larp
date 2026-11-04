-- Generated from larplite.lua; rebuild with tools/build_modules.py.
return {
function(...)
scriptStateUC = scriptStateOG:AddTab({
	Title = "Quests",
	Icon = "scroll",
})
end,
function(...)
do
	scriptStateUC:AddSection("Gem Genie")
	local function getSelectedEnchantTarget()
		local scriptStateUV, scriptStateOF = {}, {}
		local function isPetAllowedForEnchanting(scriptStatePP)
			if type(scriptStatePP) ~= "string" or scriptStatePP == "" or scriptStateOF[scriptStatePP] then
				return
			end
			scriptStateOF[scriptStatePP] = true
			table.insert(scriptStateUV, scriptStatePP)
		end
		for loopSlotE, scriptStateADO in ipairs({
			"Spin Ticket",
			"Reroll Orb",
			"Power Orb",
			"Lucky",
			"Speed",
			"Coins",
			"Mythic",
			"Royal Key",
			"Dream Shard",
			"Infinity Elixir",
			"Secret Elixir",
			"Egg Elixir",
			"Ultra Infinity Elixir",
			"Wonderland Elixir",
			"Rune Rock",
			"Green Fragment",
			"Shadow Crystal",
			"Mystery Box",
		}) do
			isPetAllowedForEnchanting(scriptStateADO)
		end
		local loopSlotAC, scriptStateACZ = pcall(function()
			return require(ReplicatedStorage.Shared.Data.Quests.GenieQuest)
		end)
		if loopSlotAC and type(scriptStateACZ) == "function" then
			local scriptStateTE, scriptStateJC = pcall(function()
				return profileStore:Get()
			end)
			if scriptStateTE and type(scriptStateJC) == "table" then
				for loopSlotB = 1, 1500 do
					local scriptStateRW, scriptStateAEJ = pcall(scriptStateACZ, scriptStateJC, loopSlotB)
					if
						scriptStateRW
						and type(scriptStateAEJ) == "table"
						and type(scriptStateAEJ.Rewards) == "table"
					then
						for loopSlotBL, scriptStateBF in ipairs(scriptStateAEJ.Rewards) do
							if type(scriptStateBF) == "table" then
								isPetAllowedForEnchanting(
									scriptStateBF.Name or scriptStateBF.Currency or scriptStateBF.Item
								)
							end
						end
					end
				end
			end
		end
		table.sort(scriptStateUV)
		return scriptStateUV
	end
	local scriptStateLF = getSelectedEnchantTarget()
	if not table.find(scriptStateLF, Config.gemGenieTargetItem) then
		Config.gemGenieTargetItem = scriptStateLF[1] or "Shadow Crystal"
		saveConfig()
	end
	scriptStateUC:AddDropdown("GemGenieTarget", {
		Title = "Target Item",
		Values = scriptStateLF,
		Default = Config.gemGenieTargetItem,
		Multi = false,
		Search = true,
		Callback = function(scriptStateP)
			Config.gemGenieTargetItem = scriptStateP
			saveConfig()
		end,
	})
	scriptStateUC:AddToggle("AutoGemGenie", {
		Title = "Auto Gem Genie",
		Default = Config.autoGemGenie,
		Callback = function(scriptStatePC)
			Config.autoGemGenie = scriptStatePC
			activeStates.BGSI_Lite_LastQuestAutomationAt = tick()
			if scriptStatePC then
				activeStates.BGSI_Lite_GemGenieActive = true
				pauseNormalAutomation()
			else
				activeStates.BGSI_Lite_GemGenieActive = false
				resumeNormalAutomation()
			end
			saveConfig()
		end,
	})
	scriptStateUC:AddToggle("OptimisedGemGenie", {
		Title = "Optimised mode (only hatch tasks,ignores selected item)",
		Default = Config.optimisedGemGenie,
		Callback = function(scriptStateACK)
			Config.optimisedGemGenie = scriptStateACK
			saveConfig()
		end,
	})
	scriptStateUC:AddSection("Season Pass")
	scriptStateUC:AddToggle("AutoSeason", {
		Title = "Auto Claim Season Pass",
		Default = Config.autoSeason,
		Callback = function(scriptStateJF)
			Config.autoSeason = scriptStateJF
			saveConfig()
		end,
	})
	scriptStateUC:AddToggle("AutoStartInfiniteTrack", {
		Title = "Auto Start Infinite Track",
		Description = "Requests the Season Infinite Track after the standard reward track is complete.",
		Default = Config.AutoStartInfiniteTrack,
		Callback = function(enabled)
			Config.AutoStartInfiniteTrack = enabled == true
			saveConfig()
		end,
	})
	scriptStateUC:AddSection("Challenge Pass")
	scriptStateUC:AddToggle("AutoChallengePassQuests", {
		Title = "Auto Bubble Challenge Pass",
		Default = Config.autoChallengePassQuests,
		Callback = function(isEnabled)
			Config.autoChallengePassQuests = isEnabled == true
			activeStates.BGSI_Lite_LastQuestAutomationAt = tick()
			if Config.autoChallengePassQuests then
				activeStates.BGSI_Lite_ChallengePassActive = true
				pauseNormalAutomation()
				task.spawn(function()
					teleportToCFrame(CFrame.new(78, 9, -110))
				end)
			else
				activeStates.BGSI_Lite_ChallengePassActive = false
				resumeNormalAutomation()
			end
			saveConfig()
		end,
	})
	scriptStateUC:AddToggle("AutoClaimChallengePassRewards", {
		Title = "Auto Claim Challenge Pass Rewards",
		Default = Config.autoClaimChallengePassRewards,
		Callback = function(isEnabled)
			Config.autoClaimChallengePassRewards = isEnabled == true
			saveConfig()
		end,
	})
	scriptStateUC:AddToggle("AutoResetChallengePass", {
		Title = "Auto Gem Reset Challenge Pass",
		Default = Config.autoResetChallengePass,
		Callback = function(isEnabled)
			Config.autoResetChallengePass = isEnabled == true
			saveConfig()
		end,
	})
	scriptStateUC:AddSection("Season Pass")
	scriptStateUC:AddToggle("AutoDailyHourly", {
		Title = "Auto Season Pass Quests (daily/hourly)",
		Default = Config.autoDailyHourlyChallenge,
		Callback = function(scriptStateABO)
			Config.autoDailyHourlyChallenge = scriptStateABO
			saveConfig()
		end,
	})
	scriptStateUC:AddToggle("SkipTicketPearlQuests", {
		Title = "Skip Ticket and Pearl Quests",
		Description = "Ignores Ticket and Pearl collection tasks. Gem Genie rerolls them when possible.",
		Default = Config.skipTicketPearlQuests,
		Callback = function(isEnabled)
			Config.skipTicketPearlQuests = isEnabled == true
			saveConfig()
		end,
	})
	scriptStateUC:AddToggle("SkipBubblingQuests", {
		Title = "Skip Bubbling Quests",
		Description = "Ignores Bubbling tasks. Gem Genie rerolls them when possible.",
		Default = Config.skipBubblingQuests,
		Callback = function(isEnabled)
			Config.skipBubblingQuests = isEnabled == true
			saveConfig()
		end,
	})
	scriptStateUC:AddToggle("BubbleQuestSwitchTeams", {
		Title = "Switch Teams for Bubbling Quests",
		Description = "Equip Bubbles during bubbling tasks, then return to Hatch. Turn off to keep your current team.",
		Default = Config.bubbleQuestSwitchTeams,
		Callback = function(isEnabled)
			Config.bubbleQuestSwitchTeams = isEnabled == true
			saveConfig()
		end,
	})
	scriptStateUC:AddInput("QuestStallTimeout", {
		Title = "Quest No-Progress Timeout",
		Description = "Moves to another quest task when progress has not changed for this many seconds (30-300).",
		Default = tostring(math.clamp(tonumber(Config.questStallTimeoutSeconds) or 60, 30, 300)),
		Numeric = true,
		Callback = function(timeoutText)
			Config.questStallTimeoutSeconds = math.clamp(tonumber(timeoutText) or 60, 30, 300)
			activeStates.BGSI_Lite_QuestNoProgressTimeout = Config.questStallTimeoutSeconds
			saveConfig()
		end,
	})
	-- Shadow Leviathan Quest: a separate quest system from the regular bounties, found in
	-- the game's own data (ReplicatedStorage.Shared.Data.Quests.ShadowLeviathanQuest,
	-- Constants.ShadowLeviathanQuestKey = "shadow-leviathan"). It hands out 3 candidate
	-- quests on a 1-hour cooldown (Constants.ShadowLeviathanQuestCooldown = 3600), one of
	-- which must be picked with StartLeviathanQuest(index) before it can be worked on -
	-- unlike regular bounties, which are already active and just need their tasks run.
	scriptStateUC:AddSection("Shadow Leviathan Quest")
	-- BGSI_Lite_GetShadowLeviathanQuestModule's "real" definition lives further down
	-- the file (next to the rest of the Shadow Leviathan automation), which hadn't run
	-- yet at this point during UI construction - calling it here threw "attempt to call
	-- a nil value" and aborted the whole tab-building function partway through, which is
	-- why other tabs below this one stopped loading too. Defining it here as well (the
	-- later definition just overwrites this one, harmlessly) makes it available before
	-- its first real use.
	if type(activeStates.BGSI_Lite_GetShadowLeviathanQuestModule) ~= "function" then
		activeStates.BGSI_Lite_GetShadowLeviathanQuestModule = function()
			if activeStates.BGSI_Lite_ShadowLeviathanQuestModule == nil then
				local ok, questFn = pcall(require, ReplicatedStorage.Shared.Data.Quests.ShadowLeviathanQuest)
				activeStates.BGSI_Lite_ShadowLeviathanQuestModule = (ok and questFn) or false
			end
			local questFn = activeStates.BGSI_Lite_ShadowLeviathanQuestModule
			return questFn ~= false and questFn or nil
		end
	end
	-- Same setup as Gem Genie's target picker: sample the quest generator across many
	-- seeds with the real player data and collect every distinct reward item it can
	-- produce, so the dropdown always reflects exactly what's actually obtainable instead
	-- of a guessed/hardcoded list.
	local function getShadowLeviathanTargetOptions()
		local options, seen = {}, {}
		local function addOption(rewardName)
			if type(rewardName) ~= "string" or rewardName == "" or seen[rewardName] then
				return
			end
			seen[rewardName] = true
			table.insert(options, rewardName)
		end
		local questFn = activeStates.BGSI_Lite_GetShadowLeviathanQuestModule()
		if type(questFn) == "function" then
			local dataOk, playerData = pcall(function()
				return profileStore:Get()
			end)
			if dataOk and type(playerData) == "table" then
				for seed = 1, 1500 do
					local ok, candidateQuest = pcall(questFn, playerData, seed)
					if ok and type(candidateQuest) == "table" and type(candidateQuest.Rewards) == "table" then
						for _, reward in ipairs(candidateQuest.Rewards) do
							if type(reward) == "table" then
								addOption(reward.Name or reward.Currency or reward.Item)
							end
						end
					end
				end
			end
		end
		-- The Ancient Shadow Leviathan pet is the whole point of this quest, but it's
		-- rare enough in the reward pool that random sampling can miss it entirely - add
		-- it (and the good Fragments the game's own reroll button also protects) directly
		-- instead of leaving it to chance whether a sample happened to roll one.
		addOption("Ancient Shadow Leviathan")
		addOption("Purple Fragment")
		addOption("Green Fragment")
		addOption("Blue Fragment")
		table.sort(options)
		return options
	end
	local shadowLeviathanTargetOptions = getShadowLeviathanTargetOptions()
	if not table.find(shadowLeviathanTargetOptions, Config.shadowLeviathanTargetItem) then
		Config.shadowLeviathanTargetItem = shadowLeviathanTargetOptions[1] or ""
		saveConfig()
	end
	scriptStateUC:AddDropdown("ShadowLeviathanTarget", {
		Title = "Target Item",
		Description = "Which reward to aim for when picking between the 3 available quests. Ignored in Optimised mode.",
		Values = shadowLeviathanTargetOptions,
		Default = Config.shadowLeviathanTargetItem,
		Multi = false,
		Search = true,
		Callback = function(selectedTarget)
			Config.shadowLeviathanTargetItem = selectedTarget
			saveConfig()
		end,
	})
	scriptStateUC:AddToggle("AutoShadowLeviathanQuest", {
		Title = "Auto Shadow Leviathan Quest",
		Description = "Picks a quest as soon as one becomes available and completes its tasks the same way regular bounties are handled.",
		Default = Config.autoShadowLeviathanQuest,
		Callback = function(isEnabled)
			Config.autoShadowLeviathanQuest = isEnabled == true
			saveConfig()
		end,
	})
	scriptStateUC:AddToggle("OptimisedShadowLeviathanQuest", {
		Title = "Optimised mode (only hatch tasks, ignores selected item)",
		Default = Config.optimisedShadowLeviathanQuest,
		Callback = function(isEnabled)
			Config.optimisedShadowLeviathanQuest = isEnabled == true
			saveConfig()
		end,
	})
	scriptStateUC:AddToggle("AutoRerollShadowLeviathanQuest", {
		Title = "Reroll For Best Reward",
		Description = "Spends Reroll Orbs re-rolling the 3 choices if none of them offer the Ancient Shadow Leviathan pet or a good Fragment - same items the game's own reroll button avoids rerolling away from. Skipped whenever a Target Item match is found instead.",
		Default = Config.autoRerollShadowLeviathanQuest,
		Callback = function(isEnabled)
			Config.autoRerollShadowLeviathanQuest = isEnabled == true
			saveConfig()
		end,
	})
	scriptStateUC:AddSection("Collection Teams")
	scriptStateUC:AddToggle("AutoCurrencyTeams", {
		Title = "Auto Currency Teams",
		Description = "Detects saved pet teams by name (a team named \"Tickets\", \"Gems\", \"Bubble\", \"Coins\", or \"Pearls\") and switches to the matching one for whichever of those a quest task needs. Falls back to building a team from your best-owned pets for that specific currency when no matching team exists. Overrides the manual team pickers below while on. Never switches or touches anything for hatch quests - that's Auto Setup Team's job, and only while already on the team named \"Hatch\".",
		Default = Config.autoCurrencyTeams,
		Callback = function(isEnabled)
			Config.autoCurrencyTeams = isEnabled == true
			saveConfig()
		end,
	})
	local ticketTeamDropdown
	local pearlTeamDropdown
	local ticketReturnTeamDropdown
	local pearlReturnTeamDropdown
	local ticketTeamOptionKeys, pearlTeamOptionKeys = {}, {}
	local ticketReturnTeamOptionKeys, pearlReturnTeamOptionKeys = {}, {}
	local function buildPetTeamOptions(selectedTeamKey, optionKeyStore, includeRestorePrevious)
		local scriptStateOptions = {}
		for scriptStateExistingLabel in pairs(optionKeyStore) do
			optionKeyStore[scriptStateExistingLabel] = nil
		end
		if includeRestorePrevious == true then
			optionKeyStore["(Restore previous team)"] = ""
			table.insert(scriptStateOptions, "(Restore previous team)")
		end
		local scriptStateTeamData = activeStates.BGSI_Lite_GetPetTeamState()
		local scriptStateTeams = scriptStateTeamData and scriptStateTeamData.Teams
		if type(scriptStateTeams) == "table" then
			for scriptStateTeamKey, scriptStateTeam in pairs(scriptStateTeams) do
				local scriptStateTeamName = type(scriptStateTeam) == "table"
						and (scriptStateTeam.Name or scriptStateTeam.TeamName)
					or nil
				local scriptStateLabel =
					string.format("%s [%s]", tostring(scriptStateTeamName or "Team"), tostring(scriptStateTeamKey))
				optionKeyStore[scriptStateLabel] = scriptStateTeamKey
				table.insert(scriptStateOptions, scriptStateLabel)
			end
		end
		table.sort(scriptStateOptions)
		if includeRestorePrevious == true then
			table.sort(scriptStateOptions, function(scriptStateLeftOption, scriptStateRightOption)
				if scriptStateLeftOption == "(Restore previous team)" then
					return true
				end
				if scriptStateRightOption == "(Restore previous team)" then
					return false
				end
				return string.lower(scriptStateLeftOption) < string.lower(scriptStateRightOption)
			end)
		end
		if #scriptStateOptions == 0 then
			scriptStateOptions = { "(No teams found - refresh)" }
		end
		local scriptStateDefault = scriptStateOptions[1]
		for scriptStateLabel, scriptStateTeamKey in pairs(optionKeyStore) do
			if tostring(scriptStateTeamKey) == tostring(selectedTeamKey or "") then
				scriptStateDefault = scriptStateLabel
				break
			end
		end
		return scriptStateOptions, scriptStateDefault
	end
	local ticketTeamOptions, ticketTeamDefault = buildPetTeamOptions(Config.selectedTicketTeam, ticketTeamOptionKeys)
	local pearlTeamOptions, pearlTeamDefault = buildPetTeamOptions(Config.selectedPearlTeam, pearlTeamOptionKeys)
	local ticketReturnTeamOptions, ticketReturnTeamDefault =
		buildPetTeamOptions(Config.selectedTicketReturnTeam, ticketReturnTeamOptionKeys, true)
	local pearlReturnTeamOptions, pearlReturnTeamDefault =
		buildPetTeamOptions(Config.selectedPearlReturnTeam, pearlReturnTeamOptionKeys, true)
	ticketTeamDropdown = scriptStateUC:AddDropdown("TicketPetTeam", {
		Title = "Ticket Pet Team",
		Description = "Used during ticket collection quests in Minigame Paradise.",
		Values = ticketTeamOptions,
		Default = ticketTeamDefault,
		Multi = false,
		Search = true,
		Callback = function(scriptStateSelectedTeamLabel)
			local scriptStateSelectedTeamKey = ticketTeamOptionKeys[scriptStateSelectedTeamLabel]
			if scriptStateSelectedTeamKey ~= nil then
				Config.selectedTicketTeam = tostring(scriptStateSelectedTeamKey)
				saveConfig()
			end
		end,
	})
	ticketReturnTeamDropdown = scriptStateUC:AddDropdown("TicketReturnPetTeam", {
		Title = "Ticket Return Team",
		Description = "Equipped after ticket collection finishes. Leave on restore previous to use the old behavior.",
		Values = ticketReturnTeamOptions,
		Default = ticketReturnTeamDefault,
		Multi = false,
		Search = true,
		Callback = function(scriptStateSelectedTeamLabel)
			local scriptStateSelectedTeamKey = ticketReturnTeamOptionKeys[scriptStateSelectedTeamLabel]
			if scriptStateSelectedTeamKey ~= nil then
				Config.selectedTicketReturnTeam = tostring(scriptStateSelectedTeamKey)
				saveConfig()
			end
		end,
	})
	pearlTeamDropdown = scriptStateUC:AddDropdown("PearlPetTeam", {
		Title = "Pearl Pet Team",
		Description = "Used during pearl collection quests in Seven Seas.",
		Values = pearlTeamOptions,
		Default = pearlTeamDefault,
		Multi = false,
		Search = true,
		Callback = function(scriptStateSelectedTeamLabel)
			local scriptStateSelectedTeamKey = pearlTeamOptionKeys[scriptStateSelectedTeamLabel]
			if scriptStateSelectedTeamKey ~= nil then
				Config.selectedPearlTeam = tostring(scriptStateSelectedTeamKey)
				saveConfig()
			end
		end,
	})
	pearlReturnTeamDropdown = scriptStateUC:AddDropdown("PearlReturnPetTeam", {
		Title = "Pearl Return Team",
		Description = "Equipped after pearl collection finishes. Leave on restore previous to use the old behavior.",
		Values = pearlReturnTeamOptions,
		Default = pearlReturnTeamDefault,
		Multi = false,
		Search = true,
		Callback = function(scriptStateSelectedTeamLabel)
			local scriptStateSelectedTeamKey = pearlReturnTeamOptionKeys[scriptStateSelectedTeamLabel]
			if scriptStateSelectedTeamKey ~= nil then
				Config.selectedPearlReturnTeam = tostring(scriptStateSelectedTeamKey)
				saveConfig()
			end
		end,
	})
	scriptStateUC:AddButton({
		Title = "Refresh Pet Teams",
		Callback = function()
			local scriptStateOptions, scriptStateDefault =
				buildPetTeamOptions(Config.selectedTicketTeam, ticketTeamOptionKeys)
			if ticketTeamDropdown.SetValues then
				ticketTeamDropdown:SetValues(scriptStateOptions)
			end
			if ticketTeamDropdown.SetValue then
				pcall(function()
					ticketTeamDropdown:SetValue(scriptStateDefault)
				end)
			end
			local ticketReturnOptions, ticketReturnDefault =
				buildPetTeamOptions(Config.selectedTicketReturnTeam, ticketReturnTeamOptionKeys, true)
			if ticketReturnTeamDropdown.SetValues then
				ticketReturnTeamDropdown:SetValues(ticketReturnOptions)
			end
			if ticketReturnTeamDropdown.SetValue then
				pcall(function()
					ticketReturnTeamDropdown:SetValue(ticketReturnDefault)
				end)
			end
			local pearlOptions, pearlDefault = buildPetTeamOptions(Config.selectedPearlTeam, pearlTeamOptionKeys)
			if pearlTeamDropdown.SetValues then
				pearlTeamDropdown:SetValues(pearlOptions)
			end
			if pearlTeamDropdown.SetValue then
				pcall(function()
					pearlTeamDropdown:SetValue(pearlDefault)
				end)
			end
			local pearlReturnOptions, pearlReturnDefault =
				buildPetTeamOptions(Config.selectedPearlReturnTeam, pearlReturnTeamOptionKeys, true)
			if pearlReturnTeamDropdown.SetValues then
				pearlReturnTeamDropdown:SetValues(pearlReturnOptions)
			end
			if pearlReturnTeamDropdown.SetValue then
				pcall(function()
					pearlReturnTeamDropdown:SetValue(pearlReturnDefault)
				end)
			end
		end,
	})
	scriptStateUC:AddSection("Global Incentive")
	scriptStateUC:AddToggle("AutoGlobalIncentive", {
		Title = "Auto Global Incentive Quests",
		Default = Config.autoGlobalIncentive,
		Callback = function(scriptStateOK)
			Config.autoGlobalIncentive = scriptStateOK
			saveConfig()
		end,
	})
	scriptStateUC:AddToggle("AutoClaimGlobalIncentive", {
		Title = "Auto Claim Global Incentive",
		Default = Config.autoClaimGlobalIncentive,
		Callback = function(scriptStatePU)
			Config.autoClaimGlobalIncentive = scriptStatePU
			saveConfig()
		end,
	})
end
end
}
