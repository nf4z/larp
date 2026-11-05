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
