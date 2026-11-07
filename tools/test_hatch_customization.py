"""Offline tests: actual envelope/V2 customization and independent alt persistence."""
from pathlib import Path
import subprocess,tempfile
ROOT=Path(__file__).resolve().parents[1]
history=(ROOT/'testhub_src/hatch-history.lua').read_text(encoding='utf-8')
custom=(ROOT/'testhub_src/hatch-customization.lua').read_text(encoding='utf-8')
code='local history=(function()\n'+history+'\nend)()\nlocal customize=(function()\n'+custom+'\nend)()\n'+r'''
local files,encoded,serial,warnings={},{},0,{}
local function encode(value)
    serial+=1;encoded[tostring(serial)]=table.clone(value)
    encoded[tostring(serial)].pets=table.clone(value.pets)
    return tostring(serial)
end
local function decode(value) assert(encoded[value],'Corrupt JSON');return encoded[value] end
local function context(user,session)
    return {UserId=user,Session=session,Read=function(p) return files[p:gsub('\\','/')] end,
        Write=function(p,v) files[p]=v end,List=function(folder)
            local result={};for p in pairs(files) do if p:sub(1,#folder+1)==folder..'/' then local normalized=p:gsub('/','\\');table.insert(result,normalized) end end
            return result
        end,IsFolder=function() return true end,MakeFolder=function() end,
        Encode=encode,Decode=decode,Time=function() return 123 end,Warn=function(v) table.insert(warnings,v) end}
end
local a=history(context(1,'a'));local b=history(context(2,'b'))
assert(next(files)==nil,'Startup does not seed counts from inventory')
assert(a.Record('Pet',false,false,false,false)==1)
assert(b.Record('Pet',false,false,false,false)==2,'Another alt includes the first writer')
assert(a.Record('Pet',false,false,false,false)==3,'Concurrent writers retain both shards')
assert(b.Record('Pet',false,true,false,false)==1,'Variant totals remain distinct')
local reload=history(context(1,'reload'))
assert(reload.Record('Pet',false,false,false,false)==4,'Counts survive reloads')
local sameAccount=history(context(1,'other-session'))
assert(sameAccount.Record('Pet',false,false,false,false)==5,'Same-account sessions do not overwrite')
assert(decode(files['qtrzip_hatch_totals.json']).pets[a.Key('Pet',false,false,false,false)]==5)
files['qtrzip_hatch_history/broken.json']='broken'
assert(b.Record('Pet',false,false,false,false)==6,'A corrupt shard cannot erase healthy history')
assert(#warnings==1)
local unavailable=history({UserId=1,Session='unsupported',Time=os.time,Warn=function(v) table.insert(warnings,v) end})
assert(unavailable.Record('Pet',false,false,false,false)==1)
assert(unavailable.Record('Pet',false,false,false,false)==2)
assert(#warnings==2,'Warn once when persistence is unavailable')
local function envelope()
    return {embeds={{color=123,fields={
        {name='Pet Info',value='<:egg:1> Egg: **Example Egg**\n<:luck:2> Chance: **1 in 100**\n<:bubble:3> Bubbles: **x100**\n<:coin:4> Coins: **x10**\n<:enchant:5> Enchants: **Ultra Roller**\n\nExist: **9**'},
        {name='User Info',value='Current Bubbles: **10**\nCoins: **20**\nGems: **30**\nTotal Eggs: **1000**\nLuck: **x10**'}
    }}}}
end
local profile={EggsOpened={['Example Egg']=1234567,['Other Egg']=9000000}}
local result=customize(envelope(),{hatchedCount=1},{},'Secret',profile).embeds[1]
local text=result.fields[1].value
assert(text:sub(1,#'Rarity: **Secret**')=='Rarity: **Secret**')
assert(text:find('Eggs opened from this egg: **1,234,567**',1,true))
assert(text:find("Exist: **9**\nYou've hatched this pet 1 time",1,true))
assert(not text:find('Bubbles:',1,true) and not text:find('Coins:',1,true))
assert(text:find('Chance:',1,true) and text:find('Enchants:',1,true))
assert(result.fields[2].value=='Total Eggs: **1000**\nLuck: **x10**')
local all=customize(envelope(),{hatchedCount=25},{showPetStats=true,showCurrencies=true,embedColor='#00AAFF'},'Void',profile).embeds[1]
assert(all.color==43775 and all.fields[1].value:find("You've hatched this pet 25 times!",1,true))
assert(all.fields[1].value:find('Bubbles:',1,true) and all.fields[2].value:find('Coins:',1,true))
local hidden=customize(envelope(),{},{showRarity=false,showEggTotal=false,showPetHatchCount=false,embedColor='INVALID'},'Infinity',nil).embeds[1]
assert(hidden.color==123 and not hidden.fields[1].value:find('Rarity:',1,true))
assert(not hidden.fields[1].value:find('Eggs opened',1,true) and not hidden.fields[1].value:find('hatched this pet',1,true))
local preview=customize(envelope(),{simulated=true},{},'Celestial',{}).embeds[1].fields[1].value
assert(preview:find('Unavailable',1,true) and preview:find('Preview only (not counted)',1,true))
'''
built=(ROOT/'bgsiscript').read_text(encoding='utf-8')
listener=built[built.index('local hatchHistory=(function()'):built.index('runtime.HasPendingWebhooks=function()')]
code+=r'''
local jobs={}
files['qtrzip_hatch_history/broken.json']=nil
local task={spawn=function(fn) table.insert(jobs,fn) end}
local function flush() while #jobs>0 do table.remove(jobs,1)() end end
local io=context(42,'pipeline')
local readfile,writefile,listfiles,isfolder,makefolder=io.Read,io.Write,io.List,io.IsFolder,io.MakeFolder
local HttpService={GenerateGUID=function() return 'pipeline' end,JSONEncode=function(_,v) return encode(v) end,JSONDecode=function(_,v) return decode(v) end}
local player={UserId=42,Name='Player'}
local runtime={Active=true,Connect=function() end}
local dedup={}
local function onTestHubHatchDedupState() return dedup end
local function isCurrentWebhookGeneration() return true end
local muted=false
local function shouldSkipPet() return muted end
local function getPetOrigin() return 'Egg' end
local function getThreshold() return nil end
local HATCH_WEBHOOK_URL,PUBLIC_WEBHOOK_URL,DISCORD_USER_ID='','',''
local SKIP_PRIVATE_PETS={}
local hideUsername=false
local hatchQueue,publicQueue={},{}
local sends=0
local function processHatch() sends+=1 end
local function processPublic() error('Public webhook must stay disabled') end
local function warn(reason) error(reason) end
local HatchWebhook={
    Describe=function(p) p=p.Pet or p;return p.Name,{},p.Rarity or 'Common',false,false,false,false end,
    GetId=function(p) return p.Id end,
    Build=function(p,options) return {count=options.hatchedCount},{fields={}} end,
}
'''+listener+r'''
local function hatch(id) return {UserId=42,Name='Egg',Pets={{Pet={Id=id,Name='Pipeline Pet',Rarity='Secret'}}}} end
runtime.HatchEvents.Accept('InventoryUpdated',hatch('inventory'));flush()
assert(sends==0)
runtime.HatchEvents.Accept('HatchEgg',hatch('one'));flush()
assert(sends==0,'No endpoint never sends')
runtime.HatchEvents.Accept('HatchEgg',hatch('one'));flush()
muted=true;runtime.HatchEvents.Accept('HatchEgg',hatch('two'));flush()
muted=false;HATCH_WEBHOOK_URL='mock-endpoint'
runtime.HatchEvents.Accept('HatchEgg',hatch('three'));flush()
assert(sends==1 and #hatchQueue==1 and hatchQueue[1].count==3,'History includes muted/endpoint-free real hatches, ignores inventory and duplicate events')
runtime.Active=false;runtime.HatchEvents.Accept('HatchEgg',hatch('after-unload'));flush()
assert(sends==1)
print('Hatch customization/history: native per-egg totals, rarity, V2 settings, alt/session shards/reload, storage failures and real event listener with muted/endpoint-free hatches: PASS (offline)')
'''
with tempfile.TemporaryDirectory() as d:
    path=Path(d)/'hatch-customization.lua';path.write_text(code,encoding='utf-8')
    result=subprocess.run([str(ROOT/'.tools/luau/luau.exe'),str(path)],capture_output=True,text=True)
    assert result.returncode==0,result.stdout+result.stderr
    print(result.stdout.strip())
