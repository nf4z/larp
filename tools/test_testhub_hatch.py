"""Compare hatch cards with pinned Larplite and exercise the real bgsiscript bridge offline."""
from pathlib import Path
import json,subprocess,tempfile,hashlib
ROOT=Path(__file__).resolve().parents[1]
formatter=(ROOT/'testhub_src/hatch-formatter.lua').read_text(encoding='utf-8')
upstream=json.loads((ROOT/'testhub_src/hatch-upstream.json').read_text(encoding='utf-8'))
for entry in upstream['functions']:assert hashlib.sha256(entry['source'].encode()).hexdigest()==entry['sha256']
original=next(e['source'] for e in upstream['functions'] if e['name']=='buildSimulatedHatchPayload')
reference=formatter[:formatter.index('function buildSimulatedHatchPayload(')]+original+'\n'+formatter[formatter.index('return {Build=buildSimulatedHatchPayload'):]
reference=reference.replace('local getWebhookSuperLegendaryEnchantText =','local Config=ctx.Config\nlocal getWebhookSuperLegendaryEnchantText =',1)
script=(ROOT/'bgsiscript').read_text(encoding='utf-8')
a=script.index('local LarpliteFormatter=(function()');b=script.index('\nend)()\n-- End hatch webhook helper.',a)
bridge=script[a:b]
code=r'''
local function equal(a,b,path)
    path=path or 'payload'
    assert(type(a)==type(b),path..' type')
    if type(a)~='table' then assert(a==b,path..': '..tostring(a)..' ~= '..tostring(b));return end
    for k,v in pairs(a) do equal(v,b[k],path..'.'..tostring(k)) end
    for k,v in pairs(b) do assert(a[k]~=nil,path..' unexpected '..tostring(k)) end
end
local player={Name='Tester',FindFirstChild=function() return nil end}
local profile={IsReady=function() return true end,Get=function() return {Coins=1234,Gems=4321,Pearls=19,Tickets=7} end}
local function petName(p) return p.Name or 'Unknown' end
local function flag(p,k) return p[k]==true end
local petUtil={GetName=function(_,p)
    local parts={};for _,key in ipairs({'Super','XL','Shiny','Mythic'}) do if p[key] then table.insert(parts,key) end end
    table.insert(parts,p.Name);return table.concat(parts,' ')
end}
local storage={Shared={Utils={PetUtil=petUtil}}}
local info={Rarity='Secret',Egg='Example Egg',Stats={Bubbles=100,Coins=200,Gems=50,Pearls=1.25,CandyCorn26=7},Images={Normal='https://images.example/normal.png',Shiny='https://images.example/shiny.png',Mythic='https://images.example/mythic.png',MythicShiny='https://images.example/both.png'}}
local eggs={['Example Egg']={Pool={{Item={Type='Pet',Name='Example Pet'},Chance=0.01}}}}
local rolls=0
local context={Player=player,Players={LocalPlayer=player},ReplicatedStorage=storage,
    HttpService={JSONDecode=function() error('Unexpected network decode') end},
    Game={HttpGet=function() error('NETWORK FORBIDDEN') end},Profile=profile,
    RemoteFunction={InvokeServer=function(_,command,name) assert(command=='GetExisting');return {Count=123} end},
    StatsUtil={GetLuckMultiplier=function() return 2 end,GetSecretLuck=function() return 3 end,GetInfinityLuck=function() return 4 end},
    WorldUtil={GetPlayerWorld=function() return 'The Overworld' end},Eggs=eggs,
    Constants={ShinyChance=2.5,MythicChance=1,SuperChance=0.1,XLMultiplier=2.5,XLChances={Secret=0.4,Legendary=0.05}},
    GetName=petName,GetFlag=flag,GetValue=function(p,keys) for _,key in ipairs(keys) do if p[key]~=nil then return p[key] end end end,
    EnchantText=function(p) return '<:enchantments:1462135985759326370> Enchants: **Bubble Machine**',{'Bubble Machine'} end,
    EnchantIcon=function(url,names) assert(names[1]=='Bubble Machine');return 'https://images.example/composite.png' end,
    RollEnchants=function() rolls+=1;return {{Id='bubble-machine',Level=1}} end,
    ActiveStates={},Config={webhookShowUserInfo=false,webhookHidePlayerName=false},
}
local env=setmetatable({os={time=function() return 1700000000 end},require=function(module) return module end}, {__index=getfenv()})
local function loadFactory(source) local fn=assert(loadstring(source));setfenv(fn,env);return fn() end
'''
code+='local install=loadFactory('+json.dumps(formatter,ensure_ascii=False)+')\nlocal originalInstall=loadFactory('+json.dumps(reference,ensure_ascii=False)+')\n'
code+=r'''
local actual=install(context);local expected=originalInstall(context)
for _,variant in ipairs({{},{Shiny=true},{Mythic=true},{Shiny=true,Mythic=true},{XL=true},{Shiny=true,Mythic=true,XL=true},{Super=true}}) do
    local pet=table.clone(variant);pet.Name='Example Pet'
    local options={simulated=true}
    local result=actual.Build(pet,info,options)
    local originalPet=table.clone(variant);originalPet.Name='Example Pet'
    equal(result,expected.Build(originalPet,info),'exact Larplite hatch')
    equal(actual.Render(result),expected.Render(result),'exact Larplite V2')
end
local pet={Name='Example Pet',Shiny=true,Mythic=true,XL=true}
local envelope=actual.Build(pet,info,{})
assert(envelope.embeds[1].color==0x00FF00 and envelope.embeds[1].image.url=='https://images.example/both.png' and not envelope.embeds[1].thumbnail)
assert(envelope.embeds[1].fields[1].value:find('x562.5',1,true),'Use the variant stat multiplier')
local formatted=actual.Render(envelope);assert(formatted.flags==32768 and formatted.embeds==nil)
local gallery=false;for _,component in ipairs(formatted.components[1].components) do if component.type==12 then gallery=true end end;assert(gallery)
local realSuper={Name='Example Pet',Super=true,Enchants={{Id='actual-hatch'}}};local before=rolls
actual.Build(realSuper,info,{});assert(rolls==before and realSuper.Enchants[1].Id=='actual-hatch','Never reroll real hatch enchants')
context.Config.webhookHidePlayerName=true;context.Config.webhookShowUserInfo=true
local shown=actual.Build({Name='Example Pet'},info,{showUserInfo=true,hideUsername=true})
equal(shown,expected.Build({Name='Example Pet'},info),'optional user info and privacy')
assert(shown.embeds[1].description=='# **Player hatched a Example Pet**')
assert(shown.embeds[1].fields[1].name=='User Info' and shown.embeds[1].fields[2].name=='Pet Info')
local rewardInfo=table.clone(info);rewardInfo.Egg=nil;rewardInfo.Tag='Rebirth Machine'
local reward=actual.Build({Name='Reward Pet'},rewardInfo,{})
assert(reward.embeds[1].fields[1].value:find('Rebirth Machine',1,true) and not reward.embeds[1].fields[1].value:find('Chance:',1,true))
assert(actual.NormalizeURL('https://discord.com/api/webhooks/example')=='https://discord.com/api/webhooks/example?with_components=true&wait=true')
local statsUtil,worldUtil=context.StatsUtil,context.WorldUtil
local ReplicatedStorage,HttpService,Players,game=storage,context.HttpService,context.Players,context.Game
local profileStore,remoteFunction,eggData,sharedConstants=profile,context.RemoteFunction,eggs,context.Constants
local activeStates,getName,getFlag,getValue=context.ActiveStates,context.GetName,context.GetFlag,context.GetValue
local getWebhookSuperLegendaryEnchantText,getEnchantedSuperWebhookIcon,rollSimulatedSuperEnchants=context.EnchantText,context.EnchantIcon,context.RollEnchants
local settings={webhook={showUserInfo=false}}
local function describe(p,meta) return p.Name,meta or info,(meta or info).Rarity,p.Super==true,p.Shiny==true,p.Mythic==true,p.XL==true end
local function getRebirthMachineCost(value) return type(value)=='string' and #value>=15 and value or nil end
local function getPetId(p) return p.Id end
local function makeSimulation() end
local bridgeModule=(function()
'''+bridge+r'''
end)()
local payload,embed=bridgeModule.Build({Name='Example Pet'},{info=info,userId='123456789012345678'})
assert(payload.flags==32768 and embed.fields[1].name=='Pet Info')
assert(payload.allowed_mentions.users[1]=='123456789012345678' and #payload.allowed_mentions.parse==0)
assert(payload.components[1].components[1].content=='<@123456789012345678>')
settings.webhook.showUserInfo=true
local _,withInfo=bridgeModule.Build({Name='Example Pet'},{info=info,hideUsername=true})
assert(withInfo.fields[1].name=='User Info' and withInfo.description=='# **Player hatched a Example Pet**')
print('Larplite parity: normal/variant/XL/Super cards, fields/emojis/colors/images/odds/stats, privacy/User Info, V2, mentions and real bridge: PASS (offline)')
'''
with tempfile.TemporaryDirectory() as d:
    p=Path(d)/'hatch.lua';p.write_text(code,encoding='utf-8')
    result=subprocess.run([str(ROOT/'.tools/luau/luau.exe'),str(p)],capture_output=True,text=True)
    if result.returncode:
        import re
        match=re.search(r'hatch.lua:(\d+)',result.stderr)
        if match:
            n=int(match[1]);print('\n'.join(f'{i+1}: {line[:200]}' for i,line in enumerate(code.splitlines()) if abs(i+1-n)<3))
    assert result.returncode==0,result.stdout+result.stderr
    print(result.stdout.strip())
