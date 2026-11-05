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
feature_code = feature_code.replace('Afbq Hub', '@qtrzip')
feature_code = re.sub(r'(    end\n)    task.wait\(0\.3\)(\n\s*-- // Embedded module:)', r'\1    task.wait()\2', feature_code)
feature_code = re.sub(r'else warn\(("\[Hub\] Failed: [^\n]+)\) end', r'else warn(\1); WindUI:ModuleFailed(tostring(err)) end', feature_code)
feature_code = feature_code.replace('print("[Hub] All repository modules initialized.")', 'WindUI:ModulesReady()\n    print("[Hub] All repository modules initialized.")')
actual = built[built.index(marker):built.rindex('\nend\nlocal ok, err = pcall(start)')]
assert actual == feature_code, 'Feature code changed beyond module scheduling'
assert 'Footagesus/WindUI/releases' not in built
assert len(re.findall('-- // Embedded module:', built)) == 17
print('All 17 feature module bodies preserved; no WindUI download: PASS')
mock = (ROOT / 'testhub_src/mock-roblox.lua').read_text(encoding='utf-8')
adapter = (ROOT / 'testhub_src/native-ui.lua').read_text(encoding='utf-8')
code = 'local mock = (function()\n' + mock + '\nend)()\n'
bad_adapter = adapter.replace('local parentZ = parent:IsA("GuiObject") and parent.ZIndex or 1', 'local parentZ = parent.ZIndex')
assert bad_adapter != adapter
code += 'local broken = assert(loadstring(' + json.dumps(bad_adapter, ensure_ascii=True) + '))\nsetfenv(broken,mock.env)\n'
code += 'local ok,err=pcall(broken);assert(not ok and tostring(err):find("ZIndex is not a valid member of ScreenGui",1,true),"Reproduce the reported startup failure")\n'
code += 'local orphan=mock.playerGui:FindFirstChild("@qtrzip");if orphan then orphan:Destroy() end\n'
code += 'local fn = assert(loadstring(' + json.dumps(adapter, ensure_ascii=True) + '))\nsetfenv(fn, mock.env)\nlocal ui = fn()\n'
code += r'''
local window = ui:CreateWindow({ToggleKey=mock.Enum.KeyCode.K})
assert(math.abs(window.Width-600)<1 and math.abs(window.Height-420)<1, "Wider default")
assert(ui.ScreenGui.Name=="@qtrzip")
assert(ui.ScreenGui.QtrzipHolder.BackgroundTransparency==1 and not ui.ScreenGui.QtrzipHolder.Active)
assert(not ui.PickerGui.Overlay.Visible, "Do not leave an overlay over the controls")
assert(ui.PickerGui.DisplayOrder>ui.ScreenGui.DisplayOrder, "Dropdowns render in a separate higher layer")
assert(mock.playerGui.ScreenGui.Inventory.BackgroundTransparency==0.45, "Do not alter the game's original backdrop")
assert(window.Native.Interactable and not window.Native.Active)
assert(mock.counters.clones > 0, "Use cloned game visuals")
assert(window.Native.BackgroundColor3.nativeSettingsColor)
assert(window.Native:FindFirstChild("Background").Image=="native-settings-art")
assert(window.Native.Main.Background.Image=="native-settings-content", "Keep the Settings light content panel")
assert(#window.Tabs==16, "Native navigation exists before feature worker startup")
local tab = window:Tab({Title="Eggs"})
tab:Select()
local section=tab:Section({Title="Hatching"})
assert(section.Frame:FindFirstChild("Items") and section.Frame.Label.Text=="Hatching")
local changes, selected, inputValue = 0, nil, nil
local toggle=tab:Toggle({Title="Auto Hatch",Value=true,Callback=function(value) changes+=1;assert(value==false) end})
assert(toggle.Frame.Parent==section.Frame.Items and toggle.Frame.Size.Y.Offset==50)
assert(toggle.ActionHost.Size.X.Offset==80, "Use Settings toggle width")
assert(toggle.Frame.BackgroundTransparency==0.75, "Keep native row visuals")
assert(toggle.Action:FindFirstChild("Blob"), "Use the native toggle")
assert(toggle.Value and changes==0, "No initialization callback")
toggle.Action.Activated:Fire();assert(changes==1 and toggle.Value==false)
toggle:Lock();toggle.Action.Activated:Fire();assert(changes==1)
toggle:Unlock()
local field=tab:Input({Title="Amount",Value="12",Callback=function(value) inputValue=value end})
assert(field.Action:TypeText("24"), "Native keybind textbox must become editable")
field.Action.FocusLost:Fire();assert(inputValue=="24")
assert(field.Action.TextEditable and field.Action.TextTransparency==0 and not field.Action.Label.Visible)
assert(field.Action.Parent.Background.ZIndex<field.Action.ZIndex, "The native artwork must sit behind the editable box")
local ran=0
local run=tab:Button({Title="Rescan",Callback=function() ran+=1 end})
run.Action.Activated:Fire();assert(ran==1)
local paragraph=tab:Paragraph({Title="Status",Desc="Ready"})
paragraph:SetTitle("Updated");paragraph:SetDesc("Running")
assert(paragraph.Label.Text=="Updated" and paragraph.Desc.Text=="Running")
local values={};for i=1,1000 do table.insert(values,"Egg "..i) end
local drop=tab:Dropdown({Title="Select Egg",Values=values,Value="Egg 1",Callback=function(value) selected=value end})
assert(drop.ActionHost.Size.X.Offset==250 and drop.Frame.Size.Y.Offset==50, "Match Settings dropdown sizing")
local plain=tab:Dropdown({Title="Target Tile",Values={"Chance","Mystery"},Value="Chance"})
assert(not plain.Icon.Visible and plain.Action.Label.TextScaled==false, "No fake letter icons or inflated labels on plain choices")
plain.Action.Activated:Fire()
assert(plain.NativePicker and plain.pool==nil, "Plain choices use the native Dropdown component")
plain.NativePicker:SelectItem(2)
assert(plain.Value=="Mystery" and plain.NativePicker==nil)
assert(tab.NavigationButton.Label.TextScaled==false and tab.NavigationButton.Label.AnchorPoint.X==0)
drop.Action.Activated:Fire()
assert(#drop.NativePicker._frames==1000 and drop.pool==nil, "Use the native component even for item lists")
local popup=drop.NativePicker._floater
assert(popup:FindFirstChildOfClass("UIScale").Scale==window.Scale.Scale)
assert(popup.Position.Y.Offset>=8, "Keep the picker inside the viewport")
assert(popup:FindFirstChildWhichIsA("TextBox",true)==nil, "No custom picker search/title/close UI")
popup.Items.CanvasPosition=mock.vector(0,998*drop.NativeStride)
assert(drop.NativeIcons[999] and drop.NativeIcons[999].Visible)
drop.NativePicker:SelectItem(999)
assert(selected=="Egg 999" and drop.Value=="Egg 999" and not popup.Visible)
assert(drop.NativePicker==nil and drop.NativeIcons==nil, "Release native icon references on close")
drop:Refresh({"Egg 2","Egg 3"});assert(#drop.Values==2)
drop:Select("Egg 2");assert(selected=="Egg 2")
local potion=tab:Dropdown({Title="Potion",Values={"Lucky 6"},Value="Lucky 6"})
assert(mock.counters.icons>0, "Use native item icon renderer")
assert((mock.counters.nativeCards or 0)==0, "Icons must not include animated rarity card backgrounds")
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
assert(tab.NavigationButton:Click(), "Cloned tabs must accept clicks despite disabled source controls")
assert(tab.Page.Visible and not other.Page.Visible)
-- Direct pointer routing must still select tabs if decorative children eat Activated.
local sidebar=window.Native:FindFirstChild("QtrzipTabs",true) or window.Native:FindFirstChild("TestHubTabs",true)
sidebar.AbsolutePosition=mock.vector(20,100);sidebar.AbsoluteSize=mock.vector(120,300)
window.DragHandle.AbsolutePosition=mock.vector(180,20);window.DragHandle.AbsoluteSize=mock.vector(400,40)
window.ResizeGrip.AbsolutePosition=mock.vector(580,400);window.ResizeGrip.AbsoluteSize=mock.vector(20,20)
for _,t in ipairs(window.Tabs) do t.NavigationButton.AbsolutePosition=mock.vector(-1000,-1000) end
other.NavigationButton.AbsolutePosition=mock.vector(30,110);other.NavigationButton.AbsoluteSize=mock.vector(100,30)
mock.input.InputBegan:Fire({UserInputType=mock.Enum.UserInputType.MouseButton1,Position=mock.vector(40,120)},true)
assert(other.Page.Visible and not tab.Page.Visible, "Global pointer routing selects the intended tab")
tab:Select();local search=window.Native.Tray.Search.Search.Bar.TextBox;search.Text="Rescan"
assert(run.Frame.Visible and not toggle.Frame.Visible)
search.Text="";assert(toggle.Frame.Visible)
local mouse={UserInputType=mock.Enum.UserInputType.MouseButton1,Position=mock.vector(10,10)}
window.DragHandle.InputBegan:Fire(mouse)
mock.input.InputChanged:Fire({UserInputType=mock.Enum.UserInputType.MouseMovement,Position=mock.vector(50,35)})
mock.input.InputEnded:Fire(mouse)
assert(window.Native.Position.X.Offset>0, "Drag handle moves the window")
local originalScale=window.Scale.Scale
window.ResizeGrip.InputBegan:Fire(mouse)
mock.input.InputChanged:Fire({UserInputType=mock.Enum.UserInputType.MouseMovement,Position=mock.vector(70,50)})
mock.input.InputEnded:Fire(mouse)
assert(window.Width>600 and window.Height>420, "Resize grip changes both dimensions")
assert(window.Scale.Scale==originalScale and window.Native.Size.X.Offset>760, "Resizing adds layout space without magnifying native controls")
-- Drag via global input, without firing the widget's InputBegan event.
local beforeDragX=window.Native.Position.X.Offset
local headerMouse={UserInputType=mock.Enum.UserInputType.MouseButton1,Position=mock.vector(200,30)}
mock.input.InputBegan:Fire(headerMouse,true)
mock.input.InputChanged:Fire({UserInputType=mock.Enum.UserInputType.MouseMovement,Position=mock.vector(240,30)})
mock.input.InputEnded:Fire(headerMouse)
assert(window.Native.Position.X.Offset>beforeDragX, "Header hit region drags even if widget input is swallowed")
mock.workspace.CurrentCamera.ViewportSize=mock.vector(390,844)
assert(window.Width<=366 and window.Native.Size.X.Offset==760, "Fit the native layout to the viewport")
assert(ui.ResolveIcon("Luck Tier 2").item.Tier==2)
assert(ui.ResolveIcon("Unknown").fallback=="U")
assert(ui.ResolveIcon("Dog").item.Type=="Pet")
assert(ui.ResolveIcon("Coins").item.Currency=="Coins")
assert(ui.ResolveIcon("Mystery Box").item.Type=="Powerup")
-- Repeated picker opens must keep one popup tree and nine live rows.
for i=1,30 do drop.Action.Activated:Fire();assert(#drop.NativePicker._frames==2);window:Close();window:Open() end
ui:Destroy();assert(ui.ScreenGui.Parent==nil)
mock.input.InputBegan:Fire({KeyCode=mock.Enum.KeyCode.K},false)
-- Missing native templates must fail clearly instead of fabricating a custom shell.
local nativeInventory=mock.playerGui.ScreenGui.Inventory
nativeInventory.Parent=nil
local fallback=assert(loadstring(ADAPTER_SOURCE))
setfenv(fallback,mock.env)
local ok,err=pcall(fallback)
assert(not ok and tostring(err):find("Inventory",1,true))
nativeInventory.Parent=mock.playerGui.ScreenGui
'''
code = code.replace('ADAPTER_SOURCE', json.dumps(adapter, ensure_ascii=True))
# Run the real startup/settings/UI code, excluding gameplay modules, twice.
prefix = built[:built.index(marker)]
suffix = built[built.rindex('\nend\nlocal ok, err = pcall(start)'):]
info_start = built.index('    -- // Embedded module: Info.Lua')
info_end = built.index('    -- // Embedded module: ActivityInfo.Lua')
worker = 'task.spawn(function()\n' + built[info_start:info_end] + '\nWindUI:ModulesReady()\nend)\n'
startup = prefix + worker + suffix
code += '\nlocal startupSource = ' + json.dumps(startup, ensure_ascii=False) + '\n'
code += r'''
local liveGlobals={Window={original=true},HubSettings={original=true}}
local writes={}
local reads={}
mock.env.getgenv=function() return liveGlobals end
mock.env.readfile=function(name)
    table.insert(reads,name)
    assert(name=="qtrzip_settings.json", "Never read afbq or earlier TestHub settings")
    error("missing")
end
mock.env.writefile=function(name,value) writes[name]=value end
local originalService=mock.env.game.GetService
mock.env.game.IsLoaded=function() return true end
mock.env.game.GetService=function(self,name)
    if name=="HttpService" then return {
        JSONDecode=function(_,value) assert(value=="qtrzip-json");return {auto={presentRain=true}} end,
        JSONEncode=function(_,value) assert(type(value)=="table");return "encoded-test-settings" end,
    } end
    if name=="VirtualUser" then return {} end
    if name=="MarketplaceService" then return {} end
    return originalService(self,name)
end
local jobs={}
-- Simulate an executor starting spawned threads with the ambient environment.
mock.env.task={
    spawn=function(fn,...)
        setfenv(fn,mock.env)
        local co=coroutine.create(fn)
        local ok,err=coroutine.resume(co,...);assert(ok,tostring(err))
        if coroutine.status(co)~="dead" then table.insert(jobs,co) end
    end,
    wait=function() coroutine.yield() end,
}
local startupFn=assert(loadstring(startupSource));setfenv(startupFn,mock.env)
local firstWindow=startupFn()
assert(firstWindow and liveGlobals._BGSI_TestHub.UI)
assert(next(liveGlobals._BGSI_TestHub.State.HubSettings)==nil, "Start with fresh settings")
for _=1,8 do
    local co=table.remove(jobs,1)
    if co then
        local ok,err=coroutine.resume(co);assert(ok,tostring(err))
        if coroutine.status(co)~="dead" then table.insert(jobs,co) end
    end
end
assert(#firstWindow.TabsByTitle.Info.Controls>=8, "Real Info feature module must populate the native panel")
assert(#liveGlobals._BGSI_TestHub.UI.ModuleErrors==0)
assert(liveGlobals.Window.original and liveGlobals.HubSettings.original)
local created=mock.counters.created
assert(startupFn()==firstWindow and mock.counters.created==created, "Rerun should reopen, not stack instances")
-- saveHubSettings was defined in the private environment, never in afbq's globals.
assert(mock.env.saveHubSettings==nil and liveGlobals.saveHubSettings==nil)
liveGlobals._BGSI_TestHub.State.saveHubSettings()
assert(writes["qtrzip_settings.json"]=="encoded-test-settings" and writes["renoa_hub_settings.json"]==nil and writes["testhub_settings.json"]==nil)
for _,name in ipairs(reads) do assert(name=="qtrzip_settings.json") end
liveGlobals._BGSI_TestHub.UI:Destroy()
mock.env.readfile=function(name)
    assert(name=="qtrzip_settings.json")
    return "qtrzip-json"
end
assert(startupFn())
assert(liveGlobals._BGSI_TestHub.State.HubSettings.auto.presentRain==true, "Reload only the new hub's own config")
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
            print('\n'.join(f'{i+1}: {text[:300]}' for i, text in enumerate(code.splitlines()) if abs(i+1-line)<3))
    assert result.returncode == 0, result.stdout + '\n' + result.stderr
print('Settings shell/categories, native plain dropdown, control sizing, unscaled labels, input/drag/resize, icons: PASS')
print('Fresh qtrzip config, no legacy reads/writes, own-config reload, branding, no cloned backdrop, real Info startup: PASS')
