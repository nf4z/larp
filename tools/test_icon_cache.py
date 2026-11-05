"""Validate cache data and execute the actual runtime reader with Luau fixtures."""
from pathlib import Path
import hashlib
import json
import os
import subprocess
import tempfile

ROOT=Path(__file__).resolve().parents[1]
paths=json.loads((ROOT/'icon-cache/paths.json').read_text())
catalogs={}
for category,path in paths.items():
    raw=(ROOT/path).read_bytes()
    assert Path(path).stem==hashlib.sha256(raw).hexdigest()[:20]
    value=json.loads(raw)
    assert value['schema']==1 and value['category']==category and value['entries']
    assert all(name==record['name'] for name,record in value['entries'].items())
    catalogs[category]=value['entries']
assert catalogs['Pets']['Doggy']['images']['Normal']=='rbxassetid://105716458186041'
assert catalogs['Runes']['Luck']['images']['Tier2']=='rbxassetid://109314989843487'
assert 'Lucky' in catalogs['Potions'] and 'Common Egg' in catalogs['Eggs']
publish=json.loads((ROOT/'icon-cache/publish-files.json').read_text())
assert all((ROOT/path).exists() for path in publish)
print(f'Cache integrity: {sum(len(v) for v in catalogs.values())} records, {len(paths)} categories: PASS')
source=(ROOT/'testhub_src/native-ui.lua').read_text(encoding='utf-8')
a=source.index('local function cachedImage(');b=source.index('\nlocal function data(',a)
reader=source[a:b]
code=r'''
local disk, requests = {}, 0
local game={HttpGet=function() requests+=1;return "catalog" end}
local HttpService={JSONDecode=function(_,source)
    assert(source=="catalog")
    return {schema=1,category="Pets",entries={Doggy={images={Normal="rbxassetid://123"}}}}
end}
local function isfile(path) return disk[path]~=nil end
local function readfile(path) return disk[path] end
local function writefile(path,value) disk[path]=value end
local function makefolder() end
local function isfolder() return true end
local task={spawn=function(fn) fn() end}
local function newReader()
    local iconCatalogs,iconCatalogPending,descriptorCache={},{},{}
    local ICON_CACHE_PATHS={Pets="icon-cache/pets/fixture.json"}
'''+reader+r'''
    return cachedImage
end
local first=newReader()
assert(first("Pets","Doggy")=="rbxassetid://123")
assert(first("Pets","Doggy")=="rbxassetid://123" and requests==1)
assert(newReader()("Pets","Doggy")=="rbxassetid://123" and requests==1, "Reuse disk cache")
disk["QtrzipIconCache/fixture.json"]="corrupt"
assert(newReader()("Pets","Doggy")=="rbxassetid://123" and requests==2, "Repair invalid disk cache")
disk={};game.HttpGet=function() error("offline") end
assert(newReader()("Pets","Doggy")==nil, "Missing cache must fall back to live rendering")
'''
with tempfile.TemporaryDirectory() as directory:
    path=Path(directory)/'test.lua';path.write_text(code,encoding='utf-8')
    result=subprocess.run([os.environ.get('LUAU',str(ROOT/'.tools/luau/luau.exe')),str(path)],capture_output=True,text=True)
    assert result.returncode==0,result.stdout+'\n'+result.stderr
print('Runtime reader: network, memory/disk reuse, corrupt repair, offline fallback: PASS')
