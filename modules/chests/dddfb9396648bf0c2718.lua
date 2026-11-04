-- Generated from larplite.lua; rebuild with tools/build_modules.py.
return {
function(...)
potionTab = scriptStateOG:AddTab({
	Title = "Chests",
	Icon = "package",
})
end,
function(...)
do
	local function addUniqueName(nameList, scriptStateVH, scriptStateBP)
		if type(scriptStateBP) == "string" and scriptStateBP ~= "" and not scriptStateVH[scriptStateBP] then
			scriptStateVH[scriptStateBP] = true
			table.insert(nameList, scriptStateBP)
		end
	end
	local function getWorldChestNames()
		local chestList, chestSet = {}, {}
		local chestFolder = getPotionList("Chests")
		if chestFolder then
			for loopSlotCW, scriptStateLD in ipairs(chestFolder:GetChildren()) do
				addUniqueName(chestList, chestSet, scriptStateLD.Name)
			end
		end
		for chestIndex, scriptStateAU in ipairs({
			"Giant Chest",
			"Infinity Chest",
			"Ticket Chest",
			"Void Chest",
		}) do
			addUniqueName(chestList, chestSet, scriptStateAU)
		end
		table.sort(chestList)
		return chestList
	end
	local function getChestRiftNames()
		local loopSlotX, riftSet = {}, {}
		if type(riftData) == "table" then
			for riftKeyEntry, potionEntry in pairs(riftData) do
				if type(potionEntry) == "table" and potionEntry.Type == "Chest" then
					addUniqueName(loopSlotX, riftSet, riftKeyEntry)
				end
			end
		end
		local scriptStateJQ = getPotionList("Rifts")
		if scriptStateJQ then
			for loopSlotAU, scriptStateACA in ipairs(scriptStateJQ:GetChildren()) do
				local riftInfoEntry = type(riftData) == "table" and riftData[scriptStateACA.Name] or nil
				if type(riftInfoEntry) == "table" and riftInfoEntry.Type == "Chest" then
					addUniqueName(loopSlotX, riftSet, scriptStateACA.Name)
				end
			end
		end
		for loopSlotCO, defaultChestName in ipairs({
			"golden-chest",
			"royal-chest",
			"super-chest",
			"dice-rift",
			"moon-chest",
		}) do
			addUniqueName(loopSlotX, riftSet, defaultChestName)
		end
		table.sort(loopSlotX)
		return loopSlotX
	end
	local function findRenderedObjectByName(objectName, worldList)
		if type(objectName) ~= "string" or objectName == "" then
			return nil
		end
		local worldChestList = string.lower(objectName)
		for worldListIndex, filteredEggs in ipairs(worldList) do
			local filteredEggs = getPotionList(filteredEggs)
			if filteredEggs then
				for loopSlotF, renderedChild in ipairs(filteredEggs:GetChildren()) do
					if string.lower(renderedChild.Name) == worldChestList then
						return renderedChild
					end
				end
			end
		end
		return nil
	end
	local function getRiftWorldName(scriptStateRC)
		local riftWorldData = type(riftData) == "table" and riftData[scriptStateRC] or nil
		if type(riftWorldData) == "table" and type(riftWorldData.World) == "string" then
			return riftWorldData.World
		end
		return scriptStateRC == "dice-rift" and "Minigame Paradise" or "The Overworld"
	end
	local function summonMoonRiftIfNeeded(riftEggName)
		if type(riftEggName) ~= "string" or riftEggName == "" then
			return
		end
		if string.find(string.lower(riftEggName), "moon", 1, true) then
			pcall(function()
				remoteFunction:InvokeServer("SummonMoonRift", {
					Type = "Chest",
					Time = 1,
				})
			end)
			return
		end
		pcall(function()
			remoteFunction:InvokeServer("SummonRift", {
				Name = riftEggName,
				Type = "Chest",
				Time = 5,
				World = getRiftWorldName(riftEggName),
			})
		end)
	end
	local function teleportToRift(scriptStateGY)
		local scriptStateMB = findRenderedObjectByName(scriptStateGY, {
			"Rifts",
		})
		local scriptStateYX = getPotionDisplayName(scriptStateMB)
		if scriptStateYX then
			teleportToCFrame(scriptStateYX + Vector3.new(0, 3, 0))
		end
	end
	-- Chest helper: attempts to claim the named chest with the supported remotes.
	local function claimChestByName(chestName)
		if type(chestName) ~= "string" or chestName == "" then
			return false
		end
		local playerData = profileStore:IsReady() and profileStore:Get() or nil
		local cooldownEndsAt = playerData
			and type(playerData.Cooldowns) == "table"
			and tonumber(playerData.Cooldowns[chestName])
			or 0
		if cooldownEndsAt > getCurrentTimestamp() then
			return false
		end
		activeStates.BGSI_Lite_ChestClaimAttempts = activeStates.BGSI_Lite_ChestClaimAttempts or {}
		if tick() - (activeStates.BGSI_Lite_ChestClaimAttempts[chestName] or 0) < 5 then
			return false
		end
		activeStates.BGSI_Lite_ChestClaimAttempts[chestName] = tick()
		return pcall(remoteEvent.FireServer, remoteEvent, "ClaimChest", chestName, true)
	end
	local worldChestList = getWorldChestNames()
	if Config.selectedWorldChest == "Giant Chest" and table.find(worldChestList, Config.selectedChest) then
		Config.selectedWorldChest = Config.selectedChest
	end
	if not table.find(worldChestList, Config.selectedWorldChest) then
		Config.selectedWorldChest = worldChestList[1] or "Giant Chest"
	end
	local chestRiftNames = getChestRiftNames()
	if not table.find(chestRiftNames, Config.selectedChest) then
		Config.selectedChest = chestRiftNames[1] or "golden-chest"
	end
	potionTab:AddSection("Normal Chests")
	-- Migrate the old single-select value into the new multi-select list once, so an
	-- existing choice isn't silently lost.
	if
		(type(Config.selectedWorldChests) ~= "table" or #Config.selectedWorldChests == 0)
		and type(Config.selectedWorldChest) == "string"
		and Config.selectedWorldChest ~= ""
	then
		Config.selectedWorldChests = { Config.selectedWorldChest }
	end
	local worldChestDropdown = potionTab:AddDropdown("SelectedWorldChest", {
		Title = "Select Chests",
		Description = "Pick one or more chests to auto-claim.",
		Values = worldChestList,
		Default = Config.selectedWorldChests,
		Multi = true,
		Search = true,
		Callback = function(selectedWorldChestsCallback)
			Config.selectedWorldChests = selectedWorldChestsCallback
			saveConfig()
		end,
	})
	potionTab:AddToggle("AutoClaimWorldChest", {
		Title = "Auto Claim Chest",
		Default = Config.autoClaimWorldChest,
		Callback = function(autoClaimWorldChestToggle)
			Config.autoClaimWorldChest = autoClaimWorldChestToggle
			saveConfig()
		end,
	})
	potionTab:AddSection("Rift Chests")
	local scriptStateABS = potionTab:AddDropdown("SelectedRiftChest", {
		Title = "Select Rift Chest",
		Values = chestRiftNames,
		Default = Config.selectedChest,
		Multi = false,
		Search = true,
		Callback = function(selectedRiftChestCallback)
			Config.selectedChest = selectedRiftChestCallback
			saveConfig()
		end,
	})
	potionTab:AddButton({
		Title = "Refresh chest lists",
		Callback = function()
			fireRemoteEventRepeatedly(worldChestDropdown, getWorldChestNames())
			fireRemoteEventRepeatedly(scriptStateABS, getChestRiftNames())
		end,
	})
	potionTab:AddToggle("AutoChestSummon", {
		Title = "Auto Spawn Rift Chest",
		Default = Config.autoChestSummon,
		Callback = function(scriptStateQJ)
			Config.autoChestSummon = scriptStateQJ
			saveConfig()
		end,
	})
	potionTab:AddToggle("AutoChest", {
		Title = "Auto Use Keys on Rift Chest",
		Default = Config.autoChest,
		Callback = function(scriptStateGJ)
			Config.autoChest = scriptStateGJ
			saveConfig()
		end,
	})
	task.spawn(function()
		while isCurrentRun() do
			task.wait(Config.autoClaimWorldChest and 1 or 0.85)
			if Config.autoClaimWorldChest then
				local selectedChests = getSelectedValues(Config.selectedWorldChests or {})
				if #selectedChests == 0 and type(Config.selectedWorldChest) == "string" then
					selectedChests = { Config.selectedWorldChest }
				end
				for _, chestName in ipairs(selectedChests) do
					claimChestByName(chestName)
				end
			end
		end
	end)
	task.spawn(function()
		local scriptStateACV = 0
		while isCurrentRun() do
			task.wait(Config.autoChestSummon and 1 or 0.85)
			if Config.autoChestSummon and tick() - scriptStateACV >= 3600 then
				summonMoonRiftIfNeeded(Config.selectedChest)
				scriptStateACV = tick()
			end
		end
	end)
	task.spawn(function()
		local scriptStateZW = 0
		while isCurrentRun() do
			task.wait(Config.autoChest and 0.3 or 0.85)
			if Config.autoChest then
				if tick() - scriptStateZW >= 3 then
					teleportToRift(Config.selectedChest)
					scriptStateZW = tick()
				end
				pcall(function()
					remoteEvent:FireServer("UnlockRiftChest", Config.selectedChest, false)
				end)
			end
		end
	end)
end
end
}
