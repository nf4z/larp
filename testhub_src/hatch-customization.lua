-- Customize the isolated Larplite envelope before rendering Discord Components V2.
return function(envelope,options,config,rarity,profile)
    local embed=envelope.embeds[1]
    local function number(value)
        local text=tostring(math.floor(value))
        return text:reverse():gsub("(%d%d%d)","%1,"):reverse():gsub("^,","")
    end
    for _,field in ipairs(embed.fields or {}) do
        if field.name=="Pet Info" then
            local lines={}
            if config.showRarity~=false then table.insert(lines,"Rarity: **"..tostring(rarity or "Unknown").."**") end
            for line in (field.value.."\n"):gmatch("(.-)\n") do
                local stat=line:match(": %*%*") and not line:find(" Egg:",1,true) and not line:find(" Chance:",1,true)
                    and not line:find("Enchants:",1,true) and not line:find("Exist:",1,true)
                if config.showPetStats==true or not stat then table.insert(lines,line) end
                if line:find(" Egg:",1,true) and config.showEggTotal~=false then
                    local egg=line:match("Egg: %*%*(.-)%*%*")
                    local total=type(profile)=="table" and type(profile.EggsOpened)=="table" and tonumber(profile.EggsOpened[egg])
                    table.insert(lines,"Eggs opened from this egg: **"..(total and number(total) or "Unavailable").."**")
                end
                if line:find("Exist:",1,true) and config.showPetHatchCount~=false then
                    local count=tonumber(options.hatchedCount)
                    table.insert(lines,count and ("You've hatched this pet "..number(count)..(count==1 and " time" or " times!"))
                        or (options.simulated and "Personal hatch count: Preview only (not counted)" or "Personal hatch count: Unavailable"))
                end
            end
            field.value=table.concat(lines,"\n")
        elseif field.name=="User Info" and config.showCurrencies~=true then
            local lines={}
            for line in (field.value.."\n"):gmatch("(.-)\n") do
                if not line:find("Current Bubbles:",1,true) and not line:find("Coins:",1,true) and not line:find("Gems:",1,true) then table.insert(lines,line) end
            end
            field.value=table.concat(lines,"\n")
        end
    end
    local color=tostring(config.embedColor or ""):gsub("^#","")
    if #color==6 and color:match("^%x+$") then embed.color=tonumber(color,16) end
    return envelope
end
