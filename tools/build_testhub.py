"""Build a standalone native-UI testHub from a pinned afbq snapshot."""
from pathlib import Path
import hashlib
import json
import re
from testhub_lifecycle import instrument
from testhub_features import enhance
from testhub_hatch import port_hatch
from port_testhub_hatch import generate

ROOT = Path(__file__).resolve().parents[1]
BASE = ROOT / 'testhub_src/afbq-base.lua'
SCRIPT_VERSION = 'v111'
RUNTIME_REVISION = 26
generate()
source = BASE.read_text(encoding='utf-8')
adapter = (ROOT / 'testhub_src/native-ui.lua').read_text(encoding='utf-8')
paths_file = ROOT / 'icon-cache/paths.json'
if paths_file.exists():
    paths = json.loads(paths_file.read_text(encoding='utf-8'))
    entries = ', '.join('[' + json.dumps(k) + '] = ' + json.dumps(v) for k,v in paths.items())
    adapter = adapter.replace('local ICON_CACHE_PATHS = {}', 'local ICON_CACHE_PATHS = {' + entries + '}')
source = source.replace('function saveHubSettings()', 'local function saveHubSettings()', 1)
source = source.replace('function loadHubSettings()', 'private.saveHubSettings = saveHubSettings\nfunction loadHubSettings()', 1)

# Keep all 17 embedded feature modules and their callbacks intact.
library_start = source.index('-- // WindUI external dependency')
window_start = source.index('-- // Complete Window Base', library_start)
source = source[:library_start] + 'local WindUI = (function()\n' + adapter + '\nend)()\n\n' + source[window_start:]
source = source.replace('Afbq Hub', '@qtrzip').replace('Folder = "AfbqHub"', 'Folder = "QtrzipHub"')
source = source.replace('print("[Hub] Loading WindUI...")', 'print("[@qtrzip] Loading native game UI...")')
source = source.replace('local settingsFile = "renoa_hub_settings.json"', 'local settingsFile = "qtrzip_settings.json"')
a = source.index('function loadHubSettings()')
b = source.index('\nloadHubSettings()', a)
source = source[:a] + '''local function loadHubSettings()
    local handoff=actualGlobals._BGSI_UpdateSettings
    if type(handoff)=="table" and handoff.revision==runtime.Revision and type(handoff.settings)=="table" then
        getgenv().HubSettings=handoff.settings
        actualGlobals._BGSI_UpdateSettings=nil
        return
    end
    local success, saved = pcall(function() return readfile(settingsFile) end)
    local decoded, settings
    if success and type(saved) == "string" then
        decoded, settings = pcall(function() return HttpService:JSONDecode(saved) end)
    end
    getgenv().HubSettings = decoded and type(settings) == "table" and settings or {}
end''' + source[b:]
# These waits separate modules; leave all gameplay timing unchanged.
source, shortened = re.subn(r'(    end\n)    task.wait\(0\.3\)(\n\s*-- // Embedded module:)', r'\1    task.wait()\2', source)
source = re.sub(r'else warn\(("\[Hub\] Failed: [^\n]+)\) end', r'else warn(\1); WindUI:ModuleFailed(tostring(err)) end', source)
source = source.replace('print("[Hub] All repository modules initialized.")', 'WindUI:ModulesReady()\n    print("[Hub] All repository modules initialized.")')

source = port_hatch(enhance(source))
source = instrument(source)

