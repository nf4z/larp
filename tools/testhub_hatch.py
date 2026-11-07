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
local customizeHatch=(function()
CUSTOMIZER
end)()
local function build(pet,options)
    options=options or {}
    local name,info,rarity,super,shiny,mythic,xl=describe(pet,options.info)
    local canonical=table.clone(pet)
    canonical.Name=name;canonical.Super=super;canonical.Shiny=shiny;canonical.Mythic=mythic;canonical.XL=xl
    options.showUserInfo=settings.webhook.showUserInfo~=false
    local envelope=LarpliteFormatter.Build(canonical,info,options)
    local profile
    pcall(function() if profileStore and profileStore:IsReady() then profile=profileStore:Get() end end)
    customizeHatch(envelope,options,settings.webhook,rarity,profile)
    local userId=getRebirthMachineCost(options.userId)
    if userId then envelope.content="<@"..userId..">";envelope.allowed_mentions={users={userId},parse={}} end
    return LarpliteFormatter.Render(envelope),envelope.embeds[1]
end
return {Build=build,Render=LarpliteFormatter.Render,NormalizeURL=LarpliteFormatter.NormalizeURL,
    Describe=describe,GetId=getPetId,MakeSimulation=makeSimulation,GetOdds=LarpliteFormatter.GetOdds}
'''.replace('FORMATTER',(ROOT/'testhub_src/hatch-formatter.lua').read_text(encoding='utf-8')).replace('CUSTOMIZER',(ROOT/'testhub_src/hatch-customization.lua').read_text(encoding='utf-8'))
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
local hatchHistory=(function()
__HATCH_HISTORY_MODULE__
end)()({UserId=player.UserId,Session=HttpService:GenerateGUID(false),
    Read=readfile,Write=writefile,List=listfiles,IsFolder=isfolder,MakeFolder=makefolder,
    Encode=function(value) return HttpService:JSONEncode(value) end,
    Decode=function(value) return HttpService:JSONDecode(value) end,
    Time=os.time,Warn=function(reason) warn("[@qtrzip] "..reason) end})
local function eligibleHatch(pet)
    local _,_,rarity,super=HatchWebhook.Describe(pet)
    return super or rarity=="Secret" or rarity=="Celestial" or rarity=="Infinity" or rarity=="Void"
end
local function processAcceptedHatch(pet,eventName,hatchResult)
    if not runtime.Active or not isCurrentWebhookGeneration() then return end
    local name,info,rarity,isSuper,isShiny,isMythic,isXL=HatchWebhook.Describe(pet)
    local hatchedCount=hatchHistory.Record(name,isSuper,isShiny,isMythic,isXL)
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
        petId=HatchWebhook.GetId(pet),eventName=eventName,hatchResult=hatchResult,hatchedCount=hatchedCount,
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

'''.replace('__HATCH_EVENT_MODULE__',(ROOT/'testhub_src/hatch-events.lua').read_text(encoding='utf-8')).replace('__HATCH_HISTORY_MODULE__',(ROOT/'testhub_src/hatch-history.lua').read_text(encoding='utf-8'))
    source=source[:a]+listener+source[b:]
    marker='WebhookTab:Section({ Title = "Settings" })'
    assert marker in source
    controls='''WebhookTab:Section({ Title = "Hatch Embed Customization" })
WebhookTab:Paragraph({Title="Shared Hatch History",Desc="Confirmed rare/Super hatches only, counted per exact pet variant across alts sharing this workspace. Saved in qtrzip_hatch_totals.json with separate history shards. Previews never count."})
'''
    for key,title,desc,default in [
        ('showRarity','Show Pet Rarity','Displays the rarity above the egg name.',True),
        ('showEggTotal','Show Egg Hatch Total','Uses this account\'s lifetime count for the source egg.',True),
        ('showPetHatchCount','Show Shared Pet Hatch Count','Your observed total for this variant across workspace alts, below Exist.',True),
        ('showPetStats','Show Pet Stats','Includes the pet\'s multiplier stats.',False),
        ('showUserInfo','Show User Info','Includes total eggs and current luck multipliers.',True),
        ('showCurrencies','Show Account Currencies','Includes bubbles, coins and gems in User Info.',False),
    ]:
        value=f'settings.webhook.{key}~=false' if default else f'settings.webhook.{key}==true'
        controls+=f'''WebhookTab:Toggle({{Title="{title}",Desc="{desc}",Value={value},
    Callback=function(value) settings.webhook.{key}=value;saveHubSettings() end}})
'''
    controls+='''WebhookTab:Input({Title="Embed Accent Color",Desc="Six hex digits, e.g. 00AAFF. Leave blank for variant colors.",Value=settings.webhook.embedColor or "",Placeholder="Automatic",
    Callback=function(value)
        local hex=tostring(value):gsub("^#","")
        if hex=="" or (#hex==6 and hex:match("^%x+$")) then settings.webhook.embedColor=hex;saveHubSettings() end
    end})
'''
    # Keep all destinations, mentions, filters and preview actions in the existing dedicated tab.
    source=source.replace('WebhookTab:Section({ Title = "Simulate Pet Hatch" })',controls+'\nWebhookTab:Section({ Title = "Preview Hatch Notification" })',1)
    source=source.replace('WebhookTab:Section({ Title = "Webhook Settings" })','WebhookTab:Section({ Title = "Webhook Destinations & Mentions" })',1)
    # Move the activity destination and enable control into the same webhook menu,
    # preserving their existing live local variables and saved config keys.
    a=source.index('ActivityTab:Input({\n    Title = "Activity Webhook URL"')
    b=source.index('-- ======================================\n-- AUTO-START SAVED TOGGLES',a)
    activity=source[a:b].replace('ActivityTab:','tab:').replace('Title = "Turn On/Turn Off"','Title = "Enable Activity Notifications"')
    source=source[:a]+'''ActivityTab:Paragraph({Title="Notification Settings",Desc="Activity webhook destination and enable control are in the Webhook tab."})
runtime.BuildActivityWebhookControls=function(tab)
    tab:Section({Title="Activity Notifications"})
'''+activity+'end\n\n'+source[b:]
    source=source.replace('print("[Webhook] Loaded!")','if runtime.BuildActivityWebhookControls then runtime.BuildActivityWebhookControls(WebhookTab) end\nprint("[Webhook] Loaded!")',1)
    source=source.replace('Hatch layout: classic Renoa embeds','Hatch layout: customizable native hatch cards; saved variant totals shared across workspace alts')
    return source
