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
end
}
