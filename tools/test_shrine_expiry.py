"""Run real shrine workers with a virtual clock through cooldown and blessing expiry."""
from pathlib import Path
import subprocess
import tempfile
from tree_sitter import Language, Parser
import tree_sitter_luau

ROOT=Path(__file__).resolve().parents[1]
parser=Parser(Language(tree_sitter_luau.language()))
lite_path=ROOT/'larplite.lua'
if not lite_path.exists():lite_path=ROOT/'src/larplite.lua'
lite=lite_path.read_text(encoding='utf-8')
bgsi=(ROOT/'bgsiscript').read_text(encoding='utf-8')

def run(code,label):
 with tempfile.TemporaryDirectory() as d:
  p=Path(d)/'shrine.lua';p.write_text(code,encoding='utf-8')
  result=subprocess.run([str(ROOT/'.tools/luau/luau.exe'),str(p)],capture_output=True,text=True)
  assert result.returncode==0,label+'\n'+result.stdout+result.stderr
 print(label+': PASS')

nodes=parser.parse(lite.encode()).root_node.named_children
dream=next(n.text.decode() for n in nodes if n.text.decode().startswith('task.spawn(function()') and 'pcall(remoteFunction.InvokeServer, remoteFunction, "DonateToDreamerShrine"' in n.text.decode())
bubble=next(n.text.decode() for n in nodes if n.text.decode().startswith('task.spawn(function()') and 'pcall(remoteFunction.InvokeServer, remoteFunction, "DonateToShrine"' in n.text.decode())
for key,worker,amount in [('DreamerShrine',dream,15),('BubbleShrine',bubble,500)]:
 setup=r'''
local key=KEY
local expected=AMOUNT
local now,start,workerThread=100000,100000,nil
local donations,restocks,reads=0,0,0
local stock=expected
local state={LastDonationTime=start,ShrineBlessingEndTime=start+86400}
local profile={[key]=state}
local util={DONATION_INTERVAL=3600}
local activeStates={BGSI_Lite_DreamerShrineUtil=util,BGSI_Lite_LogDashboardAction=function()end}
local Config={DreamerShrineEnabled=true,DreamerShrineAmount=15,shrineAuto=true,shrineAmount=1000,shrineLevel=1,shrinePotion="Lucky"}
local profileStore={IsReady=function()return true end,Get=function()return profile end}
local function getCurrentTimestamp()return now end
local function tick()return now end
local function isCurrentRun()return true end
local task={spawn=function(fn)workerThread=coroutine.create(fn)end,wait=coroutine.yield}
local require=function()return util end
local ReplicatedStorage={Shared={Utils={ShrineUtil={}}}}
local itemUtil={GetOwnedAmount=function()reads+=1;return stock end}
activeStates.BGSI_Lite_GetInventoryItemAmount=function()reads+=1;return stock end
activeStates.BGSI_Lite_SmartShopRestock=function()restocks+=1;stock=expected;return expected end
local remoteFunction={InvokeServer=function(_,action,value)
 assert(now>=state.ShrineBlessingEndTime,"Spent items before blessing expiry")
 assert(now>=state.LastDonationTime+3600,"Ignored server donation cooldown")
 assert(action==(key=="DreamerShrine" and "DonateToDreamerShrine" or "DonateToShrine"))
 local quantity=type(value)=="table" and value.Amount or value
 assert(quantity==expected,"Spend only the amount for 24 hours")
 stock-=quantity;donations+=1;state.ShrineBlessingEndTime=now+86400;state.LastDonationTime=now;return true
end}
local function pump()local ok,err=coroutine.resume(workerThread);assert(ok,tostring(err))end
'''.replace('KEY','"'+key+'"').replace('AMOUNT',str(amount))
 checks=r'''
pump();pump()
for _,offset in ipairs({3599,3600,7200,86399})do now=start+offset;pump()end
assert(donations==0 and restocks==0 and reads==0,"Hourly cooldown must not trigger inventory/restock/donation")
now=start+86400;pump();assert(donations==1 and restocks==0)
now+=3600;pump();assert(donations==1 and restocks==0,"Do not refill an active 23-hour blessing")
-- A new worker (reload/rejoin) uses the stored game expiry rather than a fresh local timer.
'''
 final=r'''
pump();pump();assert(donations==1 and restocks==0)
now=state.ShrineBlessingEndTime-1;pump();assert(donations==1 and restocks==0)
now=state.ShrineBlessingEndTime;pump();assert(donations==2 and restocks==1,"Restock only after full expiry")
state.ShrineBlessingEndTime=now+90000
now+=86400;pump();assert(donations==2,"Honor a later game-side expiry")
now+=3600;pump();assert(donations==3 and restocks==2)
state.ShrineBlessingEndTime=nil;now+=90000;pump();assert(donations==3 and restocks==2,"Unknown timers must not spend items")
'''
 run(setup+worker+checks+worker+final,'Larplite '+key+': 24h expiry, no hourly spend/restock, reload persistence, amount cap, unknown timer')

