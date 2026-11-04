-- Generated from larplite.lua; rebuild with tools/build_modules.py.
return {
function(...)
halloweenTab = scriptStateOG:AddTab({
	Title = "Halloween",
	Icon = "ghost",
})
end,
function(...)
do
	halloweenTab:AddSection("Halloween Rebirths")
	local rebirthCount = halloweenTab:AddInput("HalloweenRebirthsDisplay", {
		Title = "Rebirths",
		Default = "Loading...",
		Callback = function() end,
	})
	rebirthCount:Lock("Read-only")
	halloweenTab:AddToggle("AutoHalloweenRebirth", {
		Title = "Auto Halloween Rebirth",
		Description = "Rebirths when Candycorn covers the next cost.",
		Default = Config.autoHalloweenRebirth,
		Callback = function(enabled)
			Config.autoHalloweenRebirth = enabled == true
			saveConfig()
		end,
	})
	halloweenTab:AddSection("Trick or Treat")
	halloweenTab:AddToggle("AutoTrickOrTreat", {
		Title = "Auto Trick or Treat",
		Description = "Visits one ready house at a time, then lets your other automation resume between visits.",
		Default = Config.autoTrickOrTreat,
		Callback = function(enabled)
			Config.autoTrickOrTreat = enabled == true
			saveConfig()
		end,
	})
	halloweenTab:AddSection("Halloween Chest")
	halloweenTab:AddToggle("AutoHalloweenChest", {
		Title = "Auto Claim Halloween Chest",
		Description = "Claims the chest when its cooldown expires.",
		Default = Config.autoHalloweenChest,
		Callback = function(enabled)
			Config.autoHalloweenChest = enabled == true
			saveConfig()
		end,
	})
	task.spawn(function()
		while isCurrentRun() do
			pcall(function()
				local data = profileStore:IsReady() and profileStore:Get() or nil
				if type(data) == "table" then
					rebirthCount:SetValue("You have " .. tostring(math.floor(tonumber(data.Halloween26Rebirths) or 0)) .. " rebirths")
				end
			end)
			task.wait(3)
		end
	end)
	task.spawn(function()
		local nextHouseIndex = 1
		local retryHouseAt = {}
		while isCurrentRun() do
			if Config.autoTrickOrTreat and Config.safeMode ~= true
				and not isPriorityAutomationActive() then
				local event = Workspace:FindFirstChild("HalloweenEvent")
				local houses = event and event:FindFirstChild("Houses")
				local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
				if houses and root then
					local availableHouses = houses:GetChildren()
					local selectedHouse, selectedActive, selectedTarget
					for offset = 0, #availableHouses - 1 do
						local index = ((nextHouseIndex + offset - 1) % #availableHouses) + 1
						local house = availableHouses[index]
						local activation = house:FindFirstChild("Activation")
						local active = activation and activation:FindFirstChild("Active")
						if active and active:IsA("BoolValue") and active.Value
							and tick() >= (retryHouseAt[house] or 0) then
							local target = activeStates.BGSI_Lite_GetInstanceTargetCFrame(activation, "Root")
							if target then
								selectedHouse, selectedActive, selectedTarget = house, active, target
								nextHouseIndex = index % #availableHouses + 1
								break
							end
						end
					end
					if selectedHouse then
						local previousPosition = root.CFrame
						local attempted = false
						activeStates.BGSI_Lite_TrickOrTreatActive = true
						activeStates.BGSI_Lite_TrickOrTreatStartedAt = tick()
						local routeOk, routeError = pcall(function()
							local freezeDeadline = tick() + 15
							while LocalPlayer:GetAttribute("TrickOrTreatFreeze") and tick() < freezeDeadline
								and Config.autoTrickOrTreat and Config.safeMode ~= true do
								task.wait(0.25)
							end
							if not isCurrentRun() or not Config.autoTrickOrTreat or Config.safeMode
								or LocalPlayer:GetAttribute("TrickOrTreatFreeze") then return end
							if teleportToCFrame(selectedTarget * CFrame.new(0, 2, 0)) then
								attempted = true
								task.wait(0.35)
								if not Config.autoTrickOrTreat or Config.safeMode then return end
								pcall(activeStates.BGSI_Lite_FireGameRemote, "TrickOrTreat", selectedHouse)
								local claimDeadline = tick() + 3
								repeat task.wait(0.2) until not selectedActive.Value or tick() >= claimDeadline
							end
						end)
						pcall(function()
							if root.Parent then root.CFrame = previousPosition end
						end)
						activeStates.BGSI_Lite_TrickOrTreatActive = false
						retryHouseAt[selectedHouse] = tick()
							+ (attempted and (selectedActive.Value and 30 or 2) or 15)
						activeStates.BGSI_Lite_LastQuestAutomationAt = tick()
						if not routeOk then warn("[1rzHub Lite] Trick or Treat route failed:", tostring(routeError)) end
					end
				end
			end
			task.wait(2)
		end
		activeStates.BGSI_Lite_TrickOrTreatActive = false
	end)
end
end
}
