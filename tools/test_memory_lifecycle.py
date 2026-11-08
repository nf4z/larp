"""Real pickup hook/loop lifecycle, cache-first UI loading and bounded diagnostics."""
from pathlib import Path
import subprocess,tempfile
from tree_sitter import Language,Parser
import tree_sitter_luau
ROOT=Path(__file__).resolve().parents[1]
source=(ROOT/'larplite.lua').read_text(encoding='utf-8')
tree=Parser(Language(tree_sitter_luau.language())).parse(source.encode())
def statement(prefix):return next(n.text.decode() for n in tree.root_node.named_children if n.text.decode().startswith(prefix))
loop=next(n.text.decode() for n in tree.root_node.named_children if n.text.decode().startswith('task.spawn(function()') and 'if isCurrentRun() then pcall(installPickupRangeHook) end' in n.text.decode())
history=(ROOT/'shared_src/memory-history.lua').read_text(encoding='utf-8')
visual=(ROOT/'shared_src/memory-optimizer.lua').read_text(encoding='utf-8')
a=source.index('\tlocal rayfieldFile = "RayfieldGen2.lua"');b=source.index('\n\tlocal rayfieldWindow',a)
ui=source[a:b]
code=r'''
local alive=true;local function isCurrentRun()return alive end
local Config={autoCollectCoins=false,safeMode=false}
local currentRunToken={};local activeStates={}
local function getgenv()return activeStates end
local ReplicatedStorage={Shared={Utils={Stats={StatsUtil='native-stats'}}}}
local native=function(_,value)return value or 17 end
local stats={GetPickupRange=native}
local function require(path)assert(path=='native-stats');return stats end
local scriptStateCE;local scriptStateHD=200
'''+statement('function installPickupRangeHook(')+r'''
assert(installPickupRangeHook());local hook=stats.GetPickupRange
for i=1,100 do assert(installPickupRangeHook() and stats.GetPickupRange==hook,'Rechecking never allocates/replaces the same owned hook')end
assert(stats:GetPickupRange()==17)
Config.autoCollectCoins=true;assert(stats:GetPickupRange()==200)
activeStates.BGSI_Lite_TicketPickupActive=true;assert(stats:GetPickupRange()==1000000)
Config.safeMode=true;assert(stats:GetPickupRange()==17,'Safe Mode bypasses all pickup range changes')
Config.safeMode=false;activeStates.BGSI_Lite_TicketPickupActive=false
assert(stats:GetPickupRange('unknown')=='unknown','Preserve nonnumeric native results')
local taskThread
local task={spawn=function(fn)taskThread=coroutine.create(fn)end,wait=function()coroutine.yield()end}
'''+loop+r'''
assert(coroutine.resume(taskThread));assert(coroutine.status(taskThread)=='suspended')
alive=false;assert(coroutine.resume(taskThread));assert(coroutine.status(taskThread)=='dead','Old loop stops immediately after its wait when replaced')
assert(stats:GetPickupRange()==17 and not installPickupRangeHook(),'Inactive runs cannot change or re-install hooks')
activeStates.BGSI_Lite_PickupRangeHook.Destroy();assert(stats.GetPickupRange==native and not stats._BGSI_LITE_PickupRangeHook)
alive=true;currentRunToken={};assert(installPickupRangeHook() and stats.GetPickupRange~=hook)
activeStates.BGSI_Lite_PickupRangeHook.Destroy()
local installHistory=(function()
'''+history+r'''
end)()
local now,mode,writes=0,'off',0
local data={}
local historyContext={History=data,Version='test-v49',Now=function()return now end,Time=function()return 100000+now end,
 Mode=function()return mode end,Save=function(snapshot)assert(snapshot.schema==1 and #snapshot.samples<=120);writes+=1 end}
local recorder=installHistory(historyContext)
assert(recorder.Record({totalMB=900,vmMB=40,luaMB=50}) and writes==1)
now=5;assert(not recorder.Record({totalMB=901}) and writes==1,'No five-second file churn')
mode='safe';assert(recorder.Record({totalMB=902}) and writes==2,'Record mode transitions')
now=65;assert(recorder.Record({totalMB=903,vmMB=0/0}))
assert(data[#data].vmMB==nil,'Non-finite values cannot corrupt JSON output')
for i=1,130 do now+=60;recorder.Record({totalMB=900+i,vmMB=i})end
assert(#data==120 and data[#data].vmMB==130,'Bound history to two hours of minute samples')
local previous=#data;local replacement=installHistory(historyContext);assert(#replacement.Samples==previous)
now+=1;assert(replacement.Record({totalMB=1031}) and #data==120,'Keep bounded history across reloads')

local downloads,cache,writeCount=0,nil,0
local good='return {CreateWindow=function()end} -- CreateDropdown CreateStat\n'..string.rep(' ',11000)
local game={HttpGet=function()downloads+=1;return good end}
local function isfile()return cache~=nil end
local function readfile()return cache end
local function writefile(_,text)writeCount+=1;cache=text end
local function loadUI()
'''+ui+r'''
return Rayfield
end
cache=good;assert(type(loadUI().CreateWindow)=='function' and downloads==0,'A valid cached UI avoids any network copy')
cache='broken';loadUI();assert(downloads==1 and writeCount==1)
cache='this is broken Lua -- CreateDropdown CreateStat\n'..string.rep(' ',11000)
loadUI();assert(downloads==2 and writeCount==2,'Malformed same-size cache falls back to one fresh source')

local installVisual=(function()
'''+visual+r'''
end)()
local connections=0
local root={DescendantAdded={Connect=function()connections+=1;return {Disconnect=function()connections-=1 end}end}}
local low={Enabled=false}
local mesh=false
local visual=installVisual({Root=root,Active=function()return true end,LowDetail=function()return low end,MeshDetail=function()return mesh end})
visual.SetEnabled(true)
assert(low.Enabled and connections==0 and not visual.Pending(),'Default native low detail requires no mesh registry, signal or scan')
visual.SetEnabled(false);assert(not low.Enabled)
visual.Destroy()
local deferred={};local delayedLow={Enabled=false}
delayedLow.Changed={Connect=function(_,fn)
 return {Disconnect=function()end,Callback=fn}
end}
local callback
delayedLow.Changed.Connect=function(_,fn)callback=fn;return {Disconnect=function()end}end
delayedLow.Changed.Fire=function(_,value)local fn=callback;table.insert(deferred,function()fn(value)end)end
local delayed=installVisual({Root=root,Active=function()return true end,LowDetail=function()return delayedLow end,MeshDetail=function()return false end})
delayed.SetEnabled(true);table.remove(deferred,1)()
delayed.SetEnabled(false);assert(not delayedLow.Enabled,'An asynchronously delivered owned low-detail signal cannot overwrite the native baseline')
delayed.SetEnabled(true);local stale=table.remove(deferred,1)
delayed.SetEnabled(false);delayed.SetEnabled(true);stale()
while #deferred>0 do table.remove(deferred,1)()end
delayed.Destroy();assert(not delayedLow.Enabled,'Queued callbacks from earlier modes are ignored')
print('Memory lifecycle: idempotent pickup hook, post-wait cancellation, native/Safe Mode restoration, bounded minute history/reloads, cache-first UI and scan-free default: PASS (offline)')
'''
with tempfile.TemporaryDirectory() as directory:
    path=Path(directory)/'lifecycle.lua';path.write_text(code,encoding='utf-8')
    result=subprocess.run([str(ROOT/'.tools/luau/luau.exe'),str(path)],capture_output=True,text=True)
    assert result.returncode==0,result.stdout+result.stderr
    print(result.stdout.strip())
