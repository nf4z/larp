-- Larplite guild features adapted to this hub's private settings and owned runtime.
return function(context)
    local tab=context.Window:Tab({Title="Guilds",Icon="rbxassetid://74907707973523"})
    context.Settings.guild=type(context.Settings.guild)=="table" and context.Settings.guild or {}
    local config=context.Settings.guild
    local util=context.GuildUtil
    tab:Section({Title="Your Guild"})
    local status=tab:Paragraph({Title="Guild Status",Desc="Loading guild data..."})
    local points=tab:Paragraph({Title="Season & Points",Desc="Loading..."})
    local rewardsText=tab:Paragraph({Title="Rewards",Desc="Loading..."})
    tab:Section({Title="Weekly Quests"})
    local questCards={}
    for i=1,3 do questCards[i]=tab:Paragraph({Title="Quest "..i,Desc="Loading..."})end
    tab:Section({Title="Automation"})
    local function stop(preempted)context.SetWorking(false,preempted)end
    local function toggle(title,key,description)
        tab:Toggle({Title=title,Desc=description,Value=config[key]==true,Callback=function(value)
            config[key]=value==true
            if key=="autoQuests" and not value then stop(context.PriorityBusy())end
            context.Save()
        end})
    end
    toggle("Auto Guild Quests","autoQuests","Works bubble, hatch and sell quests tier by tier.")
    toggle("Auto Claim Guild Rewards","autoClaimRewards","Claims earned Guild and Global rewards.")
    toggle("Auto Accept Guild Invites","autoAcceptInvites","Joins the first valid invite while not in a guild.")
    local workText=tab:Paragraph({Title="Guild Activity",Desc="Automatic quest work is off."})
    local workDescription="Automatic quest work is off."
    local function showWork(message)
        if message~=workDescription then workDescription=message;workText:SetDesc(message)end
    end
    local snapshot,refreshing,requestAt,serial=nil,false,-math.huge,0
    local pending,invitePending,deferred,watch={}, {}, {}, nil
    local lastAction=-math.huge
    local labels={Bubbles="Blow Bubbles",Hatch="Hatch Eggs",Sell="Sell Bubbles",Playtime="Playtime",OpenChest="Open Chests",UsePotion="Use Potions",CatchFish="Catch Fish",CompleteMinigame="Minigame"}
    local function short(value)
        local number,index=tonumber(value) or 0,1
        local suffix={"","K","M","B","T","Qd","Qn"}
        while math.abs(number)>=1000 and index<#suffix do number/=1000;index+=1 end
        if index==1 then return tostring(math.floor(number))end
        return (string.format("%.1f%s",number,suffix[index]):gsub("%.0(%a)","%1"))
    end
    local function inGuild(data)return type(data)=="table" and type(data.Guild)=="table" and data.Guild.Id~=nil end
    local function season(data)
        if data and type(data.Season)=="table" then return data.Season end
        if util then return util:GetSeason()end
    end
    local function quests(data)
        local s=season(data)
        if not util or not s then return {}end
        local weeks=util:GetWeeks(s.Number)
        return weeks and weeks[s.Week] or {}
    end
    local function progress(data,quest)return tonumber(data and data.QuestProgress and data.QuestProgress[quest.Id]) or 0 end
    local function tier(quest,amount)
        local completed=0
        for i,goal in ipairs(quest.Tiers or {})do
            if amount<goal then return completed,goal end
            completed=i
        end
        return completed,nil
    end
    local function claimable(data)
        local result={};local s=season(data)
        if not util or not s or not inGuild(data) then return result end
        local totals={Guild=tonumber(data.Guild.Season and data.Guild.Season.Points) or 0,Global=tonumber(data.GlobalPoints) or 0}
        for _,track in ipairs({"Guild","Global"})do
            for index,reward in pairs(util:GetRewards(track,s.Number) or {})do
                local requirement=tonumber(reward.Requirement)
                if requirement and requirement<=totals[track] and not (data.Claims and data.Claims[track..":"..index]) then
                    result[#result+1]={track=track,index=index,key=tostring(s.Number)..":"..tostring(data.Guild.Id)..":"..track..":"..index}
                end
            end
        end
        table.sort(result,function(a,b)if a.track~=b.track then return a.track=="Guild"end;return a.index<b.index end)
        return result
    end
    local function display()
        local data=snapshot
        if not data then return end
        if data.Unlocked~=true and not context.Unlocked() then
            status:SetTitle("Guilds Locked");status:SetDesc("Blow 1M bubbles to unlock guilds.")
        elseif not inGuild(data) then
            local invites=0
            for _,invite in ipairs(data.Invitations or {})do if (tonumber(invite.ExpiresAt) or 0)>context.Time()then invites+=1 end end
            status:SetTitle("Not in a Guild");status:SetDesc(invites.." active invitation(s)")
        else
            local guild,count=data.Guild,0
            for _ in pairs(guild.Members or {})do count+=1 end
            status:SetTitle(tostring(guild.Name or "Your Guild"))
            status:SetDesc("Level "..tostring(guild.Level or 1).." | "..count.."/10 members")
        end
        local s=season(data)
        points:SetTitle(s and ("Season "..tostring(s.Number).." / Week "..tostring(s.Week)) or "Season & Points")
        points:SetDesc("Guild "..short(inGuild(data) and data.Guild.Season and data.Guild.Season.Points or 0).." | Global "..short(data.GlobalPoints))
        rewardsText:SetDesc(#claimable(data).." earned reward(s) ready")
        local weekly=inGuild(data) and quests(data) or {}
        for i,card in ipairs(questCards)do
            local quest=weekly[i]
            if quest then
                local taskType=quest.Task and quest.Task.Type
                local amount=progress(data,quest);local done,target=tier(quest,amount)
                local manual=taskType~="Bubbles" and taskType~="Hatch" and taskType~="Sell" and taskType~="Playtime"
                card:SetTitle(labels[taskType] or tostring(taskType or "Quest"))
                card:SetDesc(short(amount).." / "..short(target or (quest.Tiers or {})[#(quest.Tiers or {})]).." | Tier "..done.."/"..#(quest.Tiers or {})..(manual and " | Manual" or taskType=="Playtime" and " | Passive" or ""))
                if quest.Icon then card:SetIcon(quest.Icon)else card:SetIcon(nil)end
            else card:SetTitle("Quest "..i);card:SetDesc(inGuild(data) and "No quest this week." or "Join a guild to view weekly quests.");card:SetIcon(nil)end
        end
    end
    local function accept(data)
        if not context.Active() or type(data)~="table"then return end
        local before=season(snapshot);local after=season(data)
        local oldGuild=snapshot and snapshot.Guild and snapshot.Guild.Id
        local newGuild=data.Guild and data.Guild.Id
        if oldGuild~=newGuild or (before and after and (before.Number~=after.Number or before.Week~=after.Week))then
            pending={};invitePending={};deferred={};watch=nil;stop(context.PriorityBusy())
        end
        serial+=1;snapshot=data;display()
    end
    local function refresh(force)
        if not context.Active() or refreshing then return snapshot end
        local age=(config.autoQuests or config.autoClaimRewards or config.autoAcceptInvites) and 4 or 15
        if not force and context.Now()-requestAt<age then return snapshot end
        requestAt=context.Now();refreshing=true
        local before=serial
        local ok,data=pcall(context.Invoke,"GetGuildSnapshot")
        refreshing=false
        if ok and serial==before then accept(data)end
        return snapshot
    end
    context.Connect(context.Signal,function(action,data)if action=="GuildSnapshot"then accept(data)end end)
    tab:Button({Title="Refresh Guild",Desc="Requests the latest guild snapshot.",Callback=function()refresh(true)end})
    tab:Section({Title="Guild Items"})
    tab:Paragraph({Title="Guild Boxes & Eggs",Desc="Use Auto's box opener and Eggs' inventory hatcher."})
    local function step()
        if not context.Active()then stop(true);return end
        local data=refresh(false)
        if not data then return end
        local unlocked=data.Unlocked==true or context.Unlocked()
        if unlocked and context.Now()-lastAction>=0.8 then
            if config.autoClaimRewards and inGuild(data) then
                for _,reward in ipairs(claimable(data))do
                    if not pending[reward.key] or context.Now()-pending[reward.key]>=15 then
                        pending[reward.key]=context.Now();lastAction=context.Now()
                        context.Fire("GuildClaimReward",reward.track,reward.index);break
                    end
                end
            elseif config.autoAcceptInvites and not inGuild(data) then
                for _,invite in ipairs(data.Invitations or {})do
                    local key=tostring(invite.GuildId)
                    if invite.GuildId and (tonumber(invite.ExpiresAt) or 0)>context.Time() and (not invitePending[key] or context.Now()-invitePending[key]>=15)then
                        invitePending[key]=context.Now();lastAction=context.Now()
                        context.Fire("GuildAcceptInvite",invite.GuildId);break
                    end
                end
            end
        end
        if not config.autoQuests or not inGuild(data) or not unlocked or context.PriorityBusy()then
            stop(context.PriorityBusy());watch=nil
            showWork(not config.autoQuests and "Automatic quest work is off." or context.PriorityBusy() and "Waiting for other quest automation." or "Waiting for guild quests.")
            return
        end
        local currentSeason=season(data)
        if currentSeason and currentSeason.Active==false then stop(false);showWork("This guild season has ended.");return end
        local work
        for _,quest in ipairs(quests(data))do
            local kind=quest.Task and quest.Task.Type
            local amount=progress(data,quest);local _,target=tier(quest,amount)
            if target and (kind=="Bubbles"or kind=="Hatch"or kind=="Sell") and context.Now()>=(deferred[quest.Id] or 0)then
                work={id=quest.Id,kind=kind,task=quest.Task,progress=amount,target=target};break
            end
        end
        if not work then stop(false);watch=nil;showWork("Supported quests complete; other tasks are manual/passive.");return end
        if not watch or watch.id~=work.id or watch.target~=work.target or watch.progress~=work.progress then
            watch={id=work.id,target=work.target,progress=work.progress,at=context.Now()}
        elseif context.Now()-watch.at>=60 then
            deferred[work.id]=context.Now()+30;watch=nil;stop(false);showWork("No progress; trying another quest shortly.");return
        end
        context.SetWorking(true)
        local _,message=context.QuestStep(work)
        showWork(message or (labels[work.kind].." | "..short(work.progress).." / "..short(work.target)))
    end
    context.Restore(function()stop(context.PriorityBusy())end)
    task.spawn(function()
        local nextDisplay=0
        while context.Active()do
            local ok,err=pcall(step)
            if not ok then stop(context.PriorityBusy());showWork("Guild data updating; retrying shortly.");warn("[@qtrzip] Guild: "..tostring(err))end
            if context.Now()>=nextDisplay then nextDisplay=context.Now()+2;pcall(display)end
            task.wait(config.autoQuests and 0.1 or 0.5)
        end
    end)
    return {Step=step,Refresh=refresh,Accept=accept,Claimable=claimable}
end
