local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage");
local UserInputService = game:GetService("UserInputService")

local Knit = require(ReplicatedStorage.Packages.Knit)

local Camera = Knit.CreateController{
    Name = "Camera";
    CameraCFrame = CFrame.new(0, 0, 0);
    Spring = require(ReplicatedStorage.Source.Services.Spring);
    Shake = require(ReplicatedStorage.ExternalModules.CameraShaker);
    Camera = workspace.CurrentCamera;
    UIS = game:GetService("UserInputService");
    Services = {
        ["CharacterUtils"] = "None";
    };
    Tweens = {

        Fov = {}
    };
    Lock = false;
    LockChar = nil;
    CameraToggled = true;
}

function Camera:SetType(Type)
    self.Camera.CameraType = Enum.CameraType[Type];
end

function Camera:SetMouseBehavior(Behavior)
    self.UIS.MouseBehavior = Enum.MouseBehavior[Behavior]
end

function Camera:GetCFrame()
    return self.Camera.CFrame
end

function Camera:SetCFrame(CF)
    self.Camera.CFrame = CF
end

function Camera:GetOffset()
    local Humanoid = self:GetHumanoid():await()
    return Humanoid.CameraOffset
end

function Camera:SetOffset(Offset)
    --print(Offset)
    self:GetHumanoid():andThen(function(Humanoid)
        Humanoid.CameraOffset = Offset
        --Humanoid.AutoRotate = false
    end)
end

function Camera:LerpOffset(Offset, LerpPoint)
    self:GetHumanoid():andThen(function(Humanoid)
        Humanoid.CameraOffset:Lerp(Offset, LerpPoint)
    end)
end

function Camera:Lerp(a, b, t)
    return a + (b - a) * t
end

function Camera:SetFov(Fov)
    self.Camera.FieldOfView = Fov;
end

function Camera:LerpFov(Fov, DT)
    self.Camera.FieldOfView = self:Lerp(self.Camera.FieldOfView, Fov, 3*DT)
end

function Camera:TweenFov(Fov)
    for i,v in self.Tweens.Fov do
        v:Cancel()
    end
    self.Tweens.Fov = {}

    table.insert(self.Tweens.Fov, game:GetService("TweenService"):Create(self.Camera, TweenInfo.new(0.2), {FieldOfView = Fov}))
    self.Tweens.Fov[1]:Play()

    return {
        ClearOnEnd = function()
            self.Tweens.Fov[1].Completed:Wait()
            self.Tweens.Fov = {}
        end
    }
end

function Camera:Bobble()
    local T = tick()
    local BobbleX = math.cos(T * 10) * 0.25
    local BobbleY = math.abs(math.sin(T * 10)) * 0.25
    local Bobble = Vector3.new(BobbleX, BobbleY, 0)
    return Bobble
end

function Camera:GetCharacter()
    local Character = game.Players.LocalPlayer.Character or game.Players.LocalPlayer.CharacterAdded:Wait()
    local tbl = {}
    function tbl:andThen(f)
        return f(Character)
    end
    return tbl
end

function Camera:GetSpeed()
    local Character = game.Players.LocalPlayer.Character or game.Players.LocalPlayer.CharacterAdded:Wait()
    local Speed = nil
    if Character and Character:FindFirstChildWhichIsA("Humanoid") then
        local Humanoid = Character:FindFirstChildWhichIsA("Humanoid")
        Speed = Humanoid.MoveDirection.Magnitude
    end
    local tbl = {}
    function tbl:andThen(f)
        return f(Speed)
    end
    return tbl
end

function Camera:GetWalkSpeed()
    local Character = game.Players.LocalPlayer.Character or game.Players.LocalPlayer.CharacterAdded:Wait()
    if Character and Character:FindFirstChildWhichIsA("Humanoid") then
        local Humanoid = Character:FindFirstChildWhichIsA("Humanoid")
        return Humanoid.WalkSpeed
    end
end

