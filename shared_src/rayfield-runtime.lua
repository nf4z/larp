-- Rayfield alone gets this compatibility environment; executor globals are untouched.
return function(ctx)
    local original=ctx.Environment
    local dataModel=ctx.Game
    local known=ctx.Services or {}
    local typeOf=original.typeof or typeof
    local clone=original.cloneref
    local function instance(value) return value~=nil and typeOf(value)=="Instance" end
    local function resolve(name)
        if instance(known[name]) then return known[name] end
        for _,method in ipairs({"GetService","FindService","FindFirstChild"}) do
            local ok,value=pcall(function() return dataModel[method](dataModel,name) end)
            if ok and instance(value) then known[name]=value;return value end
        end
        error("[LarpLite] Rayfield service unavailable: "..tostring(name),2)
    end
    local function safeClone(value)
        if value==nil or not instance(value) or type(clone)~="function" then return value end
        local ok,result=pcall(clone,value)
        if ok and instance(result) then return result end
        return value
    end
    local environment=setmetatable({_LarpLiteUiService=resolve,cloneref=safeClone},{__index=original})
    return {
        Environment=environment,
        Prepare=function(text)
            -- Covers both parenthesized and string-literal calls in Rayfield's two service helpers.
            return (text:gsub("game%s*:%s*GetService", "_LarpLiteUiService"))
        end,
    }
end
