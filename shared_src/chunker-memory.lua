-- Preserve native chunk ranges and remove loaded flags for coordinates with no data.
return function(module,ctx)
    if type(module)~="table" or type(module.Update)~="function" then return nil end
    if module._BGSI_MEMORY_PATCH then module._BGSI_MEMORY_PATCH.Destroy() end
    local update=module._BGSI_CHUNKER_TRUE_UPDATE or module.Update
    local remove=module._BGSI_CHUNKER_TRUE_REMOVE or module.Remove
    module._BGSI_CHUNKER_TRUE_UPDATE=update
    module._BGSI_CHUNKER_TRUE_REMOVE=remove
    local tracked=setmetatable({}, {__mode="k"})
    local live=true
    local patch={}
    local function enabled() return live and ctx.Active() and ctx.Enabled() end
    local function sweep(self)
        if type(self._loaded)~="table" or type(self._chunks)~="table" then return end
        for coord in pairs(self._loaded) do
            if self._chunks[coord]==nil then self._loaded[coord]=nil;ctx.Pruned(1) end
        end
    end
    local function wrappedUpdate(self,position,...)
        if type(self)=="table" and live and ctx.Active() then
            local record=tracked[self]
            if not record then
                record={distance=self._BGSI_LITE_ORIGINAL_RENDER_DISTANCE or self.RenderDistance,swept=-math.huge}
                tracked[self]=record
            end
            local limit=ctx.DistanceCap()
            local original=tonumber(record.distance)
            local desired=limit and original and math.min(original,math.max(1,math.floor(limit))) or record.distance
            self.RenderDistance=desired;record.applied=desired
            if enabled() and ctx.Now()-record.swept>=30 then record.swept=ctx.Now();sweep(self) end
        end
        return update(self,position,...)
    end
    local function wrappedRemove(self,position,...)
        local results=table.pack(remove(self,position,...))
        if enabled() and type(self)=="table" and type(self._loaded)=="table" and type(self._chunks)=="table" then
            local coord=self:ToCoord(position)
            if self._loaded[coord]~=nil and self._chunks[coord]==nil then self._loaded[coord]=nil;ctx.Pruned(1) end
        end
        return table.unpack(results,1,results.n)
    end
    function patch.Refresh(position)
        if not live or not ctx.Active() then return end
        for self,record in pairs(tracked) do
            if position then pcall(wrappedUpdate,self,position)
            else self.RenderDistance=record.distance;record.applied=record.distance end
        end
    end
    function patch.Destroy()
        if not live then return end
        live=false
        if module.Update==wrappedUpdate then module.Update=update end
        if module.Remove==wrappedRemove then module.Remove=remove end
        local position
        if ctx.Position then local ok,value=pcall(ctx.Position);if ok then position=value end end
        for self,record in pairs(tracked) do
            if self.RenderDistance==record.applied then self.RenderDistance=record.distance end
            self._BGSI_LITE_ORIGINAL_RENDER_DISTANCE=nil
            if position then pcall(update,self,position) end
        end
        table.clear(tracked)
        if module._BGSI_MEMORY_PATCH==patch then module._BGSI_MEMORY_PATCH=nil end
    end
    module.Update=wrappedUpdate
    if type(remove)=="function" then module.Remove=wrappedRemove end
    module._BGSI_MEMORY_PATCH=patch
    return patch
end
