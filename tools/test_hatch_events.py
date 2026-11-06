"""Hatch notifications must originate from accepted client events, never inventory contents."""
from pathlib import Path
import subprocess,tempfile
ROOT=Path(__file__).resolve().parents[1]
module=(ROOT/'testhub_src/hatch-events.lua').read_text(encoding='utf-8')
built=(ROOT/'bgsiscript').read_text(encoding='utf-8')
assert 'inventoryScanCount' not in built and 'local knownPets = {}' not in built
assert 'runtime.Connect(ReplicatedStorage.Shared.Framework.Network.Remote.RemoteEvent.OnClientEvent,runtime.HatchEvents.Accept)' in built
code=r'''
local jobs={}
local task={spawn=function(fn) table.insert(jobs,coroutine.create(fn)) end}
local function flush()
    while #jobs>0 do local co=table.remove(jobs,1);local ok,err=coroutine.resume(co);assert(ok,tostring(err)) end
end
local install=(function()
'''+module+r'''
end)()
local now,active=0,true
local sent,errors={},{}
local state={}
local function data(p) return p.Pet or p end
local ctx={State=state,UserId=42,Now=function() return now end,Active=function() return active end,
    Id=function(p) return data(p).Id end,Name=function(p) return data(p).Name or 'Unknown' end,
    Eligible=function(p) return data(p).Name=='Rare Pet' end,
    OnPet=function(p,event,result) table.insert(sent,{pet=p,event=event,result=result}) end,
    Error=function(e) table.insert(errors,e) end}
local controller=install(ctx)
local existing={Name='Rare Pet',Id='old-inventory'}
assert(#sent==0,'Attaching with existing inventory sends nothing')
for _,event in ipairs({'Inventory','InventoryUpdated','PetsUpdated','LocalData','ItemsReceived','TradeCompleted','HatchOtherPlayer'}) do
    assert(controller.Accept(event,{Pets={existing}})==0,event)
end
flush();assert(#sent==0,'Inventory, trades and reward snapshots are not hatch notifications')
assert(controller.Accept('HatchEgg',{UserId=99,Name='Example Egg',Pets={{Name='Rare Pet',Id='other-player'}}})==0)
local batch={Name='Example Egg',Pets={{Pet={Name='Rare Pet',Id='one',Enchants={{Id='original'}}}},{Pet={Name='Common Pet',Id='common'}}}}
assert(controller.Accept('HatchEgg',batch)==1)
assert(controller:IsBusy())
assert(controller.Accept('HatchEgg',batch)==0,'Same result object is not replayed')
batch.Pets[1].Pet.Enchants[1].Id='changed-later'
flush();assert(#sent==1 and sent[1].pet.Pet.Enchants[1].Id=='original' and not controller:IsBusy())
assert(sent[1].event=='HatchEgg' and sent[1].result.Name=='Example Egg' and type(sent[1].result.Pets)=='table')
assert(controller.Accept('ExclusiveHatch',{Pets={{Name='Rare Pet',Id='one'}}})==0,'Duplicate ID is claimed before asynchronous formatting')
assert(controller.Accept('HatchPowerupEgg',{EggName='Inventory Egg',Pets={{Name='Rare Pet',Id='two'},{Name='Rare Pet',Id='three'}}})==2)
flush();assert(#sent==3,'Same-name legitimate hatches with different IDs are retained')
local noIds={Pets={{Name='Rare Pet'},{Name='Rare Pet'}}}
assert(controller.Accept('ExclusiveHatch',noIds)==2);flush();assert(#sent==5,'Never dedupe legitimate batch pets by name')
assert(controller.Accept('ExclusiveHatch',{Pets={{Name='Rare Pet'}}})==1);flush();assert(#sent==6)
assert(controller.Accept('ExclusiveHatch',{Name='Rare Pet',Id='single'})==1);flush()
assert(sent[#sent].result.Pets==nil,'Single-pet payload does not turn a pet name into an egg name')
controller:Destroy();controller=install(ctx)
assert(controller.Accept('HatchEgg',{Pets={{Name='Rare Pet',Id='one'}}})==0,'Keep recent IDs across a reload')
now=121;assert(controller.Accept('HatchEgg',{Pets={{Name='Rare Pet',Id='one'}}})==1);flush()
for i=1,5000 do
    controller.Accept('HatchEgg',{Pets={{Name='Rare Pet',Id='bounded-'..i}}})
    if i%100==0 then flush() end
end
flush();local count=0;for _ in pairs(state.ids) do count+=1 end
assert(count<=4096,'Bound ID memory')
local before=#sent
active=false;assert(controller.Accept('HatchEgg',{Pets={{Name='Rare Pet',Id='after-unload'}}})==0);flush();assert(#sent==before)
active=true;controller=install(ctx)
controller.Accept('HatchEgg',{Pets={{Name='Rare Pet',Id='queued-before-unload'}}});controller:Destroy();flush()
assert(#sent==before,'Destroy drops pending work instead of replaying it')
assert(#errors==0)
print('Hatch events: no startup/inventory/reward/trade messages, accepted event variants, owner checks, early dedup, same-name batches, immutable snapshots, bounded state/reload and unload cleanup: PASS (offline)')
'''
with tempfile.TemporaryDirectory() as d:
    p=Path(d)/'events.lua';p.write_text(code,encoding='utf-8')
    result=subprocess.run([str(ROOT/'.tools/luau/luau.exe'),str(p)],capture_output=True,text=True)
    assert result.returncode==0,result.stdout+result.stderr
    print(result.stdout.strip())
