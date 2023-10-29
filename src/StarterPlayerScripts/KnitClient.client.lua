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
    --// Controllers
    local CameraController = Knit.GetController("Camera")
    local UIController = Knit.GetController("UI")
    
    local WeaponClient = Knit.GetController("WeaponClient")

    local Animations = {}
    for i,v in pairs(ReplicatedStorage.GameAssets:GetDescendants()) do
        if v:IsA("Animation") then
            table.insert(Animations, v)
        end
    end
    ContentProvider:PreloadAsync(Animations)
    local PGui = Player:WaitForChild("PlayerGui")
    local Gui = PGui:FindFirstChild("Transfering")

    if Gui then
        Gui.Enabled = true
        PGui.HUD.UpdateLog.Visible = true
        task.wait(2)
        TweenService:Create(Gui.Loading, TweenInfo.new(0.5), {BackgroundTransparency = 1}):Play()
        TweenService:Create(Gui.Loading.Circle, TweenInfo.new(0.5), {ImageTransparency = 1}):Play()
        TweenService:Create(Gui.Loading.Status, TweenInfo.new(0.5), {TextTransparency = 1}):Play()

        PGui.HUD.UpdateLog.Continue.MouseButton1Click:Connect(function()
            PGui.HUD.UpdateLog.Visible = false
        end)
    end

    repeat task.wait() until workspace:GetAttribute("Begin") == true
    PGui.HUD.Countdown.Visible = false
    PGui.HUD.Version.Visible = false
    PGui.HUD.UpdateLog.Visible = false
    
    WeaponClient:MakeConnection()

    repeat task.wait() until Player.Character and Player.Character:FindFirstChild("Humanoid")
    Player.Character.Humanoid.Died:Connect(function()
        WeaponClient:Unequip()
    end)

    Player.CharacterAdded:Connect(function(Char)
        repeat task.wait() until Char:FindFirstChild("Humanoid") and Char.PrimaryPart
        Char.Humanoid.Died:Connect(function()
            WeaponClient:Unequip()
        end)
    end)

    WeaponClient:Equip("Secondary")

    UserInputService.InputBegan:Connect(function(Input, IsTyping)
        if IsTyping then return end
        if Input.KeyCode == Enum.KeyCode.One then
            WeaponClient:Equip("Primary")
        elseif Input.KeyCode == Enum.KeyCode.Two then
            WeaponClient:Equip("Secondary")
        end
    end)
end):catch(warn)
