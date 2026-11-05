-- Deterministic UI event harness. This does not emulate Roblox rendering/networking.
local function signal()
	local listeners = {}
	return {
		Connect = function(_, fn)
			local connection = {Connected = true}
			function connection:Disconnect() self.Connected = false end
			table.insert(listeners, {fn, connection})
			return connection
		end,
		Fire = function(_, ...)
			for _, entry in ipairs(table.clone(listeners)) do if entry[2].Connected then entry[1](...) end end
		end,
	}
end
local vectorMT = {}
vectorMT.__index = vectorMT
vectorMT.__add = function(a,b) return setmetatable({X=a.X+b.X,Y=a.Y+b.Y,Z=(a.Z or 0)+(b.Z or 0)},vectorMT) end
vectorMT.__sub = function(a,b) return setmetatable({X=a.X-b.X,Y=a.Y-b.Y,Z=(a.Z or 0)-(b.Z or 0)},vectorMT) end
vectorMT.__div = function(a,b) return setmetatable({X=a.X/b,Y=a.Y/b,Z=(a.Z or 0)/b},vectorMT) end
local function vector(x,y,z) return setmetatable({X=x or 0,Y=y or 0,Z=z or 0},vectorMT) end
local Vector2 = {new=vector,zero=vector(),one=vector(1,1)}
local Vector3 = {new=vector}
local UDim = {new=function(s,o) return {Scale=s or 0,Offset=o or 0} end}
local UDim2 = {
	new=function(xs,xo,ys,yo) return {X=UDim.new(xs,xo),Y=UDim.new(ys,yo)} end,
	fromOffset=function(x,y) return {X=UDim.new(0,x),Y=UDim.new(0,y)} end,
	fromScale=function(x,y) return {X=UDim.new(x,0),Y=UDim.new(y,0)} end,
}
local Enum = setmetatable({}, {__index=function(t,k)
	local group=setmetatable({}, {__index=function(g,v) rawset(g,v,k.."."..v);return k.."."..v end});rawset(t,k,group);return group
end})
local Color3 = {new=function(...) return {...} end,fromRGB=function(...) return {...} end,fromHex=function(value) return {value} end}
local ColorSequence = {new=function(...) return {...} end}
local Font = {fromEnum=function(value) return value end}
local CFrame = {lookAt=function(position) return {Position=position} end}
local methods, instanceMT, counters = {}, {}, {clones=0,created=0,icons=0,cleaned=0}
local Instance = {}
function Instance.new(class,parent)
	counters.created+=1
	local object = setmetatable({_class=class,_children={},_signals={},_props={
		Name=class,Archivable=true,Visible=true,ZIndex=1,Size=UDim2.fromOffset(100,100),
		Position=UDim2.fromOffset(0,0),AbsolutePosition=vector(250,180),AbsoluteSize=vector(192,38),
		CanvasPosition=vector(),AbsoluteContentSize=vector(),Text="",TextSize=28,FontFace="NativeFont",ViewportSize=vector(1100,800),
	}},instanceMT)
	object.Parent=parent;return object
end
local guiClasses = {Frame=true,ImageLabel=true,TextLabel=true,ImageButton=true,TextButton=true,TextBox=true,ScrollingFrame=true,ViewportFrame=true}
function methods:IsA(class) return self._class==class or class=="GuiObject" and guiClasses[self._class] or class=="GuiButton" and (self._class=="ImageButton" or self._class=="TextButton") or class=="BasePart" and self._class=="Part" end
function methods:GetChildren() return table.clone(self._children) end
function methods:GetDescendants()
	local result={}
	for _, child in ipairs(self._children) do table.insert(result,child);for _,inner in ipairs(child:GetDescendants()) do table.insert(result,inner) end end
	return result
end
function methods:FindFirstChild(name,recursive)
	for _,child in ipairs(self._children) do if child.Name==name then return child end end
	if recursive then for _,child in ipairs(self:GetDescendants()) do if child.Name==name then return child end end end
