-- MEMORY_OPTIMIZER_BEGIN
do
    if activeStates.BGSI_Lite_MemoryOptimizer then pcall(activeStates.BGSI_Lite_MemoryOptimizer.Destroy) end
    local patchChunker=(function()
__CHUNKER_MEMORY__
    end)()
    local install=(function()
__MEMORY_OPTIMIZER__
    end)()
    local statsService=game:GetService("Stats")
    local optimizer=install({
        Root=Workspace,Fidelity=Enum.RenderFidelity.Performance,Active=isCurrentRun,Now=os.clock,
        PatchChunker=patchChunker,
        Position=function()
            local character=LocalPlayer.Character
            local root=character and character:FindFirstChild("HumanoidRootPart")
            return root and root.Position
        end,
        DistanceCap=function()
            if Config.safeMode~=true and Config.disableRendering~=true then
                return math.max(1,math.floor(tonumber(Config.chunkerRenderDistance) or 4))
            end
        end,
        LowDetail=function() return require(ReplicatedStorage.Client.LowDetail) end,
        Sample=function()
            local result={}
            local ok,total=pcall(statsService.GetTotalMemoryUsageMb,statsService)
            if ok then result.totalMB=total end
            for key,name in pairs({luaMB="LuaHeap",texturesMB="GraphicsTexture",meshesMB="GraphicsMeshParts"}) do
                local success,value=pcall(function()
                    if not statsService.MemoryTrackingEnabled then return nil end
                    return statsService:GetMemoryUsageMbForTag(Enum.DeveloperMemoryTag[name])
                end)
                if success then result[key]=value end
            end
            return result
        end,
    })
    activeStates.BGSI_Lite_MemoryOptimizer=optimizer
    task.spawn(function()
        local nextSample=0
        while isCurrentRun() do
            local ok,reason=pcall(function()
                optimizer.Step()
                if os.clock()>=nextSample then nextSample=os.clock()+5;optimizer.Sample() end
            end)
            if not ok then warn("[LarpLite] Memory optimizer: "..tostring(reason)) end
            task.wait(optimizer.Pending() and 0.03 or 1)
        end
        optimizer.Destroy()
    end)
end
-- MEMORY_OPTIMIZER_END
