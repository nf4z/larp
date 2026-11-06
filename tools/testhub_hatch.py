"""Replace the old hatch card with the pinned Larplite formatter and its UI options."""
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
def port_hatch(source):
    a=source.index('local function formatRenoaOdds(')
    b=source.index('\nend)()\n-- End hatch webhook helper.',a)
    bridge='''local LarpliteFormatter=(function()
FORMATTER
end)()({Player=player,Players=Players,ReplicatedStorage=ReplicatedStorage,HttpService=HttpService,Game=game,
    Profile=profileStore,RemoteFunction=remoteFunction,StatsUtil=statsUtil,WorldUtil=worldUtil,
    Eggs=eggData,Constants=sharedConstants,ActiveStates=activeStates,
    GetName=getName,GetFlag=getFlag,GetValue=getValue,
    EnchantText=getWebhookSuperLegendaryEnchantText,EnchantIcon=getEnchantedSuperWebhookIcon,
    RollEnchants=rollSimulatedSuperEnchants})
local function build(pet,options)
    options=options or {}
    local name,info,rarity,super,shiny,mythic,xl=describe(pet,options.info)
    local canonical=table.clone(pet)
    canonical.Name=name;canonical.Super=super;canonical.Shiny=shiny;canonical.Mythic=mythic;canonical.XL=xl
    options.showUserInfo=settings.webhook.showUserInfo==true
    local envelope=LarpliteFormatter.Build(canonical,info,options)
    local userId=getRebirthMachineCost(options.userId)
    if userId then envelope.content="<@"..userId..">";envelope.allowed_mentions={users={userId},parse={}} end
    return LarpliteFormatter.Render(envelope),envelope.embeds[1]
end
return {Build=build,Render=LarpliteFormatter.Render,NormalizeURL=LarpliteFormatter.NormalizeURL,
    Describe=describe,GetId=getPetId,MakeSimulation=makeSimulation,GetOdds=LarpliteFormatter.GetOdds}
'''.replace('FORMATTER',(ROOT/'testhub_src/hatch-formatter.lua').read_text(encoding='utf-8'))
    source=source[:a]+bridge+source[b:]
    source=source.replace('                    debugStats = getDebugStats(),','')
    source=source.replace('simulated = true, debugStats = getDebugStats(),','simulated = true,')
    source=source.replace('local visibleName = hideUsername and "Hidden" or player.Name','local visibleName = hideUsername and "Player" or player.Name')
    source=source.replace('publicEmbed.description = "# **Hidden"','publicEmbed.description = "# **Player"')
    source=source.replace('local response = request({\n                    Url = url,','local response = request({\n                    Url = payload.flags==32768 and HatchWebhook.NormalizeURL(url) or url,')
    a=source.rfind('-- ======================================',0,source.index('-- FULL INVENTORY SCANNER'))
    b=source.rfind('-- ======================================',0,source.index('-- 4X EGG SCANNER',a))
    listener='''-- ======================================
-- ACCEPTED HATCH EVENTS ONLY (never inventory differences)
-- ======================================
local function eligibleHatch(pet)
    local _,_,rarity,super=HatchWebhook.Describe(pet)
    return super or rarity=="Secret" or rarity=="Celestial" or rarity=="Infinity" or rarity=="Void"
end
local function processAcceptedHatch(pet,eventName,hatchResult)
    if not runtime.Active or not isCurrentWebhookGeneration() then return end
    local name,info,rarity,isSuper,isShiny,isMythic,isXL=HatchWebhook.Describe(pet)
    local origin=getPetOrigin(info)
    if shouldSkipPet(origin,rarity) then return end
    local shouldSendPrivate=not SKIP_PRIVATE_PETS[name]
    local threshold=getThreshold()
    local isInfinityOrVoid=rarity=="Infinity" or rarity=="Void"
    if threshold and not isSuper and not isXL and not isInfinityOrVoid and not isOriginBypass(origin,rarity) then
        local oneIn,known=HatchWebhook.GetOdds(pet,name,info,isShiny,isMythic,isXL)
        if known and oneIn<=threshold then shouldSendPrivate=false end
    end
    if not (shouldSendPrivate and HATCH_WEBHOOK_URL~="") and PUBLIC_WEBHOOK_URL=="" then return end
    local payload,embed=HatchWebhook.Build(pet,{
        info=info,hideUsername=hideUsername,userId=shouldSendPrivate and DISCORD_USER_ID or "",
        petId=HatchWebhook.GetId(pet),eventName=eventName,hatchResult=hatchResult,
    })
    if not runtime.Active then return end
    if shouldSendPrivate and HATCH_WEBHOOK_URL~="" then table.insert(hatchQueue,payload);processHatch() end
    if PUBLIC_WEBHOOK_URL~="" then
        local publicEmbed=table.clone(embed);publicEmbed.fields=table.clone(embed.fields)
        local visibleName=hideUsername and "Player" or player.Name
        local prefix="# **"..visibleName
        if type(publicEmbed.description)=="string" and publicEmbed.description:sub(1,#prefix)==prefix then
            publicEmbed.description="# **Player"..publicEmbed.description:sub(#prefix+1)
        end
        table.insert(publicQueue,HatchWebhook.Render({embeds={publicEmbed}}));processPublic()
    end
end
local makeHatchEvents=(function()
__HATCH_EVENT_MODULE__
end)()
runtime.HatchEvents=makeHatchEvents({
    State=onTestHubHatchDedupState(),UserId=player.UserId,Now=os.clock,
    Active=function() return runtime.Active and isCurrentWebhookGeneration() end,
    Id=function(pet) return HatchWebhook.GetId(type(pet.Pet)=="table" and pet.Pet or pet) end,Name=function(pet) return HatchWebhook.Describe(pet) end,
    Eligible=eligibleHatch,OnPet=processAcceptedHatch,
    Error=function(reason) warn("[@qtrzip] Hatch notification: "..tostring(reason)) end,
})
runtime.HasPendingWebhooks=function()
    return runtime.HatchEvents:IsBusy() or hatchProcessing or publicProcessing or #hatchQueue>0 or #publicQueue>0
end
runtime.Connect(ReplicatedStorage.Shared.Framework.Network.Remote.RemoteEvent.OnClientEvent,runtime.HatchEvents.Accept)

'''.replace('__HATCH_EVENT_MODULE__',(ROOT/'testhub_src/hatch-events.lua').read_text(encoding='utf-8'))
    source=source[:a]+listener+source[b:]
    marker='WebhookTab:Section({ Title = "Settings" })'
    assert marker in source
    source=source.replace(marker,'''WebhookTab:Section({ Title = "Hatch Embed" })
WebhookTab:Toggle({
    Title = "Show User Info",Desc = "Adds Larplite's account currencies, hatch count and luck section.",
    Value = settings.webhook.showUserInfo==true,
    Callback = function(value) settings.webhook.showUserInfo=value;saveHubSettings() end,
})
'''+marker,1)
    return source
