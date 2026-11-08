-- Visual-only changes. Never delete game content, clear native pools, or change physics.
return function(ctx)
    local live,enabled,meshEnabled=true,false,false
    local originals=setmetatable({}, {__mode="k"})
    local stack,added={},{}
    local addedHead,addedTail=1,0
    local rescan=false
    local pending=setmetatable({}, {__mode="k"})
    local connection,lowConnection
    local low,lowOriginal,writingLow
    local lowPending,lowEpoch={},0
    local report={meshesChanged=0,chunkKeysFreed=0}
    local patch,chunkModule
    local api={Report=report}
    local function setLow(value)
        if not low or low.Enabled==value then return end
        writingLow=true
        if lowConnection then lowPending[#lowPending+1]=value end
        low.Enabled=value
        if low.Changed then
            local ok=pcall(low.Changed.Fire,low.Changed,value)
            if not ok then table.clear(lowPending) end
        end
        writingLow=false
    end
    local function inspect(instance)
        if not enabled or not live or not instance:IsA("MeshPart") or not instance:IsDescendantOf(ctx.Root) then return end
        local parent=instance.Parent
        while parent and parent~=ctx.Root do
            if parent:IsA("GuiBase2d") or parent:IsA("LayerCollector") or parent:IsA("ViewportFrame") then return end
            if parent:IsA("Model") and parent:FindFirstChildOfClass("Humanoid") then return end
            parent=parent.Parent
        end
        if originals[instance] then return end
        local ok,before=pcall(function() return instance.RenderFidelity end)
        if ok and before~=ctx.Fidelity then
            local success=pcall(function() instance.RenderFidelity=ctx.Fidelity end)
            if success then originals[instance]=before;report.meshesChanged+=1 end
        end
    end
    local function enqueue(instance)
        if not enabled or not meshEnabled or not instance:IsA("MeshPart") or pending[instance] then return end
        -- Coalesce large streaming bursts into one incremental rescan, never a frame spike.
        if addedTail-addedHead>=2047 then rescan=true;return end
        pending[instance]=true;addedTail+=1;added[addedTail]=instance
    end
    function api.SetEnabled(value)
        value=value==true
        local meshes=value and (not ctx.MeshDetail or ctx.MeshDetail()==true)
        if not live or (value==enabled and meshes==meshEnabled) then return end
        if enabled and value then api.SetEnabled(false) end
        enabled=value
        meshEnabled=meshes
        if value then
            local ok,result=pcall(ctx.LowDetail)
            if ok and type(result)=="table" and type(result.Enabled)=="boolean" then
                low=result;lowOriginal=low.Enabled
                lowEpoch+=1;local epoch=lowEpoch
                table.clear(lowPending)
                if low.Changed and type(low.Changed.Connect)=="function" then
                    lowConnection=low.Changed:Connect(function(value)
                        if epoch~=lowEpoch or not enabled then return end
                        if #lowPending>0 and lowPending[1]==value then table.remove(lowPending,1);return end
                        if not writingLow then lowOriginal=low.Enabled end
                    end)
                end
                setLow(true)
            end
            if meshEnabled then
                connection=ctx.Root.DescendantAdded:Connect(enqueue)
                stack={ctx.Root}
            end
        else
            lowEpoch+=1;table.clear(lowPending)
            if connection then connection:Disconnect();connection=nil end
            if lowConnection then lowConnection:Disconnect();lowConnection=nil end
            if low then setLow(lowOriginal);low=nil end
            for instance,before in pairs(originals) do
                pcall(function() if instance.RenderFidelity==ctx.Fidelity then instance.RenderFidelity=before end end)
            end
            table.clear(originals);table.clear(stack);table.clear(added);table.clear(pending)
            addedHead=1;addedTail=0;rescan=false;report.meshesChanged=0
        end
    end
    function api.Step()
        if not live or not enabled or not meshEnabled or not ctx.Active() then return end
        local started=ctx.Now()
        for _=1,128 do
            local instance
            if addedHead<=addedTail then
                instance=added[addedHead];added[addedHead]=nil;addedHead+=1;pending[instance]=nil
                inspect(instance)
            else
                if addedTail>0 then table.clear(added);addedHead=1;addedTail=0 end
                if #stack==0 and rescan then stack={ctx.Root};rescan=false end
                instance=table.remove(stack)
                if not instance then break end
                if instance==ctx.Root or instance:IsDescendantOf(ctx.Root) then
                    inspect(instance)
                    if not instance:IsA("GuiBase2d") and not instance:IsA("LayerCollector") then
                        for _,child in ipairs(instance:GetChildren()) do stack[#stack+1]=child end
                    end
                end
            end
            if ctx.Now()-started>=0.002 then break end
        end
    end
    function api.InstallChunker(module)
        if patch and module==chunkModule then return true end
        if patch then patch.Destroy() end
        patch=ctx.PatchChunker(module,{
            Active=function() return live and ctx.Active() end,
            Enabled=function() return enabled end,DistanceCap=ctx.DistanceCap,Now=ctx.Now,Position=ctx.Position,
            Pruned=function(count) report.chunkKeysFreed+=count end,
        })
        chunkModule=module
        return patch~=nil
    end
    function api.Sample()
        if not live then return report end
        local ok,stats=pcall(ctx.Sample)
        if ok and type(stats)=="table" then
            report.totalMB=stats.totalMB;report.luaMB=stats.luaMB
            report.texturesMB=stats.texturesMB;report.meshesMB=stats.meshesMB
            report.vmMB=stats.vmMB
        end
        if api.OnReport then pcall(api.OnReport,report) end
        return report
    end
    function api.RefreshChunks(position)
        if live and patch then patch.Refresh(position) end
    end
    function api.VisitChunkers(visitor)
        if live and patch then patch.Visit(visitor) end
    end
    function api.Pending() return rescan or #stack>0 or addedHead<=addedTail end
    function api.Destroy()
        if not live then return end
        api.SetEnabled(false);live=false
        if patch then patch.Destroy();patch=nil end
        api.OnReport=nil;chunkModule=nil
    end
    return api
end
