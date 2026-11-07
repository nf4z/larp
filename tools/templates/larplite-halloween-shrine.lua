-- HALLOWEEN_SHRINE_BEGIN
do
	local makeEngine=(function()
__HALLOWEEN_ENGINE__
	end)()
	local ok,definition=pcall(function()return require(ReplicatedStorage.Shared.Shrines.HalloweenShrine)end)
	if not ok then definition=nil end
	local engine=makeEngine({Definition=definition,Profile=profileStore,ItemUtil=itemUtil,
		Config=function()return {enabled=Config.autoHalloweenShrine==true and Config.safeMode~=true,potion=Config.halloweenShrinePotion,
			reroll=Config.halloweenShrineReroll==true,target=Config.halloweenShrineTarget}end,
		Active=isCurrentRun,Now=tick,Time=getCurrentTimestamp,
		Invoke=function(...)return remoteFunction:InvokeServer(...)end,
		Fire=function(...)return activeStates.BGSI_Lite_FireGameRemote(...)end,
		RerollCost=sharedConstants and sharedConstants.ShrineRerollCost,
	})
	scriptStateOB:AddSection("Halloween Shrine")
	scriptStateOB:AddText({Title="Shrine Info",Content="12-hour buffs for Halloween eggs only."})
	local buff=scriptStateOB:AddText({Title="Halloween Blessing",Content="Loading..."})
	local progress=scriptStateOB:AddText({Title="Shrine XP",Content="Loading..."})
	local stock=scriptStateOB:AddText({Title="Donation Stock",Content="Loading..."})
	local values,idByTitle,titleById={},{},{}
	for _,entry in ipairs(engine.Catalog)do
		table.insert(values,entry.title);idByTitle[entry.title]=entry.id;titleById[entry.id]=entry.title
	end
	local potionDropdown=scriptStateOB:AddDropdown("HalloweenShrinePotion",{Title="Halloween Donation Potion",Values=#values>0 and values or {"(Unavailable)"},Default=titleById[Config.halloweenShrinePotion],Search=true,
		Callback=function(value)if idByTitle[value]then Config.halloweenShrinePotion=idByTitle[value];saveConfig()end end})
	potionDropdown.FleetValueTransform=function(id)return titleById[id]end
	scriptStateOB:AddToggle("AutoHalloweenShrine",{Title="Auto Halloween Shrine",Default=Config.autoHalloweenShrine,
		Description="Donates selected potions, claims, then waits for the 12-hour blessing to expire.",
		Callback=function(value)Config.autoHalloweenShrine=value==true;saveConfig()end})
	scriptStateOB:AddDropdown("HalloweenShrineTarget",{Title="Halloween Target Buff",Values=definition and definition.BuffNames or {},Default=Config.halloweenShrineTarget,
		Callback=function(value)if definition and definition.BuffPool[value]then Config.halloweenShrineTarget=value;saveConfig()end end})
	scriptStateOB:AddToggle("HalloweenShrineReroll",{Title="Reroll Halloween Buff",Default=Config.halloweenShrineReroll,
		Description="Uses Shrine Tickets until the selected target buff lands.",
		Callback=function(value)Config.halloweenShrineReroll=value==true;saveConfig()end})
	local activity=scriptStateOB:AddText({Title="Halloween Shrine Activity",Content="Automatic Halloween shrine is off."})
	local last={}
	local function describe(card,text)if last[card]~=text then last[card]=text;card:Set(text)end end
	task.spawn(function()
		while isCurrentRun()do
			local good,view=pcall(engine.Step)
			if good and view.available then
				local remaining=math.floor(view.remaining or 0)
				local timer=string.format("%02d:%02d:%02d",remaining//3600,(remaining%3600)//60,remaining%60)
				local name=view.active and view.buffName or"No active blessing"
				describe(buff,name..(view.active and (" | "..timer)or""))
				describe(progress,tostring(math.floor(view.xp)).." / "..view.required.." XP")
				describe(stock,view.selected and (view.owned.." owned | "..view.needed.." needed")or"Select a potion.")
				describe(activity,view.activity)
			elseif good then describe(activity,view.activity)
			else describe(activity,"Shrine data updating; retrying shortly.")end
			task.wait(0.5)
		end
	end)
end
-- HALLOWEEN_SHRINE_END
