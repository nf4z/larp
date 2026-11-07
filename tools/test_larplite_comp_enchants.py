"""Execute changed Larplite code against controlled game/network fixtures."""
import json
import subprocess
import tempfile
from pathlib import Path
from tree_sitter import Language, Parser
import tree_sitter_luau

ROOT = Path(__file__).resolve().parents[1]
source = (ROOT / 'larplite.lua').read_text(encoding='utf-8')
parser = Parser(Language(tree_sitter_luau.language()))
nodes = parser.parse(source.encode()).root_node.named_children

def function(name):
    for n in nodes:
        t = n.text.decode()
        if t.startswith('function ' + name + '(') or t.startswith('local function ' + name + '(') or t.startswith('activeStates.' + name + ' = function('):
            return t
    raise AssertionError(name)

def nested_function(name):
    def find(n):
        if n.type == 'function_declaration' and n.text.decode().startswith('local function ' + name + '('):
            return n.text.decode()
        for child in n.named_children:
            result = find(child)
            if result: return result
    result = find(parser.parse(source.encode()).root_node)
    assert result, name
    return result

def run(code, label):
    with tempfile.TemporaryDirectory() as d:
        path = Path(d) / 'test.lua'
        path.write_text(code, encoding='utf-8')
        r = subprocess.run([str(ROOT / '.tools/luau/luau.exe'), str(path)], capture_output=True, text=True)
        assert r.returncode == 0, label + '\n' + r.stdout + r.stderr
    print(label + ': PASS')

helpers = '\n'.join(function(n) for n in [
    'normalizeEnchantName', 'buildTargetEnchantLookup', 'getMaxEnchantSlotsForPet',
    'isPetEnchantTargetSatisfied', 'getProtectedEnchantSlot', 'petHasStaleTargetEnchant',
    'BGSI_Lite_GetPetEnchantSignature', 'BGSI_Lite_RerollEnchantPet'])
run('''
local activeStates = { BGSI_Lite_IsShinyEnchantPet = function() return true end }
local Config = {autoEnchant=true, equippedTargetEnchant="ultra-roller", equippedTargetEnchant2="shiny-hunter", equippedEnchantCurrency="Gems"}
local now, calls = 0, 0
local task = {wait=function(dt) now += dt or 0.1; assert(now<30,"Worker did not finish") end}
local function tick() return now end
local function isCurrentRun() return true end
local ENCHANT_REROLL_COOLDOWN = 0.25
local function resolveEnchantCurrency(value) return value end
local function getShadowCrystalCount() return 100 end
local pet = {Shiny=true, Enchants={{Id="ultra-roller",Level=1},{Id="junk",Level=1}}}
local function getEnchantCurrency() return pet end
local remoteEvent = {}
local remoteFunction = { InvokeServer = function(_, action, id, currency, protect)
    calls += 1
    assert(action=="RerollEnchants" and protect==1,"Must keep Ultra Roller locked")
    if calls==1 then
        Config.equippedTargetEnchant2="secret-hunter"
        return id, {{Id="ultra-roller",Level=1},{Id="shiny-hunter",Level=1}}
    end
    assert(calls==2,"Did not use the authoritative returned enchants")
    return id, {{Id="ultra-roller",Level=1},{Id="secret-hunter",Level=1}}
end }
''' + helpers + '''
assert(activeStates.BGSI_Lite_RerollEnchantPet("pet", "ultra-roller", "shiny-hunter", 0, "Gems"))
assert(calls==2,"Must change selection mid-pet")
local lookup = buildTargetEnchantLookup("ultra-roller", "secret-hunter")
assert(not isPetEnchantTargetSatisfied({Shiny=true,Enchants={{Id="ultra-roller"},{Id="ultra-roller"}}},lookup,0,true),"Duplicates cannot satisfy two targets")
assert(isPetEnchantTargetSatisfied({Shiny=true,Enchants={{Id="secret-hunter"},{Id="ultra-roller"}}},lookup,0,true))
assert(not isPetEnchantTargetSatisfied({Shiny=true,Enchants={{Id="ultra-roller"}}},lookup,0,true))
assert(getProtectedEnchantSlot({Enchants={{Id="secret-hunter",Level=9},{Id="ultra-roller",Level=2}}},lookup,0,3)==1)
assert(getProtectedEnchantSlot({Enchants={ ["2"]={Id="ultra-roller",Level=9}}},lookup,0)==2)
''', 'Enchant targets change mid-roll; distinct targets, confirmed results, numeric locks, selective level refresh')

