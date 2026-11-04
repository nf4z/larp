-- Generated from larplite.lua; rebuild with tools/build_modules.py.
return {
function(...)
scriptStateKM = scriptStateOG:AddTab({
	Title = "Webhook",
	Icon = "link",
})
end,
function(...)
do
	scriptStateKM:AddSection("Hatch Embed")
	scriptStateKM:AddToggle("WebhookShowUserInfo", {
		Title = "Show User Info",
		Description = "Adds currencies, bubbles, eggs, and luck above Pet Info in hatch embeds.",
		Default = Config.webhookShowUserInfo,
		Callback = function(enabled)
			Config.webhookShowUserInfo = enabled == true
			saveConfig()
		end,
	})
	scriptStateKM:AddSection("Hatch Webhook")
	scriptStateKM:AddToggle("WebhookEnabled", {
		Title = "Enable Webhook",
		Default = Config.webhookEnabled,
		Callback = function(scriptStateAO)
			Config.webhookEnabled = scriptStateAO
			saveConfig()
		end,
	})
	scriptStateKM:AddInput("WebhookURL", {
		Title = "Webhook URL(s)",
		Default = Config.webhookURL,
		Placeholder = "Discord webhook URL(s),comma-separated",
		Callback = function(scriptStateTM)
			Config.webhookURL = scriptStateTM
			saveConfig()
		end,
	})
	scriptStateKM:AddInput("WebhookMinimumChance", {
		Title = "Minimum Chance",
		Description = "Uses base egg odds and fixed Shiny/Mythic/XL/Super variant rates, without luck. Examples: 50m, 50b, 5t. Blank or 0 disables the filter.",
		Default = Config.webhookMinimumChance,
		Placeholder = "50m / 50b / 5t (empty = all)",
		Callback = function(value)
			if not parseWebhookMinimumChance(value) then
				Interface:Notify({Title = "Invalid hatch chance", Content = "Use a number such as 50m, 50b, or 5t. Your previous setting is unchanged.", Duration = 5})
				return
			end
			Config.webhookMinimumChance = tostring(value or "")
			saveConfig()
		end,
	})
	scriptStateKM:AddSection("Simulate Pet Hatch")
	local simulatedPetName = ""
	local simulationSending = false
	scriptStateKM:AddInput("SimulatedPetName", {
		Title = "Pet Name",
		Default = "",
		Placeholder = "Classic Noob / Super Classic Noob",
		Callback = function(value)
			simulatedPetName = value
		end,
	})
	scriptStateKM:AddToggle("WebhookSimulateSuperLegendary", {
		Title = "Simulate Super Legendary",
		Description = "Default on for Legendary hatch tests. Turn off to simulate a regular Legendary.",
		Default = Config.webhookSimulationSuperDefault == true,
		Callback = function(enabled)
			Config.webhookSimulationSuperDefault = enabled == true
			saveConfig()
		end,
	})
	scriptStateKM:AddButton({
		Title = "Send Hatch Message",
		Callback = function()
			if simulationSending then return end
			local urls = getShrineLevelValue(Config.webhookURL)
			if #urls == 0 then
				Interface:Notify({Title = "Hatch Simulation", Content = "Set your Webhook URL first.", Duration = 5})
				return
			end
			local pet, info = makeSimulatedHatchPet(simulatedPetName, Config.webhookSimulationSuperDefault)
			if not pet then
				Interface:Notify({Title = "Hatch Simulation", Content = info, Duration = 5})
				return
			end
			local simulatedRarity = activeStates.BGSI_Lite_ResolvePetRarity(pet, info)
			local simulatedSourceName = getWebhookPetSource(pet, info)
			if Config.webhookSendEasySecrets == false
				and isWebhookRebirthMachineReward(pet, info, simulatedSourceName)
				and simulatedRarity ~= "Celestial"
				and simulatedRarity ~= "Infinity"
				and simulatedRarity ~= "Void"
			then
				Interface:Notify({Title = "Hatch Simulation", Content = "Filtered by Send Easy Secrets.", Duration = 5})
				return
			end
			simulationSending = true
			task.spawn(function()
				local ok, result = pcall(function()
					local payload = buildSimulatedHatchPayload(pet, info)
					local sent = 0
					for _, url in ipairs(urls) do
						if runRebirthFuse(url, payload) then sent += 1 end
					end
					if sent == 0 then return "Discord rejected the message. Check your webhook URL." end
					if sent < #urls then return ("Sent to %d of %d webhook URLs."):format(sent, #urls) end
					return "Sent hatch message for " .. (pet.Super and "Super " or "") .. pet.Name .. "."
				end)
				simulationSending = false
				Interface:Notify({
					Title = "Hatch Simulation",
					Content = ok and result or "Could not build or send the hatch message. Try again.",
					Duration = 5,
				})
				if not ok then warn("[Webhook] Hatch simulation failed: " .. tostring(result)) end
			end)
		end,
	})
	scriptStateKM:AddSection("Live Webhook")
	scriptStateKM:AddToggle("LiveWebhookEnabled", {
		Title = "Enable Live Webhook",
		Description = "Posts one live Component V2 status message and updates it every 15 seconds.",
		Default = Config.LiveWebhookEnabled,
		Callback = function(scriptStateLiveEnabled)
			Config.LiveWebhookEnabled = scriptStateLiveEnabled == true
			saveConfig()

			if Config.LiveWebhookEnabled and tostring(Config.LiveWebhookURL or "") ~= "" then
				activeStates.BGSI_Lite_StartLiveWebhook()
			else
				activeStates.BGSI_Lite_StopLiveWebhook()
			end
		end,
	})
	scriptStateKM:AddInput("LiveWebhookURL", {
		Title = "Live Webhook URL",
		Description = "Separate Discord webhook used only for live account status.",
		Default = Config.LiveWebhookURL,
		Placeholder = "Discord webhook URL",
		Callback = function(scriptStateLiveURL)
			activeStates.BGSI_Lite_StopLiveWebhook()
			Config.LiveWebhookURL = tostring(scriptStateLiveURL or "")
			saveConfig()

			if Config.LiveWebhookEnabled and Config.LiveWebhookURL ~= "" then
				activeStates.BGSI_Lite_StartLiveWebhook()
			end
		end,
	})
	scriptStateKM:AddToggle("WebhookHideName", {
		Title = "Hide username in webhooks",
		Default = Config.webhookHidePlayerName,
		Callback = function(scriptStateET)
			Config.webhookHidePlayerName = scriptStateET
			saveConfig()
		end,
	})
	scriptStateKM:AddSection("Ping")
	scriptStateKM:AddToggle("WebhookPingEnabled", {
		Title = "Ping User",
		Default = Config.webhookPingEnabled,
		Callback = function(scriptStateGD)
			Config.webhookPingEnabled = scriptStateGD
			saveConfig()
		end,
	})
	scriptStateKM:AddInput("WebhookPingUserId", {
		Title = "Discord User ID",
		Default = Config.webhookPingUserId,
		Placeholder = "right click user -> Copy User ID",
		Callback = function(scriptStateDW)
			Config.webhookPingUserId = scriptStateDW
			saveConfig()
		end,
	})
	scriptStateKM:AddSection("Low Currency Alerts")
	scriptStateKM:AddToggle("LowCurrencyEnabled", {
		Title = "Enable Low Currency Alerts",
		Default = Config.webhookLowCurrencyEnabled,
		Callback = function(scriptStateRL)
			Config.webhookLowCurrencyEnabled = scriptStateRL
			saveConfig()
		end,
	})
	scriptStateKM:AddInput("LowCoins", {
		Title = "Coins Below",
		Default = Config.webhookLowCoinsBelow,
		Placeholder = "e.g. 10M",
		Callback = function(scriptStateABN)
			Config.webhookLowCoinsBelow = scriptStateABN
			saveConfig()
		end,
	})
	scriptStateKM:AddInput("LowGems", {
		Title = "Gems Below",
		Default = Config.webhookLowGemsBelow,
		Placeholder = "e.g. 100K",
		Callback = function(scriptStateAEN)
			Config.webhookLowGemsBelow = scriptStateAEN
			saveConfig()
		end,
	})
	scriptStateKM:AddInput("LowPearls", {
		Title = "Pearls Below",
		Default = Config.webhookLowPearlsBelow,
		Placeholder = "e.g. 1K",
		Callback = function(scriptStateTS)
			Config.webhookLowPearlsBelow = scriptStateTS
			saveConfig()
		end,
	})
	scriptStateKM:AddInput("LowTickets", {
		Title = "Tickets Below",
		Default = Config.webhookLowTicketsBelow,
		Placeholder = "e.g. 50",
		Callback = function(scriptStateHV)
			Config.webhookLowTicketsBelow = scriptStateHV
			saveConfig()
		end,
	})
	scriptStateKM:AddSlider("LowCurrencyCooldown", {
		Title = "Alert Cooldown (minutes)",
		Min = 1,
		Max = 180,
		Default = Config.webhookLowCurrencyCooldownMinutes,
		Rounding = 0,
		Callback = function(scriptStateZP)
			Config.webhookLowCurrencyCooldownMinutes = math.floor(scriptStateZP)
			saveConfig()
		end,
	})
	scriptStateKM:AddSection("Hatch Animation Preview")
	local animationPetName = ""
	local animationPlaying = false
	scriptStateKM:AddInput("AnimationPetName", {
		Title = "Pet Name",
		Description = "Play a local hatch animation without receiving a pet or sending a webhook.",
		Default = "",
		Placeholder = "Classic Noob / Shiny Super Classic Noob",
		Callback = function(value)
			animationPetName = value
		end,
	})
	scriptStateKM:AddButton({
		Title = "Play Hatch Animation",
		Callback = function()
			if animationPlaying then return end
			if not hatchEffectModule or type(scriptStateID) ~= "function" then
				Interface:Notify({Title = "Hatch Preview", Content = "The game's hatch animation is unavailable.", Duration = 5})
				return
			end
			local pet, info = makeSimulatedHatchPet(animationPetName)
			if not pet then
				Interface:Notify({Title = "Hatch Preview", Content = info, Duration = 5})
				return
			end
			local isBusy, hatching = pcall(function() return hatchEffectModule:IsHatching() end)
			if isBusy and hatching then
				Interface:Notify({Title = "Hatch Preview", Content = "Wait for the current hatch animation to finish.", Duration = 5})
				return
			end
			local eggName = getWebhookHatchEggName(pet, info)
			local eggAssets = ReplicatedStorage:FindFirstChild("Assets")
			local eggModels = eggAssets and eggAssets:FindFirstChild("Eggs")
			if eggName == "Unknown" or (eggName ~= "Infinity Egg"
				and (not eggModels or not eggModels:FindFirstChild(eggName))) then
				eggName = "Common Egg"
			end
			if pet.Super then
				pet.Enchants = rollSimulatedSuperEnchants(pet)
				pet.Enchantments = nil
			end
			-- ItemUtil's Void/Celestial/Infinity checks require Type = "Pet".
			-- HatchEgg:Play then selects the matching special reveal after the egg opens.
			pet.Type = "Pet"
			animationPlaying = true
			task.spawn(function()
				local ok, err = pcall(function()
					scriptStateID(hatchEffectModule, {
						Name = eggName,
						Speed = 1,
						Pets = {{Pet = pet, New = false, Deleted = false}},
					})
				end)
				animationPlaying = false
				if not ok then
					warn("[Webhook] Hatch animation preview failed: " .. tostring(err))
					Interface:Notify({Title = "Hatch Preview", Content = "The game could not play this pet's animation.", Duration = 5})
				end
			end)
		end,
	})
end
end
}
