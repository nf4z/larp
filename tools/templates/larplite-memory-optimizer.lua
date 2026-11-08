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
    local historyFile="LarpLiteMemory_"..configAccountId..".json"
    local samples=activeStates.BGSI_Lite_MemorySamples
    if type(samples)~="table" then
        samples={}
        if type(readfile)=="function" and type(isfile)=="function" then
            local ok,data=pcall(function()
                if not isfile(historyFile) then return nil end
                local text=readfile(historyFile)
                if type(text)~="string" or #text>131072 then return nil end
                return HttpService:JSONDecode(text)
            end)
            if ok and type(data)=="table" and data.schema==1 and type(data.samples)=="table" then samples=data.samples end
        end
    end
    local history=(function()
__MEMORY_HISTORY__
    end)()({History=samples,Version=activeStates.BGSI_Lite_ScriptVersion,Now=os.clock,Time=os.time,
        Mode=function()
            if activeStates._1rzHubLite_LoadComplete~=true then return "loading" end
            if Config.safeMode then return "safe" end
            if not Config.autoOptimizeMemory then return "off" end
            return Config.optimizeMeshDetail and "low-detail+mesh" or "native-low-detail"
        end,
        Save=type(writefile)=="function" and function(data) writefile(historyFile,HttpService:JSONEncode(data)) end or nil,
    })
    activeStates.BGSI_Lite_MemorySamples=history.Samples
    local optimizer=install({
        Root=Workspace,Fidelity=Enum.RenderFidelity.Performance,Active=isCurrentRun,Now=os.clock,
        PatchChunker=patchChunker,
        MeshDetail=function() return Config.optimizeMeshDetail==true end,
        Position=function()
            local character=LocalPlayer.Character
            local root=character and character:FindFirstChild("HumanoidRootPart")
            return root and root.Position
        end,
        DistanceCap=function()
            if Config.safeMode~=true and Config.disableRendering~=true then
                return math.max(1,math.floor(tonumber(Config.chunkerRenderDistance) or 2))
            end
        end,
        LowDetail=function() return require(ReplicatedStorage.Client.LowDetail) end,
        Sample=function()
            local result={}
            local ok,total=pcall(statsService.GetTotalMemoryUsageMb,statsService)
            if ok then result.totalMB=total end
            if type(gcinfo)=="function" then
                local success,value=pcall(gcinfo)
                if success and type(value)=="number" then result.vmMB=value/1024 end
            end
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
                if os.clock()>=nextSample then nextSample=os.clock()+5;history.Record(optimizer.Sample()) end
            end)
            if not ok then warn("[LarpLite] Memory optimizer: "..tostring(reason)) end
            task.wait(optimizer.Pending() and 0.03 or 1)
        end
        optimizer.Destroy()
    end)
end
-- MEMORY_OPTIMIZER_END
