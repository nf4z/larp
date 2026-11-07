"""Verify typed icon descriptors and selected-only purchases against live stock/profile changes."""
from pathlib import Path
import subprocess,tempfile
ROOT=Path(__file__).resolve().parents[1]
source=(ROOT/'testhub_src/penguin-shop.lua').read_text(encoding='utf-8')
code=r'''
local task={spawn=function()end}
local function warn(value)error(value)end
local controls={}
local tab={}
for _,kind in ipairs({"Section","Paragraph","Dropdown","Toggle"})do
 tab[kind]=function(_,props)local c={Props=props,SetDesc=function(self,value)self.desc=value end};controls[props.Title]=c;return c end
end
local products={
 {Type="Powerup",Name="Shadow Crystal"},{Type="Potion",Name="Lucky",Level=7},
 {Type="Potion",Name="Speed",Level=7},{Type="Potion",Name="Mythic",Level=7},
 {Type="Potion",Name="Infinity Elixir"},{Type="Potion",Name="Secret Elixir"},{Type="Potion",Name="Ultra Infinity Elixir"},
 {Type="Powerup",Name="Green Fragment"},{Type="Powerup",Name="Blue Fragment"},{Type="Powerup",Name="Boost Crystal"}}
local items,stocks={},{}
for i,product in ipairs(products)do items[i]={Product=product,Cost={Type="Currency",Currency="Gems",Amount=10}};stocks[i]=5 end
local config={auto={keep=true}}
local state={Period=1,Bought={}}
local data={Shops={["winter-shop"]=state},Gems=1000}
local active,now,unlocked=true,0,10
local sent,saves={},0
local context={Window={Tab=function()return tab end},Settings=config,Save=function()saves+=1 end,
 Shops={["winter-shop"]={PermanentItems=items}},Profile={Get=function()return data end},Player={UserId=42},
 Active=function()return active end,Now=function()return now end,
 ItemUtil={GetName=function(_,item)return item.Name..(item.Level and (" "..item.Level)or"")end,CanAfford=function(_,d,cost)return d.Gems>=cost.Amount end},
 ShopUtil={GetItemsData=function(_,id,player,profile)assert(id=="winter-shop" and profile==data);return items,stocks end,GetUnlockedSlots=function()return unlocked end},
 Fire=function(...)table.insert(sent,table.pack(...))end}
local install=(function()
''' +source+r'''
end)()
local api=install(context)
assert(#api.Options==10)
for index,option in ipairs(api.Options)do
 assert(option.Item.Type==products[index].Type and option.Item.Name==products[index].Name and option.Item.Level==products[index].Level,"Each option supplies the exact native item/level for its icon")
end
api.Step();assert(#sent==0,"Opt in to purchases")
controls["Penguin Shop Items"].Props.Callback({"Powerup:Shadow Crystal:0:0","Potion:Mythic:7:0","invalid","Powerup:Shadow Crystal:0:0"})
assert(#config.penguinShop.items==2)
controls["Auto Buy Penguin Shop"].Props.Callback(true)
api.Step();api.Step();api.Step();assert(#sent==2,"Wait for stock confirmation instead of spamming")
for _,request in ipairs(sent)do assert(request[1]=="BuyShopItem" and request[2]=="winter-shop" and (request[3]==1 or request[3]==4) and request[4]==true)end
state.Bought[1]=5;state.Bought[4]=5;now=20;api.Step();assert(#sent==2,"No sold-out purchases")
state.Period=2;state.Bought={};data.Gems=0;api.Step();assert(#sent==2,"No unaffordable purchases")
data.Gems=1000;unlocked=1;api.Step();assert(#sent==3 and sent[3][3]==1,"Respect locked slots")
now=21;api.Step();assert(#sent==3)
now=31;api.Step();assert(#sent==4,"Retry a rejected/unconfirmed request after backoff")
controls["Auto Buy Penguin Shop"].Props.Callback(false);now=50;api.Step();assert(#sent==4)
active=false;config.penguinShop.autoBuy=true;api.Step();assert(#sent==4 and config.auto.keep)
assert(saves==3)
print("Penguin Shop: all 10 typed item icons, selections, stock/affordability/locks, restock period, pending dedupe, retry, config and unload: PASS")
'''
with tempfile.TemporaryDirectory()as d:
 p=Path(d)/'shop.lua';p.write_text(code,encoding='utf-8')
 r=subprocess.run([str(ROOT/'.tools/luau/luau.exe'),str(p)],capture_output=True,text=True)
 assert r.returncode==0,r.stdout+r.stderr
 print(r.stdout.strip())
