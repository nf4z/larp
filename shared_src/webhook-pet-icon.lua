-- Resolve native pet image content into an HTTP image Discord can fetch.
return function(ctx)
    local cache,count={},0
    local function publicURL(value)
        return type(value)=="string" and value:match("^https?://") and value or nil
    end
    local function decode(body)
        if type(body)~="string" or body=="" then return nil end
        local ok,data=pcall(ctx.Decode,body)
        return ok and type(data)=="table" and data or nil
    end
    local function fetch(url,method,body)
        local ok,response=pcall(ctx.Request,{Url=url,Method=method or "GET",Body=body,
            Headers={Accept="application/json",["Content-Type"]="application/json"},Timeout=8})
        if ok and type(response)=="table" then
            local status=tonumber(response.StatusCode or response.Status or response.status_code)
            if (not status or (status>=200 and status<300)) and response.Success~=false then
                local data=decode(response.Body or response.body)
                if data then return data end
            end
        end
        if method=="POST" then return nil end
        for _,get in ipairs({ctx.HttpGet,ctx.GetAsync}) do
            local success,result=pcall(get,url)
            if success then local data=decode(result);if data then return data end end
        end
    end
    local function image(data,id)
        if type(data)~="table" then return nil end
        for _,entry in ipairs(type(data.data)=="table" and data.data or data) do
            if type(entry)=="table" and (entry.targetId==nil or tostring(entry.targetId)==id)
                and (entry.state==nil or entry.state=="Completed") then
                local url=publicURL(entry.imageUrl)
                if url then return url end
            end
        end
    end
    local function remember(id,url)
        if not cache[id] then
            if count>=256 then
                local oldest,age
                for key,entry in pairs(cache) do if not age or entry.used<age then oldest,age=key,entry.used end end
                if oldest then cache[oldest]=nil;count-=1 end
            end
            count+=1
        end
        cache[id]={url=url,expires=ctx.Now()+(url and 3600 or 15),used=ctx.Now()}
        return url
    end
    local function resolve(info,shiny,mythic)
        if type(info)~="table" then return nil end
        local images=info.Images
        local content
        if type(images)=="table" then
            if shiny and mythic then content=images.MythicShiny or images.ShinyMythic or images["Shiny Mythic"] or images[4]
            elseif shiny then content=images.Shiny or images[2]
            elseif mythic then content=images.Mythic or images[3]
            else content=images.Normal or images[1] end
            content=content or images.Normal or images[1]
            if not content then for i=2,4 do if images[i] then content=images[i];break end end end
            content=content or images.Shiny or images.Mythic or images.MythicShiny
        else content=images or info.Image or info.Icon end
        content=content or info.Image or info.Icon
        if content==nil then return nil end
        local text=(type(content)=="number" and content>0 and content<math.huge and string.format("%.0f",content)
            or tostring(content)):match("^%s*(.-)%s*$")
        local lower=text:lower()
        local id=lower:match("^rbxassetid://(%d+)$") or lower:match("^(%d+)$")
        if not id and lower:match("^rbxthumb://") then id=lower:match("[?&]id=(%d+)") end
        if not id and (lower:match("^https?://www%.roblox%.com/asset[/?]") or lower:match("^https?://roblox%.com/asset[/?]")) then
            id=lower:match("[?&]id=(%d+)")
        end
        if not id then return publicURL(text) end
        if not id:match("[1-9]") then return nil end
        local existing=cache[id]
        if existing and ctx.Now()<existing.expires then existing.used=ctx.Now();return existing.url end
        local url="https://thumbnails.roblox.com/v1/assets?assetIds="..id.."&size=420x420&format=Png&isCircular=false"
        for attempt=1,3 do
            local result=image(fetch(url),id)
            if result then return remember(id,result) end
            if attempt<3 then ctx.Wait(attempt*0.35) end
        end
        -- The batch endpoint can generate a missing asset thumbnail independently.
        local ok,body=pcall(ctx.Encode,{{requestId="pet-"..id,targetId=tonumber(id),type="Asset",size="420x420",format="Png",isCircular=false}})
        if ok then
            local result=image(fetch("https://thumbnails.roblox.com/v1/batch","POST",body),id)
            if result then return remember(id,result) end
        end
        return remember(id,nil)
    end
    return {Revision=1,Resolve=resolve}
end
