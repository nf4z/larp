"""Execute bgsiscript's competition feature with controlled profiles and server snapshots."""
from pathlib import Path
import subprocess
import tempfile

ROOT=Path(__file__).resolve().parents[1]
module=(ROOT/'testhub_src/competition.lua').read_text(encoding='utf-8')
code=r'''
local task={spawn=function()end,wait=function()end}
local function warn(message)error(message)end
local install=(function()
''' + module + r'''
end)()
local function fixture(available)
 local controls,tabs,restore={}, {}, {}
 local state={now=0,active=true,fire={},saves=0,nativeOpen=false,opened=0}
 local own={Team="Blue",Hatches=60541,Bubbles=1563242848,Claims={}}
 local settings={auto={keep=true},comp={autoClaimHatches=true,autoClaimBubbles=true}}
 local season={Id="1",PersonalRewards={Hatches={{Requirement=500},{Requirement=5000},{Requirement=100000}},Bubbles={{Requirement=1000000},{Requirement=5000000000}}}}
 local definition={Name="Seals vs Frog Dogs",Enabled=true,GetSeason=function()return season end,
  Teams={Pink={Name="Seals",Shield="rbxassetid://105235648283544"},Blue={Name="Frog Dogs",Shield="rbxassetid://81317703874820"}},
  Icons={Rewards="rbxassetid://102958595859917",Hatches="rbxassetid://99740547547936",Bubbles="rbxassetid://139415836850114"}}
 local window={Tab=function(_,props)
  local tab={Props=props};tabs[props.Title]=tab
  for _,kind in ipairs({"Section","Paragraph","Toggle","Button"}) do
   tab[kind]=function(_,p)
    local c={Props=p,Title=p.Title,Desc=p.Desc,Icon=p.Icon}
    function c:SetTitle(v)self.Title=v end
    function c:SetDesc(v)self.Desc=v end
    function c:SetIcon(v)self.Icon=v end
    controls[p.Title]=c;return c
   end
  end
  return tab
 end}
 local context={Window=window,Settings=settings,Save=function()state.saves+=1 end,UserId=42,
  Competition=available and definition or nil,
  Profile={Get=function()if state.notReady then error("not ready") end;return {PinkVsBlue={["1"]=state.unjoined and nil or own}}end},
  Active=function()return state.active end,Now=function()return state.now end,
  Fire=function(...)table.insert(state.fire,table.pack(...))end,
  Connect=function(_,fn)state.receive=fn end,Signal={},Restore=function(fn)table.insert(restore,fn)end,
  NativeOpen=function()return state.nativeOpen end,
  CreateLeaderboard=function()
   state.opened+=1
   local popup={updates=0,IsOpen=function(self)return not self.closed end,Close=function(self)self.closed=true end,
    Update=function(self,snapshot)self.updates+=1;self.snapshot=snapshot end}
   state.popup=popup;return popup
  end}
 local api=install(context)
 return {api=api,controls=controls,tabs=tabs,state=state,own=own,settings=settings,season=season,restore=restore}
end
local f=fixture(true)
assert(f.tabs.Comp.Props.Icon=="rbxassetid://102958595859917")
assert(f.controls["Your Team"].Title=="Frog Dogs" and f.controls["Your Team"].Icon=="rbxassetid://81317703874820")
assert(f.controls.Hatches.Title=="60,541 Hatches" and f.controls.Bubbles.Title=="1,563,242,848 Bubbles")
assert(f.controls.Hatches.Props.Icon=="rbxassetid://99740547547936" and f.controls.Bubbles.Props.Icon=="rbxassetid://139415836850114")
f.controls["Live Leaderboards"].Props.Callback();assert(f.state.opened==1)
assert(not f.controls.Hatches.Title:find("place",1,true),"Separate count and place text")
f.state.receive("PinkVsBlueSnapshot",{Season=f.season,Standings={Boards={Blue={Hatches={{UserId=5,Score=70000},{UserId=42,Score=60000}},Bubbles={}}}}})
assert(f.controls.Hatches.Desc=="Team place: #2")
assert(f.state.popup.updates==2 and f.state.popup.snapshot.Boards.Blue.Hatches[1].Score==70000,"Push updates reach the open popup immediately")
for i=1,5 do f.api.Step();f.state.now+=0.5 end
local claims={}
for _,request in ipairs(f.state.fire) do
 if request[1]=="PinkVsBlueClaim" then
 assert(request[1]=="PinkVsBlueClaim" and request[2]=="1")
 local key="Personal:"..request[3]..":"..request[4]
 assert(not claims[key],"Pending claim repeated");claims[key]=true
 end
end
assert(#f.state.fire==4 and claims["Personal:Hatches:1"] and claims["Personal:Hatches:2"] and claims["Personal:Bubbles:1"])
for key in pairs(claims)do f.own.Claims[key]=true end
f.api.Step();assert(f.controls["Reward Status"].Desc:find("3 claimed",1,true))
f.controls["Auto Claim Hatches"].Props.Callback(false)
f.own.Hatches=200000;f.api.Step();assert(#f.state.fire==4 and f.settings.comp.autoClaimHatches==false)
assert(f.settings.auto.keep and f.state.saves==1,"Own config changes only")
f.controls["Refresh Competition"].Props.Callback();assert(f.state.fire[5][1]=="PinkVsBlueView" and f.state.fire[5][2]==true)
f.state.receive("PinkVsBlueSnapshot",{Season={},Standings={}})
local board={};for i=1,100 do board[i]={UserId=i+100,Score=1000000}end
f.state.receive("PinkVsBlueSnapshot",{Season=f.season,Standings={Boards={Blue={Hatches=board,Bubbles={}}}}})
assert(f.controls.Hatches.Desc=="Team place: Outside top 100")
f.state.notReady=true;f.api.Step();assert(f.controls["Your Team"].Title=="Join a Team")
f.state.notReady=false
f.state.active=false;local before=#f.state.fire
f.api.Step();f.controls["Refresh Competition"].Props.Callback();assert(#f.state.fire==before)
f.controls["Live Leaderboards"].Props.Callback();assert(f.state.opened==1,"No leaderboard actions after unload")
f.restore[1]();assert(f.state.fire[#f.state.fire][1]=="PinkVsBlueView" and f.state.fire[#f.state.fire][2]==false)
local g=fixture(true);g.state.nativeOpen=true;g.restore[1]();assert(#g.state.fire==0,"Leave an open native competition screen subscribed")
g=fixture(false);g.api.Step();assert(#g.state.fire==0 and #g.restore==0 and g.controls["Your Team"].Title=="Competition Unavailable")
print("Comp: native art, separate statistics, live team place, earned claims/dedupe, private toggles, refresh, top-100 bounds, profile readiness, unload: PASS")
'''
with tempfile.TemporaryDirectory() as d:
 p=Path(d)/'competition.lua';p.write_text(code,encoding='utf-8')
 result=subprocess.run([str(ROOT/'.tools/luau/luau.exe'),str(p)],text=True,capture_output=True)
 assert result.returncode==0,result.stdout+result.stderr
 print(result.stdout.strip())