header = '''local actualGlobals = (getgenv and getgenv()) or _G
local prior = rawget(actualGlobals, "_BGSI_TestHub")
if prior and prior.Revision == __RUNTIME_REVISION__ and prior.UI and prior.UI.Window and prior.UI.ScreenGui.Parent then
    prior.UI.Window:Open()
    return prior.UI.Window
end
if prior and prior.Starting and prior.Revision == __RUNTIME_REVISION__ then
    warn("[TestHub] Already starting; please wait")
    return
end
if not game:IsLoaded() then game.Loaded:Wait() end
local sharedEnvironment = getfenv()
local private = setmetatable({}, {__index = sharedEnvironment})
private._G = private
private.getgenv = function() return private end
-- Auxiliary feature scripts inherit the same private runtime.
local originalLoadstring = loadstring
private.CompileSharedLibrary = function(source, name)
    local chunk,reason=originalLoadstring(source,name)
    if chunk then setfenv(chunk,sharedEnvironment) end
    return chunk,reason
end
private.LoadSharedLibrary = function(source,name)
    return assert(private.CompileSharedLibrary(source,name))()
end
private.loadstring = function(text, name)
    local chunk, err = originalLoadstring(text, name)
    if chunk then setfenv(chunk, private) end
    return chunk, err
end
local repairTopbar = (function()
''' + (ROOT / 'testhub_src/topbar-recovery.lua').read_text(encoding='utf-8') + '''
end)()
pcall(repairTopbar, actualGlobals._BGSI_TopbarPlus)
if prior and prior.Unload then prior.Unload()
elseif prior and prior.UI then pcall(function() prior.UI:Destroy() end) end
local runtime = {Starting = true, Revision = __RUNTIME_REVISION__, ScriptVersion = "__SCRIPT_VERSION__", State = private}
actualGlobals._BGSI_TestHub = runtime
''' + (ROOT / 'testhub_src/runtime.lua').read_text(encoding='utf-8') + '''
local function start()
local task, Instance = ownedTask, ownedInstance
local function onTestHubUnload() runtime.Unload() end
local function onTestHubHatchDedupState()
    if type(actualGlobals._BGSI_HatchEventDedup)~="table" then actualGlobals._BGSI_HatchEventDedup={} end
    return actualGlobals._BGSI_HatchEventDedup
end
local function onTestHubGetTopbar()
    if actualGlobals._BGSI_TopbarPlus then return actualGlobals._BGSI_TopbarPlus end
    local storage = game:GetService("ReplicatedStorage")
    local reference = storage:FindFirstChild("TopbarPlusReference")
    local module
    if reference and reference.Value then
        local ok, result = pcall(require, reference.Value)
        if ok and type(result) == "table" and type(result.new) == "function" then module = result end
    end
    if not module then
        local source = game:HttpGet("https://raw.githubusercontent.com/nf4z/larp/main/vendor/TopbarPlus/bundle.lua", true)
        module = private.LoadSharedLibrary(source, "@TopbarPlus")
    end
    assert(type(module) == "table" and type(module.new) == "function", "Invalid TopbarPlus module")
    actualGlobals._BGSI_TopbarPlus = module
    return module
end
local function onTestHubDecorateVersion(screen)
    local label=screen:FindFirstChild("VersionLabel")
    if label then runtime.DecorateVersionLabel(label)
    else runtime.Connect(screen.ChildAdded,function(child)
        if child.Name=="VersionLabel" then runtime.DecorateVersionLabel(child) end
    end) end
end
local function onTestHubSetupUpdates(tab)
    if runtime.Updater then return end
    if type(private.HubSettings.updates)~="table" then private.HubSettings.updates={} end
    local install=(function()
''' + (ROOT / 'testhub_src/auto-update.lua').read_text(encoding='utf-8') + '''
    end)()
    local prefix="https://raw.githubusercontent.com/nf4z/larp/main/"
    runtime.Updater=install({Tab=tab,Settings=private.HubSettings.updates,Version=runtime.ScriptVersion,Revision=runtime.Revision,
        CurrentPath="releases/bgsiscript/"..runtime.ScriptVersion.."-r"..runtime.Revision..".lua",
        Active=function() return runtime.Active and actualGlobals._BGSI_TestHub==runtime and not runtime.UpdateQueued end,
        Save=private.saveHubSettings,Compile=private.CompileSharedLibrary,
        Busy=function() return runtime.HasPendingWebhooks and runtime.HasPendingWebhooks() end,
        Manifest=function()
            local response=game:HttpGet(prefix.."bgsiscript-version.json?check="..os.time(),true)
            return game:GetService("HttpService"):JSONDecode(response)
        end,
        Fetch=function(path) return game:HttpGet(prefix..path,true) end,
        CanApply=function(revision,manual)
            local failure=actualGlobals._BGSI_AutoUpdateFailure
            return manual or not failure or failure.revision~=revision or os.clock()>=failure.untilTime
        end,
        Queue=function(chunk,rollback,revision)
            if not runtime.Active or runtime.UpdateQueued or actualGlobals._BGSI_TestHub~=runtime then return false end
            runtime.UpdateQueued=true
            local function copy(value,seen)
                if type(value)~="table" then return value end
                seen=seen or {};if seen[value] then return seen[value] end
                local result={};seen[value]=result
                for key,item in pairs(value) do result[key]=copy(item,seen) end
                return result
            end
            local savedSettings=copy(private.HubSettings)
            local function handoff(target)
                actualGlobals._BGSI_UpdateSettings={revision=target,settings=copy(savedSettings)}
            end
            local oldWindow=runtime.UI and runtime.UI.Window
            local opened=not oldWindow or oldWindow.Opened
            local position=oldWindow and oldWindow.Native.Position
            local selected
            for _,tab in ipairs(oldWindow and oldWindow.Tabs or {}) do if tab.Page.Visible then selected=tab.Title end end
            -- Use the original scheduler so unloading owned workers cannot cancel the replacement.
            realTask.defer(function()
                if not runtime.Active or actualGlobals._BGSI_TestHub~=runtime then return end
                handoff(revision)
                local good,reason=pcall(chunk)
                actualGlobals._BGSI_UpdateSettings=nil
                local started=actualGlobals._BGSI_TestHub
                if good and (not started or started==runtime or started.Revision~=revision or not started.Active or not started.UI or not started.UI.Window) then
                    good=false;reason="The new release did not initialize its window"
                end
                if not good then
                    warn("[@qtrzip] Update failed, restoring previous release: "..tostring(reason))
                    local failed=actualGlobals._BGSI_TestHub
                    if failed and failed~=runtime and failed.Unload then pcall(failed.Unload) end
                    actualGlobals._BGSI_AutoUpdateFailure={revision=revision,untilTime=os.clock()+600}
                    runtime.UpdateQueued=false
                    handoff(runtime.Revision)
                    local restored,restoreError=pcall(rollback)
                    actualGlobals._BGSI_UpdateSettings=nil
                    if not restored then warn("[@qtrzip] Restore failed: "..tostring(restoreError));return end
                else actualGlobals._BGSI_AutoUpdateFailure=nil end
                local current=actualGlobals._BGSI_TestHub
                local window=current and current.UI and current.UI.Window
                if window then
                    if position then window.Native.Position=position end
                    if selected and window.TabsByTitle[selected] then window.TabsByTitle[selected]:Select() end
                    if not opened then window:Close() end
                end
            end)
            return true
        end,
    })
end
local function onTestHubSetupConfigs(tab)
    if runtime.ConfigDiscovery then return end
    local install=(function()
''' + (ROOT / 'testhub_src/config-discovery.lua').read_text(encoding='utf-8') + '''
    end)()
    runtime.ConfigDiscovery=install({Tab=tab,UserId=game:GetService("Players").LocalPlayer.UserId,
        List=listfiles,Read=readfile,IsFile=isfile,
        Decode=function(text) return game:GetService("HttpService"):JSONDecode(text) end,
    })
end
local function onTestHubUiCreated(ui) runtime.UI = ui; private.WindUI = ui end
-- Lexical bindings survive executors whose task threads reset their environment.
local function getgenv() return private end
local loadstring = private.loadstring
'''
footer = '''
end
local ok, err = pcall(start)
runtime.Starting = false
runtime.UI = rawget(private, "WindUI")
if not ok then
    if runtime.UI then
        if type(runtime.UI.Destroy) == "function" then runtime.UI:Destroy()
        elseif runtime.UI.ScreenGui then
            runtime.UI.ScreenGui:Destroy()
            if runtime.UI.PickerGui then runtime.UI.PickerGui:Destroy() end
        end
    end
    runtime.Unload()
    error("[TestHub] Startup failed: " .. tostring(err), 0)
end
return runtime.UI and runtime.UI.Window
'''
bundle_manifest = ROOT/'vendor/TopbarPlus/bundle-path.json'
if bundle_manifest.exists():
    header=header.replace('vendor/TopbarPlus/bundle.lua',json.loads(bundle_manifest.read_text(encoding='utf-8'))['path'])
header=header.replace('__SCRIPT_VERSION__',SCRIPT_VERSION).replace('__RUNTIME_REVISION__',str(RUNTIME_REVISION))
result = header + source + footer
(ROOT / 'bgsiscript').write_text(result, encoding='utf-8', newline='\n')
release_path=f'releases/bgsiscript/{SCRIPT_VERSION}-r{RUNTIME_REVISION}.lua'
(ROOT/release_path).parent.mkdir(parents=True,exist_ok=True)
(ROOT/release_path).write_text(result,encoding='utf-8',newline='\n')
manifest={'schema':1,'version':SCRIPT_VERSION,'revision':RUNTIME_REVISION,'path':release_path,'sha256':hashlib.sha256(result.encode()).hexdigest()}
(ROOT/'bgsiscript-version.json').write_text(json.dumps(manifest,indent=2)+'\n',encoding='utf-8',newline='\n')

print(json.dumps({'bytes': len(result.encode()), 'featureModules': len(re.findall(r'-- // Embedded module:', source)),
                  'shortenedModuleWaits': shortened, 'baseSHA256': hashlib.sha256(BASE.read_bytes()).hexdigest()}))
