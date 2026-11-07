return function(context)
    local tab=context.Window:Tab({Title="Shrine"})
    context.Settings.halloweenShrine=type(context.Settings.halloweenShrine)=="table" and context.Settings.halloweenShrine or {}
    local config=context.Settings.halloweenShrine
    if type(config.potion)~="string"then config.potion="Lucky/6"end
    if type(config.target)~="string"then config.target="Secret"end
    local engine=context.MakeEngine({Definition=context.Definition,Profile=context.Profile,ItemUtil=context.ItemUtil,
        Config=function()return config end,Active=context.Active,Now=context.Now,Time=context.Time,
        Invoke=context.Invoke,Fire=context.Fire,RerollCost=context.RerollCost})
    if type(config.targets)~="table"then config.targets=engine.NormalizeTargets(config.targets or config.target)end
    tab:Section({Title="Halloween Shrine"})
    tab:Paragraph({Title="Shrine Info",Desc="12-hour buffs for Halloween eggs only."})
    local buff=tab:Paragraph({Title="Halloween Blessing",Desc="Loading..."})
    local progress=tab:Paragraph({Title="Shrine XP",Desc="Loading..."})
    local stock=tab:Paragraph({Title="Donation Stock",Desc="Loading..."})
    local options={}
    for _,entry in ipairs(engine.Catalog)do options[#options+1]={Title=entry.title,Value=entry.id,Item=entry.item}end
    tab:Dropdown({Title="Halloween Donation Potion",Desc="Donates only enough selected potions to fill required XP.",Values=options,Value=config.potion,
        Callback=function(value)config.potion=value;context.Save()end})
    tab:Toggle({Title="Auto Halloween Shrine",Desc="Donate, claim, then wait for the 12-hour blessing to expire.",Value=config.enabled==true,
        Callback=function(value)config.enabled=value==true;context.Save()end})
    local buffs={}
    for _,name in ipairs(context.Definition and context.Definition.BuffNames or {})do
        buffs[#buffs+1]={Title=context.Definition:GetBuffDisplayName(name),Value=name,Icon=context.Definition:GetBuffIcon(name)}
    end
    tab:Dropdown({Title="Halloween Target Buffs",Desc="Stops on any selected buff. An empty selection pauses rerolls.",
        Values=buffs,Value=engine.NormalizeTargets(config.targets),Multi=true,Callback=function(value)
            config.targets=engine.NormalizeTargets(value);context.Save()
        end})
    tab:Toggle({Title="Reroll Halloween Buff",Desc="Uses Shrine Tickets until any selected buff lands.",Value=config.reroll==true,
        Callback=function(value)config.reroll=value==true;context.Save()end})
    local activity=tab:Paragraph({Title="Halloween Shrine Activity",Desc="Automatic Halloween shrine is off."})
    local last={}
    local shownIcon
    local function describe(card,text)if last[card]~=text then last[card]=text;card:SetDesc(text)end end
    local function render(view)
        if not view.available then describe(buff,view.activity);describe(activity,view.activity);describe(progress,"Unavailable");describe(stock,"Unavailable");return end
        local name=view.active and view.buffName or "No active blessing"
        local remaining=math.floor(view.remaining or 0)
        local timer=string.format("%02d:%02d:%02d",remaining//3600,(remaining%3600)//60,remaining%60)
        describe(buff,name..(view.active and (" | "..timer)or""))
        local icon=view.active and view.buffIcon or nil
        if icon~=shownIcon then shownIcon=icon;buff:SetIcon(icon)end
        describe(progress,tostring(math.floor(view.xp)).." / "..view.required.." XP")
        describe(stock,view.selected and (view.owned.." owned | "..view.needed.." needed")or"Select a potion.")
        describe(activity,view.activity)
    end
    task.spawn(function()
        while context.Active()do
            local ok,view=pcall(engine.Step)
            if ok then render(view)else describe(activity,"Shrine data updating; retrying shortly.")end
            task.wait(0.5)
        end
    end)
    return {Engine=engine,Render=render}
end
