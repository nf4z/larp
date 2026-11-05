"""Run actual generated egg predicates and inventory discovery against noisy fixtures."""
from pathlib import Path
import subprocess,tempfile
ROOT=Path(__file__).resolve().parents[1]
source=(ROOT/'bgsiscript').read_text(encoding='utf-8')
a=source.index('    local function validEgg(');b=source.index('\n    local function',a+20)
predicate=source[a:b]
a=source.index('local function getInventoryEggs()');b=source.index('-- Shared chunk/render scanner;',a)
inventory=source[a:b]
code='''local knownNames={["Real Egg"]=true,VisualEggLock=true}
local function typeof(v) return type(v)=="table" and v.instance and "Instance" or type(v) end
local collection={HasTag=function(_,v) return v.tagged==true end}
'''+predicate+'''
assert(validEgg({},"Real Egg"))
assert(validEgg({instance=true,tagged=true},"New Event Egg"))
assert(not validEgg({instance=true,tagged=true},"VisualEggLock"))
assert(not validEgg({instance=true,tagged=true},"EggHitbox"))
assert(not validEgg({instance=true},"EggDecoration"))
assert(not validEgg({},"Meshes/Egg"))
local catalog={
    ["Owned Egg"]={Type="Egg"},["Unowned Egg"]={Type="Egg"},
    VisualEggLock={Type="Internal"},["Egg Token"]={Type="Powerup"},["Mystery Box"]={Type="Gift"},
}
local state={Powerups={["Owned Egg"]=4,["Egg Token"]=9,VisualEggLock=1,["Mystery Box"]=2}}
local ReplicatedStorage={Shared={Data={Powerups=catalog}}}
local function require(module) return module end
local LocalData={Get=function() return state end}
'''+inventory+'''
local eggs=getInventoryEggs();assert(#eggs==1 and eggs[1]=="Owned Egg")
state.Powerups={};assert(#getInventoryEggs()==0,"Do not invent inventory eggs when empty")
print('Egg discovery: catalog/tag validation, internal lock rejection, owned Type=Egg inventory, empty inventory: PASS')
'''
with tempfile.TemporaryDirectory() as d:
    p=Path(d)/'catalog.lua';p.write_text(code,encoding='utf-8')
    r=subprocess.run([str(ROOT/'.tools/luau/luau.exe'),str(p)],text=True,capture_output=True)
    assert r.returncode==0,r.stdout+r.stderr
    print(r.stdout.strip())
