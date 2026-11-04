"""Compile and exercise TestHub's real UI adapter with deterministic event mocks."""
from pathlib import Path
import json
import os
import re
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]
LUAU = os.environ.get('LUAU', str(ROOT / '.tools/luau/luau.exe'))
COMPILER = os.environ.get('LUAU_COMPILE', str(ROOT / '.tools/luau/luau-compile.exe'))
for path in ['testHub', 'testhub_src/native-ui.lua', 'testhub_src/mock-roblox.lua']:
    result = subprocess.run([COMPILER, '--null', str(ROOT / path)], capture_output=True, text=True)
    assert result.returncode == 0, result.stderr
print('Standalone script, adapter, and harness compile: PASS')
base = (ROOT / 'testhub_src/afbq-base.lua').read_text(encoding='utf-8')
built = (ROOT / 'testHub').read_text(encoding='utf-8')
marker = '-- Shared egg scanner adapted from'
feature_code = base[base.index(marker):]
feature_code = re.sub(r'(    end\n)    task.wait\(0\.3\)(\n\s*-- // Embedded module:)', r'\1    task.wait()\2', feature_code)
actual = built[built.index(marker):built.rindex('\nend\nsetfenv(start, private)')]
assert actual == feature_code, 'Feature code changed beyond module scheduling'
assert 'Footagesus/WindUI/releases' not in built
assert len(re.findall('-- // Embedded module:', built)) == 17
print('All 17 feature module bodies preserved; no WindUI download: PASS')
mock = (ROOT / 'testhub_src/mock-roblox.lua').read_text(encoding='utf-8')
adapter = (ROOT / 'testhub_src/native-ui.lua').read_text(encoding='utf-8')
code = 'local mock = (function()\n' + mock + '\nend)()\n'
code += 'local fn = assert(loadstring(' + json.dumps(adapter, ensure_ascii=True) + '))\nsetfenv(fn, mock.env)\nlocal ui = fn()\n'
code += r'''
local window = ui:CreateWindow({ToggleKey=mock.Enum.KeyCode.K})
assert(mock.counters.clones > 0, "Use cloned game visuals")
local tab = window:Tab({Title="Eggs"})
tab:Section({Title="Hatching"})
local changes, selected, inputValue = 0, nil, nil
local toggle=tab:Toggle({Title="Auto Hatch",Value=true,Callback=function(value) changes+=1;assert(value==false) end})
assert(toggle.Value and changes==0, "No initialization callback")
toggle.Action.Activated:Fire();assert(changes==1 and toggle.Value==false)
toggle:Lock();toggle.Action.Activated:Fire();assert(changes==1)
toggle:Unlock()
local field=tab:Input({Title="Amount",Value="12",Callback=function(value) inputValue=value end})
field.Action.Text="24";field.Action.FocusLost:Fire();assert(inputValue=="24")
local ran=0
local run=tab:Button({Title="Rescan",Callback=function() ran+=1 end})
run.Action.Activated:Fire();assert(ran==1)
local paragraph=tab:Paragraph({Title="Status",Desc="Ready"})
paragraph:SetTitle("Updated");paragraph:SetDesc("Running")
assert(paragraph.Label.Text=="Updated" and paragraph.Desc.Text=="Running")
local values={};for i=1,1000 do table.insert(values,"Egg "..i) end
local drop=tab:Dropdown({Title="Select Egg",Values=values,Value="Egg 1",Callback=function(value) selected=value end})
drop.Action.Activated:Fire()
assert(#drop.pool==9, "Bounded row pool for 1000 options")
local popup=ui.ScreenGui:FindFirstChild("IconPicker",true)
local pickerSearch=popup:FindFirstChildWhichIsA("TextBox")
pickerSearch.Text="Egg 999"
assert(drop.pool[1].title.Text=="Egg 999")
drop.pool[1].button.Activated:Fire()
assert(selected=="Egg 999" and drop.Value=="Egg 999" and not popup.Visible)
assert(drop.pool==nil, "Release closed row references")
drop:Refresh({"Egg 2","Egg 3"});assert(#drop.Values==2)
drop:Select("Egg 2");assert(selected=="Egg 2")
local potion=tab:Dropdown({Title="Potion",Values={"Lucky 6"},Value="Lucky 6"})
assert(mock.counters.icons>0, "Use native item icon renderer")
local before=mock.counters.cleaned
window:Close();assert(not window.Opened and mock.counters.cleaned>before)
window:Open();assert(window.Opened)
mock.input.InputBegan:Fire({KeyCode=mock.Enum.KeyCode.K},false);assert(not window.Opened)
mock.input._focused=field.Action
mock.input.InputBegan:Fire({KeyCode=mock.Enum.KeyCode.K},false);assert(not window.Opened)
mock.input._focused=nil
mock.input.InputBegan:Fire({KeyCode=mock.Enum.KeyCode.K},true);assert(not window.Opened)
mock.input.InputBegan:Fire({KeyCode=mock.Enum.KeyCode.K},false);assert(window.Opened)
local other=window:Tab({Title="Potions"});other:Select();assert(other.Page.Visible and not tab.Page.Visible)
tab:Select();local search=window.Native:FindFirstChild("Search");search.Text="Rescan"
assert(run.Frame.Visible and not toggle.Frame.Visible)
search.Text="";assert(toggle.Frame.Visible)
mock.workspace.CurrentCamera.ViewportSize=mock.vector(390,844)
assert(window.Native.Size.X.Offset==368 and field.Frame.Size.Y.Offset==126)
assert(ui.ResolveIcon("Luck Tier 2").item.Tier==2)
assert(ui.ResolveIcon("Unknown").fallback=="U")
assert(ui.ResolveIcon("Dog").item.Type=="Pet")
assert(ui.ResolveIcon("Coins").item.Currency=="Coins")
assert(ui.ResolveIcon("Mystery Box").item.Type=="Powerup")
-- Repeated picker opens must keep one popup tree and nine live rows.
for i=1,30 do drop.Action.Activated:Fire();assert(#drop.pool==9);window:Close();window:Open() end
ui:Destroy();assert(ui.ScreenGui.Parent==nil)
mock.input.InputBegan:Fire({KeyCode=mock.Enum.KeyCode.K},false)
-- The live settings template is optional; Intro assets provide a fallback.
mock.playerGui.ScreenGui.Settings:Destroy()
local fallback=assert(loadstring(ADAPTER_SOURCE))
setfenv(fallback,mock.env)
local fallbackUI=fallback()
local fallbackWindow=fallbackUI:CreateWindow({})
fallbackWindow:Tab({Title="Fallback"}):Button({Title="Run"})
fallbackUI:Destroy()
'''
code = code.replace('ADAPTER_SOURCE', json.dumps(adapter, ensure_ascii=True))
# Run the real startup/settings/UI code, excluding gameplay modules, twice.
prefix = built[:built.index(marker)]
suffix = built[built.rindex('\nend\nsetfenv(start, private)'):]
startup = prefix + suffix
code += '\nlocal startupSource = ' + json.dumps(startup, ensure_ascii=True) + '\n'
code += r'''
local liveGlobals={Window={original=true},HubSettings={original=true}}
local writes={}
mock.env.getgenv=function() return liveGlobals end
mock.env.readfile=function(name)
    if name=="renoa_hub_settings.json" then return "legacy-json" end
    error("missing")
end
mock.env.writefile=function(name,value) writes[name]=value end
local originalService=mock.env.game.GetService
mock.env.game.IsLoaded=function() return true end
mock.env.game.GetService=function(self,name)
    if name=="HttpService" then return {
        JSONDecode=function(_,value) assert(value=="legacy-json");return {auto={presentRain=true}} end,
        JSONEncode=function(_,value) assert(value.auto.presentRain);return "encoded-test-settings" end,
    } end
    if name=="VirtualUser" then return {} end
    return originalService(self,name)
end
local startupFn=assert(loadstring(startupSource));setfenv(startupFn,mock.env)
local firstWindow=startupFn()
assert(firstWindow and liveGlobals._BGSI_TestHub.UI)
assert(liveGlobals.Window.original and liveGlobals.HubSettings.original)
local created=mock.counters.created
assert(startupFn()==firstWindow and mock.counters.created==created, "Rerun should reopen, not stack instances")
-- saveHubSettings was defined in the private environment, never in afbq's globals.
assert(mock.env.saveHubSettings==nil and liveGlobals.saveHubSettings==nil)
local rootEnv=getfenv(liveGlobals._BGSI_TestHub.UI.CreateWindow)
rootEnv.saveHubSettings()
assert(writes["testhub_settings.json"]=="encoded-test-settings" and writes["renoa_hub_settings.json"]==nil)
liveGlobals._BGSI_TestHub.UI:Destroy()
'''
with tempfile.TemporaryDirectory() as directory:
    path = Path(directory) / 'test.lua'
    path.write_text(code, encoding='utf-8')
    result = subprocess.run([LUAU, str(path)], capture_output=True, text=True)
    if result.returncode:
        match = re.search(r'test\.lua:(\d+):', result.stderr)
        if match:
            line = int(match[1])
            print('\n'.join(f'{i+1}: {text}' for i, text in enumerate(code.splitlines()) if abs(i+1-line)<3))
    assert result.returncode == 0, result.stdout + '\n' + result.stderr
print('Native clones, callbacks, locks, icons, 1000-option search, K/text focus, mobile layout, popup reuse, cleanup: PASS')
print('Real startup: fallback templates, private globals, legacy settings read, isolated writes, rerun guard: PASS')
