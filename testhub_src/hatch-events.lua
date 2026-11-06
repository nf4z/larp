-- Only accepted server hatch results can enter this notification pipeline.
return function(ctx)
    local allowed={HatchEgg=true,HatchPowerupEgg=true,ExclusiveHatch=true}
    local state=ctx.State
    state.ids=state.ids or {};state.order=state.order or {};state.head=state.head or 1;state.tail=state.tail or 0
    local objects=setmetatable({}, {__mode="k"})
    local queue,head,tail,working={},1,0,false
    local alive=true
    local controller={}
    local function active() return alive and ctx.Active() end
    local function claim(id)
        local now=ctx.Now()
        while state.head<=state.tail do
            local first=state.order[state.head]
            if now-first.time<120 and state.tail-state.head+1<4096 then break end
            if state.ids[first.id]==first.time then state.ids[first.id]=nil end
            state.order[state.head]=nil;state.head+=1
        end
        if state.head>4096 then
            local compact={};for i=state.head,state.tail do table.insert(compact,state.order[i]) end
            state.order=compact;state.head=1;state.tail=#compact
        end
        if id==nil or tostring(id)=="" then return true end
        id=tostring(id)
        if state.ids[id] and now-state.ids[id]<120 then return false end
        state.ids[id]=now;state.tail+=1;state.order[state.tail]={id=id,time=now}
        return true
    end
    local function copy(value,seen)
        if type(value)~="table" then return value end
        seen=seen or {};if seen[value] then return seen[value] end
        local result={};seen[value]=result
        for k,v in pairs(value) do result[k]=copy(v,seen) end
        return result
    end
    local function run()
        if working then return end
        working=true
        task.spawn(function()
            while active() and head<=tail do
                local entry=queue[head];queue[head]=nil;head+=1
                local ok,reason=pcall(ctx.OnPet,entry.pet,entry.event,entry.result)
                if not ok then ctx.Error(reason) end
            end
            queue={};head=1;tail=0;working=false
        end)
    end
    function controller.Accept(event,result)
        if not active() or not allowed[event] or type(result)~="table" then return 0 end
        local owner=result.UserId or result.PlayerId or result.Player or result.Owner
        if owner~=nil then
            local id=tonumber(owner)
            if not id then local ok,value=pcall(function() return owner.UserId end);if ok then id=tonumber(value) end end
            if id and id~=ctx.UserId then return 0 end
        end
        if objects[result] then return 0 end
        objects[result]=true
        local pets=result.Pets
        if type(pets)~="table" then
            if #result>0 then pets=result
            elseif ctx.Name(result)~="Unknown" then pets={result}
            else return 0 end
        end
        local accepted=0
        for _,pet in ipairs(pets) do
            if type(pet)=="table" and ctx.Eligible(pet) then
                if tail-head>=511 then ctx.Error("Hatch notification backlog is full; skipping excess results");break end
                if claim(ctx.Id(pet)) then
                    tail+=1;queue[tail]={pet=copy(pet),event=event,result={Name=result.Name,Egg=result.Egg,EggName=result.EggName,Pets=type(result.Pets)=="table" and {} or nil}}
                    accepted+=1
                end
            end
        end
        if accepted>0 then run() end
        return accepted
    end
    function controller:IsBusy() return working or head<=tail end
    function controller:Destroy() alive=false;queue={};head=1;tail=0 end
    return controller
end
