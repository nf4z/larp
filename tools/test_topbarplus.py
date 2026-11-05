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
with tempfile.TemporaryDirectory() as d:
    p=Path(d)/'bundle-test.lua';p.write_text(code,encoding='utf-8')
    r=subprocess.run([str(ROOT/'.tools/luau/luau.exe'),str(p)],text=True,capture_output=True)
    assert r.returncode==0,r.stdout+r.stderr
print('TopbarPlus: official source compilation, 21-module require graph/cache, unchanged Attribute, private registration: PASS')
