local ReplicatedStorage = game:GetService("ReplicatedStorage");
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService");
local RunService = game:GetService("RunService");
local Player = game:GetService("Players").LocalPlayer;

local Knit = require(ReplicatedStorage.Packages.Knit)
local Keybinds = require(ReplicatedStorage.Source.Keybinds)
--local Key = require(ReplicatedStorage.ExternalModules.Key)
Knit.AddControllersDeep(ReplicatedStorage.Source.Controllers)

--// Controllers
local CameraController = Knit.GetController("Camera")
local UIController = Knit.GetController("UI")
local WeaponClient = Knit.GetController("WeaponClient")

function Lerp(a, b, t)
    return a + (b - a) * t 
end

--// Blood
repeat
    task.wait()
until script.Parent.Parent
local Character = script.Parent.Parent
local OldHealth = 100
local BloodEffect = 1

if Character:FindFirstChild("Humanoid") then
    local Hum = Character:FindFirstChild("Humanoid")
    Hum:GetPropertyChangedSignal("Health"):Connect(function()
        if Hum.Health < OldHealth then
            local Diff = math.abs(Hum.Health - OldHealth)
            BloodEffect -= math.clamp(Diff / Hum.MaxHealth, 0, 1)
        end
        OldHealth = Hum.Health
    end)
end

task.spawn(function()
    while task.wait() do
        BloodEffect = Lerp(BloodEffect, 1, 0.005)
        Player.PlayerGui.HUD.Blood.ImageTransparency = BloodEffect
    end
end)

--// Downed system prevent death
while task.wait(1) do
    local Character = script.Parent.Parent
    if Character then
        local Humanoid = Character:FindFirstChildOfClass("Humanoid")
        --Humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
    end
end