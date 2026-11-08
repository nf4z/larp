-- Bounded numeric diagnostics, sampled once per minute or on a mode transition.
return function(ctx)
    local history=ctx.History
    if type(history)~="table" then history={} end
    local clean={}
    local function valid(value) return type(value)=="number" and value==value and math.abs(value)<math.huge end
    for _,row in ipairs(history) do
        if type(row)=="table" and valid(row.time) and type(row.version)=="string" and type(row.mode)=="string" then
            local entry={time=row.time,version=row.version:sub(1,80),mode=row.mode:sub(1,40)}
            for _,key in ipairs({"runSeconds","totalMB","luaMB","vmMB","texturesMB","meshesMB"}) do
                if valid(row[key]) then entry[key]=row[key] end
            end
            clean[#clean+1]=entry
        end
    end
    while #clean>120 do table.remove(clean,1) end
    table.clear(history);for i,row in ipairs(clean) do history[i]=row end
    local started,nextAt,lastMode=ctx.Now(),-math.huge,nil
    local api={Samples=history}
    function api.Record(report)
        local now,mode=ctx.Now(),ctx.Mode()
        if now<nextAt and mode==lastMode then return false end
        nextAt=now+60;lastMode=mode
        local row={time=ctx.Time(),version=ctx.Version,mode=mode,runSeconds=math.max(0,now-started)}
        for _,key in ipairs({"totalMB","luaMB","vmMB","texturesMB","meshesMB"}) do if valid(report[key]) then row[key]=report[key] end end
        history[#history+1]=row
        if #history>120 then table.remove(history,1) end
        if ctx.Save then pcall(ctx.Save,{schema=1,samples=history}) end
        return true
    end
    return api
end
