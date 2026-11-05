"""Build a standalone native-UI testHub from a pinned afbq snapshot."""
from pathlib import Path
import hashlib
import json
import re
from testhub_lifecycle import instrument
from testhub_features import enhance

ROOT = Path(__file__).resolve().parents[1]
BASE = ROOT / 'testhub_src/afbq-base.lua'
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

source = enhance(source)
source = instrument(source)

header = '''-- TestHub: afbq features with BGSI-native visuals and icon pickers.
-- Generated with tools/build_testhub.py. Press K to open/close.
local actualGlobals = (getgenv and getgenv()) or _G
local prior = rawget(actualGlobals, "_BGSI_TestHub")
if prior and prior.Revision == 14 and prior.UI and prior.UI.Window and prior.UI.ScreenGui.Parent then
    prior.UI.Window:Open()
    return prior.UI.Window
end
if prior and prior.Starting and prior.Revision == 14 then
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
private.LoadSharedLibrary = function(source, name)
    local chunk = assert(originalLoadstring(source, name))
    setfenv(chunk, sharedEnvironment)
    return chunk()
end
private.loadstring = function(text, name)
    local chunk, err = originalLoadstring(text, name)
    if chunk then setfenv(chunk, private) end
    return chunk, err
end
if prior and prior.Unload then prior.Unload()
elseif prior and prior.UI then pcall(function() prior.UI:Destroy() end) end
local runtime = {Starting = true, Revision = 14, State = private}
actualGlobals._BGSI_TestHub = runtime
''' + (ROOT / 'testhub_src/runtime.lua').read_text(encoding='utf-8') + '''
local function start()
local task, Instance = ownedTask, ownedInstance
local function onTestHubUnload() runtime.Unload() end
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
result = header + source + footer
(ROOT / 'bgsiscript').write_text(result, encoding='utf-8', newline='\n')
print(json.dumps({'bytes': len(result.encode()), 'featureModules': len(re.findall(r'-- // Embedded module:', source)),
                  'shortenedModuleWaits': shortened, 'baseSHA256': hashlib.sha256(BASE.read_bytes()).hexdigest()}))