run('''
local activeStates={BGSI_Lite_IsShinyEnchantPet=function()return true end}
local Config={autoEnchant=true,equippedTargetEnchant="secret-hunter",equippedTargetEnchant2="ultra-roller",equippedEnchantCurrency="Shadow Crystals"}
local now,calls,pending=0,0,false
local pet={Shiny=true,Enchants={{Id="shiny-hunter"},{Id="ultra-roller"}}}
local function tick()return now end
local function isCurrentRun()return true end
local function getEnchantCurrency()return pet end
local function resolveEnchantCurrency(v)return v end
local function getShadowCrystalCount()return 10 end
local ENCHANT_REROLL_COOLDOWN=0.25
local task={wait=function(dt)
 now+=dt;assert(now<5,"Stuck on previous targets")
 if pending then
  pending=false
  pet={Shiny=true,Enchants={{Id=calls==1 and "secret-hunter" or "lucky"},{Id="ultra-roller"}}}
  if calls==1 then Config.equippedTargetEnchant="lucky" end
 end
end}
local remoteFunction={}
local remoteEvent={FireServer=function(_,action,id,protect)
 calls+=1;assert(calls<=2)
 assert(action=="UseShadowCrystal" and protect==2,"Keep Ultra Roller locked in slot 2")
 pending=true
end}
''' + helpers + '''
assert(activeStates.BGSI_Lite_RerollEnchantPet("pet","secret-hunter","ultra-roller",0,"Shadow Crystals"))
assert(calls==2 and pet.Enchants[1].Id=="lucky")
''', 'Shadow Crystals: preserve slot 2 and honor a target change during confirmation')

inventory = source[source.index('\tlocal spaceOk, checkInventorySpace ='):source.index('\nend\ndo\n\tlocal function getPotionNames()')]
run('''
local activeStates, Config = {}, {selectedInventoryEgg="Cosmic Egg",autoHatchInventoryEgg=true}
local now, calls, cooldown, waiting, hasSpace = 0, 0, 0, false, true
local data = {Powerups={["Cosmic Egg"]=15}}
local profileStore = {IsReady=function()return true end,Get=function()return data end}
local function isCurrentRun()return true end
local function tick()return now end
local function getCurrentTimestamp()return now end
local require = function()return function()return hasSpace end end
local ReplicatedStorage = {Client={Gui={Utils={FindFirstChild=function(_, name) assert(name=="CheckInventorySpace"); return {} end}}}}
local giftData = {["Cosmic Egg"]={Type="Egg"}}
local LocalPlayer = {GetAttribute=function()return cooldown end}
local task = {spawn=function()end,wait=function(dt)
    now += dt; assert(now<40)
    if waiting then data={Powerups={["Cosmic Egg"]=math.max(0,data.Powerups["Cosmic Egg"]-12)}}; waiting=false end
end}
activeStates.BGSI_Lite_FireGameRemote = function(action,name,amount)
    assert(action=="HatchPowerupEgg" and name=="Cosmic Egg")
    assert(now>=cooldown,"Ignored game cooldown")
    calls+=1; assert(calls<=2,"Repeated stale inventory")
    assert(amount==(calls==1 and 12 or 3))
    assert(activeStates.BGSI_Lite_RunInventoryEggHatch()==0,"Concurrent worker")
    cooldown=now+0.5; waiting=true
end
''' + inventory + '''
assert(activeStates.BGSI_Lite_RunInventoryEggHatch()==15 and calls==2)
assert(not activeStates.BGSI_Lite_InventoryEggBusy)
data={Powerups={["Cosmic Egg"]=9}}; hasSpace=false
assert(activeStates.BGSI_Lite_RunInventoryEggHatch()==0 and calls==2)
hasSpace=true; local rejected=0
activeStates.BGSI_Lite_FireGameRemote=function()rejected+=1 end
assert(activeStates.BGSI_Lite_RunInventoryEggHatch()==9 and rejected==1)
assert(activeStates.BGSI_Lite_RunInventoryEggHatch()==0 and rejected==1,"Must back off after an unconfirmed request")
now+=3
Config.safeMode=true
assert(activeStates.BGSI_Lite_RunInventoryEggHatch()==0 and rejected==1)
''', 'Inventory: replacement profile tables, 12/3 batching, cooldown, space, concurrent calls, rejection backoff, safe mode')

