-- Selected Larplite features adapted to this hub's private settings and owned tasks.
return function(context)
    local Window, profile, powerups = context.Window, context.Profile, context.Powerups
    local settings, save = context.Settings, context.Save
    settings.auto = settings.auto or {}
    local config = settings.auto
    local function data() local ok, value = pcall(function() return profile:Get() end); return ok and value or {} end
    local function owned(name)
        local current = data()
        if context.ItemUtil then
            local ok, amount = pcall(function() return context.ItemUtil:GetOwnedAmount(current, {Type="Powerup", Name=name}) end)
            if ok and tonumber(amount) then return math.max(0, math.floor(tonumber(amount))) end
        end
        return math.max(0, math.floor(tonumber(current.Powerups and current.Powerups[name]) or 0))
    end
    local function giftNames()
        local result = {}
        for name, info in pairs(powerups) do
            if type(name)=="string" and type(info)=="table" and info.Type=="Gift" then table.insert(result,name) end
        end
        table.sort(result); return result
    end
    local function selectedNames(value)
        local result, seen = {}, {}
        if type(value)=="string" then value={value} end
        for key, item in pairs(type(value)=="table" and value or {}) do
            local name = type(key)=="string" and item==true and key or item
            if type(name)=="string" and powerups[name] and powerups[name].Type=="Gift" and not seen[name] then
                seen[name]=true;table.insert(result,name)
            end
        end
        table.sort(result);return result
    end
    config.selectedBoxes=selectedNames(config.selectedBoxes or config.selectedBox)
    config.boxBatch=math.clamp(math.floor(tonumber(config.boxBatch) or 25),1,context.MaxGifts)
    config.boxDelay=math.clamp(tonumber(config.boxDelay) or 0.5,0.2,60)
    config.condenserReserve=math.max(0,math.floor(tonumber(config.condenserReserve) or 0))
    local auto=Window:Tab({Title="Auto"})
    auto:Section({Title="Mystery Boxes"})
    local picker=auto:Dropdown({Title="Boxes To Open",Desc="All gift types, including Guild and Condensed boxes. Takes turns between owned selections.",
        Values=giftNames(),Value=config.selectedBoxes,Multi=true,Callback=function(value) config.selectedBoxes=selectedNames(value);save() end})
    local inventory=auto:Paragraph({Title="Box Inventory",Desc="Loading owned counts..."})
    local function refreshInventory()
        local parts={}
        for _, name in ipairs(config.selectedBoxes) do table.insert(parts,name..": "..owned(name)) end
        inventory:SetDesc(#parts>0 and table.concat(parts," | ") or "Select boxes above. Unowned types stay available in the list.")
    end
    auto:Button({Title="Refresh Box List",Callback=function() picker:Refresh(giftNames());refreshInventory() end})
    auto:Input({Title="Box Batch Size",Value=tostring(config.boxBatch),Callback=function(value)
        local n=tonumber(value);if n then config.boxBatch=math.clamp(math.floor(n),1,context.MaxGifts);save() end
    end})
    auto:Input({Title="Box Open Delay",Desc="Seconds between batches (0.2–60).",Value=tostring(config.boxDelay),Callback=function(value)
        local n=tonumber(value);if n then config.boxDelay=math.clamp(n,0.2,60);save() end
    end})
    auto:Toggle({Title="Auto Open Boxes",Desc="Opens and collects selected gifts without clicking the screen.",Value=config.autoOpenBox==true,
        Callback=function(value) config.autoOpenBox=value;save() end})
    local condenser=context.Condenser or {Input="Mystery Box",Output="Condensed Mystery Box",Boxes=100,Gems=500}
    local inputName,outputName=condenser.Input or "Mystery Box",condenser.Output or "Condensed Mystery Box"
    local costBoxes=math.max(1,tonumber(condenser.Boxes) or 100)
    local costGems=math.max(1,tonumber(condenser.Gems) or 500)
    local function canCondense()
        return owned(inputName)>=costBoxes and (tonumber(data().Gems) or 0)-config.condenserReserve>=costGems
    end
    auto:Section({Title="Box Condenser"})
    local condenserStatus=auto:Paragraph({Title="Condenser",Desc=costBoxes.." "..inputName.." + "..costGems.." Gems per craft."})
    auto:Input({Title="Keep Gems",Desc="Condensing stops before spending this reserve.",Value=tostring(config.condenserReserve),Callback=function(value)
        local n=tonumber(value);if n then config.condenserReserve=math.max(0,math.floor(n));save() end
    end})
    local pendingCondenser
    local function condenseOne()
        if not context.Active() or not canCondense() then return false end
        if pendingCondenser and owned(outputName)<=pendingCondenser.output and owned(inputName)>=pendingCondenser.input and context.Now()-pendingCondenser.time<5 then return false end
        local beforeInput,beforeOutput=owned(inputName),owned(outputName)
        local ok,err=context.Condense()
        if ok then
            pendingCondenser={input=beforeInput,output=beforeOutput,time=context.Now()}
            condenserStatus:SetDesc("Craft requested. Waiting for the inventory update.")
        else condenserStatus:SetDesc(tostring(err or "Load Zen Island's condenser first.")) end
        return ok
    end
    auto:Button({Title="Condense One",Desc="Crafts once, keeping your gem reserve.",Callback=condenseOne})
    auto:Toggle({Title="Auto Condense Mystery Boxes",Desc="Reserves normal boxes for crafting while affordable; the opener uses other selections.",Value=config.autoCondenseBoxes==true,
        Callback=function(value) config.autoCondenseBoxes=value;save() end})
    local rotation,lastOpen,pending=0,-math.huge,{}
    local collecting=setmetatable({}, {__mode="k"})
    local function collectGifts()
        local physical=context.PhysicalItem
        if not physical or type(physical.GetActiveGifts)~="function" then return end
        local ok,gifts=pcall(function() return physical:GetActiveGifts() end)
        if not ok or type(gifts)~="table" then return end
        for _,gift in pairs(gifts) do
            if type(gift)=="table" and gift.Animating~=true and type(gift.Collect)=="function" and not collecting[gift] then
                collecting[gift]=true
                task.spawn(function()
                    if not context.Active() then return end
                    local success=pcall(function() gift:Collect() end)
                    if not success then collecting[gift]=nil end
                end)
            end
        end
    end
    local function stepBoxes()
        if not context.Active() or not config.autoOpenBox then return end
        collectGifts()
        if context.Now()-lastOpen<config.boxDelay then return end
        local active=0
        if context.PhysicalItem and context.PhysicalItem.GetActiveObjects then
            local ok,count=pcall(function() return context.PhysicalItem:GetActiveObjects("Gift") end)
            if ok then active=tonumber(count) or 0 end
        end
        local capacity=context.MaxGifts-active
        if capacity<=0 then return end
        local names=config.selectedBoxes
        for _=1,#names do
            rotation=rotation%#names+1
            local name=names[rotation]
            local amount=owned(name)
            local waiting=pending[name] and amount>=pending[name].before and context.Now()-pending[name].time<5
            local reserved=name==inputName and config.autoCondenseBoxes and canCondense()
            if amount>0 and not waiting and not reserved then
                local batch=math.min(amount,config.boxBatch,capacity)
                local ok=pcall(context.Fire,"UseGift",name,batch)
                if ok then pending[name]={before=amount,time=context.Now()};lastOpen=context.Now() end
                return
            end
        end
    end
    refreshInventory()
    task.spawn(function()
        local lastRefresh,lastCondense=-math.huge,-math.huge
        while context.Active() do
            local ok,err=pcall(function()
                stepBoxes()
                if config.autoCondenseBoxes and context.Now()-lastCondense>=1 then lastCondense=context.Now();condenseOne() end
                if context.Now()-lastRefresh>=3 then lastRefresh=context.Now();refreshInventory() end
            end)
            if not ok then warn("[@qtrzip] Boxes: "..tostring(err)) end
            task.wait(config.autoOpenBox and 0.25 or 1)
        end
    end)
    local server=Window:Tab({Title="Server"})
    server:Section({Title="Server Tools"})
    local message=server:Paragraph({Title="Current Server",Desc=tostring(context.JobId)})
    local function report(callback)
        local ok,err=pcall(callback)
        if not ok then message:SetDesc(tostring(err)) end
    end
    server:Button({Title="Copy Job ID",Callback=function() report(function() assert(context.Copy,"Clipboard unavailable");context.Copy(context.JobId);message:SetDesc("Job ID copied.") end) end})
    server:Button({Title="Copy Join Script",Callback=function() report(function()
        assert(context.Copy,"Clipboard unavailable")
        context.Copy(string.format('game:GetService("TeleportService"):TeleportToPlaceInstance(%d, %q, game:GetService("Players").LocalPlayer)',context.PlaceId,context.JobId))
        message:SetDesc("Join script copied.")
    end) end})
    server:Button({Title="Rejoin Server",Callback=function() report(function() context.Join(context.JobId) end) end})
    local jobId=""
    server:Input({Title="Server Job ID",Placeholder="Paste a Job ID",Value="",Callback=function(value) jobId=tostring(value):gsub("%s+","") end})
    server:Button({Title="Join Job ID",Callback=function() report(function() assert(jobId~="","Enter a Job ID first.");context.Join(jobId) end) end})
    server:Button({Title="Hop To Emptiest Server",Desc="Checks up to three pages of public servers.",Callback=function() report(function()
        local id=context.FindServer();assert(id,"No other joinable public server found.");context.Join(id)
    end) end})
    return {GiftNames=giftNames,StepBoxes=stepBoxes,CondenseOne=condenseOne,CanCondense=canCondense,RefreshInventory=refreshInventory}
end
