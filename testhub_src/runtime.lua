-- Owned runtime resources. Shared game modules keep their original task/Instance APIs.
local realTask, realInstance = task, Instance
runtime.Active = true
runtime.Threads = {}
runtime.Connections = {}
runtime.Instances = setmetatable({}, {__mode = "k"})
runtime.Restore = {}
local remembered = setmetatable({}, {__mode = "k"})
function runtime.Remember(object, property)
    local properties = remembered[object]
    if not properties then properties = {}; remembered[object] = properties end
    if properties[property] then return end
    local ok, value = pcall(function() return object[property] end)
    if not ok then return end
    properties[property] = true
    table.insert(runtime.Restore, function() object[property] = value end)
end
function runtime.Set(object, property, value)
    if not runtime.Active then return end
    runtime.Remember(object, property)
    pcall(function() object[property] = value end)
end
function runtime.DecorateVersionLabel(label)
    if not label or not label:IsA("TextLabel") or runtime.VersionLabel==label then return end
    runtime.VersionLabel=label
    local base=label.Text
    local suffix=" | "..runtime.ScriptVersion
    local writing=false
    local function update()
        if writing or not runtime.Active then return end
        local text=label.Text
        if text:sub(-#suffix)==suffix then text=text:sub(1,-#suffix-1) end
        base=text
        if text=="" then return end
        writing=true;label.Text=text..suffix;writing=false
    end
    runtime.Connect(label:GetPropertyChangedSignal("Text"),update)
    table.insert(runtime.Restore,function() label.Text=base end)
    update()
end
function runtime.EnableDebug(remote, player)
    if runtime.DebugRemembered then return end
    -- Read the authoritative setting before changing it; leave it alone if unknown.
    local ok, data = pcall(function()
        return require(game:GetService("ReplicatedStorage").Client.Framework.Services.LocalData):Get()
    end)
    if not ok or not data or not data.Settings or type(data.Settings.Debug) ~= "boolean" then return end
    runtime.DebugRemembered = true
    local original = data.Settings.Debug
    table.insert(runtime.Restore, function() remote:FireServer("SetSetting", "Debug", original) end)
    pcall(function() remote:FireServer("SetSetting", "Debug", true) end)
end
function runtime.Connect(signal, callback)
    local connection = signal:Connect(function(...)
        if runtime.Active then return callback(...) end
    end)
    table.insert(runtime.Connections, connection)
    return connection
end
local ownedTask = setmetatable({}, {__index = realTask})
local function schedule(method, ...)
    if not runtime.Active then return nil end
    local arguments = table.pack(...)
    local delay = method == "delay" and arguments[1] or nil
    local callbackIndex = method == "delay" and 2 or 1
    local callback = arguments[callbackIndex]
    local function run()
        if not runtime.Active then return end
        local thread = coroutine.running()
        runtime.Threads[thread] = true
        local result = table.pack(pcall(callback, table.unpack(arguments, callbackIndex + 1, arguments.n)))
        runtime.Threads[thread] = nil
        if not result[1] then warn("[@qtrzip] Worker: " .. tostring(result[2])) end
    end
    local thread
    if delay then thread = realTask.delay(delay, run) else thread = realTask[method](run) end
    if thread and coroutine.status(thread) ~= "dead" then runtime.Threads[thread] = true end
    return thread
end
for _, method in ipairs({"spawn", "defer", "delay"}) do
    ownedTask[method] = function(...) return schedule(method, ...) end
end
ownedTask.cancel = function(thread)
    runtime.Threads[thread] = nil
    return realTask.cancel(thread)
end
local ownedInstance = setmetatable({new = function(...)
    local object = realInstance.new(...)
    runtime.Instances[object] = true
    return object
end}, {__index = realInstance})
private.task = ownedTask
private.Instance = ownedInstance
function runtime.Unload()
    if not runtime.Active then return end
    private.RdotAfishingStop = true
    private.RdotAfishingConfig = {Enabled = false, Mode = "Off"}
    private.animationHidden = false
    runtime.Active = false
    if runtime.HatchEvents then runtime.HatchEvents:Destroy();runtime.HatchEvents=nil end
    local current = coroutine.running()
    for thread in pairs(runtime.Threads) do
        if thread ~= current then pcall(realTask.cancel, thread) end
    end
    table.clear(runtime.Threads)
    for _, connection in ipairs(runtime.Connections) do pcall(function() connection:Disconnect() end) end
    table.clear(runtime.Connections)
    if runtime.UI then pcall(function() runtime.UI:Destroy() end) end
    for i = #runtime.Restore, 1, -1 do pcall(runtime.Restore[i]) end
    table.clear(runtime.Restore)
    for object in pairs(runtime.Instances) do pcall(function() object:Destroy() end) end
    table.clear(runtime.Instances)
    table.clear(remembered)
    -- Retain the private environment and stop flags for auxiliary callbacks.
    -- Clearing its getgenv would make late callbacks touch another hub's globals.
    private.WindUI = nil; private.Window = nil; private.HubSettings = nil
    runtime.UI = nil; runtime.State = nil; runtime.VersionLabel = nil; runtime.Updater = nil; runtime.HasPendingWebhooks = nil
    if actualGlobals._BGSI_TestHub == runtime then actualGlobals._BGSI_TestHub = nil end
end
