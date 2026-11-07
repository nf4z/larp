-- Penguin Trio's fixed-stock winter-shop, using the game's catalog and item descriptors.
return function(context)
    local definition=context.Shops and context.Shops["winter-shop"]
    local tab=context.Window:Tab({Title="Event"})
    tab:Section({Title="Penguin Trio Shop"})
    context.Settings.penguinShop=type(context.Settings.penguinShop)=="table" and context.Settings.penguinShop or {}
    local config=context.Settings.penguinShop
    local options,slots={},{}
    for index,entry in ipairs(definition and definition.PermanentItems or {}) do
        local product=entry.Product
        if type(product)=="table" then
            local name=context.ItemUtil:GetName(product)
            local level=product.Type=="Potion" and (tonumber(product.Level) or 1) or 0
            local value=table.concat({product.Type,product.Name,tostring(level),tostring(product.Tier or 0)},":")
            options[#options+1]={Title=tostring(name),Value=value,Item=table.clone(product)}
            slots[value]=index
        end
    end
    local function selected(value)
        local result,seen={},{}
        for key,item in pairs(type(value)=="table" and value or {}) do
            local id=type(key)=="string" and item==true and key or item
            if slots[id] and not seen[id] then seen[id]=true;table.insert(result,id) end
        end
        return result
    end
    config.items=selected(config.items)
    tab:Dropdown({Title="Penguin Shop Items",Desc="Choose items to buy when stock and gems are available.",
        Values=options,Value=config.items,Multi=true,Callback=function(value)config.items=selected(value);context.Save()end})
    tab:Toggle({Title="Auto Buy Penguin Shop",Desc="Buys selected items and resumes after the shop restocks.",
        Value=config.autoBuy==true,Callback=function(value)config.autoBuy=value==true;context.Save()end})
    local status=tab:Paragraph({Title="Penguin Shop Status",Desc=definition and "Select items and enable auto buy." or "Shop unavailable in this server."})
    local pending,rotation={},0
    local function step()
        if not context.Active() or not definition or not config.autoBuy then return end
        if #config.items==0 then status:SetDesc("Select items to buy.");return end
        local data=context.Profile:Get()
        local state=data and data.Shops and data.Shops["winter-shop"]
        if type(state)~="table" then status:SetDesc("Visit the Penguin Trio to load this shop.");return end
        local items,stocks=context.ShopUtil:GetItemsData("winter-shop",context.Player,data)
        local unlocked=context.ShopUtil:GetUnlockedSlots(data,#items)
        local period=tostring(state.Period or state.Began or "")
        for offset=1,#config.items do
            local pos=(rotation+offset-1)%#config.items+1
            local slot=slots[config.items[pos]]
            local item=items[slot]
            local bought=tonumber(state.Bought and (state.Bought[slot] or state.Bought[tostring(slot)])) or 0
            local remain=math.max(0,(tonumber(stocks[slot]) or 0)-bought)
            local old=pending[slot]
            local waiting=old and old.period==period and old.bought==bought and context.Now()-old.at<10
            if slot<=unlocked and item and remain>0 and not waiting and context.ItemUtil:CanAfford(data,item.Cost) then
                rotation=pos
                pending[slot]={period=period,bought=bought,at=context.Now()}
                context.Fire("BuyShopItem","winter-shop",slot,true)
                status:SetDesc("Buying "..context.ItemUtil:GetName(item.Product).."; waiting for inventory.")
                return
            end
        end
        status:SetDesc("Waiting for selected stock, gems, or purchase confirmation.")
    end
    task.spawn(function()
        while context.Active() do
            local ok,err=pcall(step)
            if not ok then status:SetDesc("Shop data updating; retrying shortly.");warn("[@qtrzip] Penguin shop: "..tostring(err)) end
            task.wait(0.75)
        end
    end)
    return {Step=step,Options=options}
end
