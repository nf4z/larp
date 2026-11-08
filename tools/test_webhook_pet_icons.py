"""Native PetBuilder fixtures, thumbnail failures, caching and actual Larplite V2 media."""
from pathlib import Path
import json,subprocess,tempfile
ROOT=Path(__file__).resolve().parents[1]
source=(ROOT/'larplite.lua').read_text(encoding='utf-8')
factory=(ROOT/'shared_src/webhook-pet-icon.lua').read_text(encoding='utf-8')
fixture=json.loads((ROOT/'tools/fixtures/native-pet-images.json').read_text(encoding='utf-8'))
wrapper=source[source.index('function sendPetWebhook('):source.index('function getRebirthMachineCost(')]
# Isolate the renderer declaration, excluding unrelated following statements.
from tree_sitter import Language,Parser
import tree_sitter_luau
parser=Parser(Language(tree_sitter_luau.language()))
tree=parser.parse(source.encode())
renderer=next(n.text.decode() for n in tree.root_node.named_children if n.type=='function_declaration' and n.text.startswith(b'function buildDiscordV2WebhookPayload('))
code='local install=(function()\n'+factory+'\nend)()\n'+r'''
local t1={};local T={string=function(v)return type(v)=='string'end,none=function(v)return v==nil end}
'''+fixture['builderImageFunction']+'\nlocal ids='+json.dumps(fixture['images']) .replace('[','{').replace(']','}')+r'''
local pet={};t1.Image(pet,'rbxassetid://'..ids[1],'rbxassetid://'..ids[2],'rbxassetid://'..ids[3],'rbxassetid://'..ids[4])
local info={Images=pet._images}
local now,calls,waits=0,0,0
local responses={}
local function decode(v)assert(responses[v],'Malformed JSON');return responses[v]end
local mode='ok'
local function response(options)
 calls+=1
 local id=options.Url:match('assetIds=(%d+)') or ids[1]
 if mode=='failure' then return {StatusCode=429,Body='bad'} end
 if mode=='html' then return {StatusCode=200,Body='<html>error</html>'}end
 local state=mode=='pending' and calls<3 and 'Pending' or mode=='blocked' and 'Blocked' or 'Completed'
 if mode=='batch' and options.Method~='POST' then state='Pending' end
 local token=tostring(calls)
 local entry={targetId=tonumber(id),state=state,imageUrl=state=='Completed' and 'https://tr.rbxcdn.com/'..id..'.png' or nil}
 responses[token]=options.Method=='POST' and {entry} or {data={entry}}
 return {StatusCode=200,Body=token}
end
local context={Request=response,HttpGet=function()error('blocked game HTTP')end,GetAsync=function()error('blocked native HTTP')end,
 Decode=decode,Encode=function()return 'encoded batch'end,Now=function()return now end,Wait=function()waits+=1 end}
local resolver=install(context)
for _,flags in ipairs({{false,false,1},{true,false,2},{false,true,3},{true,true,4}})do
 local url=resolver.Resolve(info,flags[1],flags[2]);assert(url=='https://tr.rbxcdn.com/'..ids[flags[3]]..'.png','Native named variant mapping')
end
local before=calls;resolver.Resolve(info,true,true);assert(calls==before,'Reuse cached icon')
local numeric=table.clone(context);numeric.Request=function(options)assert(options.Url:find('assetIds=124755896763618',1,true));return response(options)end
assert(install(numeric).Resolve({Images={Normal=124755896763618}},false,false))
assert(resolver.Resolve({Images={Normal='https://images.example/direct.png'}},false,false)=='https://images.example/direct.png')
assert(resolver.Resolve({Images={Normal='rbxthumb://type=Asset&id='..ids[1]..'&w=420&h=420'}},false,false))
assert(resolver.Resolve({Images={Normal='https://www.roblox.com/asset/?id='..ids[1]}},false,false))
assert(not resolver.Resolve({Images={Normal='rbxassetid://0'}},false,false))
mode='pending';calls=0;waits=0;local pending=install(context)
assert(pending.Resolve(info,false,false) and calls==3 and waits==2,'Retry pending thumbnails')
mode='batch';calls=0;local batch=install(context)
assert(batch.Resolve(info,false,false) and calls==4,'Fall back to the batch endpoint')
mode='blocked';calls=0;local blocked=install(context)
assert(not blocked.Resolve(info,false,false),'Never use a moderation placeholder')
before=calls;assert(not blocked.Resolve(info,false,false) and calls==before,'Briefly cache failures')
now=16;mode='ok';assert(blocked.Resolve(info,false,false) and calls>before,'Failure cache recovers')
local fallback=table.clone(context);local fallbackCalls=0
fallback.Request=function()return {StatusCode=403,Body='denied'}end
fallback.HttpGet=function()fallbackCalls+=1;return 'HTML error'end
fallback.GetAsync=function()fallbackCalls+=1;responses.native={data={{state='Completed',imageUrl='https://tr.rbxcdn.com/native.png'}}};return 'native'end
assert(install(fallback).Resolve(info,false,false)=='https://tr.rbxcdn.com/native.png' and fallbackCalls==2,'Try alternate transports after malformed/denied responses')
fallback.Request=function()return {status_code=200,body='native'}end
assert(install(fallback).Resolve(info,false,false)=='https://tr.rbxcdn.com/native.png','Executor lowercase response fields')
mode='html';calls=0;assert(not install(context).Resolve(info,false,false),'HTML responses cannot become Discord media')
mode='ok';calls=0;local bounded=install(context)
for i=1,300 do now+=0.01;assert(bounded.Resolve({Images={Normal=tostring(i)}},false,false))end
before=calls;bounded.Resolve({Images={Normal='1'}},false,false);assert(calls==before+1,'Bound the cache to 256 assets')
now=now+3601;before=calls;bounded.Resolve({Images={Normal='300'}},false,false);assert(calls==before+1,'Refresh expired CDN URLs')
local activeStates={}
local currentRunToken={}
local task={wait=function()end}
local game={HttpGet=function()error('Game HTTP unavailable')end}
local HttpService={JSONDecode=function(_,v)return decode(v)end,JSONEncode=function()return 'batch'end,GetAsync=function()error('Native HTTP unavailable')end}
local env={http={request=response}}
local request='unsupported placeholder'
local function getgenv()return env end
'''+wrapper+'\n'+renderer+r'''
calls=0
local icon=sendPetWebhook(info,true,true)
assert(icon=='https://tr.rbxcdn.com/'..ids[4]..'.png','Real wrapper uses executor http.request')
before=calls;sendPetWebhook(info,true,true);assert(calls==before,'Wrapper retains the resolver cache')
local previousResolver=activeStates.BGSI_Lite_WebhookPetIconResolver
currentRunToken={};sendPetWebhook(info,true,true)
assert(previousResolver~=activeStates.BGSI_Lite_WebhookPetIconResolver,'Reload must not retain callbacks into a previous module environment')
local normal=buildDiscordV2WebhookPayload({embeds={{description='Hatched pet',fields={{name='Pet Info',value='Example'}},thumbnail={url=icon}}}})
assert(normal.components[1].components[1].accessory.media.url==icon,'Normal pet thumbnail survives V2')
local xl=buildDiscordV2WebhookPayload({embeds={{description='Hatched XL',image={url=icon}}}})
assert(xl.components[1].components[3].items[1].media.url==icon,'XL uses the variant image in the media gallery')
print('Webhook pet icons: native game builder/variants, executor and native transports, pending/batch recovery, cache bounds/expiry, invalid/blocked responses, real wrapper and normal/XL Discord V2 media: PASS (offline)')
'''
with tempfile.TemporaryDirectory() as directory:
    path=Path(directory)/'icons.lua';path.write_text(code,encoding='utf-8')
    result=subprocess.run([str(ROOT/'.tools/luau/luau.exe'),str(path)],capture_output=True,text=True)
    assert result.returncode==0,result.stdout+result.stderr
    print(result.stdout.strip())
