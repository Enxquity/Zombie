local RunService = game:GetService('RunService')
-- LookEvent is parented to the LocalScript
local Event = script:WaitForChild('LookEvent')
local Player = game.Players.LocalPlayer
local Camera = workspace:WaitForChild('Camera')
local Character = Player.Character or Player.CharacterAdded:Wait()
local Head = Character:WaitForChild('Head')
local Humanoid = Character:WaitForChild('Humanoid')
local RootPart = Character:WaitForChild('HumanoidRootPart')
local Torso = Character:WaitForChild('Torso')
local Neck = Torso:WaitForChild('Neck')

local Ang = CFrame.Angles
local aSin = math.asin
local aTan = math.atan

local NeckOrgnC0 = Neck.C0
local HeadHorFactor = 0
local HeadVertFactor = 1
local UpdateSpeed = 0.5

while task.wait(1/60) do
	local CameraCFrame = Camera.CoordinateFrame
	local MouseOriginPosition = Player:GetMouse().Origin.Position
	if Humanoid.Health > 0 then
		Event:FireServer(CameraCFrame, HeadHorFactor, HeadVertFactor, UpdateSpeed, MouseOriginPosition)
	end
end