-- Generated from larplite.lua; rebuild with tools/build_modules.py.
return {
function(...)
riftsTab = riftsTabStub
end,
function(...)
do
	local riftsTab = riftsTab
	riftsTab:AddSection("Active Rifts")

	-- AddText, not AddConsole: Console recreates its per-line TextLabels via Instance.new
	-- whenever the line count grows past what's already pooled, and that call happens from
	-- this file's background update loop (task.spawn), not the thread that first built the
	-- UI. Under executors that gate Instance.new by thread capability ("lacking capability
	-- Plugin"), that crashes the very first real update. Text only ever rebinds one
	-- already-built label's string, so it has no such runtime Instance.new dependency.
	local riftDisplay = riftsTab:AddText({
		Title = "Current Rifts",
		Content = "Scanning for active rifts...",
	})

	riftsTab:AddButton({
		Title = "Refresh Rifts",
		Callback = function()
			local ok, err = pcall(activeStates.BGSI_Lite_UpdateRiftDisplay)
			if not ok then
				warn("[1rzHub Lite] Rift display update failed: " .. tostring(err))
				pcall(function()
					riftDisplay:Set("Rift scan failed: " .. tostring(err))
				end)
			end
		end,
	})

	activeStates.BGSI_Lite_BuildRiftSnapshot = function()
		local renderedFolder = Workspace:FindFirstChild("Rendered")
		local riftsFolder = renderedFolder and renderedFolder:FindFirstChild("Rifts")
		if not riftsFolder then
			return nil
		end
		local activeRifts = {}
		local currentTime = getCurrentTimestamp()
		for _, riftModel in ipairs(riftsFolder:GetChildren()) do
			if riftModel:IsA("Model") then
				local despawnAt = tonumber(riftModel:GetAttribute("DespawnAt"))
				local timeRemaining = despawnAt and despawnAt - currentTime or 0
				if timeRemaining > 0 then
					local riftName = riftModel.Name
					local riftInfo = type(riftData) == "table" and riftData[riftName] or nil
					local riftType = tostring(riftModel:GetAttribute("Type") or (riftInfo and riftInfo.Type) or "Unknown")
					local displayName = tostring(
						(riftInfo and (riftInfo.DisplayName or riftInfo.Egg)) or riftName
					)
					local world = riftModel:GetAttribute("World")
					local eggName = riftInfo and tostring(riftInfo.Egg or "") or ""
					local icon = riftInfo and tostring(riftInfo.Icon or "") or ""
					if eggName ~= "" and type(eggDataModule) == "table" and type(eggDataModule[eggName]) == "table" then
						icon = tostring(eggDataModule[eggName].Image or icon)
					elseif riftType == "Gift" then
						icon = "rbxassetid://110921405358636"
					end
					if
						(type(world) ~= "string" or world == "")
						and riftInfo
						and type(riftInfo.Egg) == "string"
						and type(eggDataModule) == "table"
						and type(eggDataModule[riftInfo.Egg]) == "table"
					then
						world = eggDataModule[riftInfo.Egg].World
					end
					local action = riftType == "Egg" and "hatch"
						or riftType == "Chest" and "collect"
						or riftType == "Gift" and "collect"
						or riftType == "Sell" and "sell"
						or "visit"
					local bonusLuck = math.max(
						riftType == "Egg" and 1 or 0,
						tonumber(riftModel:GetAttribute("BonusLuck")) or 0
					)
					if riftType == "Egg" then
						for _, riftDescendant in ipairs(riftModel:GetDescendants()) do
							bonusLuck =
								math.max(bonusLuck, tonumber(riftDescendant:GetAttribute("BonusLuck")) or 0)
						end
					end
					table.insert(activeRifts, {
						id = riftName,
						name = displayName,
						type = riftType,
						world = tostring(world or "Unknown"),
						eggName = eggName,
						iconAssetId = tostring(icon):match("%d+") or "",
						action = action,
						actionLabel = action == "hatch" and "Start hatching"
							or riftType == "Chest" and "Open chest"
							or riftType == "Gift" and "Collect gift"
							or action == "sell" and "Sell bubbles"
							or "Go to rift",
						bonusLuck = bonusLuck,
						timeRemaining = string.format("%.1f min", timeRemaining / 60),
						timeRemainingSeconds = math.max(0, math.floor(timeRemaining)),
					})
				end
			end
		end
		table.sort(activeRifts, function(leftRift, rightRift)
			if leftRift.timeRemainingSeconds ~= rightRift.timeRemainingSeconds then
				return leftRift.timeRemainingSeconds < rightRift.timeRemainingSeconds
			end
			return string.lower(leftRift.name) < string.lower(rightRift.name)
		end)
		return activeRifts
	end

	activeStates.BGSI_Lite_BuildGlobalEventSnapshot = function()
		local eventIcons = {
			Lucky = "79406479731411",
			Hatching = "115084184606522",
			Bubbling = "139415836850114",
			Secret = "131974934654903",
			Shiny = "73209196936182",
			Mythic = "74927583442057",
			XL = "136975814480223",
			Infinity = "129349250488902",
		}
		local activeEvents = {}
		local currentTime = getCurrentTimestamp()
		for eventName, iconAssetId in pairs(eventIcons) do
			local endsAt = tonumber(Workspace:GetAttribute(eventName))
			local timeRemaining = endsAt and endsAt - currentTime or 0
			if timeRemaining > 0 then
				table.insert(activeEvents, {
					name = eventName,
					label = eventName == "Secret" and "Secret Luck"
						or eventName == "Lucky" and "Luck"
						or eventName == "Hatching" and "Hatch Speed"
						or eventName == "Bubbling" and "Bubble Power"
						or eventName .. " Luck",
					iconAssetId = iconAssetId,
					timeRemaining = string.format("%.1f min", timeRemaining / 60),
					timeRemainingSeconds = math.max(0, math.floor(timeRemaining)),
				})
			end
		end
		table.sort(activeEvents, function(leftEvent, rightEvent)
			return leftEvent.timeRemainingSeconds < rightEvent.timeRemainingSeconds
		end)
		return activeEvents
	end

	activeStates.BGSI_Lite_BuildFourXEggSnapshot = function()
		local luckEggName = activeStates.BGSI_Lite_FindLuckEggName
				and activeStates.BGSI_Lite_FindLuckEggName()
			or nil
		if not luckEggName then
			return nil
		end

		local eggName = luckEggName:gsub("^4[xX]%s+[Ll][Uu][Cc][Kk]%s+", "")
		local eggInfo = type(eggDataModule) == "table" and eggDataModule[eggName] or nil
		local summonedEgg = Workspace:FindFirstChild("SummonedEgg")
		local expiresAt = 0
		if summonedEgg then
			local eggInstances = summonedEgg:GetDescendants()
			table.insert(eggInstances, 1, summonedEgg)
			for _, eggInstance in ipairs(eggInstances) do
				for attributeName, attributeValue in pairs(eggInstance:GetAttributes()) do
					if
						type(attributeValue) == "number"
						and (
							attributeName == "DespawnAt"
							or attributeName == "ExpiresAt"
							or attributeName == "EndAt"
							or attributeName == "EndTime"
						)
					then
						expiresAt = math.max(expiresAt, attributeValue)
					end
				end
			end
		end

		local currentTime = getCurrentTimestamp()
		local timeRemaining = math.max(0, expiresAt - currentTime)
		local world = type(eggInfo) == "table" and tostring(eggInfo.World or "") or ""
		local iconAssetId = type(eggInfo) == "table" and tostring(eggInfo.Image or ""):match("%d+") or ""
		if timeRemaining <= 0 then
			for _, rift in ipairs(activeStates.BGSI_Lite_DashboardRifts or {}) do
				if rift.type == "Egg" and rift.eggName == eggName then
					timeRemaining = math.max(0, tonumber(rift.timeRemainingSeconds) or 0)
					world = world ~= "" and world or rift.world
					iconAssetId = iconAssetId ~= "" and iconAssetId or rift.iconAssetId
					break
				end
			end
		end

		return {
			id = string.lower(luckEggName),
			name = luckEggName,
			world = world ~= "" and world or "Unknown",
			iconAssetId = iconAssetId,
			bonusLuck = 4,
			timeRemaining = timeRemaining > 0 and string.format("%.1f min", timeRemaining / 60) or "Active",
			timeRemainingSeconds = math.max(0, math.floor(timeRemaining)),
		}
	end

	activeStates.BGSI_Lite_UpdateRiftDisplay = function()
		local activeRifts = activeStates.BGSI_Lite_BuildRiftSnapshot()
		if not activeRifts then
			activeStates.BGSI_Lite_DashboardRifts = {}
			riftDisplay:Set("No rifts folder found.")
			return
		end

		activeStates.BGSI_Lite_DashboardRifts = activeRifts

		if #activeRifts == 0 then
			riftDisplay:Set("No active rifts found.")
		else
			local lines = {}
			for i, rift in ipairs(activeRifts) do
				table.insert(lines, string.format("%d. %s [%s]", i, rift.name, rift.type))
				table.insert(lines, string.format("   World: %-18s Time left: %s", rift.world, rift.timeRemaining))
				table.insert(lines, string.format("   -> %s", rift.actionLabel))
				if i < #activeRifts then
					table.insert(lines, "")
				end
			end
			riftDisplay:Set(table.concat(lines, "\n"))
		end
	end

	-- Initial update
	task.spawn(function()
		while isCurrentRun() do
			-- Not pcall-wrapping this used to mean a single bad frame (a rift model missing
			-- an expected attribute, a data module not loaded, etc.) would throw once, kill
			-- this whole coroutine, and leave the box stuck on "Scanning for active
			-- rifts..." forever with no further attempts and no visible error at all.
			local ok, err = pcall(activeStates.BGSI_Lite_UpdateRiftDisplay)
			if not ok then
				warn("[1rzHub Lite] Rift display update failed: " .. tostring(err))
				pcall(function()
					riftDisplay:Set("Rift scan failed: " .. tostring(err) .. "\nRetrying in 5s...")
				end)
			end
			task.wait(5)
		end
	end)
	
	riftsTab:AddSection("Rift Actions")
	riftsTab:AddButton("Teleport to Rift", function()
		local riftsFolder = Workspace:FindFirstChild("Rendered") and Workspace.Rendered:FindFirstChild("Rifts")
		if not riftsFolder then
			Interface:Notify({
				Title = "Error",
				Content = "No rifts folder found.",
				Duration = 3,
			})
			return
		end
		
		for _, riftModel in ipairs(riftsFolder:GetChildren()) do
			if riftModel:IsA("Model") then
				local despawnAt = tonumber(riftModel:GetAttribute("DespawnAt"))
				local timeRemaining = despawnAt and (despawnAt - getCurrentTimestamp()) or 0
				
				if timeRemaining > 0 then
					local riftTarget = activeStates.BGSI_Lite_GetRiftTargetCFrame(riftModel)
					if riftTarget and teleportToCFrame(riftTarget + Vector3.new(0, 3, 0)) then
						Interface:Notify({
							Title = "Teleported",
							Content = string.format("Teleported to %s", riftModel.Name),
							Duration = 3,
						})
						return
					end
				end
			end
		end
		
		Interface:Notify({
			Title = "Error",
			Content = "No active rifts found to teleport to.",
			Duration = 3,
		})
	end)
	
	riftsTab:AddButton("Start Hatching at Rift", function()
		local riftsFolder = Workspace:FindFirstChild("Rendered") and Workspace.Rendered:FindFirstChild("Rifts")
		if not riftsFolder then
			Interface:Notify({
				Title = "Error",
				Content = "No rifts folder found.",
				Duration = 3,
			})
			return
		end
		
		for _, riftModel in ipairs(riftsFolder:GetChildren()) do
			if riftModel:IsA("Model") then
				local riftInfo = type(riftData) == "table" and riftData[riftModel.Name] or nil
				local riftType = riftModel:GetAttribute("Type") or (riftInfo and riftInfo.Type)
				local despawnAt = tonumber(riftModel:GetAttribute("DespawnAt"))
				local timeRemaining = despawnAt and (despawnAt - getCurrentTimestamp()) or 0
				
				-- Only hatch at egg-type rifts
				if riftType == "Egg" and timeRemaining > 0 then
					local riftTarget = activeStates.BGSI_Lite_GetRiftTargetCFrame(riftModel)
					if riftTarget and teleportToCFrame(riftTarget + Vector3.new(0, 3, 0)) then
						
						-- Enable auto hatch if not already enabled
						if not Config.autoHatch then
							Config.autoHatch = true
							saveConfig()
						end
						
						Interface:Notify({
							Title = "Hatching Started",
							Content = string.format("Teleported to %s and started auto-hatching", riftModel.Name),
							Duration = 3,
						})
						return
					end
				end
			end
		end
		
		Interface:Notify({
			Title = "Error",
			Content = "No active egg rifts found to hatch at.",
			Duration = 3,
		})
	end)
end
end
}
