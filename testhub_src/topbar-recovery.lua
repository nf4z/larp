-- Repair only this hub's older bundled TopbarPlus instance, before unloading it.
return function(module)
    if type(module)~="table" or type(module.getIcons)~="function" then return end
    local ok,icons=pcall(module.getIcons)
    if not ok or type(icons)~="table" then return end
    local owned=false
    for _,icon in pairs(icons) do
        if icon.iconModule and icon.iconModule.Name=="BgsiscriptTopbarPlus" then owned=true;break end
    end
    if not owned then return end
    local snapshot=table.clone(icons)
    for _,icon in pairs(snapshot) do
        for _,resource in pairs(icon) do
            if type(resource)=="table" then
                local meta=getmetatable(resource)
                local methods=type(meta)=="table" and meta.__index
                if type(methods)=="table" and type(methods.Cleanup)=="function" then
                    for name,method in pairs(table.clone(methods)) do
                        if type(name)=="string" and type(method)=="function" then
                            methods[name:sub(1,1):lower()..name:sub(2)]=method
                        end
                    end
                end
            end
        end
    end
    for _,icon in pairs(snapshot) do
        local widget=icon.widget
        if widget and widget:GetAttribute("MinimumWidth")==nil then
            -- Complete theme attributes before queued size calculations resume.
            pcall(function() icon:setTheme(module.baseTheme) end)
            pcall(function()
                if icon.isDestroyed then icon.janitor:Cleanup() else icon:destroy() end
            end)
        end
    end
end
