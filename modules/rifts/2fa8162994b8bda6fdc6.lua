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

	-- The summoned-egg area keeps a dormant "4x Luck" egg's data next to whatever admin
	-- egg is really up, so the first egg name found there is often the wrong one. An
	-- admin egg named anywhere in it wins.
	activeStates.BGSI_Lite_FindAdminEggName = function()
		local root = Workspace:FindFirstChild("SummonedEgg")
		if not root or type(eggDataModule) ~= "table" then
			return nil
		end
		local adminNames = {}
		for name, info in pairs(eggDataModule) do
			if type(name) == "string" and type(info) == "table" and info.IsAdminEgg == true then
				table.insert(adminNames, name)
			end
		end
		table.sort(adminNames, function(left, right)
			return #left > #right
		end)
		local function match(value)
			if type(value) ~= "string" or value == "" then
				return nil
			end
			local text = value:gsub("<[^>]->", "")
			local info = eggDataModule[text]
			if type(info) == "table" and info.IsAdminEgg == true then
				return text
			end
			local lower = text:lower()
			for _, name in ipairs(adminNames) do
				if lower:find(name:lower(), 1, true) then
					return name
				end
			end
			return nil
		end
		local objects = root:GetDescendants()
		table.insert(objects, 1, root)
		for _, extraName in ipairs({ "EggText", "EggPlatformSpawn" }) do
			local extra = Workspace:FindFirstChild(extraName)
			if extra then
				table.insert(objects, extra)
				for _, child in ipairs(extra:GetDescendants()) do
					table.insert(objects, child)
				end
			end
		end
		for _, object in ipairs(objects) do
			local found = match(object.Name)
			if not found and object:IsA("StringValue") then
				found = match(object.Value)
			end
			if not found and (object:IsA("TextLabel") or object:IsA("TextButton")) then
				found = match(object.Text)
			end
			if not found then
				for _, value in pairs(object:GetAttributes()) do
					found = match(value)
					if found then
						break
					end
				end
			end
			if found then
				return found
			end
		end
		return nil
	end

	-- The luck sign (a clover with "x200000" and a countdown) is a world GUI the game
	-- places by the summoned egg. Every billboard and surface GUI in the world is kept in
	-- a list as it appears, so finding the sign is a walk over a few dozen GUIs rather
	-- than the whole map.
	if not activeStates.BGSI_Lite_WorldGuis then
		activeStates.BGSI_Lite_WorldGuis = setmetatable({}, { __mode = "k" })
		local function track(object)
			if object:IsA("BillboardGui") or object:IsA("SurfaceGui") then
				activeStates.BGSI_Lite_WorldGuis[object] = true
			end
		end
		task.spawn(function()
			for _, object in ipairs(Workspace:GetDescendants()) do
				track(object)
			end
		end)
		Workspace.DescendantAdded:Connect(track)
	end
	activeStates.BGSI_Lite_FindLuckSign = function()
		local best
		for gui in pairs(activeStates.BGSI_Lite_WorldGuis) do
			if gui.Parent and gui.Enabled ~= false then
				local multiplier, seconds
				for _, label in ipairs(gui:GetDescendants()) do
					if (label:IsA("TextLabel") or label:IsA("TextButton")) and label.Visible then
						local text = tostring(label.Text or ""):gsub("<[^>]->", ""):match("^%s*(.-)%s*$")
						local multi = text:match("^[xX×]%s*([%d,%.]+)$") or text:match("^([%d,%.]+)%s*[xX×]$")
						if multi then
							multiplier = tonumber((multi:gsub(",", ""))) or multiplier
						end
						local h, m, sec = text:match("^(%d+):(%d%d):(%d%d)$")
						if h then
							seconds = tonumber(h) * 3600 + tonumber(m) * 60 + tonumber(sec)
						else
							m, sec = text:match("^(%d+):(%d%d)$")
							if m then
								seconds = tonumber(m) * 60 + tonumber(sec)
							end
						end
					end
				end
				if multiplier and multiplier > 1 and seconds and (not best or multiplier > best.multiplier) then
					best = { multiplier = multiplier, seconds = seconds }
				end
			end
		end
		return best
	end

	-- A summoned luck egg (4x Luck, or an admin egg with its own multiplier such as
	-- "x250,000 Admin DIY Egg"). Reads the real egg name from the game's egg list, the
	-- multiplier and timing from the summoned egg's attributes or its billboard text,
	-- and sends a short sample of what it saw so the dashboard can be tuned against it.
	activeStates.BGSI_Lite_BuildLuckEventSnapshot = function()
		local root = Workspace:FindFirstChild("SummonedEgg")
		if not root and not activeStates.BGSI_Lite_FindLuckSign() then
			return nil
		end
		local objects = root and root:GetDescendants() or {}
		if root then
			table.insert(objects, 1, root)
		end
		local eggs = type(eggDataModule) == "table" and eggDataModule or {}
		local function parseNumber(text)
			local digits = tostring(text or ""):gsub(",", "")
			local number = tonumber(digits)
			if not number then
				local value, suffix = digits:match("^([%d%.]+)([kKmMbB])$")
				local scale = suffix and ({ k = 1e3, m = 1e6, b = 1e9 })[suffix:lower()]
				number = value and scale and tonumber(value) and tonumber(value) * scale or nil
			end
			return number
		end
		local function parseClock(text)
			local h, m, sec = text:match("(%d+):(%d%d):(%d%d)")
			if h then
				return tonumber(h) * 3600 + tonumber(m) * 60 + tonumber(sec)
			end
			m, sec = text:match("(%d+):(%d%d)")
			if m then
				return tonumber(m) * 60 + tonumber(sec)
			end
			local total, found = 0, false
			for amount, unit in text:lower():gmatch("(%d+)%s*([hms])%f[%A]") do
				found = true
				total += tonumber(amount) * (unit == "h" and 3600 or unit == "m" and 60 or 1)
			end
			return found and total or nil
		end
		local eggName, multiplier, spawnAt, endsAt, duration
		local spawnIn, timeLeft
		local sample = {}
		local now = getCurrentTimestamp()
		local function consider(label, value)
			if #sample < 40 then
				table.insert(sample, { key = tostring(label):sub(1, 40), value = tostring(value):sub(1, 80) })
			end
			if type(value) == "number" then
				local key = tostring(label):lower()
				if key:find("luck") or key:find("multi") or key:find("boost") then
					if value > 1 then
						multiplier = math.max(multiplier or 0, value)
					end
				elseif key:find("despawn") or key:find("expire") or key:find("endat") or key:find("endtime") or key:find("endsat") then
					endsAt = math.max(endsAt or 0, value)
				elseif key:find("spawn") or key:find("start") or key:find("open") then
					spawnAt = math.max(spawnAt or 0, value)
				elseif key:find("duration") or key:find("lifetime") then
					duration = value
				end
				return
			end
			if type(value) ~= "string" or value == "" then
				return
			end
			local text = value:gsub("<[^>]->", ""):gsub("&nbsp;", " ")
			if not eggName then
				if type(eggs[text]) == "table" then
					eggName = text
				else
					for name, info in pairs(eggs) do
						if type(name) == "string" and type(info) == "table"
							and (info.IsAdminEgg == true or name:lower():match("^%d+x%s+luck"))
							and text:lower():find(name:lower(), 1, true)
						then
							eggName = name
							break
						end
					end
				end
			end
			-- "x250,000", "250,000x", "250K x Luck"
			local multi = text:match("[xX]%s*([%d,%.]+[kKmMbB]?)") or text:match("([%d,%.]+[kKmMbB]?)%s*[xX]%f[%A]")
			local parsed = multi and parseNumber(multi)
			if parsed and parsed > 1 then
				multiplier = math.max(multiplier or 0, parsed)
			end
			local seconds = parseClock(text)
			if seconds then
				local lower = text:lower()
				if lower:find("spawn") or lower:find("arriv") or lower:find("in ") or lower:find("soon") then
					spawnIn = seconds
				else
					timeLeft = seconds
				end
			end
		end
		for _, object in ipairs(objects) do
			consider("name", object.Name)
			if object:IsA("StringValue") or object:IsA("NumberValue") or object:IsA("IntValue") then
				consider(object.Name, object.Value)
			end
			if object:IsA("TextLabel") or object:IsA("TextButton") or object:IsA("TextBox") then
				consider("text", object.Text)
			end
			for attributeName, attributeValue in pairs(object:GetAttributes()) do
				consider(attributeName, attributeValue)
			end
		end
		eggName = activeStates.BGSI_Lite_FindAdminEggName() or eggName
		for _, extraName in ipairs({ "EggText", "EggPlatformSpawn" }) do
			local extra = Workspace:FindFirstChild(extraName)
			if extra then
				for _, object in ipairs(extra:GetDescendants()) do
					if object:IsA("TextLabel") or object:IsA("TextButton") then
						consider(extraName .. ".text", object.Text)
					end
				end
				for attributeName, attributeValue in pairs(extra:GetAttributes()) do
					consider(extraName .. "." .. attributeName, attributeValue)
				end
			end
		end
		if not eggName then
			local luckName = activeStates.BGSI_Lite_FindLuckEggName and activeStates.BGSI_Lite_FindLuckEggName()
			eggName = luckName
		end
		local sign = activeStates.BGSI_Lite_FindLuckSign()
		local eggSign = root and root:FindFirstChild("Sign")
		local signGui = eggSign and eggSign:FindFirstChild("Display") and eggSign.Display:FindFirstChildWhichIsA("SurfaceGui")
		if signGui then
			for _, label in ipairs(signGui:GetDescendants()) do
				if label:IsA("TextLabel") or label:IsA("TextButton") then
					local text = tostring(label.Text or ""):gsub("<[^>]->", ""):match("^%s*(.-)%s*$")
					local multi = text:match("^[xX×]%s*([%d,%.]+)$")
					local value = multi and tonumber((multi:gsub(",", "")))
					if value and value > 1 then
						multiplier = value
					end
					local m, sec = text:match("(%d+):(%d%d)")
					if m and not timeLeft then
						timeLeft = tonumber(m) * 60 + tonumber(sec)
					end
				end
			end
		end
		if sign then
			multiplier = sign.multiplier
			timeLeft = timeLeft or sign.seconds
			table.insert(sample, 1, { key = "sign", value = "x" .. tostring(sign.multiplier) .. " " .. tostring(sign.seconds) .. "s" })
		end
		if not eggName then
			-- The sign is up but no egg name was found: still show the boost, and send
			-- what was read either way so a miss can be traced.
			if multiplier and multiplier > 1 then
				-- Use the egg's own billboard title ("Admin Abuse Egg!") when there is one.
				local title
				for _, object in ipairs(objects) do
					if object.Name == "Title" and (object:IsA("TextLabel") or object:IsA("TextButton")) then
						title = tostring(object.Text or ""):gsub("<[^>]->", ""):gsub("!+%s*$", ""):match("^%s*(.-)%s*$")
						if title ~= "" then
							break
						end
					end
				end
				eggName = (title and title ~= "") and title:sub(1, 60) or "Admin Egg"
			else
				return { id = "probe", name = "", multiplier = 0, sample = sample }
			end
		end
		if not multiplier then
			multiplier = tonumber(eggName:lower():match("^(%d+)x%s+luck"))
		end
		local secondsUntilSpawn = spawnIn or (spawnAt and spawnAt > now and spawnAt - now) or 0
		local secondsLeft = timeLeft or (endsAt and endsAt > now and endsAt - now) or 0
		if secondsLeft <= 0 and duration and secondsUntilSpawn > 0 then
			secondsLeft = secondsUntilSpawn + duration
		end
		local info = eggs[eggName]
		-- Remembered so the account's current egg shows the admin egg, not the dormant
		-- "4x Luck" egg whose name the summoned egg keeps in game.
		if not eggName:lower():match("^%d+x%s+luck") then
			activeStates.BGSI_Lite_LuckEventName = eggName
			activeStates.BGSI_Lite_LuckEventSeenAt = os.clock()
		end
		return {
			id = string.lower(eggName),
			name = eggName,
			admin = type(info) == "table" and info.IsAdminEgg == true or false,
			multiplier = multiplier or 0,
			iconAssetId = type(info) == "table" and tostring(info.Image or ""):match("%d+") or "",
			world = type(info) == "table" and tostring(info.World or "") or "",
			secondsUntilSpawn = math.max(0, math.floor(secondsUntilSpawn)),
			secondsLeft = math.max(0, math.floor(secondsLeft)),
			duration = duration and math.floor(duration) or nil,
			sample = sample,
		}
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
