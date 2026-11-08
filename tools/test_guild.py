"""Execute the guild feature and movement/automation bridge against deterministic fixtures."""
from pathlib import Path
import subprocess,tempfile
ROOT=Path(__file__).resolve().parents[1]

def run(source,label):
 with tempfile.TemporaryDirectory()as d:
  p=Path(d)/'guild.lua';p.write_text(source,encoding='utf-8')
  r=subprocess.run([str(ROOT/'.tools/luau/luau.exe'),str(p)],capture_output=True,text=True)
  assert r.returncode==0,label+'\n'+r.stdout+r.stderr
 print(label+': PASS')

feature=(ROOT/'testhub_src/guild.lua').read_text(encoding='utf-8')
run(r'''
local task={spawn=function()end}
local function warn(message)error(message)end
local controls={};local tab={}
for _,kind in ipairs({"Section","Paragraph","Toggle","Button"})do
 tab[kind]=function(_,p)
  local c={Title=p.Title,Desc=p.Desc,Props=p,SetTitle=function(self,v)self.Title=v end,SetDesc=function(self,v)self.Desc=v end,SetIcon=function(self,v)self.Icon=v end}
  controls[p.Title]=c;return c
 end
end
local state={now=0,time=100000,active=true,busy=false,calls=0,saves=0,working=false,work={},fire={},restore={}}
local settings={eggs={selectedEgg="Test Egg"},guild={autoClaimRewards=false}}
local weekly={
 {Id="b",Task={Type="Bubbles"},Tiers={10,20}},
 {Id="h",Task={Type="Hatch"},Tiers={5,10}},
 {Id="c",Task={Type="OpenChest"},Tiers={1,2}}}
local data={Unlocked=true,Guild={Id="g1",Name="Test Guild",Level=3,Members={a={},b={}},Season={Points=100}},
 Season={Number=3,Week=1,Active=true},GlobalPoints=50,QuestProgress={b=3,h=0,c=0},Claims={["Guild:1"]=true}}
local util={GetSeason=function()return data.Season end,GetWeeks=function()return {weekly}end,
 GetRewards=function(_,track)return track=="Guild" and {{Requirement=50},{Requirement=100},{Requirement=200}}or{{Requirement=20},{Requirement=80}}end}
local context={Window={Tab=function(_,props)assert(props.Title=="Guilds");return tab end},Settings=settings,
 GuildUtil=util,Save=function()state.saves+=1 end,Now=function()return state.now end,Time=function()return state.time end,
 Active=function()return state.active end,Unlocked=function()return state.unlocked==true end,
 Signal={},Connect=function(_,fn)state.listener=fn end,
 Invoke=function(action)assert(action=="GetGuildSnapshot");state.calls+=1;if state.fail then error("network")end;if state.hook then state.hook()end;return data end,
 Fire=function(...)table.insert(state.fire,table.pack(...))end,
 SetWorking=function(enabled,preempted)state.working=enabled;state.preempted=preempted end,
 PriorityBusy=function()return state.busy end,
 QuestStep=function(work)table.insert(state.work,work);return true end,
 Restore=function(fn)table.insert(state.restore,fn)end}
local install=(function()
''' +feature+r'''
end)()
local api=install(context)
api.Step();assert(state.calls==1 and #state.fire==1 and #state.work==0)
assert(not controls["Auto Claim Guild Rewards"] and controls["Automatic Guild Rewards"],"Reward claiming is always automatic even with an old disabled preference")
assert(controls["Guild Status"].Title=="Test Guild" and controls["Guild Status"].Desc=="Level 3 | 2/10 members")
assert(controls.Rewards.Desc=="2 earned reward(s) ready")
assert(controls["Quest 3"].Desc:find("Manual",1,true))
controls["Auto Guild Quests"].Props.Callback(true)
api.Step();assert(state.fire[1][1]=="GuildClaimReward" and state.fire[1][2]=="Guild" and state.fire[1][3]==2)
assert(state.work[1].id=="b" and state.work[1].target==10 and state.working)
state.now=0.1;api.Step();assert(#state.fire==1,"Guild action cooldown")
state.now=1;api.Step();assert(#state.fire==2 and state.fire[2][2]=="Global")
state.now=2;api.Step();assert(#state.fire==2,"Pending claims must not repeat")
data.Claims["Guild:2"]=true;data.Claims["Global:1"]=true
state.listener("GuildSnapshot",data);assert(controls.Rewards.Desc=="0 earned reward(s) ready")
data.QuestProgress.b=11;api.Step();assert(state.work[#state.work].target==20)
data.QuestProgress.b=20;api.Step();assert(state.work[#state.work].id=="h")
data.QuestProgress.h=10;api.Step();assert(not state.working,"Manual/passive tasks must not issue quest actions")
data.QuestProgress.b=0;data.QuestProgress.h=0
state.busy=true;local before=#state.work;api.Step();assert(#state.work==before and not state.working and state.preempted)
state.busy=false;state.now=3;api.Step();state.now=63;api.Step();assert(not state.working,"Stalled quest is deferred")
state.now=63.1;api.Step();assert(state.work[#state.work].id=="h","Try the next quest after a stall")
controls["Auto Guild Quests"].Props.Callback(false)
controls["Auto Accept Guild Invites"].Props.Callback(true)
data.Guild=nil;data.Invitations={{GuildId="expired",ExpiresAt=99999},{GuildId="valid",ExpiresAt=100100}}
state.listener("GuildSnapshot",data);state.now=70;api.Step()
assert(state.fire[#state.fire][1]=="GuildAcceptInvite" and state.fire[#state.fire][2]=="valid")
local joined=#state.fire;state.now=71;api.Step();assert(#state.fire==joined,"Wait for invitation acceptance confirmation")
data.Guild={Id="g2",Name="Joined",Members={},Season={Points=0}};state.listener("GuildSnapshot",data)
state.now=90;api.Step();assert(#state.fire==joined,"Never accept an invitation while already in a guild")
data.Guild=nil;data.Unlocked=false;state.listener("GuildSnapshot",data);state.now=91;api.Step();assert(#state.fire==joined)
assert(controls["Guild Status"].Title=="Guilds Locked")
-- An invoke returning after a newer pushed snapshot cannot roll back the display.
local newest={Unlocked=true,Guild={Id="g3",Name="Newer Push",Members={},Season={Points=999}},Season=data.Season,GlobalPoints=0,Claims={}}
state.hook=function()api.Accept(newest)end
api.Refresh(true);assert(controls["Guild Status"].Title=="Newer Push")
state.hook=nil;state.fail=true;state.now=100;api.Refresh(true);local calls=state.calls
state.now=100.1;api.Step();assert(state.calls==calls,"Network failure is rate limited")
state.active=false;local count=#state.fire;api.Step();controls["Refresh Guild"].Props.Callback();assert(#state.fire==count and not state.working)
state.restore[1]();assert(not state.working and settings.eggs.selectedEgg=="Test Egg" and state.saves==3)
''','Guild status, weekly tiers, both reward tracks, action/claim dedupe, valid invites, priority, stalls, cached/pushed snapshots and lifecycle')

