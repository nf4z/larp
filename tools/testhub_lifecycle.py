"""Targeted ownership/restore instrumentation for the pinned feature source."""
import re

def instrument(source):
    for signal in ['Players.LocalPlayer.Idled', 'title.InputBegan', 'title.InputEnded', 'game:GetService("UserInputService").InputChanged']:
        source = source.replace(signal + ':Connect(', 'runtime.Connect(' + signal + ', ')
    for obj, field in [('class','new'), ('class','Add'), ('mod','Play')]:
        source = source.replace(f'{obj}.{field} = ', f'runtime.Remember({obj}, "{field}")\n                    {obj}.{field} = ', 1)
    source = source.replace('pcall(function() obj[prop] = value end)', 'runtime.Set(obj, prop, value)')
    for obj in ['skyAltar', 'shrineUI', 'seasonUI']:
        source = re.sub(rf'{obj}\.Visible = (true|false)', rf'runtime.Set({obj}, "Visible", \1)', source)
    source = re.sub(r'^(\s*)camera\.(CameraType|CFrame) = ([^\n]+)$', r'\1runtime.Set(camera, "\2", \3)', source, flags=re.M)
    source = source.replace('pcall(function() Remote:FireServer("SetSetting", "Debug", true) end)', 'runtime.EnableDebug(Remote, player)')
    a = source.index('local function fpsJMX()')
    b = source.index('-- UI\n', a)
    effects = source[a:b]
    effects = effects.replace('setfpscap(120)', '''if getfpscap then
        local oldCap = getfpscap()
        table.insert(runtime.Restore, function() setfpscap(oldCap) end)
        setfpscap(120)
    end''')
    # Do not destroy camera children or alter hidden/read-restricted properties.
    effects = effects.replace('workspace.CurrentCamera:ClearAllChildren()', 'for _, child in ipairs(workspace.CurrentCamera:GetChildren()) do runtime.Set(child, "Parent", nil) end')
    effects = effects.replace('sethiddenproperty(Lighting, "Technology", "Compatibility")', '-- Preserve the current rendering technology.')
    effects = effects.replace('settings().Rendering.QualityLevel = 1', '-- Preserve the current rendering quality.')
    effects = re.sub(r'^(\s*)(Lighting|v|part)\.([A-Za-z]+) = ([^\n]+)$', r'\1runtime.Set(\2, "\3", \4)', effects, flags=re.M)
    return source[:a] + effects + source[b:]
