-- Generated from larplite.lua; rebuild with tools/build_modules.py.
return {
function(...)
activeStates.BGSI_Lite_FleetInit = function()
	if type(writefile) ~= "function" or type(readfile) ~= "function" or type(isfile) ~= "function" then
		warn("[LarpLite Fleet] This executor has no file access - fleet sync is disabled.")
		return
	end

	local PREFIX = "LarpLiteFleet_"
	local myId = tostring(LocalPlayer.UserId)
	local myFile = PREFIX .. "acct_" .. myId .. ".json"
	local settingsFile = PREFIX .. "settings.json"
	local revFile = PREFIX .. "rev.txt"
	local pinFile = PREFIX .. "pin.json"
	local registryFile = PREFIX .. "registry.json"
	local teleportFile = PREFIX .. "teleport.json"
	local teleportAckFile = PREFIX .. "teleport_ack_" .. myId .. ".json"
	local ALIVE_SECONDS = 20 -- a heartbeat older than this means the account is gone (a server hop takes a while)
	local PULL_INTERVAL = 0.1 -- how often an alt checks for a new settings revision
	local ROSTER_INTERVAL = 0.5
	local HEARTBEAT_INTERVAL = 1

	local fleet = {
		role = "solo", -- "solo", "master" (displayed as Leader) or "alt"
		masterId = nil,
		roster = {},
		rev = 0, -- last revision this account published as master
		appliedRev = 0, -- last revision this account applied (or published)
		dirty = false,
		applying = false,
		lastSignature = nil,
		lastApplyAt = nil,
		lastApplyCount = 0,
		tabBuilt = false,
		ui = {},
		masterControls = {},
		handoverName = nil,
		stopped = false,
	}
	activeStates.BGSI_Lite_Fleet = fleet

	-- Keep runtime state and Fleet transport controls local. All user-configurable
	-- gameplay, webhook, dropdown, and slider settings are part of a Fleet snapshot.
	local excludedKeys = {
		safeMode = true,
		safeModeSavedConfig = true,
		lastSeenScriptVersion = true,
		LiveWebhookMessageIds = true,
		fleetFollowMaster = true,
		fleetAutoPush = true,
	}
	local function isSyncKey(key)
		if type(key) ~= "string" or excludedKeys[key] then
			return false
		end
		local valueType = type(defaultConfig[key])
		return valueType == "boolean" or valueType == "number" or valueType == "string" or valueType == "table"
	end

	-- ------------------------------------------------------------------ files --
	local function fileExists(path)
		local ok, exists = pcall(isfile, path)
		return ok and exists == true
	end
	local function readJson(path)
		if not fileExists(path) then
			return nil
		end
		local ok, data = pcall(function()
			return HttpService:JSONDecode(readfile(path))
		end)
		if ok and type(data) == "table" then
			return data
		end
		return nil -- missing, or caught mid-write by another account: try again next tick
	end
	local function writeJson(path, value)
		return pcall(function()
			writefile(path, HttpService:JSONEncode(value))
		end)
	end

	-- A reload (auto-update) must not send a long-running Leader to the back of the
	-- queue, so a recent heartbeat from this same account keeps its original start time.
	local startedAt = tick()
	do
		local previous = readJson(myFile)
		if previous and tonumber(previous.startedAt) and tick() - (tonumber(previous.lastSeen) or 0) <= 60 then
			startedAt = tonumber(previous.startedAt)
		end
	end

	local function writeHeartbeat()
		writeJson(myFile, {
			id = myId,
			name = LocalPlayer.Name,
			startedAt = startedAt,
			lastSeen = tick(),
			version = tostring(activeStates.BGSI_Lite_ScriptVersion or "?"),
			appliedRev = fleet.appliedRev,
			follow = Config.fleetFollowMaster == true,
			role = fleet.role,
		})
	end

	-- ----------------------------------------------------------------- roster --
	local function listAccountIds()
		local ids, seen = {}, {}
		local function add(id)
			id = tostring(id)
			if id:match("^%d+$") and not seen[id] then
				seen[id] = true
				table.insert(ids, id)
			end
		end
		add(myId)
		if type(listfiles) == "function" then
			for _, root in ipairs({ "", "." }) do
				local ok, files = pcall(listfiles, root)
				if ok and type(files) == "table" then
					for _, path in ipairs(files) do
						local id = tostring(path):match(PREFIX .. "acct_(%d+)%.json$")
						if id then
							add(id)
						end
					end
					if #files > 0 then
						break
					end
				end
			end
		end
		-- Executors without listfiles fall back to a shared list of every id ever seen.
		local registry = readJson(registryFile)
		for _, id in ipairs(registry and registry.ids or {}) do
			add(id)
		end
		return ids
	end
	local function ensureRegistered()
		local registry = readJson(registryFile) or { ids = {} }
		if type(registry.ids) ~= "table" then
			registry.ids = {}
		end
		for _, id in ipairs(registry.ids) do
			if tostring(id) == myId then
				return
			end
		end
		table.insert(registry.ids, myId)
		writeJson(registryFile, registry)
	end

	local function readRoster()
		local now = tick()
		local list = {}
		for _, id in ipairs(listAccountIds()) do
			local record
			if id == myId then
				record = {
					name = LocalPlayer.Name,
					startedAt = startedAt,
					lastSeen = now,
					version = activeStates.BGSI_Lite_ScriptVersion,
					appliedRev = fleet.appliedRev,
					follow = Config.fleetFollowMaster == true,
				}
			else
				record = readJson(PREFIX .. "acct_" .. id .. ".json")
			end
			if record and now - (tonumber(record.lastSeen) or 0) <= ALIVE_SECONDS then
				table.insert(list, {
					id = id,
					name = tostring(record.name or id),
					startedAt = tonumber(record.startedAt) or now,
					version = tostring(record.version or "?"),
					appliedRev = tonumber(record.appliedRev) or 0,
					follow = record.follow ~= false,
				})
			end
		end
		table.sort(list, function(a, b)
			if a.startedAt ~= b.startedAt then
				return a.startedAt < b.startedAt
			end
			return (tonumber(a.id) or 0) < (tonumber(b.id) or 0)
		end)
		return list
	end

	-- Every account runs this same function over the same files, so they all agree on the
	-- answer without talking to each other. A pin wins while that account is online;
	-- otherwise the longest-running account is Leader. A lone account is never Leader.
	local function electMaster(list)
		if #list < 2 then
			return nil
		end
		local pin = readJson(pinFile)
		if pin and pin.id ~= nil then
			for _, entry in ipairs(list) do
				if entry.id == tostring(pin.id) then
					return entry.id
				end
			end
		end
		return list[1].id
	end

	-- --------------------------------------------------------------- settings --
	-- While Safe Mode has everything switched off, the settings worth sharing are the
	-- ones it saved, not the all-off values currently in Config.
	local function getSourceConfig()
		local source = {}
		for key in pairs(defaultConfig) do
			if isSyncKey(key) then
				source[key] = Config[key]
			end
		end
		if Config.safeMode == true and type(Config.safeModeSavedConfig) == "table" then
			for key, value in pairs(Config.safeModeSavedConfig) do
				if isSyncKey(key) and type(value) == type(defaultConfig[key]) then
					source[key] = value
				end
			end
		end
		return source
	end

	-- Deterministic text form of the settings, used only to skip pushes that wouldn't
	-- change anything (table iteration order is not stable, JSONEncode would not be).
	local function stableEncode(value)
		if type(value) == "table" then
			local keys = {}
			for key in pairs(value) do
				table.insert(keys, key)
			end
			table.sort(keys, function(a, b)
				return tostring(a) < tostring(b)
			end)
			local parts = {}
			for _, key in ipairs(keys) do
				table.insert(parts, tostring(key) .. ":" .. stableEncode(value[key]))
			end
			return "{" .. table.concat(parts, ",") .. "}"
		end
		return string.sub(type(value), 1, 1) .. tostring(value)
	end

	local updateUi -- assigned below

	local function pushSettings(force, applyToAll)
		if fleet.role ~= "master" then
			return false
		end
		local source = getSourceConfig()
		local signature = stableEncode(source)
		if not force and signature == fleet.lastSignature then
			return false
		end
		local rev = math.max(fleet.rev + 1, math.floor(tick() * 1000))
		-- Settings first, revision second: an alt only reads the settings after it has
		-- seen a new revision, so it never reads a half-published set.
		local wroteSettings = writeJson(settingsFile, {
			rev = rev,
			from = myId,
			fromName = LocalPlayer.Name,
			at = tick(),
			forceApply = applyToAll == true,
			config = source,
		})
		if not wroteSettings then
			return false
		end
		local wroteRevision = pcall(writefile, revFile, tostring(rev) .. ":" .. myId)
		if not wroteRevision then return false end
		fleet.lastSignature = signature
		fleet.rev = rev
		fleet.appliedRev = rev
		fleet.pushedAt = tick()
		writeHeartbeat()
		return true
	end

	-- Same follow-up work the Account Dashboard's "apply config" command does, so a
	-- setting pushed from the Leader behaves exactly like one applied from the dashboard.
	local function applyRemoteConfig(remoteConfig)
		local applied = 0
		local previousLiveEnabled = Config.LiveWebhookEnabled
		local previousLiveUrl = Config.LiveWebhookURL
		fleet.applying = true
		local ok, err = pcall(function()
			local function assignSettings(countApplied)
				for key, value in pairs(remoteConfig) do
					if isSyncKey(key) and type(value) == type(defaultConfig[key]) then
						if Config.safeMode == true and type(Config.safeModeSavedConfig) == "table" then
							Config.safeModeSavedConfig[key] = value
						else
							Config[key] = value
						end
						if countApplied then applied += 1 end
					end
				end
			end
			assignSettings(true)
			pcall(activeStates.BGSI_Lite_RefreshFleetUiControls, remoteConfig)
			pcall(activeStates.BGSI_Lite_RefreshEggLocationDropdown, true)
			assignSettings(false)
			saveConfig()
			activeStates.BGSI_Lite_LastQuestAutomationAt = tick()
			activeStates.BGSI_Lite_LastAutoEnchantTeamAttempt = 0
			activeStates.BGSI_Lite_AutoEnchantBlockedUntil = 0
			activeStates.BGSI_Lite_ForceAutoHatchTeleport = Config.autoHatch == true
			activeStates.AutoGuessThatPet = Config.autoGuessThatPet
			activeStates.BGSI_Lite_QuestNoProgressTimeout = Config.questStallTimeoutSeconds
			clearDisabledPriorityStates()
			pcall(activeStates.BGSI_Lite_ApplyHatchAnimationSetting)
			pcall(activeStates.BGSI_Lite_RequestAutoSetupTeamRefresh)
			if previousLiveEnabled ~= Config.LiveWebhookEnabled or previousLiveUrl ~= Config.LiveWebhookURL then
				if Config.LiveWebhookEnabled == true and tostring(Config.LiveWebhookURL or "") ~= "" then
					pcall(activeStates.BGSI_Lite_StartLiveWebhook)
				else
					pcall(activeStates.BGSI_Lite_StopLiveWebhook)
				end
			end
			_G.BGSI_CHUNK_RENDER_DISTANCE = Config.chunkerRenderDistance
			pcall(function()
				RunService:Set3dRenderingEnabled(Config.safeMode == true or not Config.disableRendering)
			end)
			activeStates.BGSI_Lite_ApplyPerformanceSettings()
			pcall(installChunkerRenderDistanceHook)
			pcall(refreshChunkerAroundPlayer)
		end)
		fleet.applying = false
		return ok, applied, err
	end

	local lastSeenRevText
	local function pullFromMaster()
		if fleet.role ~= "alt" or not fileExists(revFile) then
			return
		end
		local readOk, text = pcall(readfile, revFile)
		if not readOk or type(text) ~= "string" or text == lastSeenRevText then
			return
		end
		local revText, fromId = text:match("^(%d+):(%d+)$")
		-- Only the current Leader is listened to; a stale revision left by a previous
		-- Leader is ignored (and not marked as seen, in case that account takes over).
		if not revText or fromId ~= fleet.masterId then
			return
		end
		local rev = tonumber(revText)
		if rev == fleet.appliedRev then
			lastSeenRevText = text
			return
		end
		local payload = readJson(settingsFile)
		if
			not payload
			or tonumber(payload.rev) ~= rev
			or tostring(payload.from) ~= fromId
			or type(payload.config) ~= "table"
		then
			return -- caught mid-write; the next poll picks it up
		end
		if Config.fleetFollowMaster ~= true and payload.forceApply ~= true then
			lastSeenRevText = text
			return
		end
		local ok, applied, err = applyRemoteConfig(payload.config)
		if ok then
			lastSeenRevText = text
			fleet.appliedRev = rev
			fleet.lastApplyAt = tick()
			fleet.lastApplyCount = applied
			writeHeartbeat() -- tells the master this account is up to date, right away
			print(
				"["
					.. LocalPlayer.Name
					.. "] Fleet: applied "
					.. tostring(applied)
					.. " setting(s) from Leader "
					.. tostring(payload.fromName or fromId)
			)
			updateUi()
		else
			warn("[LarpLite Fleet] Could not apply Leader settings: " .. tostring(err))
		end
	end

	-- Hook saveConfig: every setting change in the UI ends in a saveConfig() call, so on
	-- the Leader that is the exact moment to publish. The push itself runs on the next
	-- frame so several changes in one frame go out as a single revision.
	local originalSaveConfig = saveConfig
	saveConfig = function(...)
		originalSaveConfig(...)
		if fleet.role == "master" and Config.fleetAutoPush == true and not fleet.applying then
			fleet.dirty = true
		end
	end

	-- ------------------------------------------------------------- dark blue --
	local tint = {
		root = nil,
		active = false,
		records = {},
		rootConnections = {},
	}
	local function mapBackground(color)
		local _, saturation, value = color:ToHSV()
		if saturation > 0.45 or value > 0.55 then
			return nil -- already a vivid/accent or light colour: leave it alone
		end
		return Color3.fromHSV(0.615, 0.80, math.clamp(0.13 + value * 1.1, 0.13, 0.6))
	end
	local function mapStroke(color)
		local _, saturation, value = color:ToHSV()
		if saturation > 0.45 or value > 0.85 then
			return nil
		end
		return Color3.fromHSV(0.61, 0.65, math.clamp(0.25 + value * 0.9, 0.25, 0.85))
	end

	local function retint(instance, property, mapper)
		local record = tint.records[instance]
		local current = instance[property]
		if record and record.applied == current then
			return
		end
		local mapped = mapper(current)
		if not mapped then
			return
		end
		record = record or {}
		record.property = property
		record.original = current
		record.applied = mapped
		tint.records[instance] = record
		instance[property] = mapped
	end
	local function watch(instance)
		local record = tint.records[instance]
		local property, mapper
		if instance:IsA("GuiObject") then
			property, mapper = "BackgroundColor3", mapBackground
		elseif instance:IsA("UIStroke") then
			property, mapper = "Color", mapStroke
		else
			return
		end
		if record and record.connection then
			return
		end
		record = record or {}
		tint.records[instance] = record
		record.property = record.property or property
		-- The UI library animates colours (hover, selection). Every step passes through
		-- the same mapping, so animations stay smooth and stay blue.
		record.connection = instance:GetPropertyChangedSignal(property):Connect(function()
			if tint.active then
				pcall(retint, instance, property, mapper)
			end
		end)
		if instance:IsA("GuiObject") and instance.BackgroundTransparency >= 0.98 then
			return
		end
		pcall(retint, instance, property, mapper)
	end

	local function findWindowRoot()
		if tint.root and tint.root.Parent then
			return tint.root
		end
		local containers = {}
		pcall(function()
			if type(gethui) == "function" then
				table.insert(containers, gethui())
			end
		end)
		table.insert(containers, CoreGui)
		pcall(function()
			table.insert(containers, LocalPlayer:FindFirstChildOfClass("PlayerGui"))
		end)
		for _, container in ipairs(containers) do
			local okChildren, children = pcall(function()
				return container:GetChildren()
			end)
			if okChildren then
				for _, gui in ipairs(children) do
					if gui:IsA("ScreenGui") and gui.Name ~= "OpenUI" then
						for _, descendant in ipairs(gui:GetDescendants()) do
							if
								descendant:IsA("TextLabel")
								and type(descendant.Text) == "string"
								and string.find(descendant.Text, "LarpLite", 1, true)
							then
								tint.root = gui
								return gui
							end
						end
					end
				end
			end
		end
		return nil
	end

	local function restoreTint()
		for instance, record in pairs(tint.records) do
			if record.connection then
				record.connection:Disconnect()
			end
			if record.original ~= nil then
				pcall(function()
					instance[record.property] = record.original
				end)
			end
		end
		tint.records = {}
		for _, connection in ipairs(tint.rootConnections) do
			connection:Disconnect()
		end
		tint.rootConnections = {}
	end

	local function setMasterTint(on)
		if on == tint.active then
			return
		end
		tint.active = on
		if not on then
			restoreTint()
			return
		end
		task.spawn(function()
			local root
			for _ = 1, 10 do
				root = findWindowRoot()
				if root or not tint.active then
					break
				end
				task.wait(0.5)
			end
			if not tint.active then
				return
			end
			if not root then
				tint.active = false
				warn("[LarpLite Fleet] Could not find the window to tint dark blue.")
				return
			end
			table.insert(
				tint.rootConnections,
				root.DescendantAdded:Connect(function(descendant)
					task.defer(function()
						if tint.active and descendant.Parent then
							pcall(watch, descendant)
						end
					end)
				end)
			)
			table.insert(
				tint.rootConnections,
				root.DescendantRemoving:Connect(function(descendant)
					local record = tint.records[descendant]
					if record then
						if record.connection then
							record.connection:Disconnect()
						end
						tint.records[descendant] = nil
					end
				end)
			)
			local scanned = 0
			for _, descendant in ipairs(root:GetDescendants()) do
				if not tint.active then
					return
				end
				pcall(watch, descendant)
				scanned += 1
				if scanned % 250 == 0 then
					task.wait() -- spread the first pass over a few frames
				end
			end
		end)
	end

	-- --------------------------------------------------------------------- ui --
	local function setControlLocked(control, locked, reason)
		local ok = pcall(function()
			if locked then
				control:Lock(reason)
			else
				control:Unlock()
			end
		end)
		if not ok then
			pcall(function()
				if locked then
					control.Native:Lock(reason)
				else
					control.Native:Unlock()
				end
			end)
		end
	end
	local function setMasterControlsLocked(locked)
		for _, control in ipairs(fleet.masterControls) do
			setControlLocked(control, locked, "This account is not the Leader")
		end
	end

	local function shortVersion(version)
		return tostring(version):gsub("^20", "")
	end
	local function describeRoster(withSyncState)
		local lines = {}
		for _, entry in ipairs(fleet.roster) do
			local isMaster = entry.id == fleet.masterId
			local line = (isMaster and "★ " or "• ")
				.. entry.name
				.. (entry.id == myId and " (you)" or "")
				.. "  ·  "
				.. (isMaster and "Leader" or "alt")
				.. "  ·  v"
				.. shortVersion(entry.version)
			if withSyncState and not isMaster then
				if entry.follow == false then
					line = line .. "  ·  not following"
				elseif fleet.rev > 0 and entry.appliedRev >= fleet.rev then
					line = line .. "  ·  synced"
				else
					line = line .. "  ·  syncing…"
				end
			end
			table.insert(lines, line)
		end
		if #lines == 0 then
			return "No accounts detected."
		end
		return table.concat(lines, "\n")
	end
	local function masterName()
		for _, entry in ipairs(fleet.roster) do
			if entry.id == fleet.masterId then
				return entry.name
			end
		end
		return "none"
	end

	local lastShown = {}
	local function setText(key, element, title, content)
		local signature = tostring(title) .. "\0" .. tostring(content)
		if lastShown[key] == signature then
			return
		end
		lastShown[key] = signature
		pcall(function()
			element:SetTitle(title)
		end)
		pcall(function()
			element:Set(content)
		end)
	end

	local NO_OTHER_ACCOUNT = "No other account online"
	local lastHandoverSignature
	updateUi = function()
		local count = #fleet.roster
		local ui = fleet.ui
		if ui.otherStatus then
			local title, content
			if fleet.role == "master" then
					title = "You are the Leader"
				content = describeRoster(false)
					.. "\n\nChanges you make on this account are sent to the other "
					.. tostring(count - 1)
					.. " account(s) automatically."
			elseif fleet.role == "alt" then
				title = "Following Leader: " .. masterName()
				content = describeRoster(false)
				if fleet.lastApplyAt then
					content = content
						.. "\n\nLast sync "
						.. tostring(math.floor(tick() - fleet.lastApplyAt))
						.. "s ago ("
						.. tostring(fleet.lastApplyCount)
						.. " settings)."
				end
				if Config.fleetFollowMaster ~= true then
					content = content .. "\n\nFollowing is OFF - this account keeps its own settings."
				end
			else
				title = "No other accounts detected"
				content = "Open the script on another account on this PC and it will show up here."
			end
			setText("otherStatus", ui.otherStatus, title, content)
		end
		if ui.masterStatus then
			local statusTitle = fleet.role == "master" and "Leader account" or ("Current Leader: " .. masterName())
			local statusContent = describeRoster(true)
			if fleet.role == "master" then
				statusContent = tostring(count - 1) .. " other account(s) online.\n" .. statusContent
			end
			setText("masterStatus", ui.masterStatus, statusTitle, statusContent)
		end
		if ui.handover then
			local names, signature = {}, ""
			for _, entry in ipairs(fleet.roster) do
				if entry.id ~= myId then
					table.insert(names, entry.name)
					signature = signature .. entry.name .. "|"
				end
			end
			if signature ~= lastHandoverSignature then
				lastHandoverSignature = signature
				pcall(function()
					ui.handover:Refresh(#names > 0 and names or { NO_OTHER_ACCOUNT })
				end)
			end
		end
	end

	local function pinMaster(accountId)
		writeJson(pinFile, { id = tostring(accountId), by = myId, at = tick() })
	end
	local function clearPin()
		if type(delfile) == "function" and fileExists(pinFile) then
			pcall(delfile, pinFile)
		else
			writeJson(pinFile, {})
		end
	end
	local function notify(content, duration)
		pcall(function()
			Interface:Notify({ Title = "Account Fleet", Content = content, Duration = duration or 4 })
		end)
	end

	local lastAppliedTeleportId
	local lastJoinTeleportId, lastJoinAttemptAt
	local function pullLeaderTeleport()
		if fleet.role ~= "alt" then return end
		local command = readJson(teleportFile)
		if type(command) ~= "table" or tostring(command.from or "") ~= fleet.masterId then return end
		local commandId = tostring(command.id or "")
		local issuedAt = tonumber(command.issuedAt) or 0
		if commandId == "" or math.abs(os.time() - issuedAt) > 180 then return end
		local targeted = false
		for _, targetId in ipairs(type(command.targets) == "table" and command.targets or {}) do
			if tostring(targetId) == myId then targeted = true break end
		end
		if not targeted or lastAppliedTeleportId == commandId then return end
		local ack = readJson(teleportAckFile)
		if ack and tostring(ack.id or "") == commandId then
			lastAppliedTeleportId = commandId
			return
		end
		local placeId = tonumber(command.placeId)
		local jobId = tostring(command.jobId or "")
		local components = command.cframe
		if not placeId or jobId == "" or type(components) ~= "table" or #components ~= 12 then return end
		for index = 1, 12 do
			local value = tonumber(components[index])
			if not value or value ~= value or math.abs(value) > 1e8 then return end
			components[index] = value
		end
		if game.PlaceId ~= placeId or game.JobId ~= jobId then
			if lastJoinTeleportId == commandId and tick() - (lastJoinAttemptAt or 0) < 15 then return end
			lastJoinTeleportId, lastJoinAttemptAt = commandId, tick()
			local queueTeleport = queue_on_teleport or queueonteleport
				or (type(syn) == "table" and syn.queue_on_teleport)
			if type(queueTeleport) == "function" then
				local numbers = {}
				for _, value in ipairs(components) do table.insert(numbers, string.format("%.17g", value)) end
				local queuedSource = string.format([[
task.spawn(function()
	if not game:IsLoaded() then game.Loaded:Wait() end
	if game.PlaceId ~= %d or game.JobId ~= %q then return end
	local player = game:GetService("Players").LocalPlayer
	local character = player.Character or player.CharacterAdded:Wait()
	local root = character:WaitForChild("HumanoidRootPart", 30)
	if root then root.CFrame = CFrame.new(%s) end
end)
]], placeId, jobId, table.concat(numbers, ", "))
				pcall(queueTeleport, queuedSource)
			end
			local ok, err = pcall(function()
				TeleportService:TeleportToPlaceInstance(placeId, jobId, LocalPlayer)
			end)
			if not ok then warn("[LarpLite Fleet] Could not join Leader server: " .. tostring(err)) end
			return
		end
		local character = LocalPlayer.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if not root then return end
		local target = CFrame.new(table.unpack(components, 1, 12))
		local ok, err = pcall(function()
			root.CFrame = target
			root.AssemblyLinearVelocity = Vector3.zero
			root.AssemblyAngularVelocity = Vector3.zero
		end)
		if not ok then
			warn("[LarpLite Fleet] Could not move to Leader: " .. tostring(err))
			return
		end
		lastAppliedTeleportId = commandId
		writeJson(teleportAckFile, { id = commandId, at = os.time() })
		notify("Moved to the Leader's location.", 3)
	end

	local function sendLeaderTeleport()
		if fleet.role ~= "master" then return end
		local character = LocalPlayer.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if not root then
			notify("Wait for the Leader's character to load, then try again.")
			return
		end
		local targets = {}
		for _, entry in ipairs(fleet.roster) do
			if entry.id ~= myId then table.insert(targets, entry.id) end
		end
		if #targets == 0 then
			notify("No other accounts are online.")
			return
		end
		local command = {
			id = myId .. ":" .. tostring(os.time()) .. ":" .. tostring(math.random(100000, 999999)),
			from = myId,
			issuedAt = os.time(),
			placeId = game.PlaceId,
			jobId = game.JobId,
			cframe = { root.CFrame:GetComponents() },
			targets = targets,
		}
		if writeJson(teleportFile, command) then
			notify("Sent your location to " .. tostring(#targets) .. " account(s).", 4)
		else
			notify("Could not write the shared teleport command.", 5)
		end
	end

	-- Always-present controls (every account, on the Other tab).
	pcall(function()
		scriptStateAFW:AddSection("Account Fleet")
		fleet.ui.otherStatus = scriptStateAFW:AddText({
			Title = "Looking for other accounts…",
			Content = "Accounts on this PC find each other automatically.",
		})
		scriptStateAFW:AddToggle("FleetFollowMaster", {
			Title = "Follow Leader's settings",
			Description = "Apply the Leader account's settings to this account the moment they change.",
			Default = Config.fleetFollowMaster == true,
			Callback = function(enabled)
				Config.fleetFollowMaster = enabled == true
				saveConfig()
				if enabled then
					lastSeenRevText = nil
					fleet.appliedRev = 0 -- pull the Leader's current settings right now
				end
				writeHeartbeat()
				updateUi()
			end,
		})
		scriptStateAFW:AddButton({
			Title = "Make this account Leader",
			Description = "Pin the Leader role to this account.",
			Callback = function()
				pinMaster(myId)
				notify("This account will become Leader within a second.")
			end,
		})
		scriptStateAFW:AddButton({
			Title = "Pick Leader automatically",
			Description = "Clear the pin: the account running the longest becomes Leader.",
			Callback = function()
				clearPin()
				notify("Leader is picked automatically again.")
			end,
		})
	end)

	-- The Leader tab only exists once this account has actually been Leader.
	local function buildMasterTab()
		if fleet.tabBuilt then
			return
		end
		fleet.tabBuilt = true
		local ok, err = pcall(function()
			scriptStateOG:AddSection("Fleet")
			local tab = scriptStateOG:AddTab({ Title = "Leader", Icon = "crown" })
			fleet.masterTab = tab
			local controls = fleet.masterControls

			fleet.ui.masterStatus = tab:AddText({ Title = "Accounts online", Content = "" })

			tab:AddSection("Settings")
			table.insert(
				controls,
				tab:AddToggle("FleetAutoPush", {
					Title = "Live sync",
					Description = "Apply changes to the other accounts automatically.",
					Default = Config.fleetAutoPush == true,
					Callback = function(enabled)
						if fleet.role ~= "master" then
							return
						end
						Config.fleetAutoPush = enabled == true
						saveConfig()
						if enabled then
							pushSettings(true)
						end
					end,
				})
			)
			local pushButton = tab:AddButton({
				Title = "Sync now",
				Description = "Copy all configurable settings, including sliders and selections, to every online account.",
				Callback = function()
					if fleet.role ~= "master" then
						return
					end
					if pushSettings(true, true) then
						notify("Settings sent to " .. tostring(#fleet.roster - 1) .. " account(s).", 3)
					else
						notify("Could not write the shared settings file.", 4)
					end
				end,
			})
			table.insert(controls, pushButton)

			tab:AddSection("Movement")
			table.insert(controls, tab:AddButton({
				Title = "Teleport Accounts to Me",
				Description = "Move all online accounts to your exact position. Accounts in another server join yours first.",
				Callback = sendLeaderTeleport,
			}))

			tab:AddSection("Handover")
			local dropdownOk, handoverDropdown = pcall(function()
				return tab:AddDropdown("FleetHandover", {
					Title = "Account",
					Description = "Choose who becomes Leader.",
					Values = { NO_OTHER_ACCOUNT },
					Default = NO_OTHER_ACCOUNT,
					Multi = false,
					Callback = function(name)
						fleet.handoverName = type(name) == "table" and name[1] or name
					end,
				})
			end)
			if dropdownOk and handoverDropdown then
				fleet.ui.handover = handoverDropdown
				table.insert(controls, handoverDropdown)
			end
			table.insert(
				controls,
				tab:AddButton({
					Title = "Hand over",
					Callback = function()
						if fleet.role ~= "master" then
							return
						end
						for _, entry in ipairs(fleet.roster) do
							if entry.name == fleet.handoverName and entry.id ~= myId then
								pinMaster(entry.id)
								notify(entry.name .. " is taking over as Leader.")
								return
							end
						end
						notify("Pick an online account first.")
					end,
				})
			)
		end)
		if not ok then
			-- Stay "built": retrying would stack a second half-built tab in the sidebar.
			warn("[LarpLite Fleet] The Leader tab only partly built: " .. tostring(err))
		end
	end

	-- ------------------------------------------------------------------ roles --
	local function onRoleChanged(oldRole, newRole)
		if newRole == "master" then
			buildMasterTab()
			setMasterControlsLocked(false)
			setMasterTint(true)
			fleet.lastSignature = nil
			if Config.fleetAutoPush == true then
				pushSettings(true)
			end
			notify("This account is now the Leader. The Leader tab is in the sidebar.", 6)
		else
			setMasterTint(false)
			setMasterControlsLocked(true)
			if oldRole == "master" then
				notify("This account is no longer the Leader.", 5)
			end
			if newRole == "alt" then
				lastSeenRevText = nil
				fleet.appliedRev = 0 -- adopt the new Leader's settings
			end
		end
		print("[" .. LocalPlayer.Name .. "] Fleet role: " .. tostring(newRole))
	end

	local function refreshFleet()
		local roster = readRoster()
		fleet.roster = roster
		local masterId = electMaster(roster)
		fleet.masterId = masterId
		local newRole
		if masterId == nil then
			newRole = "solo"
		elseif masterId == myId then
			newRole = "master"
		else
			newRole = "alt"
		end
		if newRole ~= fleet.role then
			local oldRole = fleet.role
			fleet.role = newRole
			writeHeartbeat()
			onRoleChanged(oldRole, newRole)
		end
		updateUi()
	end

	-- ------------------------------------------------------------------ loops --
	local connections = {}
	table.insert(
		connections,
		RunService.Heartbeat:Connect(function()
			if fleet.dirty and isCurrentRun() then
				fleet.dirty = false
				pcall(pushSettings, false)
			end
		end)
	)

	local function shutdown()
		if fleet.stopped then
			return
		end
		fleet.stopped = true
		for _, connection in ipairs(connections) do
			connection:Disconnect()
		end
		pcall(setMasterTint, false)
	end
	if type(getgenv) == "function" then
		local previousCleanup = getgenv()._1rzHubLiteCleanup
		getgenv()._1rzHubLiteCleanup = function()
			pcall(shutdown)
			if type(previousCleanup) == "function" then
				previousCleanup()
			end
		end
	end

	writeHeartbeat()
	pcall(ensureRegistered)
	task.spawn(function()
		local lastRoster, lastBeat, lastRegister = 0, tick(), tick()
		while isCurrentRun() and not fleet.stopped do
			local now = tick()
			if now - lastRoster >= ROSTER_INTERVAL then
				lastRoster = now
				local ok, err = pcall(refreshFleet)
				if not ok then
					warn("[LarpLite Fleet] Roster refresh failed: " .. tostring(err))
				end
			end
			pcall(pullFromMaster)
			pcall(pullLeaderTeleport)
			if now - lastBeat >= HEARTBEAT_INTERVAL then
				lastBeat = now
				pcall(writeHeartbeat)
			end
			if now - lastRegister >= 15 then
				lastRegister = now
				pcall(ensureRegistered)
			end
			task.wait(PULL_INTERVAL)
		end
		shutdown()
	end)
end
end
}