bridge=(ROOT/'testhub_src/guild-bridge.lua').read_text(encoding='utf-8')
run(r'''
local CFrame={new=function(_,y)return {Position=y}end}
local now,active,exact,space=0,true,false,true
local root={CFrame=777}
local character={FindFirstChild=function(_,name)assert(name=="HumanoidRootPart");return root end}
local boundary=0
local player={Character=character,GetAttribute=function(_,name)assert(name=="NextEggOpenAt");return boundary end}
local settings={eggs={selectedEgg="Test Egg",hatchAmount=12}}
local private={};local sent={};local profile={Bubble={Amount=0},Passes={}}
local ring={CFrame=100};local sell={FindFirstChild=function()return ring end}
local world={FindFirstChild=function()return sell end};local worlds={FindFirstChild=function()return world end}
local context={Player=player,State=private,Settings=settings,Profile={Get=function()return profile end},
 Workspace={FindFirstChild=function()return worlds end},Active=function()return active end,
 Now=function()return now end,Time=function()return now end,
 EggScanner={Teleport=function(name)assert(name=="Test Egg");root.CFrame=999;return exact end,GetNames=function()return {"Test Egg"}end},
 Stats={GetMaxEggHatches=function()return 3 end,GetBubbleStorage=function()return 100 end},
 CheckSpace=function()return space end,Fire=function(...)table.insert(sent,table.pack(...))end}
local make=(function()
''' +bridge+r'''
end)()
local api=make(context)
api.SetWorking(true);assert(private.guildQuestActive and not private.questActive)
local hatch={kind="Hatch"};api.QuestStep(hatch);assert(#sent==0,"Wait for an exact streamed egg location")
now=0.1;exact=true;api.QuestStep(hatch);assert(#sent==0)
now=1;api.QuestStep(hatch);assert(#sent==1 and sent[1][1]=="HatchEgg" and sent[1][2]=="Test Egg" and sent[1][3]==3)
now=1.1;api.QuestStep(hatch);assert(#sent==1,"One request per cooldown boundary")
boundary=10;now=2;api.QuestStep(hatch);assert(#sent==1)
now=10;space=false;api.QuestStep(hatch);assert(#sent==1,"Inventory space")
space=true;api.QuestStep(hatch);assert(#sent==2)
private.questActive=true;api.QuestStep(hatch);assert(#sent==2)
api.SetWorking(false,true);assert(root.CFrame==999 and not private.guildQuestActive and private.questActive,"Preemption must not move the higher-priority quest")
private.questActive=false;root.CFrame=777;now=11;api.SetWorking(true)
api.QuestStep({kind="Sell"});assert(root.CFrame==103 and sent[3][1]=="BlowBubble")
profile.Bubble.Amount=5;now=11.5;api.QuestStep({kind="Sell"});assert(sent[4][1]=="SellBubble")
profile.Bubble.Amount=100;now=12;api.QuestStep({kind="Bubbles"});assert(sent[5][1]=="SellBubble")
profile.Passes["Infinity Gum"]=true;now=12.5;api.QuestStep({kind="Bubbles"});assert(sent[6][1]=="BlowBubble")
api.SetWorking(false,false);assert(root.CFrame==777 and not private.guildQuestActive)
settings.eggs.selectedEgg=nil;now=14;api.SetWorking(true);api.QuestStep(hatch);assert(sent[7][2]=="Test Egg","Use the same fallback egg as the Eggs tab")
active=false;now=20;api.QuestStep(hatch);assert(#sent==7);api.SetWorking(false,false);assert(not private.guildQuestActive)
''','Guild bridge: selected egg, exact location, max hatch amount, cooldown/space, priority ownership, sell alternation, infinite storage and position restore')

built=(ROOT/'bgsiscript').read_text(encoding='utf-8')
assert 'while (getgenv().questActive or getgenv().guildQuestActive) and autoHatchEnabled do' in built
assert 'if getgenv().guildQuestActive then task.wait(0.1);continue end' in built
assert 'getgenv().guildQuestActive = true' not in built # Ownership is isolated in the bridge's state table.
print('Normal automation yields through the separate guild ownership flag: PASS')
