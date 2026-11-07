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
