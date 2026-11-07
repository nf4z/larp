-- Generated from larplite.lua; rebuild with tools/build_modules.py.
return {
function(...)
compTab = scriptStateOG:AddTab({
	Title = "Comp",
	Icon = "trophy",
})
end,
function(...)
do
	compTab:AddSection("Seals vs Frog Dogs")
	local teamText = compTab:AddParagraph({ Title = "Your Team", Content = "Loading..." })
	local hatchText = compTab:AddParagraph({ Title = "Hatches Contributed / Team Place", Content = "Loading..." })
	local bubbleText = compTab:AddParagraph({ Title = "Bubbles Contributed / Team Place", Content = "Loading..." })
	for _, metric in ipairs({ "Hatches", "Bubbles" }) do
		local key = "autoClaimComp" .. metric
		compTab:AddToggle("AutoClaimComp" .. metric, {
			Title = "Auto Claim " .. metric .. " Rewards",
			Default = Config[key] == true,
			Callback = function(value) Config[key] = value == true; saveConfig() end,
		})
	end
	local ok, competition = pcall(require, ReplicatedStorage.Shared.Data:FindFirstChild("PinkVsBlue"))
	if ok and type(competition) == "table" and competition.Enabled then
		local season = competition.GetSeason()
		local standings, snapshotAt
		local pending = {}
		local function getContribution()
			local data = profileStore:IsReady() and profileStore:Get() or nil
			return data and type(data.PinkVsBlue) == "table" and data.PinkVsBlue[tostring(season.Id)] or nil
		end
		local function getTeamPlace(contribution, metric)
			local board = standings and standings.Boards and standings.Boards[contribution.Team]
			board = board and board[metric]
			if type(board) ~= "table" then return "Waiting for standings" end
			local score = tonumber(contribution[metric]) or 0
			local rank, found = 1, false
			for index, entry in ipairs(board) do
				if tostring(entry.UserId) == tostring(LocalPlayer.UserId) then
					found = true
					if standings.Final then return "#" .. tostring(index) end
				elseif (tonumber(entry.Score) or 0) >= score then rank += 1 end
			end
			if standings.Final or score <= 0 or rank > 100 then return "Outside top 100" end
			-- Only the top 100 are exposed by the server; never invent a lower placement.
			if not found and #board >= 100 and score <= (tonumber(board[#board].Score) or 0) then return "Outside top 100" end
			return "#" .. tostring(rank)
		end
		local function updateComp()
			local contribution = getContribution()
			local team = contribution and competition.Teams[contribution.Team]
			teamText:SetDesc(team and team.Name or "Join the competition at the in-game event pad")
			for metric, paragraph in pairs({ Hatches = hatchText, Bubbles = bubbleText }) do
				paragraph:SetDesc(contribution and (string.format("%.0f", tonumber(contribution[metric]) or 0)
					.. " | " .. getTeamPlace(contribution, metric)) or "Not joined")
			end
			return contribution
		end
		if activeStates.BGSI_Lite_CompSnapshotConnection then activeStates.BGSI_Lite_CompSnapshotConnection:Disconnect() end
		local snapshotConnection = remoteEvent.OnClientEvent:Connect(function(action, snapshot)
			if not isCurrentRun() or action ~= "PinkVsBlueSnapshot" or type(snapshot) ~= "table" then return end
			if type(snapshot.Season) ~= "table" or type(snapshot.Standings) ~= "table" then return end
			if tostring(snapshot.Season.Id) ~= tostring(season.Id) then pending = {} end
			season, standings, snapshotAt = snapshot.Season, snapshot.Standings, tick()
			pcall(updateComp)
		end)
		activeStates.BGSI_Lite_CompSnapshotConnection = snapshotConnection
		compTab:AddButton({ Title = "Refresh Competition", Callback = function()
			snapshotAt = nil
			pcall(updateComp)
		end })
		task.spawn(function()
			while isCurrentRun() do
				pcall(function()
					local contribution = updateComp()
					if Config.safeMode == true then return end
					if not snapshotAt or tick() - snapshotAt >= 30 then
						snapshotAt = tick()
						remoteEvent:FireServer("PinkVsBlueView", true)
					end
					if not contribution then return end
					local claims = type(contribution.Claims) == "table" and contribution.Claims or {}
					for _, metric in ipairs({ "Hatches", "Bubbles" }) do
						if Config["autoClaimComp" .. metric] == true then
							for index, reward in ipairs(season.PersonalRewards[metric] or {}) do
								local key = "Personal:" .. metric .. ":" .. tostring(index)
								if claims[key] then pending[key] = nil
								elseif (tonumber(contribution[metric]) or 0) >= reward.Requirement
									and (not pending[key] or tick() - pending[key] >= 15) then
									pending[key] = tick()
									remoteEvent:FireServer("PinkVsBlueClaim", season.Id, metric, index)
									task.wait(0.15)
									if not isCurrentRun() or Config.safeMode or not Config["autoClaimComp" .. metric] then break end
								end
							end
						end
					end
				end)
				task.wait(2)
			end
			snapshotConnection:Disconnect()
			if activeStates.BGSI_Lite_CompSnapshotConnection == snapshotConnection then
				activeStates.BGSI_Lite_CompSnapshotConnection = nil
			end
		end)
	else
		teamText:SetDesc("Competition unavailable in this server")
		hatchText:SetDesc("Unavailable")
		bubbleText:SetDesc("Unavailable")
	end
end
end
}
