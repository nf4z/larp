-- Generated from larplite.lua; rebuild with tools/build_modules.py.
return {
function(...)
scriptStateGB = scriptStateOG:AddTab({
	Title = "Rebirth",
	Icon = "repeat",
})
scriptStateGB:AddSection("Rebirth Machine")
scriptStateGB:AddInput("RebirthMachinePetName", {
	Title = "Pet Name",
	Description = "Fuse five eligible Secrets of this variant. Admin Abuse pets use the Admin machine; blank uses any names.",
	Default = Config.RebirthPetName,
	Placeholder = "Classic Overlord",
	Callback = function(value)
		Config.RebirthPetName = tostring(value or ""):match("^%s*(.-)%s*$")
		saveConfig()
	end,
})
scriptStateGB:AddDropdown("RebirthMachineVariant", {
	Title = "Variant",
	Values = {"Normal", "Shiny", "Mythic", "Shiny Mythic"},
	Default = type(Config.RebirthVariants) == "table" and Config.RebirthVariants[1] or "Normal",
	Multi = false,
	Callback = function(value)
		Config.RebirthVariants = {value}
		saveConfig()
	end,
})
scriptStateGB:AddToggle("AutoRebirthMachine", {
	Title = "Auto Rebirth Machine",
	Default = Config.RebirthMachineEnabled,
	Callback = function(value)
		Config.RebirthMachineEnabled = value == true
		saveConfig()
	end,
})
scriptStateGB:AddToggle("WebhookSendEasySecrets", {
	Title = "Send Easy Secrets",
	Description = "When off, Rebirth Machine rewards send only Celestial, Infinity, and Void pet webhooks.",
	Default = Config.webhookSendEasySecrets,
	Callback = function(enabled)
		Config.webhookSendEasySecrets = enabled == true
		saveConfig()
	end,
})
scriptStateGB:AddSection("Admin Rebirth Machine")
scriptStateGB:AddInput("AdminRebirthMachinePetName", {
	Title = "Admin Pet Name",
	Description = "Fuse four eligible Admin Abuse Secrets of the selected variant. Leave blank to use any names.",
	Default = Config.AdminRebirthPetName,
	Placeholder = "Man Face Lord",
	Callback = function(value)
		Config.AdminRebirthPetName = tostring(value or ""):match("^%s*(.-)%s*$")
		saveConfig()
	end,
})
scriptStateGB:AddToggle("AutoAdminRebirthMachine", {
	Title = "Auto Admin Rebirth Machine",
	Description = "Uses the Variant selected above when the Admin machine is available.",
	Default = Config.AdminRebirthMachineEnabled,
	Callback = function(enabled)
		Config.AdminRebirthMachineEnabled = enabled == true
		saveConfig()
	end,
})
end,
function(...)
do
	local initialOwnedNames = getWinterAltarOwnedPetNames()
	winterAltarListedNames = table.concat(initialOwnedNames, "\0")
	local machineDisplayName = "Winter Altar"
	local requiredPetCount = 3
	if type(winterAltarUtil) == "table" then
		local machineOk, machine = pcall(winterAltarUtil.GetMachine, winterAltarUtil, winterAltarMachineName)
		if machineOk and type(machine) == "table" then
			machineDisplayName = tostring(machine.DisplayName or machineDisplayName)
			requiredPetCount = tonumber(machine.NumPetsRequired) or requiredPetCount
		end
	end
	scriptStateGB:AddSection(machineDisplayName)
	winterAltarPetDropdown = scriptStateGB:AddDropdown("WinterAltarPets", {
		Title = "Altar Pets",
		Description = "Only " .. machineDisplayName .. " pets this account owns. "
			.. requiredPetCount .. " of the Variant selected above are converted per use; "
			.. requiredPetCount .. " Ice Queen Seals give Danger of the Blizzard.",
		Values = #initialOwnedNames > 0 and initialOwnedNames or { winterAltarNoPetsOption },
		Default = Config.WinterAltarPets,
		Multi = true,
		Search = true,
		Callback = function(selected)
			local chosenNames = {}
			if type(selected) == "table" then
				for key, value in pairs(selected) do
					if type(key) == "number" and type(value) == "string" and value ~= winterAltarNoPetsOption then
						table.insert(chosenNames, value)
					elseif type(key) == "string" and value == true and key ~= winterAltarNoPetsOption then
						table.insert(chosenNames, key)
					end
				end
			end
			table.sort(chosenNames)
			Config.WinterAltarPets = chosenNames
			saveConfig()
		end,
	})
	scriptStateGB:AddButton({
		Title = "Refresh owned altar pets",
		Callback = function()
			refreshWinterAltarPetList(true)
		end,
	})
	scriptStateGB:AddToggle("AutoWinterAltar", {
		Title = "Auto " .. machineDisplayName,
		Description = "Converts the selected pets as soon as the altar cooldown allows it.",
		Default = Config.WinterAltarEnabled,
		Callback = function(enabled)
			Config.WinterAltarEnabled = enabled == true
			saveConfig()
		end,
	})
	winterAltarStatusText = scriptStateGB:AddParagraph({
		Title = machineDisplayName .. " Status",
		Content = "Select altar pets to begin.",
	})
end
end
}
