"""Compile official TopbarPlus and verify the generated require graph and unchanged attribution."""
from pathlib import Path
import json,re,subprocess,tempfile
ROOT=Path(__file__).resolve().parents[1]
bundle=(ROOT/'vendor/TopbarPlus/bundle.lua').read_text(encoding='utf-8')
r=subprocess.run([str(ROOT/'.tools/luau/luau-compile.exe'),'--null',str(ROOT/'vendor/TopbarPlus/bundle.lua')],text=True,capture_output=True)
assert r.returncode==0,r.stderr
attribute=(ROOT/'vendor/TopbarPlus/src/Attribute.lua').read_text(encoding='utf-8')
assert attribute in bundle, 'Keep upstream Attribute unchanged'
assert 'function Reference.addToReplicatedStorage() return false end' in bundle
matches=list(re.finditer(r'^factories\[nodes\["([^"]*)"\]\] = function\(script, require\)$',bundle,re.M))
assert len(matches)==21
# Exercise the real generated loader independently of Roblox rendering/services.
fixture=bundle[:matches[0].start()]
for match in matches:
    name=match.group(1)
    body='return {name=script.Name,parent=script.Parent and script.Parent.Name}'
    if name=='':body='return {name=script.Name,theme=require(script.Features.Themes),widget=require(script.Elements.Widget),again=require(script.Elements.Widget),attr=require(script.Attribute)}'
    elif name=='Features/Themes':body='return {default=require(script.Default),parent=script.Parent.Name}'
    fixture+=match.group(0)+'\n'+body+'\nend\n'
fixture+='return bundledRequire(nodes[""])\n'
mock=(ROOT/'testhub_src/mock-roblox.lua').read_text(encoding='utf-8')
code='local mock=(function()\n'+mock+'\nend)()\n'
code+='local chunk=assert(loadstring('+json.dumps(fixture)+'));setfenv(chunk,mock.env);local result=chunk()\n'
code+='assert(result.name=="BgsiscriptTopbarPlus" and result.theme.default.name=="Default")\n'
code+='assert(result.widget==result.again and result.widget.parent=="Elements" and result.theme.parent=="Features")\n'
code+='assert(result.attr.name=="Attribute")\n'
# Exercise the real Janitor implementation, not a stub: missing clean caused Themes.set to abort.
assert 'in next, table.clone(Janitor.__index) do' in bundle
assert '(tonumber(widget:GetAttribute("MinimumWidth")) or 44)' in bundle
janitor=(ROOT/'vendor/TopbarPlus/src/Packages/Janitor.lua').read_text(encoding='utf-8')
janitor=janitor.replace('in next, Janitor.__index do','in next, table.clone(Janitor.__index) do')
code += 'local game={GetService=function() return {Heartbeat={}} end}\nlocal Janitor=(function()\n'+janitor+'\nend)()\n'
code += '''local j=Janitor.new();local cleaned=0
for _,name in ipairs({"add","clean","cleanup","destroy","get","remove","linkToInstance"}) do assert(type(j[name])=="function",name) end
j:add(function() cleaned+=1 end);j:clean();assert(cleaned==1)
j:add(function() cleaned+=1 end);j:destroy();assert(cleaned==2)
'''
recovery=(ROOT/'testhub_src/topbar-recovery.lua').read_text(encoding='utf-8')
code+='local recover=(function()\n'+recovery+'\nend)()\n'
code+='''local methods={Cleanup=function(self) self.cleaned=true end,Clean=function(self) self.cleaned=true end}
local resource=setmetatable({}, {__index=methods})
local widget={attributes={},GetAttribute=function(self,key) return self.attributes[key] end}
local orphan={iconModule={Name="BgsiscriptTopbarPlus"},themesJanitor=resource,janitor=resource,widget=widget}
function orphan:setTheme(theme) self.themesJanitor:clean();self.widget.attributes.MinimumWidth=44 end
function orphan:destroy() self.janitor:clean();self.destroyed=true end
local icons={orphan};recover({getIcons=function() return icons end,baseTheme={}})
assert(methods.clean and resource.cleaned and orphan.destroyed and widget.attributes.MinimumWidth==44)
local foreignMethods={Cleanup=function() end}
local foreign=setmetatable({}, {__index=foreignMethods})
recover({getIcons=function() return {{iconModule={Name="OtherPackage"},themesJanitor=foreign}} end})
assert(foreignMethods.cleanup==nil,"Do not modify another application's package")
'''
with tempfile.TemporaryDirectory() as d:
    p=Path(d)/'bundle-test.lua';p.write_text(code,encoding='utf-8')
    r=subprocess.run([str(ROOT/'.tools/luau/luau.exe'),str(p)],text=True,capture_output=True)
    assert r.returncode==0,r.stdout+r.stderr
print('TopbarPlus: official source compilation, 21-module require graph/cache, unchanged Attribute, private registration, real Janitor aliases/cleanup and broken-icon recovery: PASS')
