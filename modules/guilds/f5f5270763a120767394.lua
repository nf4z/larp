-- Generated from larplite.lua; rebuild with tools/build_modules.py.
return {
function(...)
activeStates.BGSI_Lite_GuildTab = scriptStateOG:AddTab({
	Title = "Guilds",
	Icon = "shield",
})
end,
function(...)
activeStates.BGSI_Lite_InstallGuildFeatures = function()
	local guildTab = activeStates.BGSI_Lite_GuildTab
	if not guildTab then
		return
	end
	local guildUtilOk, GuildUtil = pcall(require, ReplicatedStorage.Shared.Utils.Stats.GuildUtil)
	if not guildUtilOk or type(GuildUtil) ~= "table" then
		GuildUtil = nil
	end

	local function formatShort(value)
		value = tonumber(value) or 0
		local suffixes = { "", "K", "M", "B", "T", "Qd", "Qn" }
		local index = 1
		while math.abs(value) >= 1000 and index < #suffixes do
			value = value / 1000
			index += 1
		end
		if index == 1 then
			return tostring(math.floor(value))
		end
		return (string.format("%.1f%s", value, suffixes[index]):gsub("%.0(%a)", "%1"))
	end

	-- Snapshot cache: refreshed by invoke at most every few seconds, plus whatever the
	-- server pushes through the GuildSnapshot event in between.
	local snapshot, snapshotAt, snapshotRefreshing = nil, 0, false
	local function acceptGuildSnapshot(data)
		if type(data) == "table" then
			snapshot = data
			snapshotAt = tick()
		end
	end
	pcall(function()
		if carnivalRemoteModule and type(carnivalRemoteModule.Event) == "function" then
			carnivalRemoteModule.Event("GuildSnapshot"):Connect(acceptGuildSnapshot)
		end
	end)
	local function refreshGuildSnapshot(maxAge)
		if snapshot and tick() - snapshotAt < (tonumber(maxAge) or 4) then
			return snapshot
		end
		if snapshotRefreshing then
			return snapshot
		end
		snapshotRefreshing = true
		local ok, data = pcall(function()
			return remoteFunction:InvokeServer("GetGuildSnapshot")
		end)
		snapshotRefreshing = false
		if ok then
			acceptGuildSnapshot(data)
		end
		return snapshot
	end
	activeStates.BGSI_Lite_GetGuildSnapshot = refreshGuildSnapshot

	local function isInGuild(data)
		return type(data) == "table" and type(data.Guild) == "table" and data.Guild.Id ~= nil
	end

	local function getSeason(data)
		if type(data) == "table" and type(data.Season) == "table" and tonumber(data.Season.Number) then
			return data.Season
		end
		if GuildUtil then
			local ok, season = pcall(function()
				return GuildUtil:GetSeason()
			end)
			if ok and type(season) == "table" then
				return season
			end
		end
		return nil
	end

	local function getCurrentWeekQuests(data)
		local season = getSeason(data)
		if not GuildUtil or not season then
			return {}
		end
		local ok, weeks = pcall(function()
			return GuildUtil:GetWeeks(season.Number)
		end)
		if not ok or type(weeks) ~= "table" or type(weeks[season.Week]) ~= "table" then
			return {}
		end
		return weeks[season.Week]
	end

	local function getQuestProgress(data, quest)
		local questProgress = type(data) == "table" and type(data.QuestProgress) == "table" and data.QuestProgress
			or {}
		return tonumber(questProgress[quest.Id]) or 0
	end

	local function getCompletedTier(quest, progress)
		local completed = 0
		for tierIndex, tierGoal in ipairs(type(quest.Tiers) == "table" and quest.Tiers or {}) do
			if progress < tierGoal then
				break
			end
			completed = tierIndex
		end
		return completed
	end

	local function getNextTierTarget(quest, progress)
		for _, tierGoal in ipairs(type(quest.Tiers) == "table" and quest.Tiers or {}) do
			if progress < tierGoal then
				return tierGoal
			end
		end
		return nil
	end

	-- Quest task types the script can actually push forward. Playtime ticks up on its
	-- own; chests, potions, fishing and minigames are left to the player.
	local function getGuildTaskKind(questTask)
		local taskType = string.lower(tostring(type(questTask) == "table" and questTask.Type or ""))
		if taskType == "bubbles" then
			return "bubbles"
		elseif taskType == "hatch" then
			return "hatch"
		elseif taskType == "sell" then
			return "sell"
		elseif taskType == "playtime" then
			return "passive"
		end
		return nil
	end

	local taskLabels = {
		Bubbles = "Blow Bubbles",
		Hatch = "Hatch Eggs",
		Sell = "Sell Bubbles",
		OpenChest = "Open Chests",
		UsePotion = "Use Potions",
		Playtime = "Playtime",
		CatchFish = "Catch Fish",
	}
	local function getTaskLabel(questTask)
		if type(questTask) ~= "table" then
			return "Quest"
		end
		if questTask.Type == "CompleteMinigame" then
			return "Minigame: " .. tostring(questTask.Minigame or "?")
		end
		return taskLabels[questTask.Type] or tostring(questTask.Type or "Quest")
	end

	-- Shapes a guild quest like any other bounty (Id / Tasks / Progress) so the shared
	-- quest handlers - bubble, hatch, stall detection, active-quest display - just work.
	-- The task's Amount is the NEXT tier, so each tier finishes and the loop re-picks.
	local function buildGuildQuestView(questId)
		local data = refreshGuildSnapshot(4)
		if not isInGuild(data) then
			return nil
		end
		for _, quest in ipairs(getCurrentWeekQuests(data)) do
			if quest.Id == questId then
				local progress = getQuestProgress(data, quest)
				local questTask = table.clone(type(quest.Task) == "table" and quest.Task or {})
				questTask.Amount = getNextTierTarget(quest, progress) or progress
				return { Id = "guild-" .. quest.Id, Tasks = { questTask }, Progress = { progress } }
			end
		end
		return nil
	end

	local function otherQuestAutomationActive()
		return activeStates.BGSI_Lite_GemGenieActive
			or activeStates.BGSI_Lite_SeasonActive
			or activeStates.BGSI_Lite_GlobalIncentiveActive
			or activeStates.BGSI_Lite_ChallengePassActive
			or activeStates.BGSI_Lite_ObbyActive
			or activeStates.BGSI_Lite_ObbyChestActive
	end

	local function shouldContinueGuildQuests()
		return isCurrentRun()
			and Config.autoGuildQuests == true
			and Config.safeMode ~= true
			and not otherQuestAutomationActive()
	end

	-- "Sell" quests count sell actions, not coins, so alternate one blow with one sell.
	local function runGuildSellTask(getQuest, shouldContinue)
		local progressWatch
		local activeQuestData
		while shouldContinue() do
			activeStates.BGSI_Lite_LastQuestAutomationAt = tick()
			local questData = getQuest()
			if not questData then
				break
			end
			activeQuestData = questData
			local requirement = tonumber(questData.Tasks[1].Amount) or 0
			local progress = tonumber(questData.Progress[1]) or 0
			local stalled
			progressWatch, stalled = activeStates.BGSI_Lite_RecordQuestProgress(progressWatch, questData, 1, progress)
			if stalled or progress >= requirement then
				break
			end
			local bubbleState = activeStates.BGSI_Lite_GetBubbleState()
			if bubbleState and bubbleState.Amount > 0 then
				activeStates.BGSI_Lite_SellBubble()
			else
				activeStates.BGSI_Lite_BlowBubble()
			end
			task.wait(0.35)
		end
		activeStates.BGSI_Lite_ClearActiveQuest(activeQuestData, 1)
	end

	local function stopGuildQuestWork()
		if activeStates.BGSI_Lite_GuildQuestActive then
			activeStates.BGSI_Lite_GuildQuestActive = false
			if not isPriorityAutomationActive() then
				resumeNormalAutomation()
			end
		end
	end

	-- Auto Guild Quests. Lowest priority of the quest systems: yields to Gem Genie,
	-- Season Pass, Challenge Pass, Global Incentive and Obby whenever they're running.
	task.spawn(function()
		while isCurrentRun() do
			task.wait(1)
			if Config.autoGuildQuests ~= true or Config.safeMode == true or otherQuestAutomationActive() then
				stopGuildQuestWork()
				continue
			end
			local data = refreshGuildSnapshot(4)
			local pendingWork = {}
			if isInGuild(data) then
				for _, quest in ipairs(getCurrentWeekQuests(data)) do
					local kind = getGuildTaskKind(quest.Task)
					if kind and kind ~= "passive" and getNextTierTarget(quest, getQuestProgress(data, quest)) then
						local questView = buildGuildQuestView(quest.Id)
						if
							questView
							and not activeStates.BGSI_Lite_IsQuestTaskDeferred(questView, 1)
							and not (kind == "bubbles" and activeStates.BGSI_Lite_ShouldSkipBubblingQuest(questView.Tasks[1]))
						then
							table.insert(pendingWork, { id = quest.Id, kind = kind })
						end
					end
				end
			end
			if #pendingWork == 0 then
				stopGuildQuestWork()
				task.wait(2)
				continue
			end
			activeStates.BGSI_Lite_GuildQuestActive = true
			activeStates.BGSI_Lite_LastQuestAutomationAt = tick()
			pauseNormalAutomation()
			for _, work in ipairs(pendingWork) do
				if not shouldContinueGuildQuests() then
					break
				end
				local getQuest = function()
					return buildGuildQuestView(work.id)
				end
				if work.kind == "sell" then
					pcall(runGuildSellTask, getQuest, shouldContinueGuildQuests)
				else
					local questView = getQuest()
					if questView then
						pcall(
							activeStates.BGSI_Lite_RunQuestTask,
							getQuest,
							1,
							questView.Tasks[1].Amount,
							shouldContinueGuildQuests
						)
					end
				end
			end
		end
	end)

	-- Reward tracks: exactly the game's own claimable test (countClaimableRewards) -
	-- Guild rewards against the guild's season points, Global rewards against global
	-- points, skipping anything already in Claims["Track:index"].
	local function getClaimableGuildRewards(data)
		local claimable = {}
		local season = getSeason(data)
		if not GuildUtil or not season or not isInGuild(data) then
			return claimable
		end
		local claims = type(data.Claims) == "table" and data.Claims or {}
		local points = {
			Guild = tonumber(type(data.Guild.Season) == "table" and data.Guild.Season.Points) or 0,
			Global = tonumber(data.GlobalPoints) or 0,
		}
		for _, track in ipairs({ "Guild", "Global" }) do
			local ok, rewards = pcall(function()
				return GuildUtil:GetRewards(track, season.Number)
			end)
			if ok and type(rewards) == "table" then
				for rewardIndex, reward in pairs(rewards) do
					local requirement = type(reward) == "table" and tonumber(reward.Requirement)
					if
						requirement
						and requirement <= points[track]
						and claims[track .. ":" .. tostring(rewardIndex)] ~= true
					then
						table.insert(claimable, { track = track, index = rewardIndex })
					end
				end
			end
		end
		table.sort(claimable, function(left, right)
			if left.track ~= right.track then
				return left.track == "Guild"
			end
			return left.index < right.index
		end)
		return claimable
	end

	local recentlyClaimed = {}
	task.spawn(function()
		while isCurrentRun() do
			task.wait(5)
			if Config.autoClaimGuildRewards == true and Config.safeMode ~= true then
				local claimedAny = false
				for _, reward in ipairs(getClaimableGuildRewards(refreshGuildSnapshot(5))) do
					local claimKey = reward.track .. ":" .. tostring(reward.index)
					if tick() - (recentlyClaimed[claimKey] or 0) >= 15 then
						recentlyClaimed[claimKey] = tick()
						pcall(activeStates.BGSI_Lite_FireGameRemote, "GuildClaimReward", reward.track, reward.index)
						claimedAny = true
						-- Data.Guilds.ActionCooldown is 0.75s between guild actions.
						task.wait(0.8)
					end
				end
				if claimedAny then
					snapshotAt = 0
				end
			end
		end
	end)

	task.spawn(function()
		while isCurrentRun() do
			task.wait(3)
			if Config.autoAcceptGuildInvites == true and Config.safeMode ~= true then
				local data = refreshGuildSnapshot(3)
				if type(data) == "table" and not isInGuild(data) and type(data.Invitations) == "table" then
					for _, invite in ipairs(data.Invitations) do
						if
							type(invite) == "table"
							and invite.GuildId ~= nil
							and (tonumber(invite.ExpiresAt) or 0) > getCurrentTimestamp()
						then
							pcall(activeStates.BGSI_Lite_FireGameRemote, "GuildAcceptInvite", invite.GuildId)
							snapshotAt = 0
							task.wait(1)
							break
						end
					end
				end
			end
		end
	end)

	local function buildGuildStatusText()
		local data = snapshot
		if type(data) ~= "table" then
			return "Loading guild data..."
		end
		if data.Unlocked ~= true and LocalPlayer:GetAttribute("GuildUnlocked") ~= true then
			return "Guilds aren't unlocked yet - blow 1,000,000 bubbles to unlock them."
		end
		local lines = {}
		if not isInGuild(data) then
			table.insert(lines, "Not in a guild.")
			local openInvites = 0
			for _, invite in ipairs(type(data.Invitations) == "table" and data.Invitations or {}) do
				if type(invite) == "table" and (tonumber(invite.ExpiresAt) or 0) > getCurrentTimestamp() then
					openInvites += 1
				end
			end
			table.insert(lines, "Pending invites: " .. tostring(openInvites))
			return table.concat(lines, "\n")
		end
		local guild = data.Guild
		local memberCount = 0
		for _ in pairs(type(guild.Members) == "table" and guild.Members or {}) do
			memberCount += 1
		end
		table.insert(
			lines,
			string.format("%s  -  Level %s  -  %d/10 members", tostring(guild.Name or "Guild"), tostring(guild.Level or 1), memberCount)
		)
		local season = getSeason(data)
		if season then
			table.insert(lines, string.format("Season %s, Week %s", tostring(season.Number), tostring(season.Week)))
		end
		table.insert(
			lines,
			string.format(
				"Guild points %s  -  Global points %s  -  %d reward(s) ready",
				formatShort(type(guild.Season) == "table" and guild.Season.Points or 0),
				formatShort(data.GlobalPoints),
				#getClaimableGuildRewards(data)
			)
		)
		for _, quest in ipairs(getCurrentWeekQuests(data)) do
			local progress = getQuestProgress(data, quest)
			local tiers = type(quest.Tiers) == "table" and quest.Tiers or {}
			local nextTarget = getNextTierTarget(quest, progress)
			local kind = getGuildTaskKind(quest.Task)
			table.insert(
				lines,
				string.format(
					"- %s: %s / %s  (tier %d/%d)%s",
					getTaskLabel(quest.Task),
					formatShort(progress),
					formatShort(nextTarget or tiers[#tiers] or 0),
					getCompletedTier(quest, progress),
					#tiers,
					(kind == nil and nextTarget) and "  [manual]" or ""
				)
			)
		end
		return table.concat(lines, "\n")
	end

	guildTab:AddSection("Guild Status")
	local statusParagraph = guildTab:AddParagraph({
		Title = "Your Guild",
		Content = "Loading guild data...",
	})
	local function updateGuildStatus()
		pcall(function()
			statusParagraph:SetDesc(buildGuildStatusText())
		end)
	end
	guildTab:AddButton({
		Title = "Refresh",
		Description = "Pulls the latest guild data from the server.",
		Callback = function()
			task.spawn(function()
				snapshotAt = 0
				refreshGuildSnapshot(0)
				updateGuildStatus()
			end)
		end,
	})
	task.spawn(function()
		while isCurrentRun() do
			local anyGuildAutomation = Config.autoGuildQuests == true
				or Config.autoClaimGuildRewards == true
				or Config.autoAcceptGuildInvites == true
			if Config.safeMode ~= true then
				refreshGuildSnapshot(anyGuildAutomation and 5 or 15)
			end
			updateGuildStatus()
			task.wait(3)
		end
	end)

	guildTab:AddSection("Automation")
	guildTab:AddToggle("AutoGuildQuests", {
		Title = "Auto Guild Quests",
		Description = "Works this week's Blow Bubbles, Hatch Eggs and Sell Bubbles quests tier by tier (hatching uses your selected egg). Chest, potion, fishing and minigame quests are marked [manual]. Waits while Gem Genie, Season Pass, Challenge Pass, Global Incentive or Obby automation is running.",
		Default = Config.autoGuildQuests,
		Callback = function(isEnabled)
			Config.autoGuildQuests = isEnabled == true
			activeStates.BGSI_Lite_LastQuestAutomationAt = tick()
			if not Config.autoGuildQuests then
				stopGuildQuestWork()
			end
			saveConfig()
		end,
	})
	guildTab:AddToggle("AutoClaimGuildRewards", {
		Title = "Auto Claim Guild Rewards",
		Description = "Claims every unlocked reward on both the Guild and Global prize tracks.",
		Default = Config.autoClaimGuildRewards,
		Callback = function(isEnabled)
			Config.autoClaimGuildRewards = isEnabled == true
			saveConfig()
		end,
	})
	guildTab:AddToggle("AutoAcceptGuildInvites", {
		Title = "Auto Accept Guild Invites",
		Description = "Only while you're not in a guild - joins the first guild that invites you.",
		Default = Config.autoAcceptGuildInvites,
		Callback = function(isEnabled)
			Config.autoAcceptGuildInvites = isEnabled == true
			saveConfig()
		end,
	})

	guildTab:AddSection("Guild Items")
	guildTab:AddText({
		Title = "Guild Mystery Box & Season 1 Guild Egg",
		Content = "These are normal inventory items, so they already show up in the Mystery Box opener and the Inventory Eggs hatcher - pick them there.",
	})
end
end
}
