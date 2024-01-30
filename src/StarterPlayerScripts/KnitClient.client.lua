local ContentProvider = game:GetService("ContentProvider")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage");
local TeleportService = game:GetService("TeleportService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService");
local RunService = game:GetService("RunService");
local Player = game:GetService("Players").LocalPlayer;

local Knit = require(ReplicatedStorage.Packages.Knit)
local Keybinds = require(ReplicatedStorage.Source.Keybinds)
--local Key = require(ReplicatedStorage.ExternalModules.Key)
Knit.AddControllersDeep(ReplicatedStorage.Source.Controllers)

Knit.Start():andThen(function()
    local Placement = Knit.GetController("Placement")
    local UI = Knit.GetController("UI")
    UserInputService.InputBegan:Connect(function(Input, IsTyping)
        if IsTyping then return end
        if Input.KeyCode == Keybinds.Build then
            --Placement:Start(workspace.Buildables.Pipes.StraightLiquid)
            UI:Call("Build", "toggle")
        end
        if Input.KeyCode == Keybinds.Pipe then
            Placement:Call("Piping", "toggle")
        end
        if Input.KeyCode == Keybinds.Cancel then
            Placement:Stop()
        end
        if Input.KeyCode == Keybinds.Rotate then
            Placement:Rotate()
        end
        if Input.UserInputType == Enum.UserInputType.MouseButton1 then
            Placement:Place()
        end
    end)
end):catch(warn)