function Camera:GetHumanoid()
    local Character = game.Players.LocalPlayer.Character or game.Players.LocalPlayer.CharacterAdded:Wait()
    local Hum = nil 
    if Character and Character:FindFirstChildWhichIsA("Humanoid") then
        local Humanoid = Character:FindFirstChildWhichIsA("Humanoid")
        Hum = Humanoid
    end
    local tbl = {}
    function tbl:andThen(f)
        return f(Hum)
    end
    function tbl:await()
        return Hum
    end
    return tbl
end

function Camera:IsStunned()
    local Character = game.Players.LocalPlayer.Character or game.Players.LocalPlayer.CharacterAdded:Wait()

    if Character then
        if Character:GetAttributes()["Stunned"] or Character:GetAttributes()["Immune"] then
            return true
        end
    end

    return
end

function Camera:GetClosestEnemy(InDistance)
    local Character = game.Players.LocalPlayer.Character
    if Character then
        local Closest, ClosestChar = math.huge, nil
        for i,v in pairs(workspace.Dummies:GetChildren()) do
            local Dist = (Character.PrimaryPart.Position - v.PrimaryPart.Position).Magnitude 
            if Dist <= InDistance and Dist < Closest then
                Closest = Dist
                ClosestChar = v
            end
        end
        return ClosestChar
    end
    return nil
end

function Camera:Render(dt) --// Our camera loop per frame
    if (not self.Services.CharacterUtils == "None") then return end
    if self.CameraToggled == true then
        self:SetMouseBehavior("LockCenter")
        self.UIS.MouseIconEnabled = false

        if #self.Tweens.Fov <= 0 then
            local Speed = self:GetWalkSpeed()
            self:LerpFov(math.clamp(60 * (Speed / 6), 50, 70), dt)

            if Speed <= 3 or self:IsStunned() then
                local Vignette = Players.LocalPlayer.PlayerGui.Combat.Vignette.ImageLabel
                Vignette.ImageTransparency = self:Lerp(Vignette.ImageTransparency, 0, 2*dt)
            else
                local Vignette = Players.LocalPlayer.PlayerGui.Combat.Vignette.ImageLabel
                Vignette.ImageTransparency = self:Lerp(Vignette.ImageTransparency, 1, 2*dt)
            end

            self:GetSpeed():andThen(function(Speed)
                if Speed > 0 and not self:IsStunned() then
                    local BobbleOffset = self:Bobble()
                    self:SetOffset(self:GetOffset():Lerp(BobbleOffset, Speed/16))
                end
            end)
        end
        self:GetCharacter():andThen(function(Character)
            if self.Lock == true then
                if not self.LockChar then
                    self.LockChar = self:GetClosestEnemy(20)
                    if not self.LockChar then
                        self.Lock = false
                    end
                else
                    if (Character.PrimaryPart.Position - self.LockChar.PrimaryPart.Position).Magnitude > 20 then
                        self.Lock = false
                    end
                    self.Camera.CameraType = Enum.CameraType.Scriptable
                    local CamPosition = CFrame.new(Character.HumanoidRootPart.Position, self.LockChar.PrimaryPart.Position) * CFrame.new(3,2,5).Position
                    self.Camera.CFrame = self.Camera.CFrame:Lerp(CFrame.new(CamPosition, self.LockChar.PrimaryPart.Position), dt*4)
        
                    Character.Humanoid.AutoRotate = false
                    Character.PrimaryPart.CFrame = CFrame.new(Character.PrimaryPart.Position, self.LockChar.PrimaryPart.Position)
                end
            else
                if Character.PrimaryPart then
                    self.LockChar = nil
                    self.Camera.CameraType = Enum.CameraType.Custom
                    Character.Humanoid.AutoRotate = true
                    local X, Y, Z = CFrame.new(Character.PrimaryPart.Position, self.Camera.CFrame.LookVector.Unit * 1000):ToOrientation()
                    --Character.PrimaryPart.CFrame = CFrame.new(Character.PrimaryPart.Position) * CFrame.Angles(0, Y, 0)
                end
            end
        end)
    else
        self:SetMouseBehavior("Default")
        self.UIS.MouseIconEnabled = true
    end
end 

function Camera:KnitStart()
    for i, _ in pairs(self.Services) do
        self.Services[i] = Knit.GetService(i)
    end
end 

function Camera:KnitInit()
    print("[Knit] Camera controller initialised!")
end

return Camera