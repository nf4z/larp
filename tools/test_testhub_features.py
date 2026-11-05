"""Exercise catalog discovery, rotation, consumption pacing, reserves and server controls."""
from pathlib import Path
import subprocess,tempfile,json
ROOT=Path(__file__).resolve().parents[1]
module=(ROOT/'testhub_src/extras.lua').read_text(encoding='utf-8')
code=r'''
local jobs={}
local task={spawn=function(fn,...) local co=coroutine.create(fn);table.insert(jobs,{co,table.pack(...)});return co end,wait=coroutine.yield}
local controls,tabs={},{}
local window={Tab=function(_,props)
    if tabs[props.Title] then return tabs[props.Title] end
    local tab={}
    for _,kind in ipairs({'Section','Paragraph','Dropdown','Input','Toggle','Button'}) do
        tab[kind]=function(_,p)
            local c={Props=p,Kind=kind,Values=p.Values}
            function c:SetDesc(v) self.Desc=v end
            function c:Refresh(v) self.Values=v end
            controls[p.Title]=c;return c
        end
    end
    tabs[props.Title]=tab;return tab
end}
local active,now,saves=true,0,0
local state={Gems=1000,Powerups={['Mystery Box']=250,['Guild Mystery Box']=8,['Condensed Mystery Box']=0,OddGift=7}}
local definitions={['Mystery Box']={Type='Gift'},['Guild Mystery Box']={Type='Gift'},['Condensed Mystery Box']={Type='Gift'},OddGift={Type='Gift'},['Fake Box']={Type='Potion'}}
local config={auto={selectedBoxes={'Mystery Box','Guild Mystery Box','Condensed Mystery Box','OddGift'},autoOpenBox=true,boxBatch=25}}
local fired,crafts,collected,joined,copied={},0,0,{},{}
local physical={GetActiveGifts=function() return {} end,GetActiveObjects=function() return 0 end}
local context={Window=window,Profile={Get=function() return state end},Powerups=definitions,Settings=config,Save=function() saves+=1 end,
    MaxGifts=50,Active=function() return active end,Now=function() return now end,PhysicalItem=physical,
    Fire=function(...) table.insert(fired,table.pack(...)) end,
    Condense=function() crafts+=1;return true end,
    PlaceId=123,JobId='current',Copy=function(value) table.insert(copied,value) end,Join=function(value) table.insert(joined,value) end,
    FindServer=function() return 'empty' end}
local install=(function()
''' +module+r'''
end)()
local api=install(context)
local gifts=api.GiftNames()
assert(#gifts==4 and table.find(gifts,'Condensed Mystery Box') and table.find(gifts,'OddGift'))
assert(not table.find(gifts,'Fake Box'),'Catalog type, not a substring or owned count, determines valid gifts')
local function click(name,value) assert(controls[name],name);controls[name].Props.Callback(value) end
click('Boxes To Open',{'Mystery Box','Guild Mystery Box'})
api.StepBoxes();assert(#fired==1 and fired[1][1]=='UseGift' and fired[1][2]=='Guild Mystery Box' and fired[1][3]==8)
now=0.6;api.StepBoxes();assert(#fired==2 and fired[2][2]=='Mystery Box' and fired[2][3]==25)
now=1.2;api.StepBoxes();assert(#fired==2,'Do not repeatedly consume stale inventory')
state.Powerups['Mystery Box']=225
now=1.8;api.StepBoxes();assert(#fired==3 and fired[3][2]=='Mystery Box')
physical.GetActiveObjects=function() return 50 end
now=10;api.StepBoxes();assert(#fired==3,'Respect the live gift limit')
physical.GetActiveObjects=function() return 0 end
click('Box Batch Size','999');assert(config.auto.boxBatch==50)
click('Box Open Delay','-10');assert(config.auto.boxDelay==0.2)
click('Box Batch Size','garbage');assert(config.auto.boxBatch==50)
click('Keep Gems','600');assert(not api.CanCondense() and not api.CondenseOne() and crafts==0)
click('Keep Gems','500');assert(api.CanCondense() and api.CondenseOne() and crafts==1)
assert(not api.CondenseOne() and crafts==1,'Wait for the craft inventory response')
state.Gems=500;state.Powerups['Mystery Box']-=100;state.Powerups['Condensed Mystery Box']=1
assert(not api.CanCondense() and not api.CondenseOne() and crafts==1,'Keep the requested gem reserve')
state.Gems=2000;state.Powerups['Mystery Box']=250
click('Auto Condense Mystery Boxes',true);click('Boxes To Open',{'Mystery Box'})
now=20;api.StepBoxes();assert(#fired==3,'Opening and condensing must not race for normal boxes')
click('Boxes To Open',{'OddGift'});now=21;api.StepBoxes();assert(#fired==4 and fired[4][2]=='OddGift')
definitions.NewGift={Type='Gift'};click('Refresh Box List');assert(table.find(controls['Boxes To Open'].Values,'NewGift'))
click('Auto Open Boxes',false);now=22;api.StepBoxes();assert(#fired==4)
click('Copy Job ID');assert(copied[1]=='current')
click('Copy Join Script');assert(copied[2]:find('123',1,true) and copied[2]:find('current',1,true))
click('Join Job ID');assert(#joined==0)
click('Server Job ID',' other-server ');click('Join Job ID');assert(joined[1]=='other-server')
click('Rejoin Server');assert(joined[2]=='current')
click('Hop To Emptiest Server');assert(joined[3]=='empty')
click('Auto Open Boxes',true);click('Boxes To Open',{})
local gift={Animating=true,Collect=function() collected+=1 end}
physical.GetActiveGifts=function() return {gift} end
local queued=#jobs;api.StepBoxes();assert(#jobs==queued,'Wait for the native spawn animation')
gift.Animating=false;api.StepBoxes();assert(#jobs==queued+1)
local collectJob=jobs[#jobs];assert(coroutine.resume(collectJob[1]));assert(collected==1)
api.StepBoxes();assert(#jobs==queued+1,'Do not claim a gift twice')
active=false;now=50;api.StepBoxes();assert(#fired==4 and not api.CondenseOne())
assert(saves>0)
print('Larplite extras: all gift types, refresh, owned rotation, batch limits, stale inventory, reserve/condense coordination, server tools: PASS')
'''
with tempfile.TemporaryDirectory() as d:
    path=Path(d)/'features.lua';path.write_text(code,encoding='utf-8')
    result=subprocess.run([str(ROOT/'.tools/luau/luau.exe'),str(path)],text=True,capture_output=True)
    assert result.returncode==0,result.stdout+result.stderr
    print(result.stdout.strip())