end
function methods:WaitForChild(name,_) return self:FindFirstChild(name) end
function methods:FindFirstChildOfClass(class)
	for _,child in ipairs(self._children) do if child:IsA(class) then return child end end
end
function methods:FindFirstChildWhichIsA(class,recursive)
	for _,child in ipairs(recursive and self:GetDescendants() or self._children) do if child:IsA(class) then return child end end
end
function methods:GetAttributeChangedSignal(name)
    local key="attribute:"..name
    if not self._signals[key] then self._signals[key]=signal() end
    return self._signals[key]
end
function methods:GetPropertyChangedSignal(name)
	local key="property:"..name
	if not self._signals[key] then self._signals[key]=signal() end
	return self._signals[key]
end
function methods:Clone()
	counters.clones+=1
	local clone=Instance.new(self._class)
	for k,v in pairs(self._props) do if k~="Parent" then clone._props[k]=v end end
	for _,child in ipairs(self._children) do child:Clone().Parent=clone end
	return clone
end
function methods:Destroy()
	if self._signals.Destroying then self._signals.Destroying:Fire() end
	for _,child in ipairs(self:GetChildren()) do child:Destroy() end
	self.Parent=nil;self._destroyed=true
	-- Tests discard instance-owned listeners when destroying popup trees.
	self._signals={}
end
function methods:GetBoundingBox() return {Position=vector()},vector(2,3,2) end
function methods:GetFocusedTextBox() return self._focused end
function methods:TypeText(value)
	if not self:IsA("TextBox") or self.TextEditable~=true or self.Active==false or self.Interactable==false then return false end
	self.Text=value;return true
end
function methods:Click()
	if not self:IsA("GuiButton") or self.Active == false then return false end
	local current=self
	while current do
		if current:IsA("GuiObject") and (current.Interactable==false or current.Visible==false) then return false end
		current=current.Parent
	end
	self.Activated:Fire();return true
end
function methods:SetAttribute(name,value) self._attributes=self._attributes or {};self._attributes[name]=value;local changed=self._signals["attribute:"..name];if changed then changed:Fire() end end
function methods:GetAttribute(name) return self._attributes and self._attributes[name] end
instanceMT.__index=function(self,key)
	if self._class=="ScreenGui" and key=="ZIndex" then error("ZIndex is not a valid member of ScreenGui") end
	if methods[key] then return methods[key] end
	if self._props[key]~=nil then return self._props[key] end
	if key=="MouseEnter" or key=="MouseLeave" or key=="MouseButton1Down" or key=="MouseButton1Up" or key=="Activated" or key=="InputBegan" or key=="InputEnded" or key=="InputChanged" or key=="FocusLost" or key=="Idled" or key=="Destroying" then
		if not self._signals[key] then self._signals[key]=signal() end
		return self._signals[key]
	end
	return self:FindFirstChild(key)
end
instanceMT.__newindex=function(self,key,value)
	if self._class=="ScreenGui" and key=="ZIndex" then error("ZIndex is not a valid member of ScreenGui") end
	if key:sub(1,1)=="_" then rawset(self,key,value);return end
	local previous=self._props[key]
	if key=="Parent" and previous~=value then
		if previous then local i=table.find(previous._children,self);if i then table.remove(previous._children,i) end end
		if value then table.insert(value._children,self) end
	end
	self._props[key]=value
	if previous~=value then
		local changed=self._signals["property:"..key];if changed then changed:Fire() end
	end
end
local function child(parent,class,name)
	local object=Instance.new(class);object.Name=name;object.Parent=parent;return object