comp = next(n.text.decode() for n in nodes if n.text.decode().startswith('do\n\tcompTab:AddSection'))
run('''
local activeStates = {}
local Config = {autoClaimCompHatches=true,autoClaimCompBubbles=true}
local labels, toggles, jobs, listener, buttons = {}, {}, {}, nil, {}
local now, running, claims, views = 0, true, {}, 0
local contribution={Team="Pink",Hatches=1500,Bubbles=1000000,Claims={}}
local profileStore={IsReady=function()return true end,Get=function()return {PinkVsBlue={["1"]=contribution}} end}
local LocalPlayer={UserId=42}
local competition={Enabled=true,Teams={Pink={Name="Seals"},Blue={Name="Frog Dogs"}}}
local season={Id="1",PersonalRewards={Hatches={{Requirement=500},{Requirement=1500},{Requirement=5000}},Bubbles={{Requirement=1000000},{Requirement=5000000}}}}
competition.GetSeason=function()return season end
local opened,minimized,canOpen=0,0,true
local frames={Open=function(_,name)assert(name=="PinkVsBlue");opened+=1 end,IsOpen=function()return canOpen end}
local scriptStateOG={Minimize=function()minimized+=1 end}
local popup={IsOpen=function(self)return not self.closed end,Close=function(self)self.closed=true end,Update=function(self,snapshot)self.snapshot=snapshot end}
local Interface={CreateCompetitionPopup=function()opened+=1;return popup end}
local warn=function()end
local require=function(module)if module==frames then return frames end;return competition end
local ReplicatedStorage={Shared={Data={FindFirstChild=function()return {} end}},Client={Gui={GuiFrame=frames}}}
local function tick()return now end
local function isCurrentRun()return running end
local function saveConfig()end
local task={spawn=function(fn)table.insert(jobs,coroutine.create(fn))end,wait=function(dt)now+=dt;coroutine.yield()end}
local compTab={AddSection=function()end,AddToggle=function(_,id,props)toggles[id]=props end,AddButton=function(_,props)buttons[props.Title]=props end,
AddParagraph=function(_,props)local p={value=props.Content,SetDesc=function(self,v)self.value=v end};labels[props.Title]=p;return p end}
local disconnected=false
local remoteEvent={OnClientEvent={Connect=function(_,fn)listener=fn;return {Disconnect=function()disconnected=true end}end},
FireServer=function(_,action,id,metric,index)
 if action=="PinkVsBlueView" then views+=1;return end
 assert(action=="PinkVsBlueClaim" and id=="1")
 local key="Personal:"..metric..":"..index
 assert(not claims[key],"Duplicate or unearned reward claim"); claims[key]=true
end}
''' + comp + '''
local function resume()local ok,err=coroutine.resume(jobs[1]);assert(ok,tostring(err))end
buttons["View Live Leaderboards"].Callback();assert(opened==1 and minimized==0)
resume()
listener("PinkVsBlueSnapshot",{Season=season,Standings={Boards={Pink={Hatches={{UserId=3,Score=2000},{UserId=42,Score=1000}},Bubbles={}}}}})
assert(popup.snapshot.Boards.Pink.Hatches[1].Score==2000,"Live push updates popup")
for i=1,4 do resume() end
assert(labels["Your Team"].value=="Seals")
assert(labels["Hatches"].value=="1500")
assert(labels["Hatch Place"].value=="#2")
assert(labels["Bubbles"].value=="1000000")
assert(labels["Bubble Place"].value=="#1")
assert(claims["Personal:Hatches:1"] and claims["Personal:Hatches:2"] and claims["Personal:Bubbles:1"])
assert(not claims["Personal:Hatches:3"] and not claims["Personal:Bubbles:2"])
assert(views>=1)
Config.safeMode=true; contribution.Hatches=99999
resume(); assert(not claims["Personal:Hatches:3"])
running=false; resume(); assert(disconnected)
buttons["View Live Leaderboards"].Callback();assert(opened==1 and popup.closed,"No actions after unload")
''', 'Comp: team placement, live contribution, eligible hatch/bubble rewards, pending dedupe, safe mode, cleanup')

run('''
local now, record, payload, applied = 100, nil, nil, 0
local fleet={role="alt",masterId="7",appliedRev=0}
local ALIVE_SECONDS, PREFIX, revFile, settingsFile = 20, "fleet_", "rev", "settings"
local Config={fleetFollowMaster=true}
local function tick()return now end
local function fileExists()return true end
local function readfile()return "1000:7" end
local function readJson(path)if path==settingsFile then return payload else return record end end
local function applyRemoteConfig()applied+=1; return true,1 end
local function writeHeartbeat()end
local function updateUi()end
local LocalPlayer={Name="fixture"}
local print=function()end
''' + nested_function('pullFromMaster') + '''
pullFromMaster(); assert(applied==0,"Absent leader")
payload={rev=1000,from="7",at=95,config={}}
record={lastSeen=50,startedAt=1}; pullFromMaster(); assert(applied==0,"Expired leader")
record={lastSeen=99,startedAt=1,stopped=true}; pullFromMaster(); assert(applied==0,"Stopped leader")
record={lastSeen=101,startedAt=1}; pullFromMaster(); assert(applied==0,"Future heartbeat")
record={lastSeen=99,startedAt=96}; pullFromMaster(); assert(applied==0,"Snapshot from previous leader session")
record={lastSeen=99,startedAt=90}; pullFromMaster(); assert(applied==1)
pullFromMaster(); assert(applied==1,"Same revision cannot overwrite local edits again")
''', 'Fleet: reject absent, expired, stopped, future and previous-session leaders; apply live leader only once')
