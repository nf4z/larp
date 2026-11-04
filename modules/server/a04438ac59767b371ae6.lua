-- Generated from larplite.lua; rebuild with tools/build_modules.py.
return {
function(...)
activeStates.BGSI_Lite_ServerTab = scriptStateOG:AddTab({
	Title = "Server",
	Icon = "server",
})
end,
function(...)
activeStates.BGSI_Lite_InstallServerTab = function()
	local serverTab = activeStates.BGSI_Lite_ServerTab
	if not serverTab then
		return
	end
	local VirtualUser = game:GetService("VirtualUser")
	local GuiService = game:GetService("GuiService")

	local specialEvents, specialEventUtil
	pcall(function()
		specialEvents = require(ReplicatedStorage.Shared.Data.SpecialEvents)
	end)
	pcall(function()
		specialEventUtil = require(ReplicatedStorage.Shared.Utils.SpecialEventUtil)
	end)

	local function notify(title, content, duration)
		pcall(function()
			Interface:Notify({ Title = title, Content = content, Duration = duration or 4 })
		end)
	end

	local function formatDuration(seconds)
		seconds = math.max(0, math.floor(tonumber(seconds) or 0))
		local hours = seconds // 3600
		local minutes = (seconds % 3600) // 60
		if hours > 0 then
			return string.format("%dh %02dm", hours, minutes)
		elseif minutes > 0 then
			return string.format("%dm %02ds", minutes, seconds % 60)
		end
		return string.format("%ds", seconds)
	end

	local function copyToClipboard(text)
		local copyFunction = setclipboard or toclipboard or (type(Clipboard) == "table" and Clipboard.set)
		if type(copyFunction) ~= "function" then
			return false
		end
		return (pcall(copyFunction, text))
	end

	local function isPrivateServer()
		return tostring(game.PrivateServerId or "") ~= ""
	end

	-- Paragraphs flicker if they're re-set with identical text every tick.
	local function makeLiveParagraph(title)
		local paragraph = serverTab:AddParagraph({ Title = title, Content = "Loading..." })
		local lastText
		return function(text)
			if text ~= lastText then
				lastText = text
				pcall(function()
					paragraph:SetDesc(text)
				end)
			end
		end
	end

	--=====================================================================
	-- Server info
	--=====================================================================
	local framesThisSecond, currentFps = 0, 0
	local frameConnection
	frameConnection = RunService.RenderStepped:Connect(function()
		if not isCurrentRun() then
			frameConnection:Disconnect()
			return
		end
		framesThisSecond += 1
	end)

	local friendCache = {}
	local function refreshFriendStatus(player)
		if player == LocalPlayer or friendCache[player.UserId] ~= nil then
			return
		end
		friendCache[player.UserId] = false
		task.spawn(function()
			local ok, isFriend = pcall(function()
				return LocalPlayer:IsFriendsWith(player.UserId)
			end)
			friendCache[player.UserId] = ok and isFriend == true
		end)
	end
	for _, player in ipairs(Players:GetPlayers()) do
		refreshFriendStatus(player)
	end

	local function buildServerInfoText()
		local players = Players:GetPlayers()
		local friendsHere = 0
		for _, player in ipairs(players) do
			if friendCache[player.UserId] == true then
				friendsHere += 1
			end
		end
		local ping = 0
		pcall(function()
			ping = math.floor(LocalPlayer:GetNetworkPing() * 1000 + 0.5)
		end)
		local serverType = "Public"
		if isPrivateServer() then
			serverType = (tonumber(game.PrivateServerOwnerId) or 0) ~= 0 and "Private (VIP)" or "Reserved"
		end
		return table.concat({
			string.format("Players: %d / %d  -  Friends here: %d", #players, Players.MaxPlayers, friendsHere),
			"Server uptime: " .. formatDuration(workspace.DistributedGameTime),
			string.format("Ping: %d ms  -  FPS: %d", ping, currentFps),
			"Server type: " .. serverType,
			"Job Id: " .. tostring(game.JobId),
		}, "\n")
	end

	--=====================================================================
	-- Event Board + global boosts + rifts
	--=====================================================================
	local function getActiveBoardEvents()
		local now = getCurrentTimestamp()
		local endTimes, bought = {}, {}
		pcall(function()
			local playerData = profileStore:IsReady() and profileStore:Get() or nil
			for eventName, endsAt in pairs(type(playerData) == "table" and playerData.SpecialEventTimers or {}) do
				endTimes[eventName] = tonumber(endsAt)
				bought[eventName] = true
			end
		end)
		if specialEventUtil then
			pcall(function()
				local current = specialEventUtil:GetCurrentEvent()
				if current then
					local slotEnd = specialEventUtil:GetEventTime(specialEventUtil:GetSeed() + 1)
					endTimes[current] = math.max(endTimes[current] or 0, slotEnd)
				end
			end)
		end
		local events = {}
		for eventName, endsAt in pairs(endTimes) do
			if endsAt and endsAt > now then
				table.insert(events, { name = eventName, remaining = endsAt - now, bought = bought[eventName] == true })
			end
		end
		table.sort(events, function(left, right)
			return left.remaining < right.remaining
		end)
		return events
	end

	local function getUpcomingBoardEvents(count)
		local upcoming = {}
		if not specialEventUtil then
			return upcoming
		end
		pcall(function()
			local now = getCurrentTimestamp()
			local seed = specialEventUtil:GetSeed()
			for offset = 1, 48 do
				if #upcoming >= count then
					break
				end
				local eventName = specialEventUtil:GetEventFromSeed(seed + offset)
				if eventName then
					table.insert(upcoming, {
						name = eventName,
						startsIn = specialEventUtil:GetEventTime(seed + offset) - now,
					})
				end
			end
		end)
		return upcoming
	end

	local function describeEvent(eventName)
		local definition = type(specialEvents) == "table" and specialEvents[eventName] or nil
		if type(definition) ~= "table" then
			return eventName
		end
		return string.format("%s %s - %s", tostring(definition.Emoji or ""), eventName, tostring(definition.Description or ""))
	end

	local function buildEventText()
		local lines = { "Active:" }
		local active = getActiveBoardEvents()
		if #active == 0 then
			table.insert(lines, "  Nothing running right now")
		end
		for _, event in ipairs(active) do
			table.insert(
				lines,
				string.format("  %s  (%s left%s)", describeEvent(event.name), formatDuration(event.remaining), event.bought and ", bought" or "")
			)
		end
		table.insert(lines, "Coming up:")
		for _, event in ipairs(getUpcomingBoardEvents(4)) do
			table.insert(lines, string.format("  %s  in %s", describeEvent(event.name), formatDuration(event.startsIn)))
		end
		return table.concat(lines, "\n")
	end

	local function buildBoostText()
		local lines = {}
		local ok, boosts = pcall(activeStates.BGSI_Lite_BuildGlobalEventSnapshot)
		for _, boost in ipairs(ok and type(boosts) == "table" and boosts or {}) do
			table.insert(lines, string.format("%s  (%s left)", tostring(boost.label or boost.name), formatDuration(boost.timeRemainingSeconds)))
		end
		return #lines > 0 and table.concat(lines, "\n") or "No global boosts active"
	end

	local function buildRiftText()
		local ok, rifts = pcall(activeStates.BGSI_Lite_BuildRiftSnapshot)
		if not ok or type(rifts) ~= "table" or #rifts == 0 then
			return "No rifts in this server"
		end
		local lines = {}
		for _, rift in ipairs(rifts) do
			local luck = (tonumber(rift.bonusLuck) or 0) > 1 and string.format("  x%s luck", tostring(rift.bonusLuck)) or ""
			table.insert(
				lines,
				string.format("%s (%s)%s  -  %s left", tostring(rift.name), tostring(rift.world), luck, formatDuration(rift.timeRemainingSeconds))
			)
		end
		return table.concat(lines, "\n")
	end

	local function buildPlayerText()
		local players = Players:GetPlayers()
		table.sort(players, function(left, right)
			return string.lower(left.DisplayName) < string.lower(right.DisplayName)
		end)
		local lines = {}
		for _, player in ipairs(players) do
			local tag = player == LocalPlayer and "  [you]" or (friendCache[player.UserId] == true and "  [friend]" or "")
			table.insert(lines, string.format("%s (@%s)%s", player.DisplayName, player.Name, tag))
		end
		return table.concat(lines, "\n")
	end

	--=====================================================================
	-- Server hopping
	--=====================================================================
	local function fetchServerPage(sortOrder, cursor)
		local url = "https://games.roblox.com/v1/games/"
			.. tostring(game.PlaceId)
			.. "/servers/Public?sortOrder="
			.. sortOrder
			.. "&limit=100&excludeFullGames=true"
		if type(cursor) == "string" and cursor ~= "" then
			url = url .. "&cursor=" .. HttpService:UrlEncode(cursor)
		end
		local ok, body = pcall(function()
			return game:HttpGet(url)
		end)
		if not ok or type(body) ~= "string" or body == "" then
			local requestFunction = request or http_request or (type(syn) == "table" and rawget(syn, "request"))
			if type(requestFunction) == "function" then
				local requestOk, response = pcall(requestFunction, { Url = url, Method = "GET" })
				body = requestOk and type(response) == "table" and response.Body or nil
			end
		end
		if type(body) ~= "string" or body == "" then
			return nil
		end
		local decodeOk, page = pcall(HttpService.JSONDecode, HttpService, body)
		return decodeOk and type(page) == "table" and page or nil
	end

	local function collectServers(sortOrder, maxPages)
		local servers, cursor = {}, nil
		for _ = 1, maxPages do
			local page = fetchServerPage(sortOrder, cursor)
			if not page then
				break
			end
			for _, info in ipairs(type(page.data) == "table" and page.data or {}) do
				local playing, maximum = tonumber(info.playing) or 0, tonumber(info.maxPlayers) or 0
				if info.id and info.id ~= game.JobId and playing < maximum then
					table.insert(servers, { id = info.id, playing = playing })
				end
			end
			cursor = page.nextPageCursor
			if type(cursor) ~= "string" or cursor == "" then
				break
			end
		end
		return servers
	end

	local hopInProgress = false
	local function hopServer(mode)
		if hopInProgress then
			return
		end
		hopInProgress = true
		task.spawn(function()
			notify("Server", mode == "smallest" and "Finding the emptiest server..." or "Finding another server...")
			local servers = collectServers(mode == "smallest" and "Asc" or "Desc", 3)
			if #servers == 0 then
				notify("Server", "Couldn't get the server list. Try again in a moment.")
				hopInProgress = false
				return
			end
			local target = servers[math.random(1, #servers)]
			if mode == "smallest" then
				table.sort(servers, function(left, right)
					return left.playing < right.playing
				end)
				target = servers[1]
			end
			local teleportOk, teleportError = pcall(function()
				if isAutomationBlocked() then
					return
				end
				TeleportService:TeleportToPlaceInstance(game.PlaceId, target.id, LocalPlayer)
			end)
			if not teleportOk then
				notify("Server", "Teleport failed: " .. tostring(teleportError))
			end
			task.delay(10, function()
				hopInProgress = false
			end)
		end)
	end

	local function rejoinServer()
		if isAutomationBlocked() then
			return
		end
		if isPrivateServer() then
			notify("Server", "Can't rejoin a private server directly - rejoining a public one instead.")
			pcall(function()
				TeleportService:Teleport(game.PlaceId, LocalPlayer)
			end)
			return
		end
		local ok = pcall(function()
			TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
		end)
		if not ok then
			pcall(function()
				TeleportService:Teleport(game.PlaceId, LocalPlayer)
			end)
		end
	end

	--=====================================================================
	-- UI
	--=====================================================================
	serverTab:AddSection("Server Stats")
	local setServerInfo = makeLiveParagraph("This Server")
	serverTab:AddSection("Event Board")
	local setEventText = makeLiveParagraph("Board Events")
	local setBoostText = makeLiveParagraph("Global Boosts")
	serverTab:AddSection("Rifts")
	local setRiftText = makeLiveParagraph("Rifts In Server")
	serverTab:AddSection("Players")
	local setPlayerText = makeLiveParagraph("Players In Server")
	serverTab:AddToggle("ServerJoinLeaveAlerts", {
		Title = "Join / Leave Alerts",
		Description = "Pops a notification whenever someone joins or leaves the server.",
		Default = Config.serverJoinLeaveAlerts,
		Callback = function(isEnabled)
			Config.serverJoinLeaveAlerts = isEnabled == true
			saveConfig()
		end,
	})

	serverTab:AddSection("Server Tools")
	serverTab:AddToggle("ServerAntiAfk", {
		Title = "Anti-AFK",
		Description = "Keeps you from counting as idle. The game moves idle players to a new server after 12 minutes and Roblox kicks at 20, both of which stop your automation.",
		Default = Config.serverAntiAfk,
		Callback = function(isEnabled)
			Config.serverAntiAfk = isEnabled == true
			saveConfig()
		end,
	})
	serverTab:AddToggle("ServerAutoRejoin", {
		Title = "Auto Rejoin On Disconnect",
		Description = "If you get disconnected, rejoins this server (or a new one if it's gone) after a few seconds.",
		Default = Config.serverAutoRejoin,
		Callback = function(isEnabled)
			Config.serverAutoRejoin = isEnabled == true
			saveConfig()
		end,
	})
	serverTab:AddButton({
		Title = "Rejoin",
		Description = "Reconnects to this same server.",
		Callback = rejoinServer,
	})
	serverTab:AddButton({
		Title = "Server Hop",
		Description = "Moves you to a random other public server.",
		Callback = function()
			hopServer("random")
		end,
	})
	serverTab:AddButton({
		Title = "Hop To Emptiest Server",
		Description = "Moves you to the public server with the fewest players.",
		Callback = function()
			hopServer("smallest")
		end,
	})
	serverTab:AddButton({
		Title = "Copy Job Id",
		Callback = function()
			notify("Server", copyToClipboard(tostring(game.JobId)) and "Job Id copied." or "Your executor can't copy to clipboard.")
		end,
	})
	serverTab:AddButton({
		Title = "Copy Join Script",
		Description = "Copies a one-line script that teleports anyone who runs it into this server.",
		Callback = function()
			local joinScript = string.format(
				'game:GetService("TeleportService"):TeleportToPlaceInstance(%d, "%s", game:GetService("Players").LocalPlayer)',
				game.PlaceId,
				tostring(game.JobId)
			)
			notify("Server", copyToClipboard(joinScript) and "Join script copied." or "Your executor can't copy to clipboard.")
		end,
	})
	local pendingJobId = ""
	serverTab:AddInput("ServerJoinJobId", {
		Title = "Job Id To Join",
		Description = "Paste a Job Id here, then press Join Job Id.",
		Default = "",
		Callback = function(value)
			pendingJobId = tostring(value or ""):gsub("%s+", "")
		end,
	})
	serverTab:AddButton({
		Title = "Join Job Id",
		Callback = function()
			if pendingJobId == "" then
				notify("Server", "Paste a Job Id first.")
				return
			end
			local ok, teleportError = pcall(function()
				TeleportService:TeleportToPlaceInstance(game.PlaceId, pendingJobId, LocalPlayer)
			end)
			if not ok then
				notify("Server", "Teleport failed: " .. tostring(teleportError))
			end
		end,
	})

	--=====================================================================
	-- Background behaviour
	--=====================================================================
	LocalPlayer.Idled:Connect(function()
		if not isCurrentRun() or Config.serverAntiAfk ~= true or Config.safeMode == true then
			return
		end
		pcall(function()
			VirtualUser:CaptureController()
			VirtualUser:ClickButton2(Vector2.new())
		end)
	end)

	local rejoinQueued = false
	GuiService.ErrorMessageChanged:Connect(function(message)
		if
			rejoinQueued
			or not isCurrentRun()
			or Config.serverAutoRejoin ~= true
			or Config.safeMode == true
			or tostring(message or "") == ""
		then
			return
		end
		rejoinQueued = true
		task.delay(5, function()
			rejoinServer()
			task.delay(30, function()
				rejoinQueued = false
			end)
		end)
	end)
	pcall(function()
		local promptGui = CoreGui:WaitForChild("RobloxPromptGui", 10)
		local overlay = promptGui and promptGui:WaitForChild("promptOverlay", 10)
		if overlay then
			overlay.ChildAdded:Connect(function(prompt)
				if Config.serverAutoRejoin ~= true or not isCurrentRun() then return end
				task.delay(2, function()
					if prompt.Parent and prompt.Name == "ErrorPrompt" and not rejoinQueued then
						rejoinQueued = true
						rejoinServer()
						task.delay(15, function() rejoinQueued = false end)
					end
				end)
			end)
		end
	end)
	TeleportService.TeleportInitFailed:Connect(function(player)
		if player == LocalPlayer and Config.serverAutoRejoin == true and isCurrentRun() and not rejoinQueued then
			rejoinQueued = true
			task.delay(5, function()
				rejoinQueued = false
				rejoinServer()
			end)
		end
	end)

	Players.PlayerAdded:Connect(function(player)
		if not isCurrentRun() then
			return
		end
		refreshFriendStatus(player)
		if Config.serverJoinLeaveAlerts == true then
			notify("Player Joined", string.format("%s (@%s)", player.DisplayName, player.Name), 3)
		end
	end)
	Players.PlayerRemoving:Connect(function(player)
		if not isCurrentRun() then
			return
		end
		friendCache[player.UserId] = nil
		if Config.serverJoinLeaveAlerts == true then
			notify("Player Left", string.format("%s (@%s)", player.DisplayName, player.Name), 3)
		end
	end)

	task.spawn(function()
		local tickCount = 0
		while isCurrentRun() do
			currentFps = framesThisSecond
			framesThisSecond = 0
			setServerInfo(buildServerInfoText())
			setEventText(buildEventText())
			setBoostText(buildBoostText())
			if tickCount % 2 == 0 then
				setPlayerText(buildPlayerText())
			end
			if tickCount % 5 == 0 then
				setRiftText(buildRiftText())
			end
			tickCount += 1
			task.wait(1)
		end
	end)
end
end
}
