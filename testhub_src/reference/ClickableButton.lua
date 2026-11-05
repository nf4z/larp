-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- [[ Script name: ClickableButton, time of decompilation: Sat Oct 31 22:42:41 2026 ]]
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalData = require(ReplicatedStorage.Client.Framework.Services.LocalData)

require(ReplicatedStorage.Shared.Types)

local PlayLocalSound = require(ReplicatedStorage.Client.Gui.Utils.PlayLocalSound)
local t1 = {
	ScalePress = 0.925,
	ScaleEnter = 1.035,
	InfoPress = TweenInfo.new(0.25, Enum.EasingStyle.Quint),
	InfoRelease = TweenInfo.new(0.13, Enum.EasingStyle.Sine)
}

local function DefaultCondition() -- line: 20
	return true
end
local function GetButton(p1) -- line: 26
	if p1:IsA("ImageButton") or p1:IsA("TextButton") then
		return p1
	end

	return p1:FindFirstChild("Activation") or (p1:FindFirstChildOfClass("ImageButton") or p1:FindFirstChildOfClass("TextButton"))
end
local function ComputeButtonState(p2, b1: boolean, b2: boolean) -- line: 36
	-- upvalues: t1 (copy), TweenService (copy)
	local InfoPress = t1.InfoPress
	local n1 = 1

	if b1 then
		n1 = t1.ScalePress
	elseif b2 then
		n1 = t1.ScaleEnter
	else
		InfoPress = t1.InfoRelease
	end

	TweenService:Create(p2, InfoPress, {
		Scale = n1
	}):Play()
end
local function PlayButtonClickSound() -- line: 54
	-- upvalues: LocalData (copy)
	if not LocalData:Get() then
		return false
	end

	return true
end
local function ClickableButton(p3, p4: ((...any) -> ...any)?, p5: ((...any) -> ...any)?) -- line: 64
	-- upvalues: GetButton (copy), DefaultCondition (copy), LocalData (copy), PlayLocalSound (copy), ComputeButtonState (copy)
	local UIScale = Instance.new("UIScale", p3)
	local v21 = GetButton(p3)
	local u22 = false
	local u23 = false

	assert(v21 ~= nil, `{ p3.Name } must be or have child of class TextButton or ImageButton`)

	if p4 then
		v21.Activated:Connect(function() -- line: 77
			-- upvalues: p5 (copy), DefaultCondition (copy), p4 (copy)
			if (p5 or DefaultCondition)() then
				p4()
			end
		end)
	end

	local function makePress() -- line: 85
		-- upvalues: v21 (copy), p5 (copy), DefaultCondition (copy), LocalData (copy), PlayLocalSound (copy), u22 (ref), ComputeButtonState (copy), UIScale (copy), u23 (ref)
		if not v21.Active or not (p5 or DefaultCondition)() then
			return
		end

		if LocalData:Get() and true or false then
			PlayLocalSound("ButtonRelease")
		end

		u22 = true
		ComputeButtonState(UIScale, u22, u23)
	end
	local function makeRelease() -- line: 96
		-- upvalues: v21 (copy), p5 (copy), DefaultCondition (copy), LocalData (copy), PlayLocalSound (copy), u22 (ref), ComputeButtonState (copy), UIScale (copy), u23 (ref)
		if not v21.Active or not (p5 or DefaultCondition)() then
			return
		end

		if LocalData:Get() and true or false then
			PlayLocalSound("ButtonPress")
		end

		u22 = false
		ComputeButtonState(UIScale, u22, u23)
	end

	v21.MouseButton1Down:Connect(makePress)
	v21.MouseButton1Up:Connect(function() -- line: 112
		-- upvalues: u23 (ref), v21 (copy), p5 (copy), DefaultCondition (copy), LocalData (copy), PlayLocalSound (copy), u22 (ref), ComputeButtonState (copy), UIScale (copy)
		if not u23 then
			return
		end

		if v21.Active then
			if not (p5 or DefaultCondition)() then
				return
			end

			if LocalData:Get() and true or false then
				PlayLocalSound("ButtonPress")
			end

			u22 = false
			ComputeButtonState(UIScale, u22, u23)
		end
	end)
	v21.MouseEnter:Connect(function() -- line: 120
		-- upvalues: v21 (copy), p5 (copy), DefaultCondition (copy), LocalData (copy), PlayLocalSound (copy), u23 (ref), ComputeButtonState (copy), UIScale (copy), u22 (ref)
		if not v21.Active or not (p5 or DefaultCondition)() then
			return
		end

		if LocalData:Get() and true or false then
			PlayLocalSound("ButtonHover")
		end

		u23 = true
		ComputeButtonState(UIScale, u22, u23)
	end)
	v21.MouseLeave:Connect(function() -- line: 134
		-- upvalues: u23 (ref), u22 (ref), ComputeButtonState (copy), UIScale (copy)
		u23 = false
		u22 = false
		ComputeButtonState(UIScale, u22, u23)
	end)
	p3:SetAttribute("ButtonActivated", false)
	p3:GetAttributeChangedSignal("ButtonActivated"):Connect(function() -- line: 144
		-- upvalues: p3 (copy), u22 (ref), ComputeButtonState (copy), UIScale (copy), u23 (ref)
		u22 = p3:GetAttribute("ButtonActivated")
		ComputeButtonState(UIScale, u22, u23)
	end)
	p3:SetAttribute("Pressed", false)
	p3:GetAttributeChangedSignal("Pressed"):Connect(function() -- line: 151
		-- upvalues: p3 (copy), u22 (ref), v21 (copy), p5 (copy), DefaultCondition (copy), LocalData (copy), PlayLocalSound (copy), ComputeButtonState (copy), UIScale (copy), u23 (ref), p4 (copy)
		local v26 = p3:GetAttribute("Pressed") or false

		if u22 == false and v26 == true then
			if v21.Active then
				if not (p5 or DefaultCondition)() then
					return
				end

				if LocalData:Get() and true or false then
					PlayLocalSound("ButtonRelease")
				end

				u22 = true
				ComputeButtonState(UIScale, u22, u23)

				return
			end
		elseif u22 == true and v26 == false then
			if p4 and (p5 or DefaultCondition)() then
				p4(true)
			end

			if v21.Active then
				if not (p5 or DefaultCondition)() then
					return
				end

				if LocalData:Get() and true or false then
					PlayLocalSound("ButtonPress")
				end

				u22 = false
				ComputeButtonState(UIScale, u22, u23)
			end
		end
	end)
end

return ClickableButton