def get_function(source,name):
 def find(node):
  if node.type=='function_declaration' and node.text.decode().startswith('local function '+name+'('):return node.text.decode()
  for child in node.named_children:
   found=find(child)
   if found:return found
 result=find(parser.parse(source.encode()).root_node)
 assert result,name
 return result

helpers='\n'.join(get_function(bgsi,n) for n in ['getDonationData','getOwnedAmount','findBubblePotion','bubbleLoop','dreamerLoop'])
for key,loop,amount in [('BubbleShrine','bubbleLoop',500),('DreamerShrine','dreamerLoop',15)]:
 setup=r'''
local key,expected=KEY,AMOUNT
local start,now=100000,100000
local donations,notifications=0,0
local state={LastDonationTime=start,ShrineBlessingEndTime=start+86400}
local data={[key]=state}
local stock=expected
local LocalData={IsReady=function()return true end,Get=function()return data end}
local Time={now=function()return now end}
local ShrineUtil,DreamerShrineUtil={DONATION_INTERVAL=3600},{DONATION_INTERVAL=3600}
local BUBBLE_AMOUNT,DREAMER_AMOUNT,CHECK_INTERVAL=500,15,15
local BUBBLE_POTION_OPTIONS={{Name="Lucky",Level=1}}
local ItemUtil={GetOwnedAmount=function()return stock end}
local bubbleEnabled,dreamerEnabled=true,true
local function isCurrentShrineGeneration()return true end
local globals={ActivityStatus={}}
local function getgenv()return globals end
local task={wait=coroutine.yield}
local function notifyUser()notifications+=1 end
local function warn(value)error(value)end
local Remote={InvokeServer=function(_,action,value)
 assert(now>=state.ShrineBlessingEndTime,"Early donation")
 local quantity=type(value)=="table" and value.Amount or value
 assert(quantity==expected)
 donations+=1;stock-=quantity;state.LastDonationTime=now;state.ShrineBlessingEndTime=now+86400;return true
end}
'''.replace('local key,expected=KEY,AMOUNT',f'local key,expected="{key}",{amount}')
 checks=r'''
local thread=coroutine.create(LOOP)
local function pump()local ok,err=coroutine.resume(thread);assert(ok,tostring(err))end
pump()
for _,offset in ipairs({3600,7200,86399})do now=start+offset;pump()end
assert(donations==0 and notifications==0)
now=start+86400;pump();assert(donations==1)
now+=3600;pump();assert(donations==1 and notifications==0,"No top-up or empty-stock alert on active blessing")
thread=coroutine.create(LOOP);pump();assert(donations==1,"Reload uses the game expiry")
now=state.ShrineBlessingEndTime;pump();assert(donations==1 and notifications==1,"Notify missing stock only when renewal is due")
stock=expected;pump();assert(donations==2)
state.ShrineBlessingEndTime=nil;now+=90000;pump();assert(donations==2)
state.ShrineBlessingEndTime=now;state.LastDonationTime=now;pump();assert(donations==2,"Cooldown remains a minimum server constraint")
'''.replace('LOOP',loop)
 run(setup+helpers+checks,'bgsiscript '+key+': full expiry, cooldown guard, reload, no premature stock alerts')
