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
function Instance.new(class)
	counters.created+=1
	return setmetatable({_class=class,_children={},_signals={},_props={
		Name=class,Archivable=true,Visible=true,ZIndex=1,Size=UDim2.fromOffset(100,100),
		Position=UDim2.fromOffset(0,0),AbsolutePosition=vector(250,180),AbsoluteSize=vector(192,38),
		CanvasPosition=vector(),Text="",FontFace="NativeFont",ViewportSize=vector(1100,800),
	}},instanceMT)
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
	for _,child in ipairs(self:GetChildren()) do child:Destroy() end
	self.Parent=nil;self._destroyed=true
	-- Tests discard instance-owned listeners when destroying popup trees.
	self._signals={}
end
function methods:GetBoundingBox() return {Position=vector()},vector(2,3,2) end
function methods:GetFocusedTextBox() return self._focused end
instanceMT.__index=function(self,key)
	if methods[key] then return methods[key] end
	if self._props[key]~=nil then return self._props[key] end
	if key=="Activated" or key=="InputBegan" or key=="InputEnded" or key=="InputChanged" or key=="FocusLost" or key=="Idled" then
		if not self._signals[key] then self._signals[key]=signal() end
		return self._signals[key]
	end
	return self:FindFirstChild(key)
end
instanceMT.__newindex=function(self,key,value)
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
	counters.icons+=1;host.Label.Image="item:"..tostring(item.Name or item.Currency)
end}
child(shared,"ModuleScript","Constants")._module={UnknownImage="unknown"}
local eggs=child(data,"ModuleScript","Eggs");eggs._module={}
for i=1,1000 do eggs._module["Egg "..i]={Image="rbxassetid://"..i} end
child(data,"ModuleScript","Potions")._module={Lucky={}}
child(data,"ModuleScript","Powerups")._module={["Mystery Box"]={Icon="box"}}
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
local action=child(template,"Frame","Action");local drop=child(action,"Frame","Dropdown");nativeButton:Clone().Parent=drop
local localPlayer=Instance.new("Player");pg.Name="PlayerGui";pg.Parent=localPlayer
local camera=Instance.new("Camera");local workspace=Instance.new("Workspace");workspace.CurrentCamera=camera
local input=Instance.new("UserInputService")
local services={Players={LocalPlayer=localPlayer},ReplicatedStorage=storage,UserInputService=input,GuiService={GetGuiInset=function() return vector(0,36),vector() end}}
local env=setmetatable({
	game={GetService=function(_,name) assert(services[name],name);return services[name] end},
	workspace=workspace,Instance=Instance,Enum=Enum,Vector2=Vector2,Vector3=Vector3,UDim=UDim,UDim2=UDim2,
	Color3=Color3,ColorSequence=ColorSequence,Font=Font,CFrame=CFrame,
	require=function(module) return module._module or {} end,
	task={spawn=function(fn,...) fn(...) end},
}, {__index=getfenv()})
return {env=env,counters=counters,playerGui=pg,input=input,workspace=workspace,Enum=Enum,vector=vector,assets=assets,signal=signal}
