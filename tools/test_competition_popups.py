"""Exercise both real popup renderers: 100 rows per team, switching, updates, reuse and teardown."""
from pathlib import Path
import json, subprocess, tempfile
from tree_sitter import Language,Parser
import tree_sitter_luau

ROOT=Path(__file__).resolve().parents[1]
mock=(ROOT/'testhub_src/mock-roblox.lua').read_text(encoding='utf-8')
adapter=(ROOT/'testhub_src/native-ui.lua').read_text(encoding='utf-8')
lite_path=ROOT/'larplite.lua'
if not lite_path.exists():lite_path=ROOT/'src/larplite.lua'
tree=Parser(Language(tree_sitter_luau.language())).parse(lite_path.read_bytes())
def find(node):
 if node.type=='function_declaration' and node.text.decode().startswith('function Interface:CreateCompetitionPopup('):return node.text.decode()
 for child in node.named_children:
  result=find(child)
  if result:return result
rf=find(tree.root_node)
assert rf
code='local mock=(function()\n'+mock+'\nend)()\n'
code+=r'''
local I=mock.env.Instance
local function child(parent,class,name)local n=I.new(class,parent);n.Name=name;return n end
local comp=child(mock.playerGui.ScreenGui,"Frame","PinkVsBlue")
local f=child(comp,"Frame","Frame")
child(f,"ImageLabel","Background").Image="native-comp-art"
child(child(f,"Frame","Top"),"TextLabel","NameLabel")
child(child(f,"Frame","Close"),"TextButton","Button")
child(f,"Frame","Sidebar")
local columns=child(child(child(f,"Frame","Body"),"Frame","Boards"),"Frame","Columns")
child(columns,"Frame","Locked")
for _,team in ipairs({"Pink","Blue"})do
 local c=child(columns,"Frame",team)
 for _,name in ipairs({"Title","Total","Empty"})do child(c,"TextLabel",name)end
 local list=child(c,"ScrollingFrame","List");child(list,"UIListLayout","UIListLayout")
 local template=child(list,"Frame","Template")
 for _,name in ipairs({"Rank","Username","Score"})do child(template,"TextLabel",name)end
 child(template,"ImageLabel","Avatar")
end
local definition={Teams={Pink={Name="Seals",Shield="rbxassetid://105235648283544"},Blue={Name="Frog Dogs",Shield="rbxassetid://81317703874820"}}}
local data={Boards={Pink={Hatches={},Bubbles={}},Blue={Hatches={},Bubbles={}}},Totals={Pink={Hatches=100000,Bubbles=200000},Blue={Hatches=300000,Bubbles=400000}}}
for _,team in ipairs({"Pink","Blue"})do
 for i=1,105 do
  data.Boards[team].Hatches[i]={UserId=i,Name=team..i,Score=10000-i}
  data.Boards[team].Bubbles[i]={UserId=i+1000,Name="Bubble"..i,Score=100000-i}
 end
end
'''
code+='local fn=assert(loadstring('+json.dumps(adapter)+'));setfenv(fn,mock.env);local ui=fn();ui:CreateWindow({})\n'
code+=r'''
local popup=assert(ui:CreateCompetitionPopup({}))
assert(popup.Frame.Background.Image=="native-comp-art" and not popup.Frame:FindFirstChild("Sidebar"))
popup:Update(data,definition)
assert(#popup.Rows.Pink==100 and #popup.Rows.Blue==100)
assert(popup.Rows.Pink[1].Username.Text=="Pink1" and popup.Rows.Blue[100].Rank.Text=="#100")
assert(popup.Rows.Pink[1].Avatar.Image=="rbxthumb://type=AvatarHeadShot&id=1&w=100&h=100")
assert(popup.Rows.Blue[100].Avatar.Image=="rbxthumb://type=AvatarHeadShot&id=100&w=100&h=100")
assert(popup.Rows.Pink[1].Avatar.Size.X.Offset==30 and popup.Rows.Pink[1].Username.Position.X.Offset==82)
assert(popup.Columns.Pink.Icon.Image==definition.Teams.Pink.Shield and popup.Columns.Blue.Icon.Image==definition.Teams.Blue.Shield)
assert(popup.Columns.Blue.Frame.Title.Position.X.Offset==64 and popup.Columns.Blue.Frame.Total.Position.X.Offset==64)
assert(popup.Frame.Close.Size.X.Offset==42 and popup.Frame.Close.Position.X.Offset==-14 and popup.Frame.Close.Position.Y.Offset==10)
assert(popup.CloseButton.Size.X.Scale==1 and popup.CloseButton.AnchorPoint.X==0.5 and popup.CloseButton.Position.X.Scale==0.5)
for _,node in ipairs(popup.CloseButton:GetChildren())do
 if node:IsA("ImageLabel") or node:IsA("TextLabel") then assert(node.Size.X.Offset==28 and node.Position.X.Scale==0.5)end
end
local first=popup.Rows.Pink[1]
popup.Columns.Pink.List.CanvasPosition=mock.vector(0,700)
data.Boards.Pink.Hatches[1].Name="UpdatedName";data.Boards.Pink.Hatches[1].Score=123456
popup:Update(data,definition)
assert(popup.Rows.Pink[1]==first and first.Username.Text=="UpdatedName")
assert(popup.Columns.Pink.List.CanvasPosition.Y==700,"Keep scroll while live data changes")
for _,node in ipairs(popup.Frame:GetDescendants())do
 if node:IsA("GuiButton") and node:FindFirstChild("Label") and node.Label.Text=="Bubbles" then node.Activated:Fire()end
end
assert(popup.Metric=="Bubbles" and popup.Rows.Blue[1].Username.Text=="Bubble1")
assert(popup.Rows.Blue[1].Avatar.Image=="rbxthumb://type=AvatarHeadShot&id=1001&w=100&h=100","Headshot follows metric/player changes")
assert(ui:CreateCompetitionPopup({})==popup,"Reuse open popup")
data.Boards.Blue.Bubbles={};popup:Update(data,definition);assert(not popup.Rows.Blue[1].Visible and popup.Columns.Blue.Frame.Empty.Visible)
popup.CloseButton.Activated:Fire();assert(not popup:IsOpen() and #popup.Rows.Pink==0 and #popup.Connections==0)
ui:CreateCompetitionPopup({});ui:Destroy();assert(not ui.CompetitionPopup)
local rfwindow={}
function rfwindow:Create(class,props)
 local n=I.new(class);for key,value in pairs(props)do n[key]=value end;return n
end
function rfwindow:Connect(signal,fn)return signal:Connect(fn)end
function rfwindow:Popup()
 local screen=child(mock.playerGui,"ScreenGui","RfPopup")
 local card=child(screen,"Frame","Card");child(card,"Frame","Header");child(card,"Frame","Footer")
 local shell={screenGui=screen,card=card,_connections={}}
 function shell:Close()self._closed=true;for _,c in ipairs(self._connections)do c:Disconnect()end;screen:Destroy()end
 return shell
end
'''
code+='local build=assert(loadstring('+json.dumps('local rayfieldWindow,Workspace,Interface=...\n'+rf+'\nreturn Interface')+'));setfenv(build,mock.env);local interface=build(rfwindow,mock.workspace,{})\n'
code+=r'''
local rp=assert(interface:CreateCompetitionPopup({}));rp:Update(data,definition)
assert(#rp.Rows.Pink==100 and #rp.Rows.Blue==100)
assert(rp.Columns.Pink.Title.Text=="Seals" and rp.Columns.Blue.Title.Text=="Frog Dogs")
local row=rp.Rows.Pink[1];data.Boards.Pink.Hatches[1].Score=987654;rp:Update(data,definition)
assert(rp.Rows.Pink[1]==row and row.Score.Text=="987,654")
for _,node in ipairs(rp.Shell.card:GetChildren())do if node:IsA("TextButton") and node.Text=="Bubbles" then node.Activated:Fire()end end
assert(rp.Metric=="Bubbles" and rp.Rows.Pink[1].Name.Text=="Bubble1")
rp:Close();assert(not rp:IsOpen() and #rp.Rows.Pink==0)
print("Native Comp clone and Rayfield popout: both teams/top 100, hatch/bubble switch, live score/name update, row reuse, scroll preservation and cleanup: PASS")
'''
with tempfile.TemporaryDirectory()as d:
 p=Path(d)/'popups.lua';p.write_text(code,encoding='utf-8')
 r=subprocess.run([str(ROOT/'.tools/luau/luau.exe'),str(p)],capture_output=True,text=True)
 assert r.returncode==0,r.stdout+r.stderr
 print(r.stdout.strip())
