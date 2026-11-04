-- Generated from larplite.lua; rebuild with tools/build_modules.py.
return {
function(...)
scriptStateCZ = scriptStateOG:AddTab({
	Title = "Event",
	Icon = "flower",
})
end,
function(...)
do
	scriptStateCZ:AddSection("Event Board")
	scriptStateCZ:AddToggle("AutoPurchaseEvents", {
		Title = "Auto Purchase Events",
		Description = "Uses Boost Crystals on the first eligible selected event.",
		Default = Config.AutoPurchaseEvents,
		Callback = function(enabled)
			Config.AutoPurchaseEvents = enabled == true
			saveConfig()
		end,
	})
	scriptStateCZ:AddDropdown("PriorityEvents", {
		Title = "Priority Events",
		Description = "Selected events are checked in the order shown here.",
		Values = activeStates.BGSI_Lite_PriorityEventOptions,
		Default = Config.PriorityEvents,
		Multi = true,
		Callback = function(selectedEvents)
			local selectedEventSet = {}
			for eventKey, eventValue in pairs(type(selectedEvents) == "table" and selectedEvents or {}) do
				if type(eventKey) == "number" and type(eventValue) == "string" then
					selectedEventSet[eventValue] = true
				elseif type(eventKey) == "string" and eventValue == true then
					selectedEventSet[eventKey] = true
				elseif type(eventValue) == "string" then
					selectedEventSet[eventValue] = true
				end
			end
			Config.PriorityEvents = {}
			for _, eventName in ipairs({
				"Luck Event",
				"Shiny Event",
				"Mythic Event",
				"Celestial Event",
				"Secret Event",
				"Infinity Event",
				"XL Event",
				"Super Palooza",
			}) do
				if selectedEventSet[eventName] then
					table.insert(Config.PriorityEvents, eventName)
				end
			end
			saveConfig()
		end,
	})
	scriptStateCZ:AddInput("EventPurchaseQuantity", {
		Title = "Event Purchase Quantity",
		Description = "Number of event durations to buy per request; capped by your Boost Crystals and reserve.",
		Default = tostring(math.max(1, math.floor(tonumber(Config.EventPurchaseQuantity) or 1))),
		Numeric = true,
		Callback = function(amount)
			Config.EventPurchaseQuantity = math.max(1, math.floor(tonumber(amount) or 1))
			saveConfig()
		end,
	})
	scriptStateCZ:AddSlider("MinimumCrystalReserve", {
		Title = "Minimum Boost Crystal Reserve",
		Description = "Event purchases will never spend below this amount.",
		Min = 0,
		Max = 250,
		Default = math.clamp(math.floor(tonumber(Config.MinimumCrystalReserve) or 0), 0, 250),
		Rounding = 0,
		Callback = function(amount)
			Config.MinimumCrystalReserve = math.clamp(math.floor(tonumber(amount) or 0), 0, 250)
			saveConfig()
		end,
	})
	scriptStateCZ:AddSlider("MaximumEventPurchasesPerSession", {
		Title = "Maximum Purchases Per Session",
		Description = "Set to 0 for no session limit.",
		Min = 0,
		Max = 50,
		Default = math.clamp(math.floor(tonumber(Config.MaximumEventPurchasesPerSession) or 8), 0, 50),
		Rounding = 0,
		Callback = function(amount)
			Config.MaximumEventPurchasesPerSession = math.clamp(math.floor(tonumber(amount) or 0), 0, 50)
			saveConfig()
		end,
	})
	scriptStateCZ:AddSlider("EventPurchaseCooldown", {
		Title = "Purchase Cooldown",
		Description = "Minimum seconds between Event Board purchase attempts.",
		Min = 1,
		Max = 900,
		Default = math.clamp(math.floor(tonumber(Config.EventPurchaseCooldown) or 60), 1, 900),
		Rounding = 0,
		Suffix = "s",
		Callback = function(seconds)
			Config.EventPurchaseCooldown = math.clamp(math.floor(tonumber(seconds) or 60), 1, 900)
			saveConfig()
		end,
	})
	scriptStateCZ:AddToggle("ExtendAlreadyActiveEvents", {
		Title = "Extend Active Events",
		Description = "Allows auto-purchase to extend an event that is already active.",
		Default = Config.ExtendAlreadyActiveEvents,
		Callback = function(enabled)
			Config.ExtendAlreadyActiveEvents = enabled == true
			saveConfig()
		end,
	})
	scriptStateCZ:AddSlider("MaximumRejectedEventAttempts", {
		Title = "Maximum Rejected Attempts",
		Description = "Disables auto-purchase after this many consecutive server rejections.",
		Min = 1,
		Max = 20,
		Default = math.clamp(math.floor(tonumber(Config.MaximumRejectedEventAttempts) or 3), 1, 20),
		Rounding = 0,
		Callback = function(amount)
			Config.MaximumRejectedEventAttempts = math.clamp(math.floor(tonumber(amount) or 3), 1, 20)
			saveConfig()
		end,
	})
	scriptStateCZ:AddSection("Present Rain")
	scriptStateCZ:AddToggle("AutoCollectPresentRain", {
		Title = "Auto Collect Present Rain",
		Default = Config.autoCollectPresentRain,
		Callback = function(scriptStateQK)
			Config.autoCollectPresentRain = scriptStateQK
			saveConfig()
		end,
	})
end
end
}