end
local storage=Instance.new("ReplicatedStorage")
local assets=child(storage,"Folder","Assets")
local shared=child(storage,"Folder","Shared")
local data=child(shared,"Folder","Data")
local utils=child(shared,"Folder","Utils");local stats=child(utils,"Folder","Stats")
local itemUtil=child(stats,"ModuleScript","ItemUtil")
itemUtil._module={UpdateIcon=function(_,host,item)
	if not item then counters.cleaned+=1;return end
	counters.icons+=1;host.Label.AnchorPoint=vector(0.5,0.5);host.Label.Image="item:"..tostring(item.Name or item.Currency)
end}
child(shared,"ModuleScript","Constants")._module={UnknownImage="unknown"}
local eggs=child(data,"ModuleScript","Eggs");eggs._module={}
for i=1,1000 do eggs._module["Egg "..i]={Image="rbxassetid://"..i} end
child(data,"ModuleScript","Potions")._module={Lucky={},["Infinity Elixir"]={Image="infinity-elixir"}}
child(data,"ModuleScript","Powerups")._module={["Mystery Box"]={Icon="box"},["Dice Key"]={Icon="dice-key"},["Giant Dice"]={Icon="giant-dice"},["Golden Dice"]={Icon="gold-dice"}}
child(data,"ModuleScript","Pets")._module={Dog={}}
child(data,"ModuleScript","Runes")._module={Luck={}}
child(data,"ModuleScript","Currency")._module={Coins={}}
local intro=child(assets,"ScreenGui","Intro");local play=child(intro,"Frame","Play")
local nativeButton=child(play,"ImageButton","Button");child(nativeButton,"TextLabel","Label")
local pg=Instance.new("PlayerGui")
local nativeScreen=child(pg,"ScreenGui","ScreenGui");local settings=child(nativeScreen,"Frame","Settings")
local frame=child(settings,"Frame","Frame");child(frame,"UIStroke","UIStroke")
local main=child(frame,"Frame","Main");local list=child(main,"ScrollingFrame","ScrollingFrame")
local template=child(list,"Frame","Template");local info=child(template,"Frame","Information");child(info,"TextLabel","Label")
local category=child(list,"Frame","General");child(category,"TextLabel","Label")
local categoryItems=child(category,"Frame","Items");child(categoryItems,"UIListLayout","UIListLayout")
template.Parent=categoryItems
child(info,"TextLabel","Description")
template.BackgroundTransparency=0.75
local action=child(template,"Frame","Action");local drop=child(action,"Frame","Dropdown");nativeButton:Clone().Parent=drop
local toggle=child(action,"ImageButton","Toggle");child(toggle,"Frame","Blob");child(toggle,"UIGradient","UIGradient")
local keybind=child(action,"Frame","Keybind");child(keybind,"Frame","Clear")
-- Real keybind geometry is layout-driven. Editable fields must not reuse this host.
child(keybind,"UIListLayout","UIListLayout")
local inputBox=child(keybind,"TextBox","InputBox");child(inputBox,"TextLabel","Label");child(inputBox,"Frame","Background")
inputBox.TextEditable=false;inputBox.AnchorPoint=vector(1,0.5)
inputBox.TextSize=72;inputBox.TextXAlignment=Enum.TextXAlignment.Right
child(inputBox,"UIPadding","UIPadding");child(inputBox,"UITextSizeConstraint","UITextSizeConstraint")
local inventory=child(nativeScreen,"Frame","Inventory")
inventory.BackgroundTransparency=0.45;inventory.Interactable=false;inventory.Active=true
local inventoryFrame=child(inventory,"Frame","Frame");inventoryFrame.Size=UDim2.fromOffset(1235,770)
inventoryFrame.Interactable=false
inventoryFrame.BackgroundColor3={nativeInventoryColor=true}
child(inventoryFrame,"ImageLabel","Background").Image="native-inventory-art"
local top=child(inventoryFrame,"Frame","Top");local topTitle=child(top,"Frame","Title");child(topTitle,"TextLabel","Title")
local topLeft=child(top,"Frame","Left");child(topLeft,"Frame","Stats");child(topLeft,"Frame","StorageHolder")
local closeHost=child(top,"Frame","Close")
local nativeClose=nativeButton:Clone();nativeClose.Image="native-close-x";nativeClose.Parent=closeHost
local inner=child(inventoryFrame,"Frame","Inner")
for _,name in ipairs({"Pets","Items"}) do local page=child(inner,"Frame",name);local main=child(page,"Frame","Main");child(main,"ScrollingFrame","ScrollingFrame") end
local side=child(inventoryFrame,"Frame","Sidebar");local nav=child(side,"Frame","Buttons");child(nav,"UIListLayout","UIListLayout")
for _,name in ipairs({"Pets","Items","Titles","Currency"}) do
	local entry=child(nav,"Frame",name);entry.Size=UDim2.fromOffset(65,65)
	local entryButton=nativeButton:Clone();entryButton.Parent=entry;entryButton.Label.Text=name
