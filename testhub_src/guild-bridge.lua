-- Position and hatch ownership for low-priority guild quest work.
return function(context)
    local state=context.State
    local origin,originRoot,lastMove,lastAction,lastBoundary,lastHatch=nil,nil,-math.huge,-math.huge,nil,-math.huge
    local targetId,positionReady=nil,false
    local fallbackEgg
    local function root()return context.Player.Character and context.Player.Character:FindFirstChild("HumanoidRootPart")end
    local function busy()return state.questActive==true end
    local function working(enabled,preempted)
        if enabled then
            if not state.guildQuestActive then originRoot=root();origin=originRoot and originRoot.CFrame end
            state.guildQuestActive=true
        else
            if state.guildQuestActive and not preempted and not busy() and root()==originRoot and origin then pcall(function()originRoot.CFrame=origin end)end
            state.guildQuestActive=false;origin=nil;originRoot=nil;lastMove=-math.huge;lastBoundary=nil;targetId=nil;positionReady=false
        end
    end
    local function step(work)
        if not context.Active() or busy()then return false,"Waiting for other quest automation."end
        local currentRoot=root();if not currentRoot then return false,"Waiting for your character."end
        local data=context.Profile:Get()
        if not data then return false,"Waiting for player data."end
        local now=context.Now()
        if work.kind=="Hatch"then
            local egg=(context.Settings.eggs or {}).selectedEgg or ""
            if egg==""then
                fallbackEgg=fallbackEgg or (context.EggScanner.GetNames and context.EggScanner.GetNames()[1])
                egg=fallbackEgg or ""
            end
            if egg==""then return false,"Select an egg in the Eggs tab."end
            if targetId~=egg then targetId=egg;lastMove=-math.huge;positionReady=false;lastBoundary=nil end
            if now-lastMove>=1 then
                lastMove=now
                positionReady=context.EggScanner.Teleport(egg)
            end
            if not positionReady then return false,"Loading selected egg location..."end
            if not context.Active() or busy()then return false end
            local boundary=tonumber(context.Player:GetAttribute("NextEggOpenAt")) or 0
            if context.Time()<boundary or (lastBoundary==boundary and now-lastHatch<2)then return false,"Waiting for the egg cooldown."end
            if context.CheckSpace and not context.CheckSpace(data)then return false,"Pet inventory is full."end
            local amount=math.clamp(math.floor(tonumber((context.Settings.eggs or {}).hatchAmount) or 12),1,12)
            if context.Stats and context.Stats.GetMaxEggHatches then amount=math.min(amount,math.max(1,context.Stats:GetMaxEggHatches(data)))end
            lastBoundary=boundary;lastHatch=now
            context.Fire("HatchEgg",egg,amount)
            return true,"Hatching "..egg.." for your guild."
        end
        if targetId~="Sell"then targetId="Sell";positionReady=false;lastMove=-math.huge end
        if now-lastMove>=1 then
            lastMove=now
            local worlds=context.Workspace:FindFirstChild("Worlds")
            local world=worlds and worlds:FindFirstChild("The Overworld")
            local sell=world and world:FindFirstChild("Sell")
            local ring=sell and sell:FindFirstChild("Ring")
            positionReady=ring~=nil
            if not positionReady then return false,"Load The Overworld's sell area first."end
            currentRoot.CFrame=ring.CFrame+CFrame.new(0,3,0).Position
        end
        if not positionReady then return false,"Load The Overworld's sell area first."end
        if now-lastAction<0.5 then return false end
        lastAction=now
        local amount=tonumber(data.Bubble and data.Bubble.Amount) or 0
        local shouldSell=work.kind=="Sell" and amount>0
        if work.kind=="Bubbles" and context.Stats and context.Stats.GetBubbleStorage then
            local maximum=context.Stats:GetBubbleStorage(data)
            shouldSell=amount>0 and amount>=maximum and not(data.Passes and data.Passes["Infinity Gum"])
        end
        context.Fire(shouldSell and "SellBubble"or"BlowBubble")
        return true,work.kind=="Sell" and "Alternating blows and sells for your guild."or"Blowing bubbles for your guild."
    end
    return {PriorityBusy=busy,SetWorking=working,QuestStep=step}
end
