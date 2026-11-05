"""Generate the isolated Larplite hatch formatter from its pinned function snapshot."""
from pathlib import Path
import json,hashlib
ROOT=Path(__file__).resolve().parents[1]

def generate():
    upstream=json.loads((ROOT/'testhub_src/hatch-upstream.json').read_text(encoding='utf-8'))
    names=[entry['name'] for entry in upstream['functions']]
    code='''-- Generated from nf4z/larp core 2f0755df109e1b92c679 (2026.11.04.41).
-- Layout, fields, icons, numbers, colors and V2 renderer are kept from Larplite.
return function(ctx)
local LocalPlayer, Players = ctx.Player, ctx.Players
local ReplicatedStorage, HttpService, game = ctx.ReplicatedStorage, ctx.HttpService, ctx.Game
local profileStore, remoteFunction = ctx.Profile, ctx.RemoteFunction
local statsUtil, worldUtil = ctx.StatsUtil, ctx.WorldUtil
local eggDataModule, sharedConstants = ctx.Eggs, ctx.Constants
local getWebhookSuperLegendaryEnchantText = ctx.EnchantText
local getEnchantedSuperWebhookIcon = ctx.EnchantIcon
local rollSimulatedSuperEnchants = ctx.RollEnchants
local activeStates = setmetatable({
    BGSI_Lite_GetHatchPetName=ctx.GetName,
    BGSI_Lite_GetHatchPetFlag=ctx.GetFlag,
    BGSI_Lite_GetHatchPetValue=ctx.GetValue,
}, {__index=ctx.ActiveStates or {}})
'''+upstream['statEmojis']+'\nlocal '+', '.join(names)+'\n'
    for entry in upstream['functions']:
        text=entry['source']
        assert hashlib.sha256(text.encode()).hexdigest()==entry['sha256'],entry['name']
        if text.startswith('local function '):text=text[len('local '):]
        if entry['name']=='buildSimulatedHatchPayload':
            text=text.replace('function buildSimulatedHatchPayload(pet, info)', '''function buildSimulatedHatchPayload(pet, info, options)
    options=options or {}
    local Config={webhookHidePlayerName=options.hideUsername==true,webhookShowUserInfo=options.showUserInfo==true}''',1)
            text=text.replace('if super then\n\t\tpet.Enchants = rollSimulatedSuperEnchants(pet)', 'if super and options.simulated then\n\t\tpet.Enchants = rollSimulatedSuperEnchants(pet)',1)
            text=text.replace('getWebhookPetSource(pet, info)','getWebhookPetSource(pet, info, options.eventName, options.hatchResult)',1)
            text=text.replace('getPetVariantName(variantName, pet, 4)','getPetVariantName(variantName, pet, options.simulated and 4 or 8)',1)
            text=text.replace('getWebhookSuperLegendaryEnchantText({Enchants = pet.Enchants}, petName, shiny, mythic, xl)','getWebhookSuperLegendaryEnchantText(pet, petName, shiny, mythic, xl)',1)
        code+=text+'\n\n'
        if entry['name']=='formatWebhookNumber':code+='activeStates.BGSI_Lite_GetWebhookPetStatValue=function(value) return "x"..formatWebhookNumber(value,4) end\n'
    code+='''return {Build=buildSimulatedHatchPayload,Render=buildDiscordV2WebhookPayload,NormalizeURL=normalizeDiscordWebhookV2Url,
    GetOdds=function(pet,name,info,shiny,mythic,xl)
        local origin,isEgg=getWebhookPetSource(pet,info)
        if not isEgg then return nil,false end
        local _,percent=getWebhookHatchChances(name,info,origin,shiny,mythic,xl,ctx.GetFlag(pet,"Super"))
        return percent>0 and 100/percent or nil,percent>0
    end}
end
'''
    (ROOT/'testhub_src/hatch-formatter.lua').write_text(code,encoding='utf-8',newline='\n')
    return code
if __name__=='__main__':print('Larplite hatch formatter generated:',len(generate()),'characters')
