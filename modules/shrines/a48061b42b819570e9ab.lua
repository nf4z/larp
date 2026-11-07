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
	local makeEngine=(function()
-- Shared policy for both hubs. The game owns XP, buffs, costs and expiry timestamps.
return function(context)
    local definition=context.Definition
    local catalog,byId={},{}
    for _,entry in ipairs(definition and definition.Potions or {})do
        if type(entry.Item)=="table" and entry.Item.Type=="Potion" and (tonumber(entry.XP) or 0)>0 then
            local item=table.clone(entry.Item);item.Level=tonumber(item.Level) or 1
            local id=item.Name.."/"..item.Level
            local title=item.Name..(item.Level>1 and (" "..item.Level)or"")
            if context.ItemUtil and type(context.ItemUtil.GetName)=="function"then
                local ok,name=pcall(context.ItemUtil.GetName,context.ItemUtil,item)
                if ok then title=name end
            end
            local option={id=id,title=tostring(title),item=item,xp=entry.XP}
            table.insert(catalog,option);byId[id]=option
        end
    end
    local function normalizeTargets(value)
        if type(value)=="string"then value={value}end
        local wanted,result={},{}
        for key,item in pairs(type(value)=="table"and value or {})do
            local name=type(key)=="string"and item==true and key or item
            if type(name)=="string"and (not definition or (definition.BuffPool and definition.BuffPool[name]))then wanted[name]=true end
        end
        for _,name in ipairs(definition and definition.BuffNames or {})do
            if wanted[name]then table.insert(result,name);wanted[name]=nil end
        end
        local extra={};for name in pairs(wanted)do table.insert(extra,name)end;table.sort(extra)
        for _,name in ipairs(extra)do table.insert(result,name)end
        return result
    end
    local pending,nextAction=nil,-math.huge
    local function read()
        local config=context.Config()
        local view={available=false,enabled=config.enabled==true,activity="Waiting for Halloween shrine data."}
        if not definition or (tonumber(definition.Duration) or 0)<=0 or (tonumber(definition.XPRequired) or 0)<=0 then
            view.activity="Halloween shrine is unavailable in this server.";return view
        end
        local ok,data=pcall(context.Profile.Get,context.Profile)
        local state=ok and type(data)=="table" and data.HalloweenShrine
        if type(state)~="table" or tonumber(state.StartTime)==nil or tonumber(state.XPOffered)==nil then return view end
        local start=tonumber(state.StartTime)
        local buff=state.Buff
        local remaining=buff and math.max(0,start+definition.Duration-context.Time()) or 0
        local selected=byId[config.potion]
        local owned=0
        if selected then
            local good,amount=pcall(function()return context.ItemUtil:GetOwnedAmount(data,selected.item)end)
            if good then owned=math.max(0,math.floor(tonumber(amount) or 0))end
        end
        view.available=true;view.data=data;view.state=state;view.start=start;view.buff=buff
        view.buffName=tostring(buff or "No active blessing")
        if buff and type(definition.GetBuffDisplayName)=="function"then
            local good,name=pcall(definition.GetBuffDisplayName,definition,buff)
            if good then view.buffName=name end
        end
        if buff and type(definition.GetBuffIcon)=="function"then
            local good,icon=pcall(definition.GetBuffIcon,definition,buff)
            if good then view.buffIcon=icon end
        end
        view.active=remaining>0;view.remaining=remaining
        view.xp=math.max(0,tonumber(state.XPOffered));view.required=definition.XPRequired
        view.selected=selected;view.owned=owned
        view.needed=selected and math.max(0,math.ceil((view.required-view.xp)/selected.xp)) or 0
        view.activity=view.enabled and "Ready to renew."or"Automatic Halloween shrine is off."
        return view
    end
    local function step()
        local view=read()
        if not context.Active() or not view.enabled or not view.available then return view end
        local config=context.Config()
        local selectedTargets=normalizeTargets(config.targets~=nil and config.targets or config.target)
        if view.active and config.reroll==true then
            if table.find(selectedTargets,view.buff)then
                view.activity="Selected buff active; rerolls stopped.";return view
            elseif #selectedTargets==0 then
                view.activity="Select at least one target buff.";return view
            end
        end
        if pending then
            local changed=pending.action=="donate" and view.xp~=pending.xp
                or pending.action=="claim" and (view.start~=pending.start or view.active)
                or pending.action=="reroll" and view.buff~=pending.buff
            if not changed and context.Now()-pending.at<10 then
                view.activity="Waiting for the shrine's update.";return view
            end
            pending=nil
        end
        if context.Now()<nextAction then view.activity="Waiting before the next shrine request.";return view end
        if view.active then
            view.activity="Blessing active; donations paused."
            if config.reroll~=true then return view end
            local cost=context.RerollCost
            if not cost or not context.ItemUtil or not context.ItemUtil:CanAfford(view.data,cost)then
                view.activity="No Shrine Tickets for target rerolls.";return view
            end
            if not context.Active() or context.Config().enabled~=true then return view end
            pending={action="reroll",buff=view.buff,at=context.Now()};nextAction=context.Now()+1
            local ok=pcall(context.Fire,"RerollHalloweenShrine")
            if not ok then pending=nil;nextAction=context.Now()+5 end
            view.activity="Rerolling toward selected buffs.";return view
        end
        if view.xp>=view.required then
            if not context.Active() or context.Config().enabled~=true then return view end
            pending={action="claim",start=view.start,buff=view.buff,at=context.Now()};nextAction=context.Now()+1
            local ok=pcall(context.Fire,"ClaimHalloweenShrineBuff")
            if not ok then pending=nil;nextAction=context.Now()+5 end
            view.activity="Claiming the Halloween blessing.";return view
        end
        if not view.selected then view.activity="Choose a donation potion.";return view end
        local amount=math.min(view.owned,view.needed)
        if amount<=0 then view.activity="No selected potion in inventory.";return view end
        if not context.Active() or context.Config().enabled~=true then return view end
        pending={action="donate",xp=view.xp,at=context.Now()};nextAction=context.Now()+1
        local item=view.selected.item
        local ok,accepted=pcall(context.Invoke,"DonateToHalloweenShrine",item.Name,item.Level,amount)
        if not ok or accepted~=true then
            pending=nil;nextAction=context.Now()+5;view.activity="Donation rejected; retrying shortly."
        else view.activity="Donated "..amount.."; waiting for updated XP."end
        return view
    end
    return {Catalog=catalog,Read=read,Step=step,NormalizeTargets=normalizeTargets}
end

	end)()
	local ok,definition=pcall(function()return require(ReplicatedStorage.Shared.Shrines.HalloweenShrine)end)
	if not ok then definition=nil end
	local engine=makeEngine({Definition=definition,Profile=profileStore,ItemUtil=itemUtil,
		Config=function()return {enabled=Config.autoHalloweenShrine==true and Config.safeMode~=true,potion=Config.halloweenShrinePotion,
			reroll=Config.halloweenShrineReroll==true,targets=Config.halloweenShrineTargets,target=Config.halloweenShrineTarget}end,
		Active=isCurrentRun,Now=tick,Time=getCurrentTimestamp,
		Invoke=function(...)return remoteFunction:InvokeServer(...)end,
		Fire=function(...)return activeStates.BGSI_Lite_FireGameRemote(...)end,
		RerollCost=sharedConstants and sharedConstants.ShrineRerollCost,
	})
	if type(Config.halloweenShrineTargets)~="table"then Config.halloweenShrineTargets=engine.NormalizeTargets(Config.halloweenShrineTargets or Config.halloweenShrineTarget)end
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
	scriptStateOB:AddDropdown("HalloweenShrineTargets",{Title="Halloween Target Buffs",Values=definition and definition.BuffNames or {},
		Default=engine.NormalizeTargets(Config.halloweenShrineTargets),Multi=true,
		Description="Stops on any selected buff. An empty selection pauses rerolls.",
		Callback=function(value)Config.halloweenShrineTargets=engine.NormalizeTargets(value);saveConfig()end})
	scriptStateOB:AddToggle("HalloweenShrineReroll",{Title="Reroll Halloween Buff",Default=Config.halloweenShrineReroll,
		Description="Uses Shrine Tickets until any selected target buff lands.",
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
do
	scriptStateOB:AddSection("Dream Fountain")
	scriptStateOB:AddToggle("DreamShrine", {
		Title = "Auto Dreamer Fountain",
		Description = "Waits for the blessing to expire before donating or restocking. 15 Dream Shards gives 24 hours.",
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
		Placeholder = "0-500",
		Numeric = true,
		Callback = function(scriptStateDC)
			local scriptStateABI = tonumber(scriptStateDC)
			if scriptStateABI then
				Config.shrineAmount = math.clamp(math.floor(scriptStateABI), 0, 500)
				saveConfig()
			end
		end,
	})
	scriptStateOB:AddToggle("AutoShrine", {
		Title = "Auto Donate to Bubble Shrine",
		Description = "Renews after the blessing expires. 500 potions gives 24 hours; never tops up an active blessing.",
		Default = Config.shrineAuto,
		Callback = function(scriptStateXQ)
			Config.shrineAuto = scriptStateXQ
			saveConfig()
		end,
	})
end
end
}
