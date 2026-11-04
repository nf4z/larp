-- Generated from larplite.lua; rebuild with tools/build_modules.py.
return {
function(...)
scriptStateOB = scriptStateOG:AddTab({
	Title = "Shrines",
	Icon = "sparkles",
})
end,
function(...)
do
	scriptStateOB:AddSection("Dream Fountain")
	scriptStateOB:AddToggle("DreamShrine", {
		Title = "Auto Dreamer Fountain",
		Description = "Rations Dream Shards and restocks them from available shops and free rerolls when needed.",
		Default = Config.DreamerShrineEnabled,
		Callback = function(scriptStateAV)
			Config.DreamerShrineEnabled = scriptStateAV
			saveConfig()
		end,
	})
	scriptStateOB:AddInput("DreamShrineAmount", {
		Title = "Amount",
		Default = tostring(Config.DreamerShrineAmount),
		Placeholder = "1-15",
		Numeric = true,
		Callback = function(scriptStateIW)
			local scriptStateAE = tonumber(scriptStateIW)
			if scriptStateAE then
				Config.DreamerShrineAmount = math.clamp(math.floor(scriptStateAE), 1, 15)
				saveConfig()
			end
		end,
	})
	scriptStateOB:AddSection("Bubble Shrine")
	local scriptStateD = {
		"Lucky",
		"Mythic",
		"Speed",
		"Tickets",
		"Coins",
	}
	local scriptStateSD = {
		"1",
		"2",
		"3",
		"4",
		"5",
	}
	scriptStateOB:AddDropdown("ShrinePotion", {
		Title = "Potion",
		Values = scriptStateD,
		Default = Config.shrinePotion,
		Multi = false,
		Callback = function(scriptStateACT)
			Config.shrinePotion = scriptStateACT
			saveConfig()
		end,
	})
	scriptStateOB:AddDropdown("ShrineLevel", {
		Title = "Level",
		Values = scriptStateSD,
		Default = tostring(Config.shrineLevel),
		Multi = false,
		Callback = function(scriptStateIA)
			Config.shrineLevel = tonumber(scriptStateIA) or 1
			saveConfig()
		end,
	})
	scriptStateOB:AddInput("ShrineAmount", {
		Title = "Amount",
		Default = tostring(Config.shrineAmount),
		Placeholder = "0-1000",
		Numeric = true,
		Callback = function(scriptStateDC)
			local scriptStateABI = tonumber(scriptStateDC)
			if scriptStateABI then
				Config.shrineAmount = math.clamp(math.floor(scriptStateABI), 0, 1000)
				saveConfig()
			end
		end,
	})
	scriptStateOB:AddToggle("AutoShrine", {
		Title = "Auto Donate to Bubble Shrine",
		Default = Config.shrineAuto,
		Callback = function(scriptStateXQ)
			Config.shrineAuto = scriptStateXQ
			saveConfig()
		end,
	})
end
end
}