end
local tray=child(inventoryFrame,"Frame","Tray");child(tray,"Frame","Buttons")
local searchHost=child(tray,"Frame","Search")
child(searchHost,"ImageLabel","OuterTrayArtwork").Image="unwanted-outer-search-wrapper"
local search=child(searchHost,"Frame","Search")
child(search,"ImageLabel","MagnifyingGlass").Image="native-search-glass"
child(search,"ImageLabel","Background").Image="native-search-background"
local bar=child(search,"Frame","Bar");bar.Position=UDim2.fromOffset(56,4);bar.Size=UDim2.new(1,-64,1,-8)
local searchInput=child(bar,"TextBox","TextBox");searchInput.Position=UDim2.fromOffset(8,0);searchInput.Size=UDim2.new(1,-16,1,0)
searchInput.AnchorPoint=vector(0.5,0.5);searchInput.Position=UDim2.new(0.5,0,0.5,24);searchInput.Size=UDim2.new(1,-16,0,16)
child(searchInput,"UITextSizeConstraint","UITextSizeConstraint")
searchInput.TextXAlignment=Enum.TextXAlignment.Left;searchInput.TextColor3={nativeSearchText=true};searchInput.PlaceholderColor3={nativeSearchPlaceholder=true}
top:Clone().Parent=frame;side:Clone().Parent=frame
frame.BackgroundColor3={nativeSettingsColor=true}
child(frame,"ImageLabel","Background").Image="native-settings-art"
child(main,"ImageLabel","Background").Image="native-settings-content"
local client=child(storage,"Folder","Client");local gui=child(client,"Folder","Gui");local guiUtils=child(gui,"Folder","Utils");local components=child(gui,"Folder","Components")
child(gui,"ModuleScript","GuiFrame")._module={Initialize=function() end}
child(guiUtils,"ModuleScript","ClickableButton")
child(guiUtils,"ModuleScript","PlayLocalSound")._module=function() counters.sounds=(counters.sounds or 0)+1 end
local framework=child(client,"Folder","Framework");local servicesRoot=child(framework,"Folder","Services")
child(servicesRoot,"ModuleScript","LocalData")._module={Get=function() return {} end}
child(shared,"ModuleScript","Types")
child(guiUtils,"ModuleScript","AutoButtonColor")._module=function(button,theme) button:SetAttribute("MockTheme",theme) end
child(guiUtils,"ModuleScript","ItemFrame")._module=function(item)
	counters.nativeCards=(counters.nativeCards or 0)+1
	local card=Instance.new("Frame");local b=child(card,"ImageButton","Button");local inner=child(b,"Frame","Inner")
	for _,name in ipairs({"Label","Bottom","Secret","XL"}) do child(inner,"TextLabel",name) end
	local icon=child(inner,"Frame","Icon");child(icon,"ImageLabel","Label");itemUtil._module:UpdateIcon(icon,item)
	card.Destroying:Connect(function() counters.cardCleanup=(counters.cardCleanup or 0)+1 end)
	return card
