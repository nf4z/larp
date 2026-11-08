"""Embed the tested thumbnail resolver in Larplite's standalone source."""
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]

def generate():
    path=ROOT/'larplite.lua'
    if not path.exists():path=ROOT/'src/larplite.lua'
    source=path.read_text(encoding='utf-8')
    a=source.index('function sendPetWebhook(')
    b=source.index('function getRebirthMachineCost(',a)
    module=(ROOT/'shared_src/webhook-pet-icon.lua').read_text(encoding='utf-8')
    block='''function sendPetWebhook(info,shiny,mythic)
    local resolver=activeStates.BGSI_Lite_WebhookPetIconResolver
    if type(resolver)~="table" or resolver.Revision~=1 or resolver.Owner~=currentRunToken then
        resolver=(function()
__RESOLVER__
        end)()({
            Request=function(options)
                local env=(getgenv and getgenv()) or _G
                local fn=type(request)=="function" and request or type(http_request)=="function" and http_request
                    or (type(syn)=="table" and type(rawget(syn,"request"))=="function" and rawget(syn,"request"))
                    or (type(rawget(env,"request"))=="function" and rawget(env,"request"))
                    or (type(rawget(env,"http_request"))=="function" and rawget(env,"http_request"))
                if type(fn)~="function" then
                    local http=rawget(env,"http")
                    fn=type(http)=="table" and rawget(http,"request") or nil
                end
                if type(fn)=="function" then return fn(options) end
            end,
            HttpGet=function(url) return game:HttpGet(url,true) end,
            GetAsync=function(url) return HttpService:GetAsync(url,true) end,
            Decode=function(body) return HttpService:JSONDecode(body) end,
            Encode=function(value) return HttpService:JSONEncode(value) end,
            Now=os.clock,Wait=task.wait,
        })
        resolver.Owner=currentRunToken
        activeStates.BGSI_Lite_WebhookPetIconResolver=resolver
    end
    return resolver.Resolve(info,shiny,mythic)
end
'''.replace('__RESOLVER__',module)
    path.write_text(source[:a]+block+source[b:],encoding='utf-8')

if __name__=='__main__':generate()
