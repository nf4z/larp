-- Each runtime writes its own shard: simultaneous alts never overwrite each other.
-- The root JSON is a readable snapshot; shards are the authoritative counters.
return function(ctx)
    local folder="qtrzip_hatch_history"
    local snapshot="qtrzip_hatch_totals.json"
    local own={schema=1,account=tostring(ctx.UserId),pets={}}
    local path=folder.."/"..tostring(ctx.UserId).."-"..ctx.Session..".json"
    local warned=false
    local function warning(reason)
        if not warned then warned=true;ctx.Warn("Hatch totals cannot be saved: "..tostring(reason)) end
    end
    local function key(name,super,shiny,mythic,xl)
        return tostring(#name)..":"..name..":"..(super and "S" or "-")..(shiny and "H" or "-")..(mythic and "M" or "-")..(xl and "X" or "-")
    end
    local function merge(totals,data)
        if type(data)~="table" or data.schema~=1 or type(data.pets)~="table" then return end
        for id,count in pairs(data.pets) do
            if type(id)=="string" and type(count)=="number" and count>=0 and count<math.huge then
                totals[id]=(totals[id] or 0)+math.floor(count)
            end
        end
    end
    local function aggregate()
        local totals={}
        if ctx.List and ctx.Read then
            local ok,files=pcall(ctx.List,folder)
            if ok and type(files)=="table" then
                for _,file in ipairs(files) do
                    local normalized=tostring(file):gsub("\\","/")
                    if normalized:match("/[%w%-]+%.json$") and normalized:sub(-#path)~=path then
                        local success,data=pcall(function() return ctx.Decode(ctx.Read(file)) end)
                        if success then merge(totals,data) else warning("an unreadable history shard was skipped") end
                    end
                end
            elseif not ok then warning(files) end
        end
        merge(totals,own)
        return totals
    end
    local ready=false
    local function prepare()
        if ready then return true end
        if not (ctx.MakeFolder and ctx.Write and ctx.Read and ctx.List) then warning("executor file functions unavailable");return false end
        local ok,reason=pcall(function()
            if not ctx.IsFolder or not ctx.IsFolder(folder) then ctx.MakeFolder(folder) end
        end)
        if not ok then warning(reason);return false end
        ready=true;return true
    end
    return {
        Record=function(name,super,shiny,mythic,xl)
            local id=key(name,super,shiny,mythic,xl)
            own.pets[id]=(own.pets[id] or 0)+1
            if prepare() then
                local ok,reason=pcall(ctx.Write,path,ctx.Encode(own))
                if not ok then warning(reason) end
            end
            local totals=aggregate()
            if ready then
                local ok,reason=pcall(ctx.Write,snapshot,ctx.Encode({schema=1,pets=totals,updatedAt=ctx.Time()}))
                if not ok then warning(reason) end
            end
            return totals[id] or own.pets[id]
        end,
        Key=key,
    }
end
