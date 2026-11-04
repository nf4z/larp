-- Generated from larplite.lua; rebuild with tools/build_modules.py.
return {
function(...)
activeStates.BGSI_Lite_StatsTab = scriptStateOG:AddTab({
	Title = "Stats",
	Icon = "chart-no-axes-combined",
})
end,
function(...)
do
	local statsTab = activeStates.BGSI_Lite_StatsTab
	statsTab:AddSection("Live session")
	local liveStatsPrimary = statsTab.Native:CreateGroup()
	local liveStatsPerformance = statsTab.Native:CreateGroup()
	local liveStatsStatus = statsTab.Native:CreateGroup()
	local liveStatsServer = statsTab.Native:CreateGroup()
	local liveStatHandles = {
		Hatches = liveStatsPrimary:CreateStat({
			name = "Total hatches",
			icon = "egg",
			value = 0,
			changeMode = "absolute",
		}),
		HatchRate = liveStatsPrimary:CreateStat({
			name = "Hatch rate",
			icon = "gauge",
			value = 0,
			suffix = "/m",
			changeMode = "absolute",
			numberEasing = false,
		}),
		Luck = liveStatsPerformance:CreateStat({
			name = "Luck",
			icon = "clover",
			value = 0,
			suffix = "%",
			changeMode = "absolute",
			numberEasing = false,
		}),
		HatchSpeed = liveStatsPerformance:CreateStat({
			name = "Hatch speed",
			icon = "fast-forward",
			value = 0,
			suffix = "%",
			changeMode = "absolute",
			numberEasing = false,
		}),
		Fps = liveStatsStatus:CreateStat({
			name = "FPS",
			icon = "monitor",
			value = 0,
			changeMode = "absolute",
			numberEasing = false,
		}),
		Uptime = liveStatsStatus:CreateStat({
			name = "Uptime (seconds)",
			icon = "clock",
			value = 0,
			changeMode = "absolute",
			numberEasing = false,
		}),
		Players = liveStatsServer:CreateStat({
			name = "Server players",
			icon = "users",
			value = #Players:GetPlayers(),
			changeMode = "absolute",
			numberEasing = false,
		}),
		Hatching = liveStatsServer:CreateStat({
			name = "Hatching",
			icon = "radio",
			value = 0,
			changeMode = "absolute",
			numberEasing = false,
		}),
	}
	local statsStartedAt = tick()

	local function parseDebugNumber(debugText)
		local numberText, magnitude = tostring(debugText or ""):gsub("<.->", ""):gsub("&nbsp;", " "):match(
			"([%+%-]?[%d][%d,]*%.?%d*)%s*([kKmMbBtT]?)"
		)
		local numberValue = tonumber(numberText and numberText:gsub(",", "") or "")
		if not numberValue then
			return nil
		end
		local multipliers = {
			k = 1e3,
			m = 1e6,
			b = 1e9,
			t = 1e12,
		}
		return numberValue * (multipliers[string.lower(magnitude or "")] or 1)
	end

	local function getDebugStatValues()
		local playerGui = LocalPlayer and LocalPlayer:FindFirstChild("PlayerGui")
		local screenGui = playerGui and playerGui:FindFirstChild("ScreenGui")
		local debugGui = screenGui and screenGui:FindFirstChild("_debug")
		local debugTags = debugGui and debugGui:FindFirstChild("Tags")
		local luckValue
		local hatchSpeedValue
		local secretLuckDisplay
		local infinityLuckDisplay
		local combinedSecretInfinityLuckDisplay
		for _, debugTag in ipairs(debugTags and debugTags:GetChildren() or {}) do
			local debugLabel = debugTag:FindFirstChild("Label")
			if debugLabel and (debugLabel:IsA("TextLabel") or debugLabel:IsA("TextButton")) then
				local debugText = tostring(debugLabel.Text or ""):gsub("<.->", ""):gsub("&nbsp;", " ")
				local identifier = string.lower(tostring(debugTag.Name) .. " " .. debugText)
				local hasSecret = identifier:find("secret", 1, true) ~= nil
				local hasInfinity = identifier:find("infinity", 1, true) ~= nil
				local hasLuck = identifier:find("luck", 1, true) ~= nil
				if identifier:find("hatch", 1, true) and identifier:find("speed", 1, true) then
					hatchSpeedValue = parseDebugNumber(debugText) or hatchSpeedValue
				elseif hasSecret and hasInfinity and hasLuck then
					-- Some game versions show one combined "Secret/Infinity Luck" tag instead
					-- of two separate ones. That combined figure is the one actually shown to
					-- the player (it reflects whatever's currently boosting it, e.g. an active
					-- luck event) and can run well ahead of a plain "Secret Luck" tag if that
					-- one still exists separately but isn't kept in sync - that mismatch is
					-- exactly what showed the webhook at roughly half the real in-game value.
					-- The combined reading wins whenever it's present.
					combinedSecretInfinityLuckDisplay = debugText:match("[xX]%s*[%d][%d,]*%.?%d*")
						or combinedSecretInfinityLuckDisplay
				elseif hasSecret and hasLuck then
					secretLuckDisplay = debugText:match("[xX]%s*[%d][%d,]*%.?%d*") or secretLuckDisplay
				elseif hasInfinity and hasLuck then
					infinityLuckDisplay = debugText:match("[xX]%s*[%d][%d,]*%.?%d*") or infinityLuckDisplay
				elseif hasLuck and not hasSecret and not hasInfinity and not identifier:find("egg", 1, true) then
					luckValue = parseDebugNumber(debugText) or luckValue
				end
			end
		end
		return luckValue, hatchSpeedValue, combinedSecretInfinityLuckDisplay or secretLuckDisplay, infinityLuckDisplay
	end
	activeStates.BGSI_Lite_GetDebugLuckDisplays = function()
		local _, _, secretLuckDisplay, infinityLuckDisplay = getDebugStatValues()
		return secretLuckDisplay, infinityLuckDisplay
	end

	task.spawn(function()
		local frameCount = 0
		local fpsSampleStartedAt = tick()
		local currentFps = 0
		local renderConnection = RunService.RenderStepped:Connect(function()
			frameCount += 1
		end)
		while isCurrentRun() do
			task.wait(1)
			local now = tick()
			local elapsed = math.max(0.001, now - fpsSampleStartedAt)
			currentFps = math.floor(frameCount / elapsed + 0.5)
			activeStates.BGSI_Lite_CurrentFPS = currentFps
			frameCount = 0
			fpsSampleStartedAt = now
			pcall(function()
				liveStatHandles.HatchRate:Set(tonumber(activeStates.BGSI_Lite_CurrentHatchRate) or 0)
				liveStatHandles.Fps:Set(currentFps)
				liveStatHandles.Uptime:Set(math.floor(now - statsStartedAt))
				liveStatHandles.Players:Set(#Players:GetPlayers())
				liveStatHandles.Hatching:Set(activeStates.BGSI_Lite_IsHatching == true and 1 or 0)
			end)
			pcall(function()
				local playerData = profileStore:Get()
				liveStatHandles.Hatches:Set(tonumber(playerData.Stats and playerData.Stats.Hatches) or 0)
			end)
			pcall(function()
				local luckValue, hatchSpeedValue = getDebugStatValues()
				if luckValue then
					activeStates.BGSI_Lite_CurrentLuck = tonumber(luckValue) or 0
					liveStatHandles.Luck:Set(luckValue)
				end
				if hatchSpeedValue then
					activeStates.BGSI_Lite_CurrentHatchSpeed = tonumber(hatchSpeedValue) or 0
					liveStatHandles.HatchSpeed:Set(hatchSpeedValue)
				end
			end)
		end
		renderConnection:Disconnect()
	end)
end
end
}
