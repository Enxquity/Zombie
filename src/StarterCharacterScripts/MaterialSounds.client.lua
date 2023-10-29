local MaterialSounds = 
	{
		[Enum.Material.Grass] = "rbxassetid://3205597457",
		[Enum.Material.Metal] = "rbxassetid://3477114901",
		[Enum.Material.DiamondPlate] = "rbxassetid://3477114901",
		[Enum.Material.Pebble] = "rbxassetid://1612909793",
		[Enum.Material.Wood] = "rbxassetid://1612936942",
		[Enum.Material.WoodPlanks] = "rbxassetid://1612936942",
		[Enum.Material.Plastic] = "rbxassetid://1612901459",
		[Enum.Material.SmoothPlastic] = "rbxassetid://1612901459",
		[Enum.Material.Sand] = "rbxassetid://336575096",
		[Enum.Material.Brick] = "rbxassetid://1612901699",
		[Enum.Material.Cobblestone] = "rbxassetid://1612901459",
		[Enum.Material.Concrete] = "rbxassetid://1612901699",
		[Enum.Material.CorrodedMetal] = "rbxassetid://348649563",
		[Enum.Material.Fabric] = "rbxassetid://1124822722",
		[Enum.Material.Foil] = "rbxassetid://4981969796",
		[Enum.Material.ForceField] = "rbxassetid://4981969796",
		[Enum.Material.Glass] = "rbxassetid://1236071978",
		[Enum.Material.Granite] = "rbxassetid://1612901459",
		[Enum.Material.Ice] = "rbxassetid://772157562",
		[Enum.Material.Marble] = "rbxassetid://944075408",
		[Enum.Material.Neon] = "rbxassetid://4981969796",
		[Enum.Material.Slate] = "rbxassetid://1612901459",
	}

local Character = script.Parent.Parent
local Humanoid = Character:WaitForChild("Humanoid")
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
local FootStepsSound = HumanoidRootPart:WaitForChild("Running")

local Vol = FootStepsSound.Volume
FootStepsSound.PlaybackSpeed = (0.6 * (Humanoid.WalkSpeed / 8))

Humanoid:GetPropertyChangedSignal("FloorMaterial"):Connect(function()
	local FloorMaterial = Humanoid.FloorMaterial
	local Sound = MaterialSounds[FloorMaterial]
	if Sound then
		FootStepsSound.SoundId = Sound
	else
		FootStepsSound.SoundId = "rbxasset://sounds/action_footsteps_plastic.mp3"
	end
end)

Humanoid:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
	local Speed = Humanoid.WalkSpeed
	game:GetService("TweenService"):Create(FootStepsSound, TweenInfo.new(1), {PlaybackSpeed = (0.6 * math.clamp((Speed / 5), 0, 1))}):Play()
	game:GetService("TweenService"):Create(FootStepsSound, TweenInfo.new(1), {Volume = (Vol * (Speed / 8))}):Play()
end)