local Event = script.Parent:WaitForChild('LookEvent', 20)
local Ang = CFrame.Angles
local aSin = math.asin
local aTan = math.atan

local Character = script.Parent.Parent.Parent
local Head = Character:WaitForChild('Head')
local LeftArm = Character:WaitForChild('Left Arm')
local RightArm = Character:WaitForChild('Right Arm')
local Humanoid = Character:WaitForChild('Humanoid')
local RootPart = Character:WaitForChild('HumanoidRootPart')
local Torso = Character:WaitForChild('Torso')
local Neck = Torso:WaitForChild('Neck')
local NeckOrgnC0 = Neck.C0
local RightShoulder = Torso:WaitForChild('Right Shoulder')
local RightShoulderOrgnC0 = RightShoulder.C1
local LeftShoulder = Torso:WaitForChild('Left Shoulder')
local LeftShoulderOrgnC0 = LeftShoulder.C1

Event.OnServerEvent:Connect(function(Player, CameraCFrame, HeadHorFactor, HeadVertFactor, UpdateSpeed, MouseOriginPosition)
	if Humanoid.Health > 0 then
		local Dist = (Head.CFrame.Position-CameraCFrame.Position).Magnitude
		local Diff = Head.CFrame.Y-CameraCFrame.Y
		
		local HeadPosition = Head.CFrame.Position
		
		local LeftArmPosition = LeftArm.CFrame.Position
		
		local RightArmPosition = RightArm.CFrame.Position
		
		local TorsoLookVector = RootPart.CFrame.lookVector
		
		
		local X = -(math.asin((MouseOriginPosition - CameraCFrame.Position).unit.y)) * -1
		
		--Neck.C0 = Neck.C0:Lerp(NeckOrgnC0*Ang(-(aSin(Diff/Dist)*HeadVertFactor), 0, -(((HeadPosition-MouseOriginPosition).Unit):Cross(TorsoLookVector)).Y*HeadHorFactor),UpdateSpeed/2)
		
		local _, Y, Z = Neck.C0:ToEulerAnglesXYZ()
		Neck.C0  = CFrame.new(Neck.C0.Position) * CFrame.Angles(X - 1.5, Y, Z)
		
		local _, Y, Z = RightShoulder.C0:ToEulerAnglesXYZ()
		local OldRightC0 = RightShoulder.C0
		RightShoulder.C0 = CFrame.new(RightShoulder.C0.Position) * CFrame.Angles(X, Y, Z)
		
		local _, Y, Z = LeftShoulder.C0:ToEulerAnglesXYZ()
		LeftShoulder.C0 = CFrame.new(LeftShoulder.C0.Position) * CFrame.Angles(X, Y, Z)
	end
end)