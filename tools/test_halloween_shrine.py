"""Test the shared Halloween engine and both hubs' real controls with native-shaped state."""
from pathlib import Path
import subprocess,tempfile
ROOT=Path(__file__).resolve().parents[1]
core=(ROOT/'shared_src/halloween-shrine.lua').read_text(encoding='utf-8')
bgsi_ui=(ROOT/'testhub_src/halloween-shrine.lua').read_text(encoding='utf-8')
template=(ROOT/'tools/templates/larplite-halloween-shrine.lua').read_text(encoding='utf-8')
lua=r'''
local task={spawn=function()end}
local function warn(value)error(value)end
local make=(function()
''' +core+r'''
end)()
local function fixture()
 local f={now=100000,clock=0,active=true,sent={},config={enabled=false,potion="Lucky/6",target="Secret",reroll=false},accept=true,tickets=0}
 f.state={StartTime=0,XPOffered=995000}
 f.data={HalloweenShrine=f.state,Potions={}}
 f.owned={["Lucky/6"]=1000,["Lucky/7"]=100}
 f.definition={Duration=43200,XPRequired=1000000,
 Potions={{XP=2500,Item={Type="Potion",Name="Lucky",Level=6}},{XP=25000,Item={Type="Potion",Name="Lucky",Level=7}}},
 BuffPool={Luck={},Secret={}},BuffNames={"Luck","Secret"},
 GetBuffDisplayName=function(_,name)assert(name=="Luck" or name=="Secret");return name.." Buff"end,
 GetBuffIcon=function(_,name)assert(name=="Luck" or name=="Secret");return "rbxassetid://"..(name=="Luck"and"1"or"2")end}
 f.items={GetName=function(_,item)return item.Name.." "..item.Level end,
 GetOwnedAmount=function(_,data,item)return f.owned[item.Name.."/"..item.Level]or 0 end,
 CanAfford=function(_,data,cost)assert(cost.Name=="Shrine Ticket");return f.tickets>=cost.Amount end}
 f.profile={Get=function()return f.data end}
 f.context={Definition=f.definition,Profile=f.profile,ItemUtil=f.items,Config=function()return f.config end,
 Active=function()return f.active end,Now=function()return f.clock end,Time=function()return f.now end,
 RerollCost={Type="Powerup",Name="Shrine Ticket",Amount=1},
 Fire=function(...)table.insert(f.sent,table.pack(...))end,
 Invoke=function(...)table.insert(f.sent,table.pack(...));return f.accept end}
 f.api=make(f.context)
 return f
end
local f=fixture()
f.api.Step();assert(#f.sent==0,"Defaults must not spend items")
f.config.enabled=true;f.api.Step()
assert(f.sent[1][1]=="DonateToHalloweenShrine" and f.sent[1][2]=="Lucky" and f.sent[1][3]==6 and f.sent[1][4]==2,"Donate only the XP deficit")
f.clock=1;f.config.potion="Lucky/7";f.api.Step();assert(#f.sent==1,"A selection change must not duplicate an unconfirmed donation")
f.state.XPOffered=1000000;f.api.Step();assert(f.sent[2][1]=="ClaimHalloweenShrineBuff")
f.state.XPOffered=0;f.clock=2;f.api.Step();assert(#f.sent==2,"XP reset alone is not claim confirmation")
f.state.StartTime=f.now;f.state.Buff="Luck";f.clock=3;f.api.Step();assert(#f.sent==2)
local start=f.now
for _,elapsed in ipairs({3600,21600,43199})do f.now=start+elapsed;f.clock+=elapsed;f.api.Step()end
assert(#f.sent==2,"No donations during the entire native 12-hour buff")
f.api=make(f.context);f.api.Step();assert(#f.sent==2,"Reload reads the real game expiry")
f.now=start+43200;f.clock+=1;f.api.Step()
assert(f.sent[3][1]=="DonateToHalloweenShrine" and f.sent[3][3]==7 and f.sent[3][4]==40)
f=fixture();f.state.XPOffered=0;f.owned["Lucky/6"]=3;f.config.enabled=true;f.api.Step();assert(f.sent[1][4]==3,"Partial stock is bounded to owned quantity")
f=fixture();f.config.enabled=true;f.owned["Lucky/6"]=0;f.api.Step();assert(#f.sent==0)
f.config.potion="Invalid/9";f.api.Step();assert(#f.sent==0,"Never substitute an unselected expensive potion")
f=fixture();f.config.enabled=true;f.state.StartTime=f.now;f.state.Buff="Luck";f.config.reroll=true
f.api.Step();assert(#f.sent==0,"Rerolls require native Shrine Ticket cost")
f.tickets=10;f.api.Step();assert(f.sent[1][1]=="RerollHalloweenShrine")
f.clock=1;f.api.Step();assert(#f.sent==1,"Wait for confirmed reroll data")
f.state.Buff="Secret";f.api.Step();assert(#f.sent==1,"Stop immediately when the target lands")
f.state.Buff="Unknown future buff";f.config.reroll=false;assert(f.api.Step().buffName=="Unknown future buff")
f=fixture();f.config.enabled=true;f.accept=false;f.api.Step();f.clock=1;f.api.Step();assert(#f.sent==1)
f.clock=5;f.api.Step();assert(#f.sent==2,"Rejected requests back off")
f.active=false;f.clock=20;f.api.Step();assert(#f.sent==2,"Unload stops requests")
f=fixture();f.config.enabled=true;f.state.StartTime=nil;f.api.Step();assert(#f.sent==0,"Unknown timers defer spending")
local controls={};local tab={}
for _,kind in ipairs({"Section","Paragraph","Dropdown","Toggle"})do
 tab[kind]=function(_,props)
  local c={Props=props,SetDesc=function(self,v)self.desc=v end,SetIcon=function(self,v)self.icon=v end};controls[props.Title]=c;return c
 end
end
f=fixture();local saved=0;local settings={guild={keep=true}}
local install=(function()
''' +bgsi_ui+r'''
end)()
local widget=install({Window={Tab=function(_,props)assert(props.Title=="Shrine");return tab end},Settings=settings,Save=function()saved+=1 end,
 MakeEngine=make,Definition=f.definition,Profile=f.profile,ItemUtil=f.items,RerollCost=f.context.RerollCost,
 Active=f.context.Active,Time=f.context.Time,Now=f.context.Now,Fire=f.context.Fire,Invoke=f.context.Invoke})
local potion=controls["Halloween Donation Potion"].Props
assert(#potion.Values==2 and potion.Values[2].Item.Level==7 and potion.Values[1].Item.Type=="Potion")
assert(controls["Halloween Target Buff"].Props.Values[2].Icon=="rbxassetid://2")
potion.Callback("Lucky/7");controls["Auto Halloween Shrine"].Props.Callback(true)
controls["Halloween Target Buff"].Props.Callback("Secret");controls["Reroll Halloween Buff"].Props.Callback(true)
assert(settings.halloweenShrine.potion=="Lucky/7" and settings.halloweenShrine.enabled and settings.halloweenShrine.reroll and settings.guild.keep and saved==4)
widget.Render(widget.Engine.Step());assert(f.sent[1][3]==7 and f.sent[1][4]==1)
'''
lua+=r'''
local Config={autoHalloweenShrine=false,halloweenShrinePotion="Lucky/6",halloweenShrineReroll=false,halloweenShrineTarget="Secret",safeMode=false}
local ReplicatedStorage={Shared={Shrines={HalloweenShrine={}}}}
local require=function()return f.definition end
local profileStore,itemUtil=f.profile,f.items
local sharedConstants={ShrineRerollCost=f.context.RerollCost}
local isCurrentRun=f.context.Active
local tick,getCurrentTimestamp=f.context.Now,f.context.Time
local remoteFunction={InvokeServer=function(_,...)return f.context.Invoke(...)end}
local activeStates={BGSI_Lite_FireGameRemote=f.context.Fire}
local saveConfig=function()end
local liteControls={}
local scriptStateOB={AddSection=function()end,
 AddText=function(_,props)return {Set=function()end}end,
 AddDropdown=function(_,key,props)local c={Props=props};liteControls[key]=c;return c end,
 AddToggle=function(_,key,props)liteControls[key]={Props=props}end,
 AddParagraph=function(_,props)return {SetDesc=function()end}end}
'''
lua+=template.replace('__HALLOWEEN_ENGINE__',core)
lua+=r'''
liteControls.HalloweenShrinePotion.Props.Callback("Lucky 7")
assert(Config.halloweenShrinePotion=="Lucky/7")
assert(liteControls.HalloweenShrinePotion.FleetValueTransform("Lucky/6")=="Lucky 6","Fleet receives a stable ID and displays the corresponding label")
liteControls.AutoHalloweenShrine.Props.Callback(true);liteControls.HalloweenShrineReroll.Props.Callback(true)
assert(Config.autoHalloweenShrine and Config.halloweenShrineReroll)
print("Halloween shrine: shared donate/claim/reroll protocol, XP deficit and owned cap, 12-hour expiry, reload, confirmation/backoff, target stop, typed icons, private config and Fleet UI mapping: PASS")
'''
with tempfile.TemporaryDirectory()as d:
 p=Path(d)/'halloween.lua';p.write_text(lua,encoding='utf-8')
 r=subprocess.run([str(ROOT/'.tools/luau/luau.exe'),str(p)],capture_output=True,text=True)
 assert r.returncode==0,r.stdout+r.stderr
 print(r.stdout.strip())
lite_path=ROOT/'larplite.lua'
if not lite_path.exists():lite_path=ROOT/'src/larplite.lua'
assert core.strip() in lite_path.read_text(encoding='utf-8')
assert core.strip() in (ROOT/'bgsiscript').read_text(encoding='utf-8')
print('Both generated scripts embed the exact same shared Halloween policy: PASS')
