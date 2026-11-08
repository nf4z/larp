-- Generated from larplite.lua; rebuild with tools/build_modules.py.
return {
function(...)
scriptStateAFW = scriptStateOG:AddTab({
	Title = "Other",
	Icon = "workflow",
})
scriptStateAFW:AddSection("Performance")
scriptStateAFW:AddToggle("AutoOptimizeMemory", {
	Title="Automatic Memory Optimization",
	Description="Native low detail, lower mesh detail and stale chunk cleanup. Restores visuals when disabled.",
	Default=Config.autoOptimizeMemory,
	Callback=function(enabled)
		Config.autoOptimizeMemory=enabled==true
		saveConfig()
		activeStates.BGSI_Lite_ApplyPerformanceSettings()
		pcall(refreshChunkerAroundPlayer)
	end,
})
do
	local memoryCard=scriptStateAFW:AddParagraph({Title="Client Memory",Content="Sampling..."})
	local optimizer=activeStates.BGSI_Lite_MemoryOptimizer
	if optimizer then
		optimizer.OnReport=function(report)
			local function mb(value) return type(value)=="number" and string.format("%.1f MB",value) or "Unavailable" end
			memoryCard:SetDesc("Client "..mb(report.totalMB).." | Lua "..mb(report.luaMB)
				.."\nTextures "..mb(report.texturesMB).." | Meshes "..mb(report.meshesMB)
				.."\n"..report.meshesChanged.." mesh changes | "..report.chunkKeysFreed.." stale chunk entries released")
		end
		optimizer.Sample()
	end
end
scriptStateAFW:AddToggle("DisableRendering", {
	Title = "Disable 3D Rendering (AFK / save GPU)",
	Default = Config.disableRendering,
	Callback = function(enabled)
		Config.disableRendering = enabled == true
		saveConfig()
		pcall(function()
			RunService:Set3dRenderingEnabled(Config.safeMode == true or not Config.disableRendering)
		end)
	end,
})
scriptStateAFW:AddInput("SetFps", {
	Title = "FPS Cap",
	Description = "Caps FPS when the original limit can be read and restored for Safe Mode.",
	Default = tostring(Config.setfps),
	Placeholder = "60",
	Numeric = true,
	Callback = function(value)
		local fpsCap = tonumber(value)
		if not fpsCap or fpsCap ~= fpsCap then
			return
		end
		Config.setfps = math.max(1, math.floor(fpsCap))
		saveConfig()
		if type(activeStates.BGSI_Lite_ApplyPerformanceSettings) == "function" then
			activeStates.BGSI_Lite_ApplyPerformanceSettings()
		end
	end,
})
scriptStateAFW:AddInput("ChunkerRenderDistance", {
	Title = "Chunk Render Distance",
	Description = "Caps chunk distance without increasing the game's smaller native ranges.",
	Default = tostring(Config.chunkerRenderDistance),
	Placeholder = "4",
	Numeric = true,
	Callback = function(value)
		local renderDistance = tonumber(value)
		if not renderDistance or renderDistance ~= renderDistance then
			return
		end
		Config.chunkerRenderDistance = math.max(1, math.floor(renderDistance))
		_G.BGSI_CHUNK_RENDER_DISTANCE = Config.chunkerRenderDistance
		pcall(installChunkerRenderDistanceHook)
		saveConfig()
		pcall(refreshChunkerAroundPlayer)
	end,
})
end,
function(...)
scriptStateAFW:AddSection("Auto Update")
scriptStateAFW:AddToggle("AutoUpdateScript", {
	Title = "Auto Update Script",
	Description = "Checks GitHub for a newer version and reloads automatically when one is released.",
	Default = Config.autoUpdateScript,
	Callback = function(enabled)
		Config.autoUpdateScript = enabled == true
		saveConfig()
	end,
})
scriptStateAFW:AddSlider("AutoUpdateIntervalSeconds", {
	Title = "Update Check Interval",
	Description = "How often to check GitHub for a new version.",
	Min = 60,
	Max = 1800,
	Default = math.clamp(math.floor(tonumber(Config.autoUpdateIntervalSeconds) or 300), 60, 1800),
	Rounding = 0,
	Suffix = "s",
	Callback = function(seconds)
		Config.autoUpdateIntervalSeconds = math.clamp(math.floor(tonumber(seconds) or 300), 60, 1800)
		saveConfig()
	end,
})
scriptStateAFW:AddButton({
	Title = "Check For Update Now",
	Callback = function()
		task.spawn(function()
			if type(activeStates.BGSI_Lite_RunAutoUpdateCheck) ~= "function" then
				Interface:Notify({
					Title = "Auto Update",
					Content = "Update system is not ready yet.",
					Duration = 5,
				})
				return
			end
			local status, version, errorMessage = activeStates.BGSI_Lite_RunAutoUpdateCheck(true)
			if status == "queued" then
				return
			elseif status == "up-to-date" then
				Interface:Notify({
					Title = "Auto Update",
					Content = "You're already on the latest version (" .. tostring(version or activeStates.BGSI_Lite_ScriptVersion) .. ").",
					Duration = 5,
				})
			else
				Interface:Notify({
					Title = "Auto Update",
					Content = "Check failed: " .. tostring(errorMessage or "unknown error"),
					Duration = 6,
				})
			end
		end)
	end,
})
scriptStateAFW:AddButton({
	Title = "Reload Script",
	Description = "Downloads the current script fresh and reloads immediately, even if the version is unchanged.",
	Callback = function()
		task.spawn(function()
			if type(activeStates.BGSI_Lite_ForceReloadScript) ~= "function" then
				Interface:Notify({
					Title = "Reload Script",
					Content = "Reload system is not ready yet.",
					Duration = 5,
				})
				return
			end
			local status, errorMessage = activeStates.BGSI_Lite_ForceReloadScript()
			if status ~= "queued" then
				Interface:Notify({
					Title = "Reload Script",
					Content = "Reload failed: " .. tostring(errorMessage or "unknown error"),
					Duration = 6,
				})
			end
		end)
	end,
})
scriptStateAFW:AddSection("Configuration")
scriptStateAFW:AddButton({
	Title = "Reset Config & Restart",
	Description = "Delete all saved settings and restart LarpLite with a completely fresh configuration.",
	Callback = function()
		activeStates.BGSI_Lite_ConfigResetPending = true
		Config.autoTrickOrTreat = false
		activeStates.BGSI_Lite_TrickOrTreatActive = false
		local resetFiles = {
			configFile,
			sharedConfigFile,
			legacyConfigFile,
		}
		local deletedAny = false
		for _, fileName in ipairs(resetFiles) do
			if type(isfile) == "function" and isfile(fileName) and type(delfile) == "function" then
				pcall(function()
					delfile(fileName)
					deletedAny = true
				end)
			end
		end
		Config.safeMode = false
		if type(activeStates.BGSI_Lite_ForceReloadScript) == "function" then
			local status, err = activeStates.BGSI_Lite_ForceReloadScript()
			if status == "queued" then
				return
			end
			activeStates.BGSI_Lite_ConfigResetPending = false
			Interface:Notify({
				Title = "Reset failed",
				Content = tostring(err or "Could not restart the script."),
				Duration = 5,
			})
			return
		end
		activeStates.BGSI_Lite_ConfigResetPending = false
		Interface:Notify({
			Title = "Reset failed",
			Content = "The script reload function is not ready yet.",
			Duration = 5,
		})
	end,
})
end
}
