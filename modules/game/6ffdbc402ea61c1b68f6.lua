-- Generated from larplite.lua; rebuild with tools/build_modules.py.
return {
function(...)
gameTab = scriptStateOG:AddTab({
	Title = "Game",
	Icon = "gamepad",
})
end,
function(...)
do
	local scriptStateBY = {
		"Pets",
		"Buffs",
		"Shops",
		"Rift",
	}
	local prizesData, prizesUtil, fragmentUtil
	pcall(function()
		fragmentUtil = require(ReplicatedStorage.Shared.Utils.FragmentUtil)
	end)
	local fragmentTypes = type(fragmentUtil) == "table" and fragmentUtil.FRAGMENT_TYPES
		or { "Green", "Blue", "Purple", "Rainbow" }
	local maximumIndividualFragmentCount = type(fragmentUtil) == "table"
		and tonumber(fragmentUtil.MAX_INDIVIDUAL_FRAGMENT_COUNT)
		or 250
	activeStates.BGSI_Lite_FindLuckEggName = function()
		local now = tick()
		if now - (activeStates.BGSI_Lite_LuckEggCacheTime or 0) < 1 then
			return activeStates.BGSI_Lite_LuckEggName
		end
		local function matchLuckEggName(candidateName)
			if type(candidateName) ~= "string" then
				return nil
			end
			local lowerName = string.lower(candidateName)
			local nameStart = string.find(lowerName, "4x luck", 1, true)
			local nameEnd = nameStart and string.find(lowerName, "egg", nameStart, true)
			return nameStart and nameEnd and candidateName:sub(nameStart, nameEnd + 2) or nil
		end
		local summonedEgg = workspace:FindFirstChild("SummonedEgg")
		if summonedEgg then
			local eggInstances = summonedEgg:GetDescendants()
			table.insert(eggInstances, 1, summonedEgg)
			for _, eggInstance in ipairs(eggInstances) do
				local eggName = matchLuckEggName(eggInstance.Name)
				if not eggName and eggInstance:IsA("StringValue") then
					eggName = matchLuckEggName(eggInstance.Value)
				elseif
					not eggName
					and (eggInstance:IsA("TextLabel") or eggInstance:IsA("TextButton") or eggInstance:IsA("TextBox"))
				then
					eggName = matchLuckEggName(eggInstance.Text)
				end
				if not eggName then
					for _, attributeValue in pairs(eggInstance:GetAttributes()) do
						eggName = matchLuckEggName(attributeValue)
						if eggName then
							break
						end
					end
				end
				if eggName then
					activeStates.BGSI_Lite_LuckEggName = eggName
					activeStates.BGSI_Lite_LuckEggCacheTime = now
					return eggName
				end
			end
		end
		for _, eggName in ipairs(safeGetChildren(true)) do
			local matchingEggName = matchLuckEggName(eggName)
			if matchingEggName then
				activeStates.BGSI_Lite_LuckEggName = matchingEggName
				activeStates.BGSI_Lite_LuckEggCacheTime = now
				return matchingEggName
			end
		end
		activeStates.BGSI_Lite_LuckEggName = nil
		activeStates.BGSI_Lite_LuckEggCacheTime = now
		return nil
	end
	local luckEggServerHistoryFile = "1rzHubLiteLuckEggServers.json"
	local luckEggServerHistory = {}

	pcall(function()
		if isfile and isfile(luckEggServerHistoryFile) then
			local savedHistory = HttpService:JSONDecode(readfile(luckEggServerHistoryFile))
			if
				type(savedHistory) == "table"
				and tostring(savedHistory.PlaceId or "") == tostring(game.PlaceId)
				and type(savedHistory.Servers) == "table"
			then
				for savedJobId, rejectedAt in pairs(savedHistory.Servers) do
					local rejectedTimestamp = tonumber(rejectedAt)
					if type(savedJobId) == "string" and savedJobId ~= "" and rejectedTimestamp then
						luckEggServerHistory[savedJobId] = rejectedTimestamp
					end
				end
			end
		end
	end)

	local function saveLuckEggServerHistory()
		if not writefile then
			return
		end
		pcall(function()
			writefile(
				luckEggServerHistoryFile,
				HttpService:JSONEncode({
					PlaceId = tostring(game.PlaceId),
					Servers = luckEggServerHistory,
					UpdatedAt = os.time(),
				})
			)
		end)
	end

	local function rejectLuckEggServer(jobId)
		jobId = tostring(jobId or "")
		if jobId == "" or luckEggServerHistory[jobId] then
			return
		end
		luckEggServerHistory[jobId] = os.time()
		saveLuckEggServerHistory()
		print("[" .. LocalPlayer.Name .. "] Saved no-egg JobId = " .. jobId)
	end

	local function fetchLuckEggServerPage(cursor)
		local serverURL = "https://games.roblox.com/v1/games/"
			.. game.PlaceId
			.. "/servers/Public?sortOrder=Asc&limit=100&excludeFullGames=true"
		if type(cursor) == "string" and cursor ~= "" then
			serverURL = serverURL .. "&cursor=" .. HttpService:UrlEncode(cursor)
		end
		local requestOk, responseBody = pcall(function()
			return game:HttpGet(serverURL)
		end)
		if not requestOk or type(responseBody) ~= "string" or responseBody == "" then
			local requestFunction = request
				or http_request
				or (type(syn) == "table" and rawget(syn, "request"))
				or rawget(activeStates, "http_request")
			if type(requestFunction) ~= "function" then
				local httpTable = rawget(activeStates, "http")
				requestFunction = type(httpTable) == "table" and rawget(httpTable, "request") or nil
			end
			if type(requestFunction) == "function" then
				local executorOk, executorResponse = pcall(requestFunction, {
					Url = serverURL,
					Method = "GET",
					Headers = {
						["Accept"] = "application/json",
					},
				})
				local statusCode = executorOk
						and type(executorResponse) == "table"
						and tonumber(executorResponse.StatusCode or executorResponse.Status)
					or nil
				if
					executorOk
					and type(executorResponse) == "table"
					and statusCode
					and statusCode >= 200
					and statusCode < 300
				then
					responseBody = executorResponse.Body
					requestOk = type(responseBody) == "string" and responseBody ~= ""
				end
			end
		end
		if not requestOk or type(responseBody) ~= "string" or responseBody == "" then
			return nil, "request failed"
		end
		local decodeOk, serverPage = pcall(HttpService.JSONDecode, HttpService, responseBody)
		if not decodeOk or type(serverPage) ~= "table" then
			return nil, "invalid response"
		end
		return serverPage
	end

	local function getUnvisitedLuckEggServers()
		local serverIds = {}
		local cursor
		local pageCount = 0
		local lastError
		local seenCursors = {}
		repeat
			pageCount = pageCount + 1
			local serverPage, pageError = fetchLuckEggServerPage(cursor)
			if not serverPage then
				lastError = pageError
				break
			end
			for _, serverInfo in ipairs(serverPage.data or {}) do
				local serverId = type(serverInfo) == "table" and tostring(serverInfo.id or "") or ""
				local playing = type(serverInfo) == "table" and tonumber(serverInfo.playing) or 0
				local maximumPlayers = type(serverInfo) == "table" and tonumber(serverInfo.maxPlayers) or 0
				if
					serverId ~= ""
					and serverId ~= game.JobId
					and not luckEggServerHistory[serverId]
					and playing < maximumPlayers
				then
					table.insert(serverIds, serverId)
				end
			end
			local nextCursor = serverPage.nextPageCursor
			if type(nextCursor) == "string" and nextCursor ~= "" and not seenCursors[nextCursor] then
				seenCursors[nextCursor] = true
				cursor = nextCursor
			else
				cursor = nil
			end
		until cursor == nil or pageCount >= 100
		return serverIds, pageCount, lastError
	end

	local targetRiftServerHistoryFile = "1rzHubLiteTargetRiftServers.json"
	local targetRiftServerHistory = {}
	local function getTargetRiftSelectionKey()
		if type(activeStates.BGSI_Lite_GetTargetRiftSelectionKey) == "function" then
			return activeStates.BGSI_Lite_GetTargetRiftSelectionKey()
		end
		return ""
	end
	pcall(function()
		if isfile and isfile(targetRiftServerHistoryFile) then
			local savedHistory = HttpService:JSONDecode(readfile(targetRiftServerHistoryFile))
			if
				type(savedHistory) == "table"
				and tostring(savedHistory.PlaceId or "") == tostring(game.PlaceId)
				and tostring(savedHistory.TargetKey or "") == getTargetRiftSelectionKey()
				and type(savedHistory.Servers) == "table"
			then
				for savedJobId, rejectedAt in pairs(savedHistory.Servers) do
					local rejectedTimestamp = tonumber(rejectedAt)
					if type(savedJobId) == "string" and savedJobId ~= "" and rejectedTimestamp then
						targetRiftServerHistory[savedJobId] = rejectedTimestamp
					end
				end
			end
		end
	end)
	local function saveTargetRiftServerHistory()
		if not writefile then
			return
		end
		pcall(function()
			writefile(
				targetRiftServerHistoryFile,
				HttpService:JSONEncode({
					PlaceId = tostring(game.PlaceId),
					TargetKey = getTargetRiftSelectionKey(),
					Servers = targetRiftServerHistory,
					UpdatedAt = os.time(),
				})
			)
		end)
	end
	activeStates.BGSI_Lite_ResetTargetRiftServerHistory = function()
		for jobId in pairs(targetRiftServerHistory) do
			targetRiftServerHistory[jobId] = nil
		end
		saveTargetRiftServerHistory()
	end
	local function rejectTargetRiftServer(jobId)
		jobId = tostring(jobId or "")
		if jobId == "" or targetRiftServerHistory[jobId] then
			return
		end
		targetRiftServerHistory[jobId] = os.time()
		saveTargetRiftServerHistory()
		print("[" .. LocalPlayer.Name .. "] Saved no-target-rift JobId = " .. jobId)
	end
	local function getUnvisitedTargetRiftServers()
		local serverIds = {}
		local cursor
		local pageCount = 0
		local lastError
		local seenCursors = {}
		repeat
			pageCount += 1
			local serverPage, pageError = fetchLuckEggServerPage(cursor)
			if not serverPage then
				lastError = pageError
				break
			end
			for _, serverInfo in ipairs(serverPage.data or {}) do
				local serverId = type(serverInfo) == "table" and tostring(serverInfo.id or "") or ""
				local playing = type(serverInfo) == "table" and tonumber(serverInfo.playing) or 0
				local maximumPlayers = type(serverInfo) == "table" and tonumber(serverInfo.maxPlayers) or 0
				if serverId ~= "" and serverId ~= game.JobId and not targetRiftServerHistory[serverId] and playing < maximumPlayers then
					table.insert(serverIds, serverId)
				end
			end
			local nextCursor = serverPage.nextPageCursor
			if type(nextCursor) == "string" and nextCursor ~= "" and not seenCursors[nextCursor] then
				seenCursors[nextCursor] = true
				cursor = nextCursor
			else
				cursor = nil
			end
		until cursor == nil or pageCount >= 100
		return serverIds, pageCount, lastError
	end

	activeStates.BGSI_Lite_HopForTargetRift = function()
		if
			not isCurrentRun()
			or Config.autoHopTargetRifts ~= true
			or Config.autoHopLuckEgg == true
			or activeStates.BGSI_Lite_TargetRiftHopInProgress
		then
			return
		end
		if getTargetRiftSelectionKey() == "" then
			return
		end
		activeStates.BGSI_Lite_TargetRiftHopInProgress = true
		rejectTargetRiftServer(game.JobId)
		print("[" .. LocalPlayer.Name .. "] No selected rift found. Searching for another server...")
		if tostring(game.PrivateServerId or "") ~= "" then
			print("[" .. LocalPlayer.Name .. "] Current server is private. Target-rift hop only checks public servers.")
		end
		local serverIds, scannedPages, serverListError = getUnvisitedTargetRiftServers()
		local rejectedCount = 0
		for _ in pairs(targetRiftServerHistory) do
			rejectedCount += 1
		end
		if #serverIds == 0 and not serverListError and rejectedCount > 0 then
			print("[" .. LocalPlayer.Name .. "] All known public servers were checked for the selected rifts. Clearing target-rift history and rescanning.")
			activeStates.BGSI_Lite_ResetTargetRiftServerHistory()
			serverIds, scannedPages, serverListError = getUnvisitedTargetRiftServers()
		end
		task.delay(10, function()
			if isCurrentRun() then
				activeStates.BGSI_Lite_TargetRiftHopInProgress = false
			end
		end)
		if #serverIds > 0 then
			local serverId = serverIds[math.random(1, #serverIds)]
			activeStates.BGSI_Lite_TargetRiftHopTarget = serverId
			print("[" .. LocalPlayer.Name .. "] Target-rift scan pages = " .. tostring(scannedPages) .. ", unvisited servers = " .. tostring(#serverIds))
			print("[" .. LocalPlayer.Name .. "] Target-rift hop JobId = " .. serverId)
			local teleportOk, teleportError = pcall(function()
				if isAutomationBlocked() then
					return
				end
				TeleportService:TeleportToPlaceInstance(game.PlaceId, serverId, LocalPlayer)
			end)
			if not teleportOk then
				print("[" .. LocalPlayer.Name .. "] Target-rift hop failed = " .. tostring(teleportError))
				activeStates.BGSI_Lite_TargetRiftHopInProgress = false
			end
		else
			if serverListError then
				print("[" .. LocalPlayer.Name .. "] Target-rift server list unavailable (" .. tostring(serverListError) .. "). Staying here and retrying.")
			else
				print("[" .. LocalPlayer.Name .. "] No unvisited public servers found for the selected rifts after " .. tostring(scannedPages) .. " pages.")
			end
			activeStates.BGSI_Lite_TargetRiftHopInProgress = false
		end
	end

	activeStates.BGSI_Lite_HopForLuckEgg = function()
		if isAutomationBlocked() or Config.autoHopLuckEgg ~= true or activeStates.BGSI_Lite_LuckEggHopInProgress then
			return
		end
		activeStates.BGSI_Lite_LuckEggHopInProgress = true
		rejectLuckEggServer(game.JobId)
		print("[" .. LocalPlayer.Name .. "] No matching 4x egg found. Searching for another server...")
		if tostring(game.PrivateServerId or "") ~= "" then
			print("[" .. LocalPlayer.Name .. "] Current server is private. Public-server-only hop is active.")
		end
		local serverIds, scannedPages, serverListError = getUnvisitedLuckEggServers()
		local rejectedCount = 0
		for _ in pairs(luckEggServerHistory) do
			rejectedCount = rejectedCount + 1
		end
		if #serverIds == 0 and not serverListError and rejectedCount > 0 then
			print(
				"["
					.. LocalPlayer.Name
					.. "] All known public servers were rejected. Clearing "
					.. tostring(rejectedCount)
					.. " saved JobIds and rechecking every server."
			)
			for rejectedJobId in pairs(luckEggServerHistory) do
				luckEggServerHistory[rejectedJobId] = nil
			end
			saveLuckEggServerHistory()
			serverIds, scannedPages, serverListError = getUnvisitedLuckEggServers()
			rejectedCount = 0
		end
		task.delay(10, function()
			if isCurrentRun() then
				activeStates.BGSI_Lite_LuckEggHopInProgress = false
			end
		end)
		if #serverIds > 0 then
			local serverId = serverIds[math.random(1, #serverIds)]
			activeStates.BGSI_Lite_LuckEggHopTarget = serverId
			print(
				"["
					.. LocalPlayer.Name
					.. "] Server scan pages = "
					.. tostring(scannedPages)
					.. ", unvisited servers = "
					.. tostring(#serverIds)
			)
			print("[" .. LocalPlayer.Name .. "] Server hop target JobId = " .. serverId)
			local teleportOk, teleportError = pcall(function()
				if isAutomationBlocked() then
					return
				end
				TeleportService:TeleportToPlaceInstance(game.PlaceId, serverId, LocalPlayer)
			end)
			if not teleportOk then
				print("[" .. LocalPlayer.Name .. "] Server hop failed = " .. tostring(teleportError))
				activeStates.BGSI_Lite_LuckEggHopInProgress = false
			end
		else
			if serverListError then
				print(
					"["
						.. LocalPlayer.Name
						.. "] Server list unavailable ("
						.. tostring(serverListError)
						.. "). Staying here and retrying; same-server fallback is disabled."
				)
			else
				print(
					"["
						.. LocalPlayer.Name
						.. "] No unvisited public servers found after "
						.. tostring(scannedPages)
						.. " pages. Rejected JobIds = "
						.. tostring(rejectedCount)
						.. ". Waiting for a new server."
				)
			end
			activeStates.BGSI_Lite_LuckEggHopInProgress = false
		end
	end
	local function getInventoryItemAmount(itemName)
		if type(itemName) ~= "string" or itemName == "" then
			return 0
		end
		local ok, playerData = pcall(function()
			return profileStore:IsReady() and profileStore:Get() or nil
		end)
		if not ok or type(playerData) ~= "table" then
			return 0
		end
		local function amountFromValue(value, depth)
			depth = tonumber(depth) or 0
			if depth > 4 or value == nil then
				return 0
			end
			if type(value) == "number" then
				return value
			end
			if type(value) ~= "table" then
				return 0
			end
			local directAmount =
				tonumber(value.Amount or value.amount or value.Count or value.count or value.Quantity or value.quantity)
			if directAmount then
				return directAmount
			end
			local totalAmount = 0
			for _, childValue in pairs(value) do
				if type(childValue) == "table" then
					local childName = childValue.Name
						or childValue.name
						or childValue.Item
						or childValue.item
						or childValue.Type
						or childValue.type
					if childName == itemName then
						totalAmount = totalAmount + amountFromValue(childValue, depth + 1)
					end
				end
			end
			return totalAmount
		end
		local highestAmount = 0
		for _, containerName in ipairs({
			"Powerups",
			"Items",
			"Gifts",
			"Inventory",
			"Currencies",
		}) do
			local container = playerData[containerName]
			if type(container) == "table" then
				highestAmount = math.max(highestAmount, amountFromValue(container[itemName], 0))
			end
		end
		if itemUtil and type(itemUtil.GetOwnedAmount) == "function" then
			for _, itemPayload in ipairs({
				itemName,
				{
					Type = "Fragment",
					Name = itemName,
				},
				{
					Type = "Powerup",
					Name = itemName,
				},
				{
					Type = "Item",
					Name = itemName,
				},
			}) do
				local itemOk, ownedAmount = pcall(function()
					return itemUtil:GetOwnedAmount(playerData, itemPayload)
				end)
				if itemOk and type(ownedAmount) == "number" then
					highestAmount = math.max(highestAmount, ownedAmount)
				end
			end
		end
		return math.max(0, math.floor(highestAmount))
	end
	activeStates.BGSI_Lite_GetInventoryItemAmount = getInventoryItemAmount
	local function claimAvailablePrizes()
		if not prizesData or not prizesUtil then
			pcall(function()
				prizesData = require(ReplicatedStorage.Shared.Data.Prizes)
				prizesUtil = require(ReplicatedStorage.Shared.Utils.PrizesUtil)
			end)
		end
		local playerData = profileStore:IsReady() and profileStore:Get() or nil
		local claimedPrizes = playerData and playerData.ClaimedPrizes
		local prizes = prizesData and prizesData.data
		if
			type(playerData) ~= "table"
			or type(claimedPrizes) ~= "table"
			or type(prizes) ~= "table"
			or type(prizesUtil) ~= "table"
		then
			return
		end
		for prizeIndex, prize in ipairs(prizes) do
			if not Config.autoClaimPrizes then
				break
			end
			local progressOk, progress = pcall(prizesUtil.GetProgress, prizesUtil, playerData, prize.Type)
			if
				progressOk
				and type(progress) == "number"
				and claimedPrizes[prize.Key] == nil
				and progress >= prize.Requirement
			then
				remoteEvent:FireServer("ClaimPrize", prizeIndex)
				task.wait(0.15)
			end
		end
	end
	activeStates.BGSI_Lite_ClaimIndexRewards = function()
		local playerData = profileStore:IsReady() and profileStore:Get() or nil
		local indexUtil = activeStates.BGSI_Lite_IndexUtil
		if type(playerData) ~= "table" or type(indexUtil) ~= "table" then
			return
		end
		local claimedEggPrizes = type(playerData.EggPrizesClaimed) == "table" and playerData.EggPrizesClaimed
			or {}
		local openedEggs = type(playerData.EggsOpened) == "table" and playerData.EggsOpened or {}
		for eggName, eggInfo in pairs(type(eggDataModule) == "table" and eggDataModule or {}) do
			if openedEggs[eggName] ~= nil and type(eggInfo) == "table" and eggInfo.World and eggInfo.Reward then
				for _, indexMode in ipairs({ "Normal", "Shiny" }) do
					local claimKey = (indexMode == "Shiny" and "S" or "") .. tostring(eggName)
					if claimedEggPrizes[claimKey] == nil then
						local completedOk, completed = pcall(
							indexUtil.GetEggCompleted,
							indexUtil,
							playerData,
							eggInfo.World,
							indexMode,
							eggName
						)
						if
							completedOk
							and type(completed) == "table"
							and math.max(0, (tonumber(completed.Total) or 0) - (tonumber(completed.Found) or 0)) == 0
						then
							remoteEvent:FireServer("EggPrizeClaim", eggName, indexMode == "Shiny")
							task.wait(0.1)
						end
					end
				end
			end
		end
		local discoveredXL = {}
		pcall(function()
			discoveredXL = indexUtil:GetXLDiscovered(playerData)
		end)
		for taskName, taskInfo in pairs(
			type(activeStates.BGSI_Lite_XLIndexTasks) == "table" and activeStates.BGSI_Lite_XLIndexTasks or {}
		) do
			if
				type(taskInfo) == "table"
				and not table.find(type(playerData.XLIndexClaimed) == "table" and playerData.XLIndexClaimed or {}, taskName)
			then
				local progressOk, progress = pcall(indexUtil.GetXLTaskProgress, indexUtil, discoveredXL, taskName)
				if progressOk and (tonumber(progress) or 0) >= (tonumber(taskInfo.Amount) or math.huge) then
					remoteEvent:FireServer("ClaimXLIndexRewards", taskName)
					task.wait(0.1)
				end
			end
		end
		activeStates.BGSI_Lite_IndexClaimAttempts = activeStates.BGSI_Lite_IndexClaimAttempts or {}
		for worldName, worldInfo in pairs(
			type(activeStates.BGSI_Lite_WorldData) == "table" and activeStates.BGSI_Lite_WorldData or {}
		) do
			if
				type(worldInfo) == "table"
				and worldInfo.IndexLocked == nil
				and type(playerData.WorldsUnlocked) == "table"
				and playerData.WorldsUnlocked[worldName] ~= nil
			then
				for _, indexMode in ipairs({ "Normal", "Shiny" }) do
					local claimKey = (indexMode == "Shiny" and "Shiny" or "") .. tostring(worldName)
					if
						type(playerData.ClaimedIndex) == "table"
						and playerData.ClaimedIndex[claimKey] == nil
						and tick() - (activeStates.BGSI_Lite_IndexClaimAttempts[claimKey] or 0) >= 60
					then
						activeStates.BGSI_Lite_IndexClaimAttempts[claimKey] = tick()
						remoteEvent:FireServer("ClaimIndex", worldName, indexMode)
						task.wait(0.1)
					end
				end
			end
		end
	end
	activeStates.BGSI_Lite_TryUpgradeMastery = function()
		local playerData = profileStore:IsReady() and profileStore:Get() or nil
		local masteryData = activeStates.BGSI_Lite_MasteryData
		if
			type(playerData) ~= "table"
			or type(masteryData) ~= "table"
			or type(masteryData.Upgrades) ~= "table"
			or type(itemUtil) ~= "table"
			or type(itemUtil.CanAfford) ~= "function"
		then
			return false
		end
		for _, masteryName in ipairs(scriptStateBY) do
			local masteryInfo = masteryData.Upgrades[masteryName]
			local currentLevel = type(playerData.MasteryLevels) == "table"
					and math.max(0, math.floor(tonumber(playerData.MasteryLevels[masteryName]) or 0))
				or 0
			local nextLevel = type(masteryInfo) == "table"
				and type(masteryInfo.Levels) == "table"
				and masteryInfo.Levels[currentLevel + 1]
				or nil
			if type(nextLevel) == "table" and type(nextLevel.Cost) == "table" then
				local canAffordOk, canAfford = pcall(itemUtil.CanAfford, itemUtil, playerData, nextLevel.Cost)
				if canAffordOk and canAfford then
					remoteEvent:FireServer("UpgradeMastery", masteryName)
					local updateDeadline = tick() + 2
					repeat
						task.wait(0.1)
						playerData = profileStore:IsReady() and profileStore:Get() or nil
					until not Config.autoUpgradeMastery
						or type(playerData) ~= "table"
						or (
							type(playerData.MasteryLevels) == "table"
							and (tonumber(playerData.MasteryLevels[masteryName]) or 0) > currentLevel
						)
						or tick() >= updateDeadline
					return true
				end
			end
		end
		return false
	end
	activeStates.BGSI_Lite_ClaimDailyAndWheelRewards = function()
		local playerData = profileStore:IsReady() and profileStore:Get() or nil
		if type(playerData) ~= "table" then
			return
		end
		if Config.autoDailyRewards == true then
			local dailyRewards = type(playerData.DailyRewards) == "table" and playerData.DailyRewards or nil
			local absoluteDay
			pcall(function()
				absoluteDay = timeModule.getAbsoluteDay()
			end)
			if
				dailyRewards
				and dailyRewards.Claimed ~= true
				and (
					absoluteDay == nil
					or (tonumber(dailyRewards.LastDay) or -1) >= absoluteDay
				)
				and tick() - (tonumber(activeStates.BGSI_Lite_LastDailyRewardAttempt) or 0) >= 30
			then
				activeStates.BGSI_Lite_LastDailyRewardAttempt = tick()
				remoteEvent:FireServer("DailyRewardClaimStars")
			end
		end
		if Config.autoWheelSpin == true then
			if tick() - (tonumber(activeStates.BGSI_Lite_LastFreeWheelAttempt) or 0) >= 60 then
				activeStates.BGSI_Lite_LastFreeWheelAttempt = tick()
				remoteEvent:FireServer("ClaimFreeWheelSpin")
			end
			local spinTickets = getInventoryItemAmount("Spin Ticket")
			local nextFreeSpinAt = tonumber(playerData.NextWheelSpin) or math.huge
			if
				(spinTickets > 0 or nextFreeSpinAt <= getCurrentTimestamp())
				and tick() - (tonumber(activeStates.BGSI_Lite_LastWheelSpinAttempt) or 0) >= 8
			then
				activeStates.BGSI_Lite_LastWheelSpinAttempt = tick()
				local spinOk, spinResult = pcall(remoteFunction.InvokeServer, remoteFunction, "WheelSpin")
				if spinOk and spinResult ~= nil then
					task.wait(0.2)
					remoteEvent:FireServer("ClaimWheelSpinQueue")
				end
			end
		end
	end
	local function useFragment(fragmentType)
		local playerData = profileStore:IsReady() and profileStore:Get() or nil
		local usedFragments = playerData and playerData.Fragments or {}
		local usedBefore = tonumber(usedFragments[fragmentType]) or 0
		local ownedBefore = getInventoryItemAmount(fragmentType .. " Fragment")
		if ownedBefore <= 0 or usedBefore >= maximumIndividualFragmentCount then
			return false
		end
		local remoteOk = pcall(function()
			remoteEvent:FireServer("UseFragment", fragmentType)
		end)
		if not remoteOk then
			return false
		end
		local updateDeadline = tick() + 1.5
		repeat
			task.wait(0.1)
			playerData = profileStore:IsReady() and profileStore:Get() or nil
			usedFragments = playerData and playerData.Fragments or {}
			if
				(tonumber(usedFragments[fragmentType]) or 0) > usedBefore
				or getInventoryItemAmount(fragmentType .. " Fragment") < ownedBefore
			then
				return true
			end
		until tick() >= updateDeadline
		return false
	end
	gameTab:AddSection("Thangs")
	gameTab:AddToggle("AutoPlaytime", {
		Title = "Claim Playtime",
		Default = Config.autoPlaytime,
		Callback = function(scriptStateFS)
			Config.autoPlaytime = scriptStateFS
			saveConfig()
		end,
	})
	gameTab:AddToggle("AutoClaimPrizes", {
		Title = "Auto Claim Prizes",
		Default = Config.autoClaimPrizes,
		Callback = function(isEnabled)
			Config.autoClaimPrizes = isEnabled
			saveConfig()
		end,
	})
	gameTab:AddToggle("AutoDailyRewards", {
		Title = "Auto Daily Rewards",
		Default = Config.autoDailyRewards,
		Callback = function(isEnabled)
			Config.autoDailyRewards = isEnabled
			saveConfig()
		end,
	})
	gameTab:AddToggle("AutoWheelSpin", {
		Title = "Auto Wheel Spins",
		Default = Config.autoWheelSpin,
		Callback = function(isEnabled)
			Config.autoWheelSpin = isEnabled
			saveConfig()
		end,
	})
	gameTab:AddToggle("AutoInventoryCleanup", {
		Title = "Safe Inventory Cleanup",
		Default = Config.autoInventoryCleanup,
		Callback = function(isEnabled)
			Config.autoInventoryCleanup = isEnabled
			saveConfig()
		end,
	})
	gameTab:AddSlider("InventoryCleanupMinCopies", {
		Title = "Cleanup Minimum Copies",
		Description = "Keeps at least this many copies of each disposable pet.",
		Min = 2,
		Max = 100,
		Default = Config.inventoryCleanupMinCopies,
		Rounding = 0,
		Callback = function(amount)
			Config.inventoryCleanupMinCopies = math.clamp(math.floor(tonumber(amount) or 10), 2, 100)
			saveConfig()
		end,
	})
	gameTab:AddToggle("AutoDeleteLowRarityEggPets", {
		Title = "Auto Delete Common, Rare, Epic",
		Description = "Enables the egg auto-delete list for Common, Rare, and Epic pets on the egg being hatched.",
		Default = Config.autoDeleteLowRarityEggPets ~= false,
		Callback = function(isEnabled)
			Config.autoDeleteLowRarityEggPets = isEnabled == true
			activeStates.BGSI_Lite_LastAutoDeleteEggAt = 0
			saveConfig()
		end,
	})
	gameTab:AddToggle("HealthRecoveryEnabled", {
		Title = "Client Recovery",
		Default = Config.healthRecoveryEnabled,
		Callback = function(isEnabled)
			Config.healthRecoveryEnabled = isEnabled
			saveConfig()
		end,
	})
	gameTab:AddDropdown("AccountRole", {
		Title = "Account Role",
		Values = { "Balanced", "Hatcher", "Quest", "Farmer" },
		Default = Config.accountRole,
		Multi = false,
		Callback = function(role)
			Config.accountRole = role
			saveConfig()
		end,
	})
	gameTab:AddToggle("AutoUpgradeMastery", {
		Title = "Auto Upgrade Mastery",
		Default = Config.autoUpgradeMastery,
		Callback = function(autoUpgradeMasteryToggle)
			Config.autoUpgradeMastery = autoUpgradeMasteryToggle
			saveConfig()
		end,
	})
	gameTab:AddToggle("AutoPowerOrbEquipped", {
		Title = "Auto Power Orb",
		Default = Config.autoPowerOrbEquipped,
		Callback = function(scriptStateAER)
			Config.autoPowerOrbEquipped = scriptStateAER
			saveConfig()
		end,
	})
	gameTab:AddSection("Coins and Bubbles")
	gameTab:AddToggle("AutoCollectCoins", {
		Title = "Auto Collect Coins/Pickups",
		Default = Config.autoCollectCoins,
		Callback = function(autoCollectCoinsToggle)
			Config.autoCollectCoins = autoCollectCoinsToggle
			pcall(installPickupRangeHook)
			saveConfig()
		end,
	})
	gameTab:AddToggle("AutoBubble", {
		Title = "Auto Bubble",
		Default = Config.autoBubble,
		Callback = function(scriptStateTF)
			Config.autoBubble = scriptStateTF
			saveConfig()
		end,
	})
	gameTab:AddToggle("AutoSellBubble", {
		Title = "Auto Sell Bubble",
		Default = Config.autoSell,
		Callback = function(scriptStateAEL)
			Config.autoSell = scriptStateAEL
			saveConfig()
		end,
	})
	gameTab:AddSection("Classic Island Obbys")
	gameTab:AddToggle("AutoObbyCycle", {
		Title = "Hard to Easy Obby Cycle",
		Description = "Runs the hardest available course, skips active cooldowns, opens every matching key, and continues automatically.",
		Default = Config.autoObbyCycle,
		Callback = function(isEnabled)
			Config.autoObbyCycle = isEnabled == true
			if Config.autoObbyCycle then
				activeStates.BGSI_Lite_ObbyCycleIndex = 1
			end
			saveConfig()
		end,
	})
	gameTab:AddDropdown("SelectedObby", {
		Title = "Selected Obby",
		Description = "Choose the course used when the automatic Hard-to-Easy cycle is disabled.",
		Values = activeStates.BGSI_Lite_ObbyDifficultyOptions,
		Default = Config.selectedObby,
		Multi = false,
		Callback = function(selectedObby)
			Config.selectedObby = selectedObby
			saveConfig()
		end,
	})
	gameTab:AddToggle("AutoObby", {
		Title = "Auto Complete Obby",
		Description = "Runs the full Hard-to-Easy cycle, or only the selected course when automatic cycling is disabled.",
		Default = Config.autoObby,
		Callback = function(isEnabled)
			Config.autoObby = isEnabled == true
			if not Config.autoObby then
				activeStates.BGSI_Lite_ObbyActive = false
				if Config.autoObbyChest ~= true then
					activeStates.BGSI_Lite_ObbyChestActive = false
					resumeNormalAutomation()
				end
			end
			saveConfig()
		end,
	})
	gameTab:AddToggle("AutoObbyChest", {
		Title = "Auto Open Obby Chest",
		Description = "Immediately uses owned keys on the chest for the active Classic Island course.",
		Default = Config.autoObbyChest,
		Callback = function(isEnabled)
			Config.autoObbyChest = isEnabled == true
			if not activeStates.BGSI_Lite_ShouldOpenObbyChest() then
				activeStates.BGSI_Lite_ObbyChestActive = false
				resumeNormalAutomation()
			end
			saveConfig()
		end,
	})
	gameTab:AddToggle("ObbyChestUseThreeKeys", {
		Title = "Use 3 Obby Keys",
		Description = "Uses the chest's three-key option whenever at least three matching keys are owned.",
		Default = Config.obbyChestUseThreeKeys,
		Callback = function(isEnabled)
			Config.obbyChestUseThreeKeys = isEnabled == true
			saveConfig()
		end,
	})
	activeStates.BGSI_Lite_GetObbyCourse = function(difficulty)
		local obbyFolder = Workspace:FindFirstChild("Obbys")
		return obbyFolder and obbyFolder:FindFirstChild(tostring(difficulty or "")) or nil
	end
	activeStates.BGSI_Lite_GetObbyDifficulty = function()
		if Config.autoObbyCycle == true then
			local cycleIndex = math.clamp(tonumber(activeStates.BGSI_Lite_ObbyCycleIndex) or 1, 1, 3)
			local playerData = profileStore:IsReady() and profileStore:Get() or nil
			local cooldowns = type(playerData) == "table" and playerData.ObbyCooldowns or nil
			local currentTimestamp = getCurrentTimestamp()
			for offset = 0, 2 do
				local availableIndex = (cycleIndex + offset - 1) % 3 + 1
				local difficulty = ({ "Hard", "Medium", "Easy" })[availableIndex]
				local availableAt = type(cooldowns) == "table" and tonumber(cooldowns[difficulty]) or nil
				if not availableAt or currentTimestamp >= availableAt then
					activeStates.BGSI_Lite_ObbyCycleIndex = availableIndex
					return difficulty
				end
			end
			return nil
		end
		return table.find({ "Easy", "Medium", "Hard" }, Config.selectedObby) and Config.selectedObby or "Easy"
	end
	activeStates.BGSI_Lite_ShouldOpenObbyChest = function()
		return Config.autoObbyChest == true or Config.autoObby == true and Config.autoObbyCycle == true
	end
	activeStates.BGSI_Lite_IsInObby = function()
		local controllerOk, obbyController = pcall(function()
			return require(ReplicatedStorage.Client.Gui.Frames.Obbys)
		end)
		if not controllerOk or type(obbyController) ~= "table" or type(obbyController.IsInObby) ~= "function" then
			return false
		end
		local stateOk, isInObby = pcall(obbyController.IsInObby, obbyController)
		return stateOk and isInObby == true
	end
	activeStates.BGSI_Lite_GetObbyKeyAmount = function(difficulty)
		return getInventoryItemAmount(tostring(difficulty or "") .. " Obby Key")
	end
	activeStates.BGSI_Lite_OpenObbyChest = function(difficulty, course)
		if
			not activeStates.BGSI_Lite_ShouldOpenObbyChest()
			or type(course) ~= "userdata" and typeof(course) ~= "Instance"
		then
			return false
		end
		if not activeStates.BGSI_Lite_IsInObby() then
			return false
		end
		local chest = course:FindFirstChild("Chest")
		local promptPart = chest and chest:FindFirstChild("Prompt")
		if not promptPart or not promptPart:IsA("BasePart") then
			return false
		end
		local keyAmount = activeStates.BGSI_Lite_GetObbyKeyAmount(difficulty)
		if keyAmount <= 0 then
			return false
		end
		activeStates.BGSI_Lite_ObbyChestActive = true
		activeStates.BGSI_Lite_LastQuestAutomationAt = tick()
		pauseNormalAutomation()
		teleportToCFrame(promptPart.CFrame + Vector3.new(0, 3, 0))
		local character = LocalPlayer.Character
		local rootPart = character and character:FindFirstChild("HumanoidRootPart")
		local proximityDeadline = tick() + 1
		while rootPart and (rootPart.Position - promptPart.Position).Magnitude > 15 and tick() < proximityDeadline do
			teleportToCFrame(promptPart.CFrame + Vector3.new(0, 3, 0))
			task.wait(0.1)
			character = LocalPlayer.Character
			rootPart = character and character:FindFirstChild("HumanoidRootPart")
		end
		task.wait(0.3)
		local useThreeKeys =
			keyAmount >= 3 and (Config.obbyChestUseThreeKeys == true or Config.autoObbyCycle == true)
		local claimAmount = useThreeKeys and 3 or 1
		local expectedAmount = keyAmount - claimAmount
		pcall(remoteEvent.FireServer, remoteEvent, "ClaimObbyChest", useThreeKeys)
		local replicationDeadline = tick() + 0.6
		repeat
			task.wait(0.05)
		until activeStates.BGSI_Lite_GetObbyKeyAmount(difficulty) <= expectedAmount
			or tick() >= replicationDeadline
		if activeStates.BGSI_Lite_GetObbyKeyAmount(difficulty) >= keyAmount then
			pcall(function()
				local lootPoolViewer = require(ReplicatedStorage.Client.Gui.LootPoolViewer)
				if lootPoolViewer and lootPoolViewer.Activated and type(lootPoolViewer.Activated.Fire) == "function" then
					lootPoolViewer.Activated:Fire(claimAmount)
				end
			end)
			replicationDeadline = tick() + 1
			repeat
				task.wait(0.05)
			until activeStates.BGSI_Lite_GetObbyKeyAmount(difficulty) <= expectedAmount
				or tick() >= replicationDeadline
		end
		return activeStates.BGSI_Lite_GetObbyKeyAmount(difficulty) < keyAmount
	end
	activeStates.BGSI_Lite_LeaveObby = function()
		if not activeStates.BGSI_Lite_IsInObby() then
			return true
		end
		local worlds = Workspace:FindFirstChild("Worlds")
		local sevenSeas = worlds and worlds:FindFirstChild("Seven Seas")
		local areas = sevenSeas and sevenSeas:FindFirstChild("Areas")
		local classicIsland = areas and areas:FindFirstChild("Classic Island")
		local houseSpawn = classicIsland and classicIsland:FindFirstChild("HouseSpawn")
		if not houseSpawn then
			return false
		end
		activeStates.BGSI_Lite_LastQuestAutomationAt = tick()
		pcall(remoteEvent.FireServer, remoteEvent, "Teleport", houseSpawn:GetFullName())
		local leaveDeadline = tick() + 5
		repeat
			task.wait(0.1)
		until not activeStates.BGSI_Lite_IsInObby() or tick() >= leaveDeadline
		if activeStates.BGSI_Lite_IsInObby() then
			return false
		end
		activeStates.BGSI_Lite_CurrentObbyDifficulty = nil
		activeStates.BGSI_Lite_ObbyCompletedAt = 0
		activeStates.BGSI_Lite_ObbyChestActive = false
		if Config.autoObbyCycle == true then
			local cycleIndex = math.clamp(tonumber(activeStates.BGSI_Lite_ObbyCycleIndex) or 1, 1, 3)
			activeStates.BGSI_Lite_ObbyCycleIndex = cycleIndex % 3 + 1
		end
		resumeNormalAutomation()
		return true
	end
	activeStates.BGSI_Lite_RunSelectedObby = function()
		if activeStates.BGSI_Lite_ObbyActive or Config.autoObby ~= true then
			return false
		end
		local isInObby = activeStates.BGSI_Lite_IsInObby()
		if not isInObby and activeStates.BGSI_Lite_CurrentObbyDifficulty then
			activeStates.BGSI_Lite_CurrentObbyDifficulty = nil
			activeStates.BGSI_Lite_ObbyCompletedAt = 0
			activeStates.BGSI_Lite_ObbyChestActive = false
			resumeNormalAutomation()
		end
		local difficulty = activeStates.BGSI_Lite_CurrentObbyDifficulty
			or activeStates.BGSI_Lite_GetObbyDifficulty()
		if not table.find({ "Easy", "Medium", "Hard" }, difficulty) then
			return false
		end
		local playerData = profileStore:IsReady() and profileStore:Get() or nil
		local cooldowns = type(playerData) == "table" and playerData.ObbyCooldowns or nil
		local availableAt = type(cooldowns) == "table" and tonumber(cooldowns[difficulty]) or nil
		if not isInObby and availableAt and getCurrentTimestamp() < availableAt then
			return false
		end
		if
			isInObby
			and activeStates.BGSI_Lite_CurrentObbyDifficulty == difficulty
			and activeStates.BGSI_Lite_ObbyCompletedAt > 0
		then
			return false
		end
		activeStates.BGSI_Lite_ObbyActive = true
		activeStates.BGSI_Lite_LastQuestAutomationAt = tick()
		pauseNormalAutomation()
		local course = activeStates.BGSI_Lite_GetObbyCourse(difficulty)
		if not isInObby then
			local worlds = Workspace:FindFirstChild("Worlds")
			local sevenSeas = worlds and worlds:FindFirstChild("Seven Seas")
			local areas = sevenSeas and sevenSeas:FindFirstChild("Areas")
			local classicIsland = areas and areas:FindFirstChild("Classic Island")
			local activations = classicIsland and classicIsland:FindFirstChild("Obbys")
			local activationFolder = activations and activations:FindFirstChild(difficulty)
			local activationRoot = activationFolder and activationFolder:FindFirstChild("Root", true)
			if activationRoot and activationRoot:IsA("BasePart") then
				teleportToCFrame(activationRoot.CFrame + Vector3.new(0, 3, 0))
				task.wait(0.35)
			end
			pcall(remoteEvent.FireServer, remoteEvent, "StartObby", difficulty)
			local startDeadline = tick() + 6
			repeat
				task.wait(0.1)
			until activeStates.BGSI_Lite_IsInObby()
				or Config.autoObby ~= true
				or tick() >= startDeadline
		end
		if not activeStates.BGSI_Lite_IsInObby() then
			activeStates.BGSI_Lite_ObbyActive = false
			resumeNormalAutomation()
			return false
		end
		activeStates.BGSI_Lite_CurrentObbyDifficulty = difficulty
		local completePart = course and course:FindFirstChild("Complete")
		if course and completePart and completePart:IsA("BasePart") and Config.autoObby == true then
			activeStates.BGSI_Lite_LastQuestAutomationAt = tick()
			teleportToCFrame(completePart.CFrame + Vector3.new(0, 3, 0))
			task.wait(0.12)
			teleportToCFrame(completePart.CFrame)
			local character = LocalPlayer.Character
			local rootPart = character and character:FindFirstChild("HumanoidRootPart")
			local touchInterest = firetouchinterest or activeStates.firetouchinterest
			if rootPart and type(touchInterest) == "function" then
				pcall(touchInterest, rootPart, completePart, 0)
				pcall(touchInterest, rootPart, completePart, 1)
			end
			pcall(remoteEvent.FireServer, remoteEvent, "CompleteObby")
			local completionDeadline = tick() + 3
			repeat
				task.wait(0.1)
				playerData = profileStore:IsReady() and profileStore:Get() or nil
				cooldowns = type(playerData) == "table" and playerData.ObbyCooldowns or nil
				availableAt = type(cooldowns) == "table" and tonumber(cooldowns[difficulty]) or nil
			until availableAt and availableAt > getCurrentTimestamp()
				or Config.autoObby ~= true
				or tick() >= completionDeadline
			if availableAt and availableAt > getCurrentTimestamp() then
				activeStates.BGSI_Lite_ObbyCompletedAt = tick()
			end
			if activeStates.BGSI_Lite_ShouldOpenObbyChest() then
				activeStates.BGSI_Lite_ObbyChestActive = true
				activeStates.BGSI_Lite_LastQuestAutomationAt = tick()
				pauseNormalAutomation()
				local chestDeadline = tick() + 4
				repeat
					if not activeStates.BGSI_Lite_OpenObbyChest(difficulty, course) then
						task.wait(0.15)
					end
				until activeStates.BGSI_Lite_GetObbyKeyAmount(difficulty) <= 0
					or not activeStates.BGSI_Lite_ShouldOpenObbyChest()
					or tick() >= chestDeadline
			end
		end
		activeStates.BGSI_Lite_ObbyActive = false
		if not activeStates.BGSI_Lite_ObbyChestActive then
			resumeNormalAutomation()
		end
		return availableAt and availableAt > getCurrentTimestamp() or false
	end
	task.spawn(function()
		while isCurrentRun() do
			task.wait((Config.autoObby or activeStates.BGSI_Lite_ShouldOpenObbyChest()) and 0.25 or 0.85)
			if Config.autoObby and not isPriorityAutomationActive() then
				local runOk = pcall(activeStates.BGSI_Lite_RunSelectedObby)
				if not runOk then
					activeStates.BGSI_Lite_ObbyActive = false
					if not activeStates.BGSI_Lite_ObbyChestActive then
						resumeNormalAutomation()
					end
				end
			end
			if
				activeStates.BGSI_Lite_ShouldOpenObbyChest()
				and not activeStates.BGSI_Lite_ObbyActive
				and activeStates.BGSI_Lite_IsInObby()
			then
				local difficulty = activeStates.BGSI_Lite_CurrentObbyDifficulty
					or activeStates.BGSI_Lite_GetObbyDifficulty()
				local course = activeStates.BGSI_Lite_GetObbyCourse(difficulty)
				local keyAmount = activeStates.BGSI_Lite_GetObbyKeyAmount(difficulty)
				if course and keyAmount > 0 then
					pcall(activeStates.BGSI_Lite_OpenObbyChest, difficulty, course)
				elseif
					Config.autoObby == true
					and Config.autoObbyCycle == true
					and activeStates.BGSI_Lite_ObbyCompletedAt > 0
					and tick() - activeStates.BGSI_Lite_ObbyCompletedAt >= 2
				then
					pcall(activeStates.BGSI_Lite_LeaveObby)
				elseif
					Config.autoObbyCycle ~= true
					and activeStates.BGSI_Lite_ObbyCompletedAt > 0
					and tick() - activeStates.BGSI_Lite_ObbyCompletedAt >= 2
				then
					activeStates.BGSI_Lite_ObbyChestActive = false
					resumeNormalAutomation()
				end
			end
		end
	end)
	gameTab:AddToggle("AutoUseFragments", {
		Title = "Auto Use Fragments",
		Default = Config.autoUseFragments,
		Callback = function(isEnabled)
			Config.autoUseFragments = isEnabled
			saveConfig()
		end,
	})
	gameTab:AddSection("4x Egg Server Hop")
	gameTab:AddToggle("AutoHopLuckEgg", {
		Title = "Server Hop for 4x Egg (AA)",
		Default = Config.autoHopLuckEgg,
		Callback = function(isEnabled)
			Config.autoHopLuckEgg = isEnabled
			saveConfig()
		end,
	})
	gameTab:AddSection("Targeted Rift Server Hop")
	local targetRiftHopOptions = type(activeStates.BGSI_Lite_GetTargetRiftHopOptions) == "function"
			and activeStates.BGSI_Lite_GetTargetRiftHopOptions()
		or {}
	gameTab:AddDropdown("TargetRiftHopIds", {
		Title = "Target Rifts",
		Description = "Stay when any selected egg rift is present; otherwise keep hopping public servers.",
		Values = targetRiftHopOptions,
		Default = Config.targetRiftIds,
		Multi = true,
		Search = true,
		Callback = function(selectedRifts)
			local selectedSet = {}
			for riftKey, riftValue in pairs(type(selectedRifts) == "table" and selectedRifts or {}) do
				if type(riftKey) == "number" and type(riftValue) == "string" then
					selectedSet[riftValue] = true
				elseif type(riftKey) == "string" and riftValue == true then
					selectedSet[riftKey] = true
				elseif type(riftValue) == "string" then
					selectedSet[riftValue] = true
				end
			end
			Config.targetRiftIds = {}
			for _, riftId in ipairs(targetRiftHopOptions) do
				if selectedSet[riftId] then
					table.insert(Config.targetRiftIds, riftId)
				end
			end
			if type(activeStates.BGSI_Lite_ResetTargetRiftServerHistory) == "function" then
				activeStates.BGSI_Lite_ResetTargetRiftServerHistory()
			end
			saveConfig()
		end,
	})
	gameTab:AddToggle("AutoHopTargetRifts", {
		Title = "Server Hop for Selected Rifts",
		Description = "The 4x Egg server hopper takes priority when both hop options are enabled.",
		Default = Config.autoHopTargetRifts,
		Callback = function(isEnabled)
			Config.autoHopTargetRifts = isEnabled == true
			if not isEnabled then
				activeStates.BGSI_Lite_TargetRiftHopTarget = nil
				activeStates.BGSI_Lite_TargetRiftHopInProgress = false
			end
			saveConfig()
		end,
	})
	gameTab:AddSection("Shops")

	local cachedShopData = nil

	local function getShopData()
		if type(cachedShopData) == "table" then
			return cachedShopData
		end

		local ok, shops = pcall(function()
			return require(ReplicatedStorage.Shared.Data.Shops)
		end)

		if ok and type(shops) == "table" then
			cachedShopData = shops
		else
			cachedShopData = {}
		end

		return cachedShopData
	end

	local function refreshShopData()
		cachedShopData = nil
		return getShopData()
	end

	function getSelectedValues(selectionTable)
		local selectedValues = {}

		if type(selectionTable) ~= "table" then
			return selectedValues
		end

		local hasArrayValues = false
		for _, selectedName in ipairs(selectionTable) do
			hasArrayValues = true
			if type(selectedName) == "string" and selectedName ~= "" then
				table.insert(selectedValues, selectedName)
			end
		end

		if hasArrayValues then
			return selectedValues
		end

		for selectedName, isSelected in pairs(selectionTable) do
			if isSelected and type(selectedName) == "string" and selectedName ~= "" then
				table.insert(selectedValues, selectedName)
			end
		end

		table.sort(selectedValues)
		return selectedValues
	end

	local function getSortedShopNames()
		local shopNames = {}
		local shops = getShopData()

		for shopName in pairs(shops) do
			if type(shopName) == "string" and shopName ~= "" then
				table.insert(shopNames, shopName)
			end
		end

		table.sort(shopNames)
		return shopNames
	end

	local function getShopItemName(shopItem, depth)
		depth = depth or 0
		if depth > 4 or shopItem == nil then
			return nil
		end

		if type(shopItem) == "string" then
			return shopItem
		end

		if type(shopItem) ~= "table" then
			return tostring(shopItem)
		end

		local itemData = shopItem.Item
		if type(itemData) == "string" then
			return itemData
		elseif type(itemData) == "table" then
			local productData = itemData.Product
			if type(productData) == "string" then
				return productData
			elseif type(productData) == "table" then
				local nestedProductName = getShopItemName(productData, depth + 1)
				if nestedProductName then
					return nestedProductName
				end
			end

			local directItemName = itemData.Name or itemData.Item or itemData.ItemName or itemData.Id
			if type(directItemName) == "string" then
				return directItemName
			elseif directItemName ~= nil then
				return tostring(directItemName)
			end

			if itemData[1] ~= nil then
				return getShopItemName(itemData[1], depth + 1)
			end
		end

		local directProduct = shopItem.Product
		if type(directProduct) == "string" then
			return directProduct
		elseif type(directProduct) == "table" then
			local directProductName = getShopItemName(directProduct, depth + 1)
			if directProductName then
				return directProductName
			end
		end

		local directName = shopItem.Name or shopItem.ItemName or shopItem.Id
		if type(directName) == "string" then
			return directName
		elseif directName ~= nil then
			return tostring(directName)
		end

		if shopItem[1] ~= nil then
			return getShopItemName(shopItem[1], depth + 1)
		end

		return nil
	end

	local function eachShopSlot(shopName, shopData, callback)
		if type(shopData) ~= "table" then
			return
		end

		for _, listName in ipairs({ "PermanentItems", "RandomItems", "Items" }) do
			local itemList = shopData[listName]
			if type(itemList) == "table" then
				for slotIndex, shopItem in ipairs(itemList) do
					callback(shopName, slotIndex, shopItem)
				end

				for slotIndex, shopItem in pairs(itemList) do
					if type(slotIndex) ~= "number" or slotIndex > #itemList then
						callback(shopName, slotIndex, shopItem)
					end
				end
			end
		end

		if type(shopData.Slots) == "table" then
			for slotIndex, shopItem in pairs(shopData.Slots) do
				callback(shopName, tonumber(slotIndex) or slotIndex, shopItem)
			end
		end
	end

	local function getSortedShopItemNames()
		local itemNames = {}
		local seenItems = {}
		local shops = getShopData()

		for shopName, shopData in pairs(shops) do
			if type(shopName) == "string" then
				eachShopSlot(shopName, shopData, function(_, _, shopItem)
					local itemName = getShopItemName(shopItem)
					if type(itemName) == "string" and itemName ~= "" and not seenItems[itemName] then
						seenItems[itemName] = true
						table.insert(itemNames, itemName)
					end
				end)
			end
		end

		table.sort(itemNames)
		return itemNames
	end

	local function resolveShopItemSelection(selectedItemName)
		if type(selectedItemName) ~= "string" or selectedItemName == "" then
			return nil, nil
		end

		local directShopName, directSlot = selectedItemName:match("^(.-)%s*|%s*Slot%s*#?(%d+)$")
		if directShopName and directSlot then
			return directShopName, tonumber(directSlot)
		end

		local selectedLower = string.lower(selectedItemName)
		local shops = getShopData()

		for shopName, shopData in pairs(shops) do
			if type(shopName) == "string" then
				local foundShop, foundSlot = nil, nil
				eachShopSlot(shopName, shopData, function(currentShopName, slotIndex, shopItem)
					if foundShop then
						return
					end

					local itemName = getShopItemName(shopItem)
					if type(itemName) == "string" and string.lower(itemName) == selectedLower then
						foundShop = currentShopName
						foundSlot = slotIndex
					end
				end)

				if foundShop and foundSlot ~= nil then
					return foundShop, foundSlot
				end
			end
		end

		return nil, nil
	end

	local function resolveAllShopItemSelections(selectedItemNames)
		local selectedLookup = {}
		for _, selectedItemName in ipairs(selectedItemNames) do
			if type(selectedItemName) == "string" and selectedItemName ~= "" then
				selectedLookup[string.lower(selectedItemName)] = true
			end
		end

		local matches = {}
		for shopName, shopData in pairs(getShopData()) do
			if type(shopName) == "string" then
				eachShopSlot(shopName, shopData, function(currentShopName, slotIndex, shopItem)
					local itemName = getShopItemName(shopItem)
					if type(itemName) == "string" and selectedLookup[string.lower(itemName)] then
						table.insert(matches, {
							shop = currentShopName,
							slot = slotIndex,
							item = itemName,
						})
					end
				end)
			end
		end
		table.sort(matches, function(left, right)
			return tostring(left.shop) .. "|" .. tostring(left.slot)
				< tostring(right.shop) .. "|" .. tostring(right.slot)
		end)
		return matches
	end

	local function getShopSlotCount(shopName)
		local shopData = getShopData()[shopName]
		if type(shopData) ~= "table" then
			return 3
		end

		local slotCount = tonumber(shopData.SlotCount)
		if slotCount and slotCount >= 1 then
			return math.floor(slotCount)
		end

		for _, listName in ipairs({ "RandomItems", "PermanentItems", "Items" }) do
			if type(shopData[listName]) == "table" and #shopData[listName] > 0 then
				return #shopData[listName]
			end
		end

		if type(shopData.Slots) == "table" then
			local highestSlot = 0
			for slotIndex in pairs(shopData.Slots) do
				highestSlot = math.max(highestSlot, tonumber(slotIndex) or 0)
			end
			if highestSlot > 0 then
				return highestSlot
			end
		end

		return 3
	end

	local shopDropdown
	local shopItemDropdown
	local fragmentShopDropdown

	local function getSortedFragmentNames()
		local fragmentNames = {}
		local seenFragments = {}
		local function addFragment(fragmentName)
			if type(fragmentName) ~= "string" or fragmentName == "" then
				return
			end
			if not string.find(string.lower(fragmentName), "fragment", 1, true) then
				fragmentName ..= " Fragment"
			end
			local fragmentKey = string.lower(fragmentName)
			if not seenFragments[fragmentKey] then
				seenFragments[fragmentKey] = true
				table.insert(fragmentNames, fragmentName)
			end
		end

		for fragmentKey, fragmentType in pairs(fragmentTypes) do
			addFragment(type(fragmentType) == "string" and fragmentType or fragmentKey)
		end
		for _, itemName in ipairs(getSortedShopItemNames()) do
			if string.find(string.lower(itemName), "fragment", 1, true) then
				addFragment(itemName)
			end
		end

		table.sort(fragmentNames)
		return fragmentNames
	end
	local function getLiveShopSlots(shopName, playerData)
		local shopUtil = activeStates.BGSI_Lite_ShopUtil
		if not shopUtil then
			local ok, loaded = pcall(require, ReplicatedStorage.Shared.Utils.ShopUtil)
			if ok then shopUtil = loaded; activeStates.BGSI_Lite_ShopUtil = loaded end
		end
		local shopState = type(playerData) == "table" and type(playerData.Shops) == "table"
			and playerData.Shops[shopName] or nil
		if type(shopUtil) ~= "table" or type(shopState) ~= "table" then return {} end
		local ok, items, stocks = pcall(shopUtil.GetItemsData, shopUtil, shopName, LocalPlayer, playerData)
		if not ok or type(items) ~= "table" or type(stocks) ~= "table" then return {} end
		local unlockOk, unlocked = pcall(shopUtil.GetUnlockedSlots, shopUtil, playerData, #items)
		unlocked = unlockOk and tonumber(unlocked) or #items
		local slots = {}
		for slot, item in ipairs(items) do
			local bought = type(shopState.Bought) == "table" and tonumber(shopState.Bought[slot]) or 0
			local available = math.max(0, (tonumber(stocks[slot]) or 0) - (bought or 0))
			if slot <= unlocked and available > 0 and type(item) == "table" then
				table.insert(slots, { Shop = shopName, Slot = slot, Item = item,
					Name = getShopItemName(item.Product), Available = available })
			end
		end
		return slots
	end
	local function tryFreeShopReroll(shopName, playerData)
		local shopData = getShopData()[shopName]
		local shopUtil = activeStates.BGSI_Lite_ShopUtil
		if type(shopData) ~= "table" or shopData.Rerollable ~= true
			or type(shopUtil) ~= "table" or type(playerData) ~= "table" then return false end
		local oldState = type(playerData.Shops) == "table" and playerData.Shops[shopName] or nil
		if type(oldState) ~= "table" then return false end
		local ok, maxRerolls = pcall(shopUtil.GetMaxFreeRerolls, shopUtil, playerData)
		local used = type(playerData.ShopFreeRerolls) == "table"
			and tonumber(playerData.ShopFreeRerolls.Used) or 0
		if not ok or used >= (tonumber(maxRerolls) or 0) then return false end
		local previousPeriod, previousBegan = oldState.Period, oldState.Began
		local sent = pcall(function() remoteEvent:FireServer("ShopFreeReroll", shopName) end)
		if not sent then return false end
		local deadline = tick() + 2
		repeat
			task.wait(0.1)
			local updated = profileStore:IsReady() and profileStore:Get() or nil
			local state = type(updated) == "table" and type(updated.Shops) == "table"
				and updated.Shops[shopName] or nil
			local newUsed = type(updated) == "table" and type(updated.ShopFreeRerolls) == "table"
				and tonumber(updated.ShopFreeRerolls.Used) or used
			if type(state) == "table" and (state.Period ~= previousPeriod
				or state.Began ~= previousBegan or newUsed > used) then return true end
		until tick() >= deadline or not isCurrentRun()
		return false
	end
	activeStates.BGSI_Lite_SmartShopRestock = function(itemType, itemName, itemLevel, allowFreeReroll)
		if type(itemName) ~= "string" or itemName == "" then
			return 0
		end
		if not activeStates.BGSI_Lite_ShopUtil then
			pcall(function()
				activeStates.BGSI_Lite_ShopUtil = require(ReplicatedStorage.Shared.Utils.ShopUtil)
			end)
		end
		local shopUtil = activeStates.BGSI_Lite_ShopUtil
		local shops = getShopData()
		local playerData = profileStore:IsReady() and profileStore:Get() or nil
		if type(shopUtil) ~= "table" or type(shops) ~= "table" or type(playerData) ~= "table" then
			return 0
		end
		local function matchesProduct(product)
			return type(product) == "table"
				and tostring(product.Type or "") == tostring(itemType or product.Type or "")
				and tostring(product.Name or "") == itemName
				and (itemLevel == nil or tonumber(product.Level) == tonumber(itemLevel))
		end
		local function getOwnedAmount()
			local amountOk, ownedAmount = pcall(itemUtil.GetOwnedAmount, itemUtil, playerData, {
				Type = itemType,
				Name = itemName,
				Level = itemLevel,
			})
			return amountOk and math.max(0, math.floor(tonumber(ownedAmount) or 0)) or 0
		end
		local targetShopNames = {}
		for shopName, shopData in pairs(shops) do
			if
				type(shopName) == "string"
				and type(shopData) == "table"
				and type(playerData.Shops) == "table"
				and type(playerData.Shops[shopName]) == "table"
			then
				local canStockTarget = false
				eachShopSlot(shopName, shopData, function(_, _, shopItem)
					if getShopItemName(shopItem) == itemName then
						canStockTarget = true
					end
				end)
				if canStockTarget then
					table.insert(targetShopNames, shopName)
				end
			end
		end
		local function buyCurrentStock()
			local purchasedAmount = 0
			local targetVisible = false
			for _, shopName in ipairs(targetShopNames) do
				playerData = profileStore:IsReady() and profileStore:Get() or playerData
				local shopState = type(playerData.Shops) == "table" and playerData.Shops[shopName] or nil
				local itemsOk, itemsData, itemStocks = pcall(
					shopUtil.GetItemsData,
					shopUtil,
					shopName,
					LocalPlayer,
					playerData
				)
				local unlockedOk, unlockedSlots = pcall(
					shopUtil.GetUnlockedSlots,
					shopUtil,
					playerData,
					type(itemsData) == "table" and #itemsData or 0
				)
				if itemsOk and type(itemsData) == "table" and type(itemStocks) == "table" then
					for slotIndex, shopItem in pairs(itemsData) do
						local product = type(shopItem) == "table" and shopItem.Product or nil
						local boughtAmount = type(shopState) == "table"
								and type(shopState.Bought) == "table"
								and tonumber(shopState.Bought[slotIndex])
							or 0
						local availableStock = math.max(0, (tonumber(itemStocks[slotIndex]) or 0) - boughtAmount)
						if
							matchesProduct(product)
							and availableStock > 0
							and (not unlockedOk or (tonumber(slotIndex) or math.huge) <= unlockedSlots)
						then
							targetVisible = true
							local canAffordOk, canAfford = pcall(
								itemUtil.CanAfford,
								itemUtil,
								playerData,
								shopItem.Cost
							)
							if not canAffordOk or canAfford then
								local amountBefore = getOwnedAmount()
								remoteEvent:FireServer("BuyShopItem", shopName, slotIndex, false)
								task.wait(0.35)
								playerData = profileStore:IsReady() and profileStore:Get() or playerData
								purchasedAmount += math.max(0, getOwnedAmount() - amountBefore)
							end
						end
					end
				end
			end
			return purchasedAmount, targetVisible
		end
		local purchasedAmount, targetVisible = buyCurrentStock()
		if purchasedAmount > 0 or targetVisible or allowFreeReroll ~= true then
			return purchasedAmount
		end
		local maxRerollsOk, maxFreeRerolls =
			pcall(shopUtil.GetMaxFreeRerolls, shopUtil, playerData)
		maxFreeRerolls = maxRerollsOk and math.max(0, math.floor(tonumber(maxFreeRerolls) or 0)) or 0
		for _, shopName in ipairs(targetShopNames) do
			playerData = profileStore:IsReady() and profileStore:Get() or playerData
			local usedFreeRerolls = type(playerData.ShopFreeRerolls) == "table"
					and math.max(0, math.floor(tonumber(playerData.ShopFreeRerolls.Used) or 0))
				or 0
			if
				usedFreeRerolls >= maxFreeRerolls
				or type(shops[shopName]) ~= "table"
				or shops[shopName].Rerollable ~= true
			then
				continue
			end
			if not tryFreeShopReroll(shopName, playerData) then
				continue
			end
			local rerollPurchases, rerollTargetVisible = buyCurrentStock()
			purchasedAmount += rerollPurchases
			if rerollPurchases > 0 or rerollTargetVisible then
				break
			end
		end
		return purchasedAmount
	end

	local function refreshShopDropdowns()
		refreshShopData()

		local shopNames = getSortedShopNames()
		local shopItemNames = getSortedShopItemNames()
		local fragmentNames = getSortedFragmentNames()

		if #shopNames == 0 then
			shopNames = { "No shops found" }
		end
		if #shopItemNames == 0 then
			shopItemNames = { "No shop items found" }
		end
		if #fragmentNames == 0 then
			fragmentNames = { "No fragments found" }
		end

		fireRemoteEventRepeatedly(shopDropdown, shopNames)
		fireRemoteEventRepeatedly(shopItemDropdown, shopItemNames)
		fireRemoteEventRepeatedly(fragmentShopDropdown, fragmentNames)
	end

	gameTab:AddButton({
		Title = "Load Shop Lists",
		Description = "Loads shop names and item names into the dropdowns below.",
		Callback = function()
			refreshShopDropdowns()
		end,
	})

	shopDropdown = gameTab:AddDropdown("SelectedShops", {
		Title = "Select Shops - leave empty for all",
		Values = { "Click Load Shop Lists" },
		Default = Config.selectedShops or {},
		Multi = true,
		Search = true,
		Callback = function(selectedShops)
			Config.selectedShops = selectedShops or {}
			saveConfig()
		end,
	})

	shopItemDropdown = gameTab:AddDropdown("SelectedShopItems", {
		Title = "Select Shop Items - optional",
		Values = { "Click Load Shop Lists" },
		Default = Config.selectedShopItems or {},
		Multi = true,
		Search = true,
		Callback = function(selectedShopItems)
			Config.selectedShopItems = selectedShopItems or {}
			saveConfig()
		end,
	})

	fragmentShopDropdown = gameTab:AddDropdown("SelectedFragments", {
		Title = "Fragments to Buy",
		Description = "Select one or more fragments. Leave empty to buy every fragment sold by a shop.",
		Values = getSortedFragmentNames(),
		Default = Config.selectedFragments or {},
		Multi = true,
		Search = true,
		Callback = function(selectedFragments)
			Config.selectedFragments = selectedFragments or {}
			saveConfig()
		end,
	})
	task.defer(refreshShopDropdowns)

	gameTab:AddToggle("AutoBuyFragments", {
		Title = "Auto Buy Fragments",
		Description = "Safely buys the selected fragments from any shop that currently sells them.",
		Default = Config.autoBuyFragments ~= false,
		Callback = function(enabled)
			Config.autoBuyFragments = enabled == true
			saveConfig()
		end,
	})
	gameTab:AddInput("ShopBuyInterval", {
		Title = "Buy Delay",
		Default = tostring(Config.shopInterval or 1),
		Numeric = true,
		Callback = function(intervalText)
			local buyDelay = tonumber(intervalText)
			if buyDelay then
				Config.shopInterval = math.clamp(buyDelay, 0.1, 60)
				saveConfig()
			end
		end,
	})

	gameTab:AddToggle("AutoBuyShops", {
		Title = "Auto Buy Shops",
		Description = "Buys affordable live stock from selected shops. Selected items may use available free rerolls.",
		Default = Config.autoBuyShops == true,
		Callback = function(enabled)
			Config.autoBuyShops = enabled == true
			saveConfig()
		end,
	})

	local lastShopBuyAttempt = {}
	local lastShopRerollAttempt = {}
	task.spawn(function()
		while isCurrentRun() do
			task.wait(Config.autoBuyShops == true and math.max(0.1, tonumber(Config.shopInterval) or 1) or 0.85)
			if Config.autoBuyShops ~= true or Config.safeMode == true then continue end
			pcall(function()
				local playerData = profileStore:IsReady() and profileStore:Get() or nil
				if type(playerData) ~= "table" then return end
				local selectedShops = getSelectedValues(Config.selectedShops or {})
				if #selectedShops == 0 then selectedShops = getSortedShopNames() end
				local selectedItems = getSelectedValues(Config.selectedShopItems or {})
				local wanted = {}
				for _, name in ipairs(selectedItems) do wanted[string.lower(name)] = true end
				local candidates = {}
				local rerollShops = {}
				for _, shopName in ipairs(selectedShops) do
					if type(getShopData()[shopName]) == "table" then
						local targetVisible = false
						for _, slot in ipairs(getLiveShopSlots(shopName, playerData)) do
							if #selectedItems == 0 or (slot.Name and wanted[string.lower(slot.Name)]) then
								targetVisible = true
								local affordOk, canAfford = pcall(itemUtil.CanAfford, itemUtil, playerData, slot.Item.Cost)
								if affordOk and canAfford then table.insert(candidates, slot) end
							end
						end
						if #selectedItems > 0 and not targetVisible then
							local canStockTarget = false
							eachShopSlot(shopName, getShopData()[shopName], function(_, _, item)
								local name = getShopItemName(item)
								if name and wanted[string.lower(name)] then canStockTarget = true end
							end)
							if canStockTarget then table.insert(rerollShops, shopName) end
						end
					end
				end
				if #candidates > 0 then
					table.sort(candidates, function(left, right)
						return left.Shop .. "|" .. left.Slot < right.Shop .. "|" .. right.Slot
					end)
					for _, slot in ipairs(candidates) do
						local key = slot.Shop .. "|" .. slot.Slot
						if tick() - (lastShopBuyAttempt[key] or 0) >= 2 then
							lastShopBuyAttempt[key] = tick()
							remoteEvent:FireServer("BuyShopItem", slot.Shop, slot.Slot, false)
							break
						end
					end
				elseif #rerollShops > 0 then
					for _, shopName in ipairs(rerollShops) do
						if tick() - (lastShopRerollAttempt[shopName] or 0) >= 5 then
							lastShopRerollAttempt[shopName] = tick()
							if tryFreeShopReroll(shopName, playerData) then break end
						end
					end
				end
			end)
		end
	end)

	task.spawn(function()
		while isCurrentRun() do
			task.wait(Config.autoBuyFragments ~= false and math.max(0.75, tonumber(Config.shopInterval) or 1) or 0.85)
			if Config.autoBuyFragments == false or Config.safeMode == true then
				continue
			end
			pcall(function()
				local playerData = profileStore:IsReady() and profileStore:Get() or nil
				if type(playerData) ~= "table" then return end
				local selected = getSelectedValues(Config.selectedFragments or {})
				local wanted = {}
				for _, name in ipairs(selected) do wanted[string.lower(name)] = true end
				for _, shopName in ipairs(getSortedShopNames()) do
					for _, slot in ipairs(getLiveShopSlots(shopName, playerData)) do
						local name = slot.Name
						if name and string.find(string.lower(name), "fragment", 1, true)
							and (#selected == 0 or wanted[string.lower(name)]) then
							local key = shopName .. "|" .. slot.Slot
							local affordable, canAfford = pcall(itemUtil.CanAfford, itemUtil, playerData, slot.Item.Cost)
							if affordable and canAfford and tick() - (lastShopBuyAttempt[key] or 0) >= 2 then
								lastShopBuyAttempt[key] = tick()
								remoteEvent:FireServer("BuyShopItem", shopName, slot.Slot, false)
								return
							end
						end
					end
				end
			end)
		end
	end)
	gameTab:AddSection("Mystery Boxes")
	local function getGiftNames()
		local giftNames = {}
		if type(giftData) == "table" then
			for loopSlotCZ, scriptStateAEU in pairs(giftData) do
				if
					type(loopSlotCZ) == "string"
					and type(scriptStateAEU) == "table"
					and scriptStateAEU.Type == "Gift"
				then
					table.insert(giftNames, loopSlotCZ)
				end
			end
		end
		table.sort(giftNames)
		if #giftNames == 0 then
			giftNames = {
				"Mystery Box",
				"Admin Mystery Box",
				"OG Mystery Box",
			}
		end
		return giftNames
	end
	-- Multi-select so regular, Condensed and Guild boxes can all be opened in rotation.
	-- selectedMysteryBox (single) stays in sync with the first pick for older code paths
	-- such as the pearl quest, which still read it.
	if type(Config.selectedMysteryBoxes) ~= "table" then
		Config.selectedMysteryBoxes = {}
	end
	if
		#getSelectedValues(Config.selectedMysteryBoxes) == 0
		and type(Config.selectedMysteryBox) == "string"
		and Config.selectedMysteryBox ~= ""
	then
		Config.selectedMysteryBoxes = { Config.selectedMysteryBox }
	end
	local mysteryBoxDropdown = gameTab:AddDropdown("SelectedMysteryBoxes", {
		Title = "Boxes To Open",
		Description = "Pick any mix, e.g. Mystery Box and Condensed Mystery Box. Auto Open Box takes turns between the ones you own.",
		Values = getGiftNames(),
		Default = getSelectedValues(Config.selectedMysteryBoxes),
		Multi = true,
		Search = true,
		Callback = function(selectedBoxes)
			Config.selectedMysteryBoxes = getSelectedValues(selectedBoxes)
			Config.selectedMysteryBox = Config.selectedMysteryBoxes[1] or "Mystery Box"
			saveConfig()
		end,
	})
	gameTab:AddButton({
		Title = "Load Mystery Boxes",
		Callback = function()
			fireRemoteEventRepeatedly(mysteryBoxDropdown, getGiftNames())
		end,
	})
	task.defer(function()
		fireRemoteEventRepeatedly(mysteryBoxDropdown, getGiftNames())
	end)
	gameTab:AddToggle("AutoOpenMystery", {
		Title = "Auto Open Box",
		Default = Config.autoOpenMystery,
		Callback = function(scriptStateRA)
			Config.autoOpenMystery = scriptStateRA
			saveConfig()
		end,
	})
	gameTab:AddInput("AutoOpenMysteryDelay", {
		Title = "Open Delay",
		Default = tostring(Config.autoOpenMysteryDelay),
		Numeric = true,
		Callback = function(scriptStateIC)
			local parsedDelayValue = tonumber(scriptStateIC)
			if parsedDelayValue then
				Config.autoOpenMysteryDelay = math.clamp(parsedDelayValue, 0.1, 60)
				saveConfig()
			end
		end,
	})
	-- Box Condenser (game update 72), from Shared.Data.BoxCondenser: 100 Mystery Boxes +
	-- 500 Gems -> 1 Condensed Mystery Box. The machine is
	-- workspace.Worlds["The Overworld"].Islands.Zen.Island.BoxCondenser, and the game's
	-- own buttons fire CondenseMysteryBox(false) for one craft or (true) for craft-all.
	activeStates.BGSI_Lite_InstallBoxCondenser = function()
		local condenserData = { Input = "Mystery Box", Output = "Condensed Mystery Box", Boxes = 100, Gems = 500 }
		pcall(function()
			local data = require(ReplicatedStorage.Shared.Data.BoxCondenser)
			if type(data) == "table" and data.Input and data.Output then
				condenserData = data
			end
		end)
		local boxesPerCraft = math.max(1, tonumber(condenserData.Boxes) or 100)
		local gemsPerCraft = math.max(1, tonumber(condenserData.Gems) or 500)

		local function getOwnedPowerup(powerupName)
			local owned = 0
			pcall(function()
				local playerData = profileStore:IsReady() and profileStore:Get() or nil
				owned = tonumber(itemUtil:GetOwnedAmount(playerData, { Type = "Powerup", Name = powerupName })) or 0
			end)
			return math.max(0, math.floor(owned))
		end

		local function getCraftCounts()
			local boxes = getOwnedPowerup(condenserData.Input)
			local gems = getCurrentGems()
			local reserve = math.max(0, tonumber(Config.condenserGemReserve) or 0)
			local byBoxes = math.floor(boxes / boxesPerCraft)
			local affordable = math.min(byBoxes, math.floor(gems / gemsPerCraft))
			local allowed = math.min(byBoxes, math.floor(math.max(0, gems - reserve) / gemsPerCraft))
			return allowed, affordable, boxes
		end
		activeStates.BGSI_Lite_CanCondenseMysteryBoxes = function()
			return (getCraftCounts()) > 0
		end

		local function getCondenserCFrame()
			local ok, targetCFrame = pcall(function()
				local machine = workspace.Worlds["The Overworld"].Islands.Zen.Island.BoxCondenser
				return activeStates.BGSI_Lite_GetInstanceTargetCFrame(machine:FindFirstChild("Activation") or machine)
			end)
			return ok and typeof(targetCFrame) == "CFrame" and targetCFrame or nil
		end

		-- Same snap-fire-snap-back trick as selling: the player is back where they were in
		-- the same frame, so Auto Hatch keeps its spot at the egg.
		local function fireAtCondenser(craftAll)
			local character = LocalPlayer.Character
			local rootPart = character and character:FindFirstChild("HumanoidRootPart")
			local originalCFrame = rootPart and rootPart.CFrame
			local machineCFrame = getCondenserCFrame()
			if rootPart and machineCFrame then
				rootPart.CFrame = machineCFrame
			end
			pcall(activeStates.BGSI_Lite_FireGameRemote, "CondenseMysteryBox", craftAll == true)
			if rootPart and machineCFrame and originalCFrame then
				rootPart.CFrame = originalCFrame
			end
		end

		local function waitForOutputAbove(previousAmount, seconds)
			local deadline = tick() + seconds
			repeat
				task.wait(0.1)
			until getOwnedPowerup(condenserData.Output) > previousAmount or tick() >= deadline
			return getOwnedPowerup(condenserData.Output) > previousAmount
		end

		activeStates.BGSI_Lite_CondenseMysteryBoxes = function()
			if Config.safeMode == true or activeStates.BGSI_Lite_CondenserBusy then
				return 0
			end
			local allowed, affordable = getCraftCounts()
			if allowed <= 0 then
				return 0
			end
			activeStates.BGSI_Lite_CondenserBusy = true
			local startAmount = getOwnedPowerup(condenserData.Output)
			pcall(function()
				if allowed >= affordable then
					-- Craft-all spends every Gem it can, so only use it when the reserve
					-- doesn't hold anything back.
					fireAtCondenser(true)
					waitForOutputAbove(startAmount, 3)
				else
					for _ = 1, allowed do
						if Config.safeMode == true or not isCurrentRun() then
							break
						end
						local before = getOwnedPowerup(condenserData.Output)
						fireAtCondenser(false)
						if not waitForOutputAbove(before, 2) then
							break
						end
					end
				end
			end)
			activeStates.BGSI_Lite_CondenserBusy = false
			return math.max(0, getOwnedPowerup(condenserData.Output) - startAmount)
		end

		gameTab:AddSection("Box Condenser")
		local condenserStatus = gameTab:AddParagraph({
			Title = "Condenser",
			Content = "Loading...",
		})
		gameTab:AddToggle("AutoCondenseMysteryBoxes", {
			Title = "Auto Condense Mystery Boxes",
			Description = "Turns every 100 Mystery Boxes into 1 Condensed Mystery Box (500 Gems each). Never takes your Gems below Keep Gems.",
			Default = Config.autoCondenseMysteryBoxes,
			Callback = function(isEnabled)
				Config.autoCondenseMysteryBoxes = isEnabled == true
				saveConfig()
			end,
		})
		gameTab:AddInput("CondenserGemReserve", {
			Title = "Keep Gems",
			Description = "Condensing stops before your Gems would drop below this.",
			Default = tostring(math.max(0, tonumber(Config.condenserGemReserve) or 0)),
			Numeric = true,
			Callback = function(value)
				local reserve = tonumber(value)
				if reserve then
					Config.condenserGemReserve = math.max(0, math.floor(reserve))
					saveConfig()
				end
			end,
		})
		gameTab:AddButton({
			Title = "Condense Now",
			Description = "Condenses as many as you can afford right now.",
			Callback = function()
				task.spawn(function()
					local made = activeStates.BGSI_Lite_CondenseMysteryBoxes()
					pcall(function()
						Interface:Notify({
							Title = "Box Condenser",
							Content = made > 0 and ("Made " .. tostring(made) .. " Condensed Mystery Box(es).")
								or "Nothing to condense (need 100 Mystery Boxes and 500 spare Gems).",
							Duration = 4,
						})
					end)
				end)
			end,
		})

		task.spawn(function()
			while isCurrentRun() do
				pcall(function()
					local allowed, _, boxes = getCraftCounts()
					condenserStatus:SetDesc(
						string.format(
							"Mystery Boxes: %d  -  Condensed: %d\nCan condense now: %d (%d boxes + %d Gems each)",
							boxes,
							getOwnedPowerup(condenserData.Output),
							allowed,
							boxesPerCraft,
							gemsPerCraft
						)
					)
				end)
				if Config.autoCondenseMysteryBoxes == true and Config.safeMode ~= true then
					pcall(activeStates.BGSI_Lite_CondenseMysteryBoxes)
				end
				task.wait(4)
			end
		end)
	end
	xpcall(activeStates.BGSI_Lite_InstallBoxCondenser, function(installError)
		warn("[1rzHub Lite] Box Condenser failed to load: " .. tostring(installError))
	end)
	local playtimeRewardsData
	pcall(function()
		playtimeRewardsData = require(ReplicatedStorage.Shared.Data.Playtime)
	end)
	task.spawn(function()
		while isCurrentRun() do
			task.wait(Config.autoPlaytime and 5 or 0.85)
			if Config.autoPlaytime then
				pcall(function()
					local playerData = profileStore:IsReady() and profileStore:Get() or nil
					local rewards = type(playerData) == "table" and playerData.PlaytimeRewards
					local gifts = type(playtimeRewardsData) == "table" and playtimeRewardsData.Gifts
					if type(rewards) ~= "table" or type(gifts) ~= "table" then return end
					local elapsed = getCurrentTimestamp() - (tonumber(rewards.Start) or math.huge)
					for rewardIndex, gift in pairs(gifts) do
						if type(rewardIndex) == "number" and type(gift) == "table"
							and elapsed >= (tonumber(gift.Time) or math.huge)
							and (type(rewards.Claimed) ~= "table" or rewards.Claimed[tostring(rewardIndex)] == nil)
						then
							remoteFunction:InvokeServer("ClaimPlaytime", rewardIndex)
							break
						end
					end
				end)
			end
		end
	end)
	task.spawn(function()
		while isCurrentRun() do
			task.wait((Config.autoDailyRewards or Config.autoWheelSpin) and 5 or 0.85)
			if Config.autoDailyRewards or Config.autoWheelSpin then
				pcall(activeStates.BGSI_Lite_ClaimDailyAndWheelRewards)
			end
		end
	end)
	task.spawn(function()
		local searchStartedAt = tick()
		local lastDetectedEggName
		while isCurrentRun() do
			task.wait(Config.autoHopLuckEgg and 2 or 0.85)
			if not Config.autoHopLuckEgg then
				activeStates.BGSI_Lite_LuckEggHopTarget = nil
				activeStates.BGSI_Lite_LuckEggHopInProgress = false
				searchStartedAt = tick()
				continue
			end
			local detectedEggName = activeStates.BGSI_Lite_FindLuckEggName()
			if detectedEggName then
				if detectedEggName ~= lastDetectedEggName then
					print("[" .. LocalPlayer.Name .. "] Found " .. detectedEggName .. ". Staying in this server.")
				end
				lastDetectedEggName = detectedEggName
				searchStartedAt = tick()
			elseif tick() - searchStartedAt >= 12 then
				lastDetectedEggName = nil
				activeStates.BGSI_Lite_HopForLuckEgg()
				searchStartedAt = tick()
			end
		end
	end)
	task.spawn(function()
		local searchStartedAt = tick()
		local lastDetectedRiftName
		while isCurrentRun() do
			task.wait(Config.autoHopTargetRifts and 2 or 0.85)
			if not Config.autoHopTargetRifts then
				activeStates.BGSI_Lite_TargetRiftHopTarget = nil
				activeStates.BGSI_Lite_TargetRiftHopInProgress = false
				lastDetectedRiftName = nil
				searchStartedAt = tick()
				continue
			end
			local selectionKey = type(activeStates.BGSI_Lite_GetTargetRiftSelectionKey) == "function"
					and activeStates.BGSI_Lite_GetTargetRiftSelectionKey()
				or ""
			if selectionKey == "" or Config.autoHopLuckEgg == true then
				lastDetectedRiftName = nil
				searchStartedAt = tick()
				continue
			end
			local targetedRift = type(activeStates.BGSI_Lite_FindTargetedHopRift) == "function"
					and activeStates.BGSI_Lite_FindTargetedHopRift()
				or nil
			if targetedRift then
				if targetedRift.Name ~= lastDetectedRiftName then
					print("[" .. LocalPlayer.Name .. "] Found selected rift " .. targetedRift.Name .. ". Staying in this server.")
				end
				lastDetectedRiftName = targetedRift.Name
				activeStates.BGSI_Lite_TargetRiftHopTarget = nil
				searchStartedAt = tick()
			elseif tick() - searchStartedAt >= 12 then
				lastDetectedRiftName = nil
				if type(activeStates.BGSI_Lite_HopForTargetRift) == "function" then
					activeStates.BGSI_Lite_HopForTargetRift()
				end
				searchStartedAt = tick()
			end
		end
	end)
	task.spawn(function()
		local previousHatchCount
		local previousSampleTime = tick()
		while isCurrentRun() do
			task.wait(5)
			-- Keep local hatch telemetry current for the live Discord webhook.
			local playerData
			pcall(function()
				if profileStore and profileStore:IsReady() then
					playerData = profileStore:Get()
				end
			end)
				local currentHatchCount = playerData and playerData.Stats and tonumber(playerData.Stats.Hatches) or 0
				local currentSampleTime = tick()
				local elapsedTime = math.max(currentSampleTime - previousSampleTime, 0.001)
				local hatchRate = previousHatchCount
						and math.max(0, math.floor(((currentHatchCount - previousHatchCount) / elapsedTime) * 60 + 0.5))
					or 0
				local formattedHatchRate = tostring(hatchRate)
				while true do
					local formattedValue, replacementCount = formattedHatchRate:gsub("^(-?%d+)(%d%d%d)", "%1,%2")
					formattedHatchRate = formattedValue
					if replacementCount == 0 then
						break
					end
				end
				local lastHatchRequestAt = tonumber(activeStates.BGSI_Lite_LastHatchRequestAt) or 0
				local lastHatchEventAt = tonumber(activeStates.BGSI_Lite_LastHatchEventAt) or 0
				local recentHatchActivity = currentSampleTime - math.max(lastHatchRequestAt, lastHatchEventAt) <= 8
				local currentEggName = recentHatchActivity
					and tostring(activeStates.BGSI_Lite_LastHatchRequestedEgg or "")
					or nil
				if (not currentEggName or currentEggName == "") and activeStates.BGSI_Lite_LuckEggActive == true then
					currentEggName = activeStates.BGSI_Lite_LuckEggName
						or activeStates.BGSI_Lite_FindLuckEggName()
						or "4x Luck Ultra Carnival Egg"
				elseif (not currentEggName or currentEggName == "") and activeStates.BGSI_Lite_RiftEggActive == true then
					currentEggName = tostring(Config.selectedRiftEgg or "")
				end
				if
					(not currentEggName or currentEggName == "")
					and (
						Config.autoHatch == true
						or scriptStateGV == true
						or recentHatchActivity
						or hatchRate > 0
					)
				then
					currentEggName = tostring(Config.selectedEgg or "")
				end
				if not currentEggName or currentEggName == "" then
					currentEggName = "None"
				end
				local isHatching = currentEggName ~= "None"
					and (recentHatchActivity or hatchRate > 0)
				activeStates.BGSI_Lite_CurrentEggName = currentEggName
				activeStates.BGSI_Lite_IsHatching = isHatching
				activeStates.BGSI_Lite_CurrentHatchRate = hatchRate
				local logPrefix = "[" .. LocalPlayer.Name .. "] "
				print(logPrefix .. "Egg = " .. currentEggName)
				print(logPrefix .. "isHatching = " .. tostring(isHatching))
			print(logPrefix .. "Hatchrate = " .. formattedHatchRate .. "/m")
			previousHatchCount = currentHatchCount
			previousSampleTime = currentSampleTime
		end
	end)
	task.spawn(function()
		while isCurrentRun() do
			task.wait(Config.autoUpgradeMastery and 1 or 0.85)
			if Config.autoUpgradeMastery then
				local upgradeOk, upgraded = pcall(activeStates.BGSI_Lite_TryUpgradeMastery)
				if not upgradeOk or not upgraded then
					task.wait(5)
				end
			end
		end
	end)
	task.spawn(function()
		while isCurrentRun() do
			task.wait(Config.autoClaimPrizes and 5 or 0.85)
			if Config.autoClaimPrizes then
				pcall(claimAvailablePrizes)
				pcall(activeStates.BGSI_Lite_ClaimIndexRewards)
			end
		end
	end)
	task.spawn(function()
		while isCurrentRun() do
			task.wait(Config.autoPowerOrbEquipped and 0.4 or 0.85)
			if Config.autoPowerOrbEquipped then
				local scriptStateAR = getSelectedChestName()
				local scriptStateRE = scriptStateAR
					and scriptStateAR.Teams
					and scriptStateAR.TeamEquipped
					and scriptStateAR.Teams[scriptStateAR.TeamEquipped]
				local scriptStateOC = scriptStateRE and scriptStateRE.Pets
				if type(scriptStateOC) == "table" then
					for loopSlotDP, scriptStateIB in ipairs(scriptStateOC) do
						if not Config.autoPowerOrbEquipped then
							break
						end
						if scriptStateIB and scriptStateIB ~= "" then
							pcall(function()
								remoteEvent:FireServer("UsePowerOrb", scriptStateIB)
							end)
							task.wait(0.08)
						end
					end
				end
			end
		end
	end)
	task.spawn(function()
		while isCurrentRun() do
			task.wait(Config.autoCollectCoins and 2 or 0.85)
			if Config.autoCollectCoins then
				pcall(installPickupRangeHook)
				pcall(function()
					remoteEvent:FireServer("UseGoldenOrb")
				end)
				if type(activeStates.BGSI_Lite_CollectVisibleRenderedPickups) == "function" then
					pcall(activeStates.BGSI_Lite_CollectVisibleRenderedPickups, 12, false)
				end
			end
		end
	end)
	task.spawn(function()
		while isCurrentRun() do
			task.wait(Config.autoBubble and 0.01 or 0.85)
			if Config.autoBubble then
				activeStates.BGSI_Lite_BlowBubble()
			end
		end
	end)
	task.spawn(function()
		while isCurrentRun() do
			task.wait(Config.autoSell and 0.05 or 0.85)
			if Config.autoSell then
				local bubbleState = activeStates.BGSI_Lite_GetBubbleState()
				if
					bubbleState
					and bubbleState.Amount > 0
					and (
						(
							not bubbleState.Infinite
							and bubbleState.Storage > 0
							and bubbleState.Amount + math.max(1, bubbleState.Power) >= bubbleState.Storage
						)
						or (
							bubbleState.Infinite
							and Config.autoSell
							and tick() - (tonumber(activeStates.BGSI_Lite_LastBubbleSellAt) or 0) >= 2
						)
					)
				then
					activeStates.BGSI_Lite_SellBubble()
				end
			end
		end
	end)
	task.spawn(function()
		while isCurrentRun() do
			task.wait(Config.autoUseFragments and 1 or 0.85)
			if Config.autoUseFragments then
				for _, fragmentType in ipairs(fragmentTypes) do
					if not Config.autoUseFragments then
						break
					end
					while Config.autoUseFragments do
						if not useFragment(fragmentType) then
							break
						end
						task.wait(0.1)
					end
				end
			end
		end
	end)
	-- Mystery Box / Gift opening.
	--
	-- UseGift only tells the server to spawn the physical drop(s) - it never grants the
	-- reward by itself. The visible player flow is: hit the drop 8 times, which then calls
	-- the Gift wrapper's own :Collect() method, which is what actually fires
	-- Remote:FireServer("ClaimGift", ...) - the real grant. Reading the Gift class itself
	-- (confirmed from the game's own decompiled source) shows :Collect() has no hit-count
	-- check at all; the 8-hit requirement lives entirely in :Hit(), which only calls
	-- :Collect() once its own counter reaches 8. :Collect() only checks that the drop's
	-- spawn-in animation has finished (Animating == false, ~0.5s after it appears) and
	-- never checks the player's position. So calling :Collect() directly, the moment the
	-- drop is done animating, claims it instantly with no hitting and no need to be near it.
	activeStates.BGSI_Lite_GetPhysicalItemModule = function()
		if type(activeStates.BGSI_Lite_PhysicalItemModule) ~= "table" then
			pcall(function()
				activeStates.BGSI_Lite_PhysicalItemModule = require(ReplicatedStorage.Client.Effects.PhysicalItem)
			end)
		end
		return activeStates.BGSI_Lite_PhysicalItemModule
	end

	-- Instantly collects every currently-loaded gift drop as soon as it's done spawning in,
	-- with no hitting and no teleporting. Returns true if at least one drop was collected.
	activeStates.BGSI_Lite_OpenSpawnedGifts = function(deadlineSeconds)
		local physicalItem = activeStates.BGSI_Lite_GetPhysicalItemModule()
		if type(physicalItem) ~= "table" or type(physicalItem.GetActiveGifts) ~= "function" then
			return false
		end
		local deadline = tick() + (tonumber(deadlineSeconds) or 15)
		local collectedAnyEver = false
		local triedGiftInstances = {}
		while tick() < deadline and isCurrentRun() do
			local activeCount = 0
			pcall(function()
				activeCount = physicalItem:GetActiveObjects("Gift")
			end)
			if activeCount <= 0 then
				break
			end
			local activeGifts
			local getOk = pcall(function()
				activeGifts = physicalItem:GetActiveGifts()
			end)
			if getOk and type(activeGifts) == "table" then
				for physicalInstance, giftWrapper in pairs(activeGifts) do
					if
						type(giftWrapper) == "table"
						and giftWrapper.Animating ~= true
						and not triedGiftInstances[physicalInstance]
					then
						triedGiftInstances[physicalInstance] = true
						collectedAnyEver = true
						-- Collect() blocks on its own squash/explode tweens for roughly half a
						-- second internally (confirmed from the decompiled Gift class). Calling
						-- it in a loop without spawning each call lets every prior drop's wait
						-- serialize the next one, which is what made a whole batch collect
						-- visibly one at a time. Spawning each call lets every ready drop's
						-- ClaimGift fire in the same instant instead of queued behind the last.
						task.spawn(function()
							pcall(function()
								giftWrapper:Collect()
							end)
						end)
					end
				end
			end
			task.wait(0.1)
		end
		return collectedAnyEver
	end

	-- Concurrent batch consumer: fires a Powerup-consuming remote (UseGift,
	-- HatchPowerupEgg, ...) from several worker coroutines at once instead of one call,
	-- wait, check, repeat. Confirmed straight from the game's own Constants table
	-- (v1.MaxSpawnableLimit = 50) that UseGift's real per-call cap is 50, not the 10 this
	-- script used to assume - and neither UseGift nor HatchPowerupEgg carry any
	-- server-side cooldown attribute the way world HatchEgg's NextEggOpenAt does, so
	-- nothing actually stops several batches from being in flight together. The only
	-- thing that was limiting speed before was firing them one at a time.
	--
	-- lastObservedOwned/reconcileObserved is the concurrency-safety mechanism: Luau
	-- coroutines only yield at task.wait, so any stretch of code with no task.wait in it
	-- runs atomically relative to every other worker. reconcileObserved reads the live
	-- owned amount and, if it dropped since the last time ANYONE observed it, claims the
	-- whole drop for totalConsumed and rebases the baseline - all without yielding - so
	-- whichever worker notices a drop first claims it and the next worker to check sees
	-- the already-updated baseline and claims nothing extra. That rules out two workers
	-- double-crediting the same server-side consumption. pendingClaimed works the same
	-- way to stop two workers claiming the same not-yet-consumed units for their batches.
	activeStates.BGSI_Lite_ConcurrentConsumeItem = function(options)
		local remoteName = options.remoteName
		local itemName = options.itemName
		local perCallCap = math.max(1, math.floor(tonumber(options.perCallCap) or 12))
		local concurrency = math.max(1, math.floor(tonumber(options.concurrency) or 4))
		local targetTotal = math.max(1, math.floor(tonumber(options.targetTotal) or perCallCap))
		local shouldContinue = type(options.shouldContinue) == "function" and options.shouldContinue
			or function()
				return true
			end
		local onBatchConfirmed = options.onBatchConfirmed
		local giftItem = { Type = "Powerup", Name = itemName }

		local function getOwned()
			local ownedAmount = 0
			pcall(function()
				local playerData = profileStore:IsReady() and profileStore:Get() or nil
				local amount = itemUtil:GetOwnedAmount(playerData, giftItem)
				ownedAmount = math.max(0, math.floor(tonumber(amount) or 0))
			end)
			return ownedAmount
		end

		local lastObservedOwned = getOwned()
		local totalConsumed = 0
		local pendingClaimed = 0
		local activeWorkers = 0

		local function reconcileObserved()
			local current = getOwned()
			if current < lastObservedOwned then
				local delta = lastObservedOwned - current
				lastObservedOwned = current
				totalConsumed += delta
				if type(onBatchConfirmed) == "function" then
					pcall(onBatchConfirmed, delta)
				end
			end
			return current
		end

		local function worker()
			activeWorkers += 1
			while totalConsumed < targetTotal and shouldContinue() do
				local ownedAmount = reconcileObserved()
				local available = ownedAmount - pendingClaimed
				local remainingTarget = targetTotal - totalConsumed - pendingClaimed
				local batchAmount = math.min(perCallCap, remainingTarget, available)
				if batchAmount <= 0 then
					break
				end
				pendingClaimed += batchAmount
				pcall(activeStates.BGSI_Lite_FireGameRemote, remoteName, itemName, batchAmount)
				local waitDeadline = tick() + 3
				local sawDrop = false
				repeat
					task.wait(0.1)
					local before = lastObservedOwned
					reconcileObserved()
					if lastObservedOwned < before then
						sawDrop = true
					end
				until sawDrop or tick() >= waitDeadline or not shouldContinue()
				pendingClaimed = math.max(0, pendingClaimed - batchAmount)
				if not sawDrop then
					task.wait(0.2)
				end
			end
			activeWorkers -= 1
		end

		for _ = 1, concurrency do
			task.spawn(worker)
		end

		local overallDeadline = tick() + 60
		while activeWorkers > 0 and tick() < overallDeadline and shouldContinue() do
			task.wait(0.1)
		end
		reconcileObserved()
		return totalConsumed
	end

	activeStates.BGSI_Lite_GetSelectedMysteryBoxes = function()
		local selectedBoxes = getSelectedValues(
			type(Config.selectedMysteryBoxes) == "table" and Config.selectedMysteryBoxes or {}
		)
		if #selectedBoxes == 0 and type(Config.selectedMysteryBox) == "string" and Config.selectedMysteryBox ~= "" then
			selectedBoxes = { Config.selectedMysteryBox }
		end
		return selectedBoxes
	end
	activeStates.BGSI_Lite_IsMysteryBoxSelected = function(boxName)
		return table.find(activeStates.BGSI_Lite_GetSelectedMysteryBoxes(), boxName) ~= nil
	end
	-- Takes turns between the selected boxes you actually own. Plain Mystery Boxes are
	-- left alone while Auto Condense can still turn them into Condensed ones, so the two
	-- features never race for the same boxes.
	activeStates.BGSI_Lite_PickNextMysteryBox = function()
		local selectedBoxes = activeStates.BGSI_Lite_GetSelectedMysteryBoxes()
		if #selectedBoxes == 0 then
			return nil
		end
		for _ = 1, #selectedBoxes do
			activeStates.BGSI_Lite_MysteryBoxRotation = (tonumber(activeStates.BGSI_Lite_MysteryBoxRotation) or 0)
					% #selectedBoxes
				+ 1
			local candidate = selectedBoxes[activeStates.BGSI_Lite_MysteryBoxRotation]
			local owned = 0
			pcall(function()
				local playerData = profileStore:IsReady() and profileStore:Get() or nil
				owned = tonumber(itemUtil:GetOwnedAmount(playerData, { Type = "Powerup", Name = candidate })) or 0
			end)
			local heldForCondenser = candidate == "Mystery Box"
				and Config.autoCondenseMysteryBoxes == true
				and type(activeStates.BGSI_Lite_CanCondenseMysteryBoxes) == "function"
				and activeStates.BGSI_Lite_CanCondenseMysteryBoxes()
			if owned > 0 and not heldForCondenser then
				return candidate
			end
		end
		return nil
	end
	task.spawn(function()
		while isCurrentRun() do
			local scriptStateIP = math.clamp(tonumber(Config.autoOpenMysteryDelay) or 0.2, 0.2, 60)
			task.wait(Config.autoOpenMystery and scriptStateIP or 0.85)
			local boxName = Config.autoOpenMystery and activeStates.BGSI_Lite_PickNextMysteryBox() or nil
			if boxName then
				local physicalItem = activeStates.BGSI_Lite_GetPhysicalItemModule()
				local collectorRunning = true
				-- Collecting runs concurrently with the consume workers below instead of
				-- after each batch - since multiple UseGift batches can legitimately be in
				-- flight together now, waiting for one batch's drops to fully clear before
				-- requesting the next would only waste time again.
				task.spawn(function()
					local collectDeadline = tick() + 65
					while collectorRunning and isCurrentRun() and tick() < collectDeadline do
						local activeCount = 0
						if type(physicalItem) == "table" then
							pcall(function()
								activeCount = physicalItem:GetActiveObjects("Gift")
							end)
						end
						if activeCount > 0 then
							activeStates.BGSI_Lite_OpenSpawnedGifts(2)
						end
						task.wait(0.15)
					end
				end)
				activeStates.BGSI_Lite_ConcurrentConsumeItem({
					remoteName = "UseGift",
					itemName = boxName,
					perCallCap = math.max(
						1,
						math.floor(tonumber(sharedConstants and sharedConstants.MaxSpawnableLimit) or 50)
					),
					concurrency = 3,
					targetTotal = 50,
					shouldContinue = function()
						return isCurrentRun()
							and Config.autoOpenMystery
							and activeStates.BGSI_Lite_IsMysteryBoxSelected(boxName)
					end,
				})
				collectorRunning = false
				task.wait(0.2)
				if type(physicalItem) == "table" then
					activeStates.BGSI_Lite_OpenSpawnedGifts(3)
				end
			end
		end
	end)
end
end
}
