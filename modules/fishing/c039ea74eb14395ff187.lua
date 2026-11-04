-- Generated from larplite.lua; rebuild with tools/build_modules.py.
return {
function(...)
do
	local fishingTab = scriptStateOG:AddTab({Title = "Fishing", Icon = "fish"})
	fishingTab:AddSection("Automatic Fishing")
	fishingTab:AddText({Title = "Fishing", Content = "Auto Fish travels to your best unlocked island and tracks its index."})
	local function setFishingStatus(message)
		activeStates.BGSI_Lite_FishingStatus = tostring(message)
	end
	local function addFishingToggle(flag, title, description, configKey)
		return fishingTab:AddToggle(flag, {
			Title = title,
			Description = description,
			Default = Config[configKey],
			Callback = function(enabled)
				Config[configKey] = enabled == true
				saveConfig()
			end,
		})
	end
	addFishingToggle("AutoFishing", "Auto Fish", "Uses the game's fishing state machine for casts and the reel minigame.", "fishingAuto")
	addFishingToggle("FishingAutoProgress", "Auto Progress Islands", "Travels to the highest fishing island as soon as its level requirement is met.", "fishingAutoProgress")
	local instantReelToggle = addFishingToggle("FishingInstantReel", "Try Instant Reel", "Attempts an immediate catch at the bite event; turns itself off after repeated failures.", "fishingInstantReel")
	fishingTab:AddSection("Fish Index and Inventory")
	addFishingToggle("FishingAutoClaimIndex", "Auto Claim Fish Index", "Claims completed island rewards and the all-fish reward.", "fishingAutoClaimIndex")
	addFishingToggle("FishingIndexSweep", "Sweep Earlier Islands", "After unlocking the final island, revisit incomplete islands once the final island index is done.", "fishingIndexSweep")
	addFishingToggle("FishingAutoEquipBestRod", "Auto Equip Best Rod", "Selects the strongest owned rod using its game-defined attributes.", "fishingAutoEquipBestRod")
	addFishingToggle("FishingAutoSellWhenFull", "Sell Unlocked Fish When Full", "Uses the game's Sell All Fish action only when inventory is full.", "fishingAutoSellWhenFull")
	local fishingState = {forceTravel = false, forceClaim = false, areaId = nil, castPosition = nil, lastTravel = 0, lastClaim = 0,
		lastRod = 0, lastSell = 0, lastInstant = 0, instantFailures = 0, instantPending = false}
	fishingTab:AddButton({Title = "Travel to Best Island", Callback = function()
		fishingState.forceTravel = true
	end})
	fishingTab:AddButton({Title = "Claim Available Fish Index Rewards", Callback = function()
		fishingState.forceClaim = true
	end})

	task.spawn(function()
		local fishingAreas, fishingAreasUtil, fishingUtil, experienceUtil, fishingRods, autoFishModule, fishingWorldUtil
		local function setAutoFishEnabled(enabled)
			if autoFishModule then pcall(autoFishModule.SetEnabled, autoFishModule, enabled) end
		end
		local function loadFishingModules()
			if fishingAreas and fishingAreasUtil and fishingUtil and experienceUtil and fishingRods
				and autoFishModule and fishingWorldUtil then return true end
			local ok = pcall(function()
				fishingAreas = require(ReplicatedStorage.Shared.Data.FishingAreas)
				fishingAreasUtil = require(ReplicatedStorage.Shared.Utils.FishingAreasUtil)
				fishingUtil = require(ReplicatedStorage.Shared.Utils.FishingUtil)
				experienceUtil = require(ReplicatedStorage.Shared.Utils.ExperienceUtil)
				fishingRods = require(ReplicatedStorage.Shared.Data.FishingRods)
				autoFishModule = require(ReplicatedStorage.Client.Gui.Frames.Fishing.FishingWorldAutoFish)
				fishingWorldUtil = require(ReplicatedStorage.Shared.Utils.WorldUtil)
			end)
			return ok and fishingAreas and fishingAreasUtil and fishingUtil and experienceUtil
				and fishingRods and autoFishModule and fishingWorldUtil
		end
		local function getFishingLevel(profile)
			local ok, level = pcall(experienceUtil.GetLevel, experienceUtil,
				tonumber(profile.FishingExperience) or 0, fishingUtil.XP_CONFIG)
			return ok and tonumber(level) or 1
		end
		local function isIndexComplete(profile, area)
			if type(area.Pool) ~= "table" or type(profile.CollectedFish) ~= "table" then return false, 0, 0 end
			local found, total = 0, 0
			for _, entry in ipairs(area.Pool) do
				total += 1
				if profile.CollectedFish[entry.Item] then found += 1 end
			end
			return total > 0 and found >= total, found, total
		end
		local function chooseFishingArea(profile)
			local level = getFishingLevel(profile)
			local bestId, bestData, bestOrder
			local highestRequirement = 0
			for id, area in pairs(fishingAreas) do
				local required = tonumber(area.RequiredLevel) or 0
				local order = tonumber(area.DisplayOrder) or 0
				highestRequirement = math.max(highestRequirement, required)
				if level >= required and (not bestOrder or order > bestOrder) then
					bestId, bestData, bestOrder = id, area, order
				end
			end
			if Config.fishingAutoProgress ~= true and fishingState.areaId and fishingAreas[fishingState.areaId]
				and level >= (tonumber(fishingAreas[fishingState.areaId].RequiredLevel) or 0) then
				bestId, bestData = fishingState.areaId, fishingAreas[fishingState.areaId]
			end
			if Config.fishingIndexSweep == true and level >= highestRequirement and bestData
				and isIndexComplete(profile, bestData) then
				local pendingOrder
				for id, area in pairs(fishingAreas) do
					local complete = isIndexComplete(profile, area)
					local order = tonumber(area.DisplayOrder) or 0
					if not complete and (not pendingOrder or order < pendingOrder) then
						bestId, bestData, pendingOrder = id, area, order
					end
				end
			end
			return bestId, bestData, level
		end
		local function claimFishingIndex(profile)
			if tick() - fishingState.lastClaim < 10 and not fishingState.forceClaim then return end
			fishingState.lastClaim = tick()
			fishingState.forceClaim = false
			local claimed = type(profile.ClaimedFishIslandRewards) == "table" and profile.ClaimedFishIslandRewards or {}
			local allComplete = true
			for id, area in pairs(fishingAreas) do
				local complete = isIndexComplete(profile, area)
				if not complete then allComplete = false end
				if complete and not table.find(claimed, id) then
					pcall(remoteEvent.FireServer, remoteEvent, "ClaimFishingIndexRewards", id)
				end
			end
			if allComplete and profile.FishIndexClaimedRewardV1 ~= true then
				pcall(remoteEvent.FireServer, remoteEvent, "ClaimAllFishingIndexRewards")
			end
		end
		local function equipBestRod(profile)
			if tick() - fishingState.lastRod < 10 or type(profile.RodInventory) ~= "table" then return end
			fishingState.lastRod = tick()
			local bestName, bestScore
			for name in pairs(profile.RodInventory) do
				local data = fishingRods.Data and fishingRods.Data[name]
				local attributes = data and data.Attributes
				if attributes then
					local score = (tonumber(attributes.RodPower) or 1) * (tonumber(attributes.CatchSpeed) or 1)
						* (tonumber(attributes.ReelSpeed) or 1) * (tonumber(attributes.RodLuck) or 1)
					if not bestScore or score > bestScore then bestName, bestScore = name, score end
				end
			end
			if bestName and bestName ~= profile.EquippedRod then
				pcall(remoteEvent.FireServer, remoteEvent, "SetEquippedRod", bestName, false)
			end
		end
		local function getIslandAndSpawn(area)
			local worlds = Workspace:FindFirstChild("Worlds")
			local seas = worlds and worlds:FindFirstChild("Seven Seas")
			local islands = seas and seas:FindFirstChild("Areas")
			local island = islands and islands:FindFirstChild(area.DisplayName)
			local teleport = island and island:FindFirstChild("IslandTeleport")
			return island, teleport and teleport:FindFirstChild("Spawn")
		end
		local function moveToCastSpot(areaId, island, spawn)
			local activeAreas = fishingAreasUtil:GetActiveAreas()
			local candidates = {}
			for _, entry in pairs(activeAreas) do
				local instance = entry.Instance
				local root = instance and instance:FindFirstChild("Root")
				if entry.Id == areaId and root and root:IsA("BasePart") and instance:IsDescendantOf(island) then
					table.insert(candidates, root)
				end
			end
			table.sort(candidates, function(a, b)
				return (a.Position - spawn.Position).Magnitude < (b.Position - spawn.Position).Magnitude
			end)
			local character = LocalPlayer.Character
			local playerRoot = character and character:FindFirstChild("HumanoidRootPart")
			if not playerRoot then return false end
			for _, water in ipairs(candidates) do
				local localSpawn = water.CFrame:PointToObjectSpace(spawn.Position)
				local halfX = math.max(0, water.Size.X / 2 - 1)
				local halfZ = math.max(0, water.Size.Z / 2 - 1)
				local edge = water.CFrame:PointToWorldSpace(Vector3.new(
					math.clamp(localSpawn.X, -halfX, halfX),
					water.Size.Y / 2,
					math.clamp(localSpawn.Z, -halfZ, halfZ)))
				local toward = Vector3.new(water.Position.X - spawn.Position.X, 0, water.Position.Z - spawn.Position.Z)
				if toward.Magnitude < 1 then toward = Vector3.new(edge.X - spawn.Position.X, 0, edge.Z - spawn.Position.Z) end
				if toward.Magnitude < 1 then continue end
				toward = toward.Unit
				local stand = edge - toward * 11
				local groundParams = RaycastParams.new()
				groundParams.FilterType = Enum.RaycastFilterType.Exclude
				groundParams.FilterDescendantsInstances = {water, character}
				local ground = Workspace:Raycast(stand + Vector3.new(0, 30, 0), Vector3.new(0, -80, 0), groundParams)
				if ground then stand = Vector3.new(stand.X, ground.Position.Y + 3, stand.Z)
				else stand = spawn.Position + Vector3.new(0, 3, 0) end
				local castParams = RaycastParams.new()
				castParams.FilterType = Enum.RaycastFilterType.Include
				castParams.FilterDescendantsInstances = {water}
				local valid = false
				for distance = fishingUtil.MIN_CAST_DISTANCE, fishingUtil.MAX_CAST_DISTANCE, 2 do
					local hit = Workspace:Raycast(stand + toward * distance + Vector3.new(0, 2, 0),
						Vector3.new(0, -50, 0), castParams)
					if hit then valid = true break end
				end
				if valid then
					if teleportToCFrame(CFrame.lookAt(stand, stand + toward)) then return stand end
				end
			end
			return nil
		end
		local function travelToArea(id, area)
			local island, spawn = getIslandAndSpawn(area)
			if not island or not spawn then return false, "Island is not loaded" end
			if tick() - fishingState.lastTravel < 4 then return false, "Traveling" end
			fishingState.lastTravel = tick()
			if autoFishModule:IsEnabled() then setAutoFishEnabled(false) end
			pcall(remoteEvent.FireServer, remoteEvent, "UnequipRod")
			pcall(remoteEvent.FireServer, remoteEvent, "Teleport", spawn:GetFullName())
			task.wait(0.9)
			local worldOk, currentWorld = pcall(fishingWorldUtil.GetPlayerWorld, fishingWorldUtil, LocalPlayer)
			if not worldOk or currentWorld ~= fishingUtil.WORLD_NAME then
				return false, "Waiting for Seven Seas travel"
			end
			local castPosition = moveToCastSpot(id, island, spawn)
			local ready = castPosition ~= nil
			if ready then
				fishingState.areaId = id
				fishingState.castPosition = castPosition
			end
			return ready, ready and "Ready" or "No valid cast spot found"
		end
		if activeStates.BGSI_Lite_FishingEventConnection then
			activeStates.BGSI_Lite_FishingEventConnection:Disconnect()
		end
		activeStates.BGSI_Lite_FishingEventConnection = remoteEvent.OnClientEvent:Connect(function(action, result)
			if action == "ReelReady" and Config.fishingAuto == true and Config.fishingInstantReel == true
				and isCurrentRun() and tick() - fishingState.lastInstant > 2 then
				fishingState.lastInstant = tick()
				fishingState.instantPending = true
				task.delay(0.15, function()
					if isCurrentRun() and Config.fishingAuto == true and Config.fishingInstantReel == true then
						pcall(remoteEvent.FireServer, remoteEvent, "Reel", true)
					end
				end)
			elseif action == "ReelFinished" and fishingState.instantPending and isCurrentRun() then
				fishingState.instantPending = false
				if type(result) == "table" and result.Success == true then
					fishingState.instantFailures = 0
				else
					fishingState.instantFailures += 1
					if fishingState.instantFailures >= 3 then
						Config.fishingInstantReel = false
						pcall(instantReelToggle.SetValue, instantReelToggle, false)
						saveConfig()
						warn("[LarpLite] Instant Reel was turned off after three failed catches.")
					end
				end
			end
		end)
		while isCurrentRun() do
			task.wait(1)
			if not loadFishingModules() then setFishingStatus("Fishing modules are loading") continue end
			if not profileStore:IsReady() then setFishingStatus("Waiting for account data") continue end
			local profile = profileStore:Get()
			if type(profile) ~= "table" then continue end
			local areaId, area, level = chooseFishingArea(profile)
			local found, total = 0, 0
			if area then
				local _, areaFound, areaTotal = isIndexComplete(profile, area)
				found, total = areaFound, areaTotal
			end
			local areaName = area and area.DisplayName or "None"
			local status = ("Level %d | %s | Index %d/%d | Rod: %s"):format(
				level, areaName, found or 0, total or 0, tostring(profile.EquippedRod or "None"))
			if Config.safeMode == true or activeStates.BGSI_Lite_RebirthMachineBusy == true
				or activeStates.BGSI_Lite_BubbleQuestActive == true then
				if autoFishModule:IsEnabled() then setAutoFishEnabled(false) end
				setFishingStatus(status .. " | Paused")
				continue
			end
			if Config.fishingAutoClaimIndex == true or fishingState.forceClaim then claimFishingIndex(profile) end
			if Config.fishingAutoEquipBestRod == true and Config.fishingAuto == true then equipBestRod(profile) end
			local inventoryOk, inventoryFull = pcall(fishingUtil.IsInventoryFull, fishingUtil, profile)
			if Config.fishingAutoSellWhenFull == true and Config.fishingAuto == true
				and tick() - fishingState.lastSell >= 10 and inventoryOk and inventoryFull then
				fishingState.lastSell = tick()
				pcall(remoteEvent.FireServer, remoteEvent, "SellAllFish")
			end
			if Config.fishingAuto == true and inventoryOk and inventoryFull then
				if autoFishModule:IsEnabled() then setAutoFishEnabled(false) end
				setFishingStatus(status .. " | Inventory full")
				continue
			end
			if not Config.fishingAuto and not fishingState.forceTravel then
				if autoFishModule:IsEnabled() then setAutoFishEnabled(false) end
				fishingState.areaId = nil
				fishingState.castPosition = nil
				setFishingStatus(status .. " | Auto Fish off")
				continue
			end
			if not areaId then setFishingStatus("No unlocked fishing area") continue end
			local worldOk, currentWorld = pcall(fishingWorldUtil.GetPlayerWorld, fishingWorldUtil, LocalPlayer)
			if not worldOk or currentWorld ~= fishingUtil.WORLD_NAME then fishingState.areaId = nil end
			local character = LocalPlayer.Character
			local playerRoot = character and character:FindFirstChild("HumanoidRootPart")
			if fishingState.castPosition and playerRoot
				and (playerRoot.Position - fishingState.castPosition).Magnitude > 25 then
				fishingState.areaId = nil
			end
			if fishingState.forceTravel or fishingState.areaId ~= areaId then
				fishingState.forceTravel = false
				local ready, reason = travelToArea(areaId, area)
				setFishingStatus(status .. " | " .. reason)
				if not ready then continue end
			end
			if Config.fishingAuto == true then
				if LocalPlayer:GetAttribute("RodEquipped") ~= true then
					pcall(remoteEvent.FireServer, remoteEvent, "EquipRod")
					setFishingStatus(status .. " | Equipping rod")
					continue
				end
				if not autoFishModule:IsEnabled() then setAutoFishEnabled(true) end
				setFishingStatus(status .. " | Fishing")
			end
		end
		if autoFishModule and autoFishModule:IsEnabled() then setAutoFishEnabled(false) end
		if activeStates.BGSI_Lite_FishingEventConnection then
			activeStates.BGSI_Lite_FishingEventConnection:Disconnect()
			activeStates.BGSI_Lite_FishingEventConnection = nil
		end
	end)
end
end
}