end
child(components,"ModuleScript","Dropdown")._module={new=function(_,props)
	local floater=Instance.new("Frame");local items=child(floater,"ScrollingFrame","Items");child(items,"UIListLayout","UIListLayout")
	local frames={}
	for _,name in ipairs(props.Items) do local entry=nativeButton:Clone();entry.Parent=items;entry.Label.Text=name;table.insert(frames,entry) end
	local function positionRows()
        for index,entry in ipairs(frames) do entry.AbsoluteSize=vector(192,100);entry.AbsolutePosition=vector(250,180+(index-1)*100-items.CanvasPosition.Y) end
    end
    positionRows();items:GetPropertyChangedSignal("CanvasPosition"):Connect(positionRows)
    local picker={_floater=floater,_frames=frames,_height=math.min(#props.Items,6)*50,
		OnSelectionChanged=signal(),Closed=signal(),_renderTrove={Add=function(_,v) return v end},_trove={Add=function(_,v) return v end}}
	function picker:SetOpened(value) self.Opened=value;if value then if self._observeSize then self:_observeSize() end else self.Closed:Fire() end end
	function picker:SelectItem(index) self:SetOpened(false);assert(not self.Destroyed,"Do not destroy before selection");self.OnSelectionChanged:Fire(props.Items[index],index) end
	function picker:Destroy() self.Destroyed=true;self.Closed:Fire();floater:Destroy() end
	return picker
end}
local palette={Button={}}
for _,name in ipairs({"Blue","Green","Inactive","Red"}) do palette.Button[name]={Color=ColorSequence.new(Color3.new(1,1,1))} end
child(shared,"ModuleScript","Palette")._module=palette
-- Closed native menus can be cloned with disabled buttons and active decoration.
for _,node in ipairs(nativeScreen:GetDescendants()) do
	if node:IsA("GuiButton") then node.Interactable=false end
	if node:IsA("TextLabel") then node.Active=true end
end
local localPlayer=Instance.new("Player");pg.Name="PlayerGui";pg.Parent=localPlayer
local camera=Instance.new("Camera");local workspace=Instance.new("Workspace");workspace.CurrentCamera=camera
local input=Instance.new("UserInputService")
local tweenService={Create=function(_,object,info,props)
    counters.tweens=(counters.tweens or 0)+1
    return {Play=function() for key,value in pairs(props) do object[key]=value end end,Cancel=function() end}
end}
local Icon={new=function()
    local icon={selected=signal(),isEnabled=true}
    function icon:setName(v) self.name=v;return self end
    function icon:setLabel(v) self.label=v;return self end
    function icon:align(v) self.alignment=v;return self end
    function icon:setOrder(v) self.order=v;return self end
    function icon:setCaption(v) self.caption=v;return self end
    function icon:setDestroyOnRespawn(v) self.destroyOnRespawn=v;return self end
    function icon:setEnabled(v) self.isEnabled=v;return self end
    function icon:deselect() self.isSelected=false;return self end
    function icon:destroy() self.isDestroyed=true end
    counters.topbar=(counters.topbar or 0)+1
    return icon
end}
local services={TweenService=tweenService,Players={LocalPlayer=localPlayer},ReplicatedStorage=storage,UserInputService=input,HttpService={JSONDecode=function() error("No JSON fixture") end},GuiService={GetGuiInset=function() return vector(0,36),vector() end}}
local env=setmetatable({
	game={GetService=function(_,name) assert(services[name],name);return services[name] end},
	workspace=workspace,Instance=Instance,Enum=Enum,Vector2=Vector2,Vector3=Vector3,UDim=UDim,UDim2=UDim2,
	TweenInfo={new=function(...) return {...} end},Color3=Color3,ColorSequence=ColorSequence,Font=Font,CFrame=CFrame,
	onTestHubGetTopbar=function() return Icon end,
	require=function(module) return module._module or {} end,
	task={spawn=function(fn,...) fn(...) end,defer=function() end},
}, {__index=getfenv()})
return {env=env,counters=counters,playerGui=pg,input=input,workspace=workspace,Enum=Enum,vector=vector,assets=assets,signal=signal}
