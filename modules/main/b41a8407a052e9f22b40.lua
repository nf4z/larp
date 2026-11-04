-- Generated from larplite.lua; rebuild with tools/build_modules.py.
return {
function(...)
scriptStateDB = scriptStateOG:AddTab({
	Title = "Main",
	Icon = "home",
})
end,
function(...)
scriptStateDB:AddSection("Safety")
scriptStateDB:AddToggle("SafeMode", {
	Title = "Safe Mode",
	Description = "Pause every automation feature and restore normal game performance without losing your setup.",
	Default = Config.safeMode,
	Callback = function(enabled)
		activeStates.BGSI_Lite_SetSafeMode(enabled)
		Interface:Notify({
			Title = enabled and "Safe Mode enabled" or "Safe Mode disabled",
			Content = enabled and "Automation is paused. Your settings are saved." or "Your saved setup has been restored.",
			Duration = 4,
		})
	end,
})
scriptStateDB:AddToggle("AutoSkipIntro", {
	Title = "Skip Intro",
	Description = "Automatically press the game's intro or loading-screen continue button.",
	Default = Config.autoSkipIntro,
	Callback = function(enabled)
		Config.autoSkipIntro = enabled
		saveConfig()
		if enabled then
			task.spawn(activeStates.BGSI_Lite_SkipIntro)
		end
	end,
})
scriptStateDB:AddToggle("AutoClosePopups", {
	Title = "Auto Close Game Popups",
	Description = "Automatically closes confirmation prompts opened by in-game automation.",
	Default = Config.autoClosePopups,
	Callback = function(enabled)
		Config.autoClosePopups = enabled == true
		saveConfig()
	end,
})
end,
function(...)
scriptStateDB:AddChangelog()
end
}
