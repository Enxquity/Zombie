local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage");
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService");
local RunService = game:GetService("RunService");
local Players = game:GetService("Players")
local Player = Players.LocalPlayer

local Knit = require(ReplicatedStorage.Packages.Knit)
local Animations = require(ReplicatedStorage.Source.Controllers.Classes.Animations)

local Spring = require(ReplicatedStorage.ExternalModules.Spring)
local Crosshair = require(ReplicatedStorage.ExternalModules.CrosshairService)
local Trajectory = require(ReplicatedStorage.ExternalModules.Trajectory).new(Vector3.new(0, -workspace.Gravity, 0))
local CameraShake = require(ReplicatedStorage.ExternalModules.CameraShaker)

local WeaponClient = Knit.CreateController{
    Name = "WeaponClient";

    Connections = {};
    Instances = {};
    Services = {
        ["WeaponServer"] = 0;
        ["VFXService"] = 0;
        ["PointsService"] = 0;
        ["Gameplay"] = 0;
    };
    Controllers = {
        ["Spectate"] = 0
    };
    Interfaces = {};

    Camera = workspace.CurrentCamera;
    Mouse = Player:GetMouse();
    Crosshair = Crosshair.new(Player.PlayerGui:WaitForChild("HUD").Crosshair, 15);
    AnimationHandler = Animations.AnimationClass();

    CacheValues = {
        LastShot = tick();
        LastGrenade = tick();
        LastKnife = tick();
        HoldStart = tick();
        UpdateHUD = tick();
        LastCF = CFrame.new();
        SOffset = CFrame.new();
        Animations = {};
        Events = {}; 
        ViewmodelOffset = CFrame.new(-0.3, -1, -2);
        CameraOffset = CFrame.new(0, 0, 0);

        Rand = Random.new();

        Power = false;
        SlideCancel = false;
        IsReloading = false;
        IsSliding = false;
        IsCrouching = false;
        IsKnifing = false;
        IsThrowing = false;
        IsRepairing = false;
        IsDowned = false;
        IsEquipping = false;
        IsReviving = false;
        IsJumping = false;
    };
    Knife = "None";
    Grenade = "None";
    Downed = "None";
    CurrentPerk = "";
    CurrentBarrier = "";
    CurrentDoor = "";
    CurrentPart = "";
    CurrentPlayer = "";
}

function WeaponClient:GetBobbing(Addition, Speed, Modifier)
    return math.sin(time() * Addition * Speed) * Modifier
end

function WeaponClient:IsEquipping()
    return self.CacheValues.IsEquipping
end

function WeaponClient:IsEngaged()
    return self.CacheValues.IsRepairing == false
end

function WeaponClient:IsDowned()
    return self.CacheValues.IsDowned
end

function WeaponClient:IsHoldingW()
    return (UserInputService:IsKeyDown(Enum.KeyCode.W) and not UserInputService:IsKeyDown(Enum.KeyCode.S))
end

function WeaponClient:IsKnifing()
    return self.CacheValues.IsKnifing
end

function WeaponClient:IsAiming()
    return UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) and not self:IsKnifing() and not self:IsThrowing() and not self:IsKnifing() and (tick() - self.CacheValues.LastGrenade) > 1
end

function WeaponClient:IsSliding()
    return self.CacheValues.IsSliding
end

function WeaponClient:IsCrouching()
    return self.CacheValues.IsCrouching
end

function WeaponClient:IsReloading()
    return self.CacheValues.IsReloading
end

function WeaponClient:IsThrowing()
    return self.CacheValues.IsThrowing
end

function WeaponClient:IsSprinting()
    return (UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) and Player.Character.Humanoid.MoveDirection.Magnitude > 0 and not self:IsAiming() and not self:IsSliding() and self:IsHoldingW() and not self:IsReloading() and not self:IsKnifing() and not self:IsThrowing())
end

function WeaponClient:Lerp(a, b, t)
    return a + (b - a) * t 
end

function WeaponClient:GetRotationBetween(u, v, axis)
    local dot, uxv = u:Dot(v), u:Cross(v)
	if (dot < -0.99999) then return CFrame.fromAxisAngle(axis, math.pi) end
	return CFrame.new(0, 0, 0, uxv.x, uxv.y, uxv.z, 1 + dot)
end

function WeaponClient:CalculateGrenade(P1, P2)
    local Direction = (P1 - P2).Unit
	local x0 = P2 + Direction * 2
	local v0 = Direction * 100
    return Trajectory:Cast(x0, v0, Enum.Material.Plastic, {workspace.Ignore, Player.Character})
end

function WeaponClient:CalculateVelocity(Dir)
    local Params = RaycastParams.new()
    Params.IgnoreWater = false
    Params.FilterType = Enum.RaycastFilterType.Exclude
    Params.FilterDescendantsInstances = {Player.Character, self.Instances["Viewmodel"], workspace.SlideIgnore, workspace.Zombies, workspace.Map, workspace.RandomPoints}

    local Up = Player.Character.PrimaryPart.CFrame.UpVector 

    local RayDown = workspace:Raycast(Player.Character.PrimaryPart.Position, Up * -7, Params)
    local RayForward = workspace:Raycast(Player.Character.PrimaryPart.Position, Dir * 0.1 + Up * -7, Params)
    
    if RayDown and RayForward then  
        Player.Character.PrimaryPart.CFrame = CFrame.new(Player.Character.PrimaryPart.CFrame.X, RayDown.Position.Y + Player.Character.PrimaryPart.Size.Y * 1.5, Player.Character.PrimaryPart.CFrame.Z)
        local Angle = math.deg(math.acos(RayDown.Normal:Dot(Vector3.yAxis)))
        if Angle < 5 then
            Angle = 0
        elseif Angle > 45 then
            Angle = 45
        end
        return (RayForward and RayForward.Position.Y > RayDown.Position.Y) and -Angle or Angle
    else
        return 0
    end
end

function WeaponClient:GetCrosshairRadius()
    local HUD = Player.PlayerGui:FindFirstChild("HUD")
    if HUD and HUD:FindFirstChild("Crosshair") then
        return (not self:IsAiming() and Player.PlayerGui.HUD.Crosshair.Right.Position.X.Offset or Player.PlayerGui.HUD.Crosshair.Right.Position.X.Offset / 3)
    else
        repeat task.wait() HUD = Player.PlayerGui:FindFirstChild("HUD") until HUD and HUD:FindFirstChild("Crosshair")
        return self:GetCrosshairRadius()
    end
end

function WeaponClient:RenderSound(Sound, Part, RenderOnPart)
    local NewSound = Sound:Clone()

    local NewPart;
    if not RenderOnPart then
        NewPart = Instance.new("Part")
        NewPart.Parent = workspace.Ignore
        NewPart.Transparency = 1
        NewPart.CFrame = Part.CFrame
        NewPart.CanCollide = false
        NewPart.Anchored = true

        NewSound.Parent = NewPart
    else
        NewSound.Parent = Part
    end
    NewSound:Play()
    NewSound.Ended:Connect(function()
        if NewPart then
            NewPart:Destroy()
        else
            NewSound:Destroy()
        end
    end)
    return NewSound
end

function WeaponClient:Render(Gun)
    for i,v in pairs(Gun.FirePart:GetChildren()) do
        if v:IsA("ParticleEmitter") then
            v:Emit(20)
        end
        if v:IsA("Sound") then
            self:RenderSound(v, Gun.PrimaryPart)
        end
    end
end

function WeaponClient:RenderGrenade(Start, P1, P2)
    if Start and P1 and P2 then
        local GrenadeProp = ReplicatedStorage.GameAssets.Throwables.Grenade:Clone()
        GrenadeProp.Parent = workspace.Ignore
        GrenadeProp.PrimaryPart.Position = Start
        
        local Path = self:CalculateGrenade(P1, P2)
        Trajectory:Travel(GrenadeProp.PrimaryPart, Path)

        Debris:AddItem(GrenadeProp, 3)
    end
end

function WeaponClient:RenderVFX(Particle, Pos, Amount)
    local NewParticle = Particle:Clone()
    NewParticle.Parent = workspace.Ignore
    NewParticle.Position = Pos

    local HighestTime = 0
    for i,v in pairs(NewParticle:GetDescendants()) do
        if v:IsA("ParticleEmitter") then
            v:Emit(Amount)
            if v.Lifetime.Max > HighestTime then
                HighestTime = v.Lifetime.Max
            end
        end
    end

    Debris:AddItem(NewParticle, HighestTime)
end

function WeaponClient:Slide(Direction, CancelSpeed)
    self.CacheValues.IsSliding = true

    local NewBodyVelocity = Instance.new("BodyVelocity", Player.Character.PrimaryPart)
    NewBodyVelocity.MaxForce = Vector3.new(30000, 0, 30000)
    local SlideStart = tick()
    local SlideStart2 = tick()
    local Multi = 1

    local Sound = self:RenderSound(ReplicatedStorage.GameAssets.SFX.Slide, Player.Character.PrimaryPart, true)
    local Dir = self.Camera.CFrame.LookVector
    while Multi > 0.1 and NewBodyVelocity and Player.Character and self.CacheValues.SlideCancel == false do
        self.CacheValues.CameraOffset = self.CacheValues.CameraOffset:Lerp(CFrame.new(self.CacheValues.CameraOffset.X, -2, self.CacheValues.CameraOffset.Z), 0.1)
        local Vel = self:CalculateVelocity(Dir)
        local Params = RaycastParams.new()
        Params.FilterType = Enum.RaycastFilterType.Exclude
        Params.FilterDescendantsInstances = {self.Camera, Player.Character, workspace.SlideIgnore}

        local ForwardRay = workspace:Raycast(Player.Character["Left Leg"].Position + Vector3.new(0, 1, 0), Direction and Direction * 2 or Dir * 2, Params)
        if ForwardRay and Vel == 0 then
            break
        end

        NewBodyVelocity.Velocity = (Direction and Direction or Dir) * ((50+Vel) * Multi)

        if Vel <= 0 then
            Multi = 1 - (tick()-SlideStart)/1
        else    
            if not CancelSpeed and (tick()-SlideStart2 > 0.7) then
                SlideStart = tick()-(1 - (Vel/35))
            end
        end
        task.wait()
    end
    if NewBodyVelocity then
        NewBodyVelocity:Destroy()
        Sound:Destroy()
    end
    self.CacheValues.SlideCancel = false
    self.CacheValues.IsSliding = false
    for i = 1, 10 do
        self.CacheValues.CameraOffset = self.CacheValues.CameraOffset:Lerp(CFrame.new(self.CacheValues.CameraOffset.X, 0, self.CacheValues.CameraOffset.Z), 0.1)
        task.wait()
    end
    return
end

function WeaponClient:Flashlight()
    local Gun = self.Instances["Viewmodel"]:FindFirstChildWhichIsA("Model")
    if Gun then
        for i,v in pairs(Gun:GetDescendants()) do
            if v:IsA("SpotLight") or v:IsA("SurfaceLight") or v:IsA("Beam") then
                v.Enabled = not v.Enabled
            end
        end
        self.Services.WeaponServer:Flashlight():await()
        --[[for i,v in pairs(Player.Character:FindFirstChildWhichIsA("Model"):GetDescendants()) do
            if v:IsA("SpotLight") or v:IsA("SurfaceLight") or v:IsA("Beam") then
                v.Enabled = false
            end
        end--]]
    end
end

function WeaponClient:UpdateHUD()
    if self.Instances["Gun"] then
        local Values = self.Instances["Gun"].Values
        local Mag, Ammo, Type = Values.MagCur.Value, Values.Ammo.Value, Values.FireType.Value

        local Gun = self.Interfaces["Gun"].Gun.UI.Gun

        if Gun then
            Gun.Ammo.Text = Ammo
            Gun.Mag.Text = Mag
            Gun.Gun.Text = self.Instances["Gun"].Name .. " ︱ " .. Type
        end
    end

    if tick() - self.CacheValues.UpdateHUD < 0.5 then
        return
    end

    local Async, Perks = self.Services.WeaponServer:GetPerks():await()
    local Async, Parts = self.Services.Gameplay:GetParts():await()
    
    if Perks and Parts then
        for i,v in pairs(Perks) do
            Player.PlayerGui.HUD.Perks:FindFirstChild(v).Visible = true
            Player.PlayerGui.HUD.Perks:FindFirstChild(v).Position = UDim2.fromScale(0.052 + (0.036 * (i-1)) , 0.918)
        end

        for i,v in pairs(Parts) do
            Player.PlayerGui.HUD.Parts:FindFirstChild(v).Visible = true
        end

        for i,v in pairs(workspace:GetAttributes()) do
            if not Player.PlayerGui.HUD.Perks:FindFirstChild(i) then continue end 
            if v == true then
                Player.PlayerGui.HUD.Perks:FindFirstChild(i).Visible = true
            else
                Player.PlayerGui.HUD.Perks:FindFirstChild(i).Visible = false
            end
        end
    end

    self.CacheValues.UpdateHUD = tick()
end

function WeaponClient:UpdatePoints()
    local PlayerList = Players:GetChildren()
    table.sort(PlayerList, function(a, b)
        return a == Player
    end)

    local PointsFolder = self.Interfaces["Points"].UI
    for i = 1, #PlayerList do
        local Plr = PlayerList[i]
        self.Services.PointsService:GetPoints(Plr):andThen(function(Points)
            if not PointsFolder:FindFirstChild(Plr.Name) then
                local LowestY = math.huge
                for i,v in pairs(PointsFolder:GetChildren()) do
                    if v.Points.Position.Y.Scale < LowestY then
                        LowestY = v.Points.Position.Y.Scale
                    end
                end
                LowestY = (LowestY == math.huge and 0.806+0.08 or LowestY)

                local NewY = LowestY - 0.08
                local NewTemplate = ReplicatedStorage.GameAssets.UI.PointTemplate:Clone()
                NewTemplate.Parent = PointsFolder
                NewTemplate.Name = Plr.Name

                NewTemplate.Points.Position = UDim2.fromScale(0.45, NewY)
                NewTemplate.Profile.Position = UDim2.fromScale(0.009, NewY-0.017)
                NewTemplate.Gain.Position = UDim2.fromScale(0, NewY-0.006)

                local ThumbnailType = Enum.ThumbnailType.HeadShot
                local ThumbnailSize = Enum.ThumbnailSize.Size420x420
                local Content, IsReady = Players:GetUserThumbnailAsync(Plr.UserId, ThumbnailType, ThumbnailSize)
                NewTemplate.Profile.Image = Content
            else
                PointsFolder:FindFirstChild(Plr.Name).Points.Text = Points
            end
        end):catch(warn)
    end

    for i,v in pairs(PointsFolder:GetChildren()) do
        if not Players:FindFirstChild(v.Name) then
            local YLevel = v.Points.Position.Y.Scale

            --// Move anything over it down
            for _, PointsF in pairs(PointsFolder:GetChildren()) do
                if PointsF.Points.Position.Y.Scale < YLevel then
                    PointsF.Points.Position = UDim2.fromScale(0.45, PointsF.Points.Position.Y.Scale + 0.08)
                    PointsF.Profile.Position = UDim2.fromScale(0.009, PointsF.Profile.Position.Y.Scale + 0.08)
                    PointsF.Gain.Position = UDim2.fromScale(0, PointsF.Gain.Position.Y.Scale + 0.08)
                end
            end
            v:Destroy()
        end
    end
end

function WeaponClient:Fire(RecoilSpring, Viewmodel, RecoilCounter)
    if (tick()-self.CacheValues.LastShot < self.Instances["Gun"].Values.FireRate.Value) then return end
    if self.Instances["Gun"].Values.MagCur.Value <= 0 then
        self:RenderSound(self.Instances["Gun"].Sounds.Empty, self.Instances["ClientGun"].PrimaryPart)
        self.CacheValues.LastShot = tick()
        return true
    end
    RecoilSpring:Impulse(Vector3.new(math.random(-1,1), self.Instances["Gun"].Values.Recoil.Value / (self:IsAiming() and 3 or 1), 0))
    self.CacheValues.Animations["Firing"]:Play()
    self.CacheValues.LastShot = tick()

    self:Render(self.Camera.Viewmodel:FindFirstChildWhichIsA("Model"))

    self.Crosshair:Shove(30)

    local Params = RaycastParams.new()
    Params.FilterType = Enum.RaycastFilterType.Exclude
    Params.FilterDescendantsInstances = {Viewmodel, Player.Character, workspace.Ignore}
    Params.IgnoreWater = true
        
    local Radius = (self:GetCrosshairRadius() * self.Instances["Gun"].Values.Spread.Value) / 100

    local DirectionalCF = CFrame.new(Vector3.new(), self.Camera.CFrame.LookVector.Unit)
    local Direction = (DirectionalCF * CFrame.fromOrientation(0, 0, self.CacheValues.Rand:NextNumber(0, math.pi * 2)) * CFrame.fromOrientation(math.rad(self.CacheValues.Rand:NextNumber(Radius / 1.5, Radius)), 0, 0)).LookVector
    local RayResult = workspace:Raycast(self.Camera.CFrame.Position, Direction * 10000, Params)
        
    self.Services.WeaponServer:HandleShot(RayResult and {RayResult.Position, RayResult.Normal, RayResult.Instance, RayResult.Distance} or nil, {OriginDirection = DirectionalCF, OriginPosition = self.Camera.CFrame.Position})
    
    task.delay(0.3, function()
        --RecoilCounter:Impulse(Vector3.new(0, -self.Instances["Gun"].Values.Recoil.Value / (self:IsAiming() and 3 or 1), 0))
    end)
end

function WeaponClient:HasGun()
    return self.Instances["Gun"] or self.Instances["ClientGun"]
end

function WeaponClient:MakeConnection()
    local CameraShaker = CameraShake.new(Enum.RenderPriority.Camera.Value, function(ShakeCF)
        self.Camera.CFrame *= ShakeCF
    end)
    CameraShaker:Start()

    self.Services.WeaponServer.Render:Connect(function(Gun)
        self:Render(Gun)
    end)
    self.Services.WeaponServer.RenderGrenade:Connect(function(Start, P1, P2)
        self:RenderGrenade(Start, P1, P2)
    end)
    self.Services.WeaponServer.SFX:Connect(function(Sound, Part, RenderOnPart)
        self:RenderSound(Sound, Part, RenderOnPart)
    end)
    self.Services.WeaponServer.VFX:Connect(function(Particle, Pos, Amount)
        self:RenderVFX(Particle, Pos, Amount)
    end)
    self.Services.WeaponServer.Shake:Connect(function(PresetName)
        CameraShaker:Shake(CameraShake.Presets[PresetName])
    end)
    self.Services.WeaponServer.ClientEquip:Connect(function(Type)
        self:Equip(Type)
    end)
    self.Services.PointsService.PointsChanged:Connect(function(PointsPlr, NewPoints, PointsDifference)
        if not PointsPlr then return end
        local PlayerGui = Player.PlayerGui
        local HUD = self.Interfaces["Points"]
        if HUD then
            local PointsFolder = HUD.UI
            local PlayerPoints = PointsFolder:FindFirstChild(PointsPlr.Name)
            if PlayerPoints then
                local NewGain = PlayerPoints.Gain:Clone()
                NewGain.Parent = PlayerPoints
                NewGain.Text = (PointsDifference < 0 and "%d" or "+"  .. "%d"):format(PointsDifference)
                NewGain.Visible = true
                if PointsDifference < 0 then
                    NewGain.TextColor3 = Color3.fromRGB(255, 39, 39)
                end
                NewGain.Position = UDim2.new(PlayerPoints.Points.Position.X.Scale, PlayerPoints.Points.AbsoluteSize.X, NewGain.Position.Y.Scale, 0)
                TweenService:Create(NewGain, TweenInfo.new(2), {Position = UDim2.fromScale(NewGain.Position.X.Scale + math.random(25, 150)/1000, NewGain.Position.Y.Scale + math.random(-150, 150)/1000)}):Play()
                task.wait(0.8)
                TweenService:Create(NewGain, TweenInfo.new(0.2), {TextTransparency = 1}):Play()
                Debris:AddItem(NewGain, 0.5)
            end
        end
    end)

    Player.PlayerGui.HUD.AdminPanel.PointsButton.MouseButton1Click:Connect(function()
        self.Services.PointsService:AddPoints(tonumber(Player.PlayerGui.HUD.AdminPanel.PointsBox.Text))
    end)

    --// Jump detection
    Player.Character.Humanoid:GetPropertyChangedSignal("FloorMaterial"):Connect(function()
        local Hum = Player.Character.Humanoid
        if Hum.FloorMaterial == Enum.Material.Air then
            self.CacheValues.IsJumping = true
        else
            task.wait(0.5)
            self.CacheValues.IsJumping = false
        end
    end)

    --// To initialise the weapon system, we need to get a viewmodel
    local NewViewmodel = ReplicatedStorage.GameAssets.Viewmodels.Viewmodel:Clone()
    NewViewmodel.Parent = self.Camera

    table.insert(self.Connections, "Viewmodel")
    self.Instances["Viewmodel"] = NewViewmodel

    local MovementSway = Spring.new(Vector3.new())
    MovementSway.Speed = 20
    MovementSway.Damper = .4
    local RecoilSpring = Spring.new(Vector3.new())
    RecoilSpring.Speed = 20
    RecoilSpring.Damper = .4
    local RecoilCounterSpring = Spring.new(Vector3.new())
    RecoilCounterSpring.Speed = 10
    RecoilCounterSpring.Damper = 2

    local Aim = CFrame.new()
    self.Knife = self.Instances["Viewmodel"].Humanoid.Animator:LoadAnimation(self.Instances["Viewmodel"]["LeftArm"].Knife)
    self.Grenade = self.Instances["Viewmodel"].Humanoid.Animator:LoadAnimation(self.Instances["Viewmodel"]["LeftArm"].Grenade)

    --// Params
    local SlideParams = RaycastParams.new()
    SlideParams.FilterType = Enum.RaycastFilterType.Exclude
    SlideParams.IgnoreWater = true

    UserInputService.InputBegan:Connect(function(Input, IsTyping)
        if Input.KeyCode == Enum.KeyCode.Tab and not IsTyping then
            Player.PlayerGui.HUD.Scoreboard.Enabled = true
            repeat 
                task.wait()
            until not UserInputService:IsKeyDown(Enum.KeyCode.Tab)
            Player.PlayerGui.HUD.Scoreboard.Enabled = false
        end
        if self.CacheValues.IsReviving == true then return end
        if IsTyping or not self.Instances["Gun"] or not self:IsEngaged() then return end
        if Input.KeyCode == Enum.KeyCode.LeftShift then
            if self:IsDowned() then return end
            if self.CacheValues.IsReloading == true then
                if self.Instances["Gun"].Values.MagCur.Value == self.Instances["Gun"].Values.MagSize.Value then
                    return
                end
                self.Services.WeaponServer:CancelReload()
                self.CacheValues.Animations["Reloading"]:Stop()
                self.CacheValues.IsReloading = false
                return
            end
        end
        if Input.UserInputType == Enum.UserInputType.MouseButton1 and not self:IsSprinting() and (tick()-self.CacheValues.LastShot >= self.Instances["Gun"].Values.FireRate.Value) then
            if self.CacheValues.IsReloading == true then
                if self.Instances["Gun"].Values.MagCur.Value == self.Instances["Gun"].Values.MagSize.Value then
                    return
                end
                self.Services.WeaponServer:CancelReload()
                self.CacheValues.Animations["Reloading"]:Stop()

                task.wait(1)
                self.CacheValues.IsReloading = false
                return
            end
            if self.Instances["Gun"].Values.FireType.Value == "Auto" then
                while UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) and not self:IsReloading() do
                    local CanBreak = self:Fire(RecoilSpring, NewViewmodel, RecoilCounterSpring)
                    if CanBreak then
                        break
                    end
                    task.wait()
                end
            else
                self:Fire(RecoilSpring, NewViewmodel, RecoilCounterSpring)
            end
        end
        if Input.KeyCode == Enum.KeyCode.R and not self.CacheValues.IsReloading and self.Instances["Gun"].Values.MagCur.Value < self.Instances["Gun"].Values.MagSize.Value and self.Instances["Gun"].Values.Ammo.Value > 0 then
            self.CacheValues.Animations["Reloading"]:Play()
            if self.Services.WeaponServer:HasPerk("Speed Cola") then
                self.CacheValues.Animations["Reloading"]:AdjustSpeed(1.75)
            end
            self.CacheValues.IsReloading = true
            self.Services.WeaponServer:Reload()
            self.CacheValues.Animations["Reloading"].Ended:Wait()
            self.CacheValues.IsReloading = false;
        end
        if Input.KeyCode == Enum.KeyCode.C and not self:IsSliding() and self:IsSprinting() and not self.CacheValues.IsJumping then
            if self:IsDowned() then return end
            self:Slide()
            return
        end
        if Input.KeyCode == Enum.KeyCode.C and not self:IsSprinting() and not self:IsSliding() then
            if self:IsDowned() then return end
            self.CacheValues.IsCrouching = not self:IsCrouching()
        end
        if Input.KeyCode == Enum.KeyCode.V and not self:IsSliding() and (tick() - self.CacheValues.LastKnife) > 1 then
            self.CacheValues.IsKnifing = true
            self.CacheValues.LastKnife = tick()
            
            local Knife = ReplicatedStorage.GameAssets.Knifes.Knife:Clone()
            Knife.Parent = self.Instances["Viewmodel"]
            self.Instances["Viewmodel"]["LeftArm"].Attach.Part1 = Knife.PrimaryPart

            self.Knife:Play()

            self.Services.WeaponServer:Knife()
            self.Knife.Stopped:Wait()

            Knife:Destroy()
            self.CacheValues.IsKnifing = false
        end
        if Input.KeyCode == Enum.KeyCode.Space then
            if self:IsDowned() then return end
            Player.Character.Humanoid.JumpPower = 0
            if self:IsCrouching() then
                self.CacheValues.IsCrouching = false
                return
            end
            if self:IsSliding() then
                self.CacheValues.SlideCancel = true
                return
            end
            
            Player.Character.Humanoid.JumpPower = 35
        end
        if Input.KeyCode == Enum.KeyCode.F then
            if self:IsDowned() then return end
            if self.CurrentBarrier == "" and self.CurrentDoor == "" and self.CurrentPart == "" and self.CurrentPlayer == "" and self.CacheValues.Power == false and not workspace:GetAttribute("ClientPrompt") then
                self:Flashlight()
            else
                if self.CurrentBarrier ~= "" then --// Higher priority
                    self.Services.WeaponServer:BarrierStart(self.CurrentBarrier)
                    self.CacheValues.IsRepairing = true

                    while UserInputService:IsKeyDown(Enum.KeyCode.F) do
                        task.wait()
                    end
                    if self.CurrentBarrier ~= "" then
                        self.Services.WeaponServer:BarrierStop(self.CurrentBarrier)
                    end
                    self.CacheValues.IsRepairing = false
                    return
                end
                if self.CurrentPlayer ~= "" then
                    local Start = tick()
                    self.Services.WeaponServer:ReviveStart(self.CurrentPlayer)
                    self.CacheValues.IsReviving = true
                    Player.PlayerGui.HUD.ReviveFrame.Visible = true

                    while UserInputService:IsKeyDown(Enum.KeyCode.F) do
                        task.wait()
                        Player.PlayerGui.HUD.ReviveFrame.Cover.Size = UDim2.fromScale(math.clamp(self:Lerp(0, 1, (tick()-Start)/ (Player:GetAttributes()["Quick Revive"] == true and 2.5 or 5)), 0, 1), 1)
                    end
                    if self.CurrentPlayer ~= "" then
                        self.Services.WeaponServer:ReviveStop()
                    end
                    Player.PlayerGui.HUD.ReviveFrame.Visible = false
                    self.CacheValues.IsReviving = false
                    return
                end

                if self.CurrentPart ~= "" then
                    self.Services.Gameplay:PickupPart(self.CurrentPart)
                    return
                end

                task.wait(1) --// Hold delay
                if self.CacheValues.Power == true then
                    self.Services.Gameplay:Power()
                    return
                end
                if self.CurrentDoor ~= "" and UserInputService:IsKeyDown(Enum.KeyCode.F) then
                    self.Services.WeaponServer:UnlockDoor(self.CurrentDoor)
                    return
                end
            end
        end
        if Input.KeyCode == Enum.KeyCode.E then
            if self:IsDowned() then return end
            local Async, BuyPerk = self.Services["WeaponServer"]:GetPerk(self.CurrentPerk):await()
            if BuyPerk then
                print("Bought")
                -- Animations and stuff
            end
        end
    end)

    RunService:BindToRenderStep("Viewmodel", 301, function(DT)
        if Player:GetAttributes()["Dead"] then
            self.Controllers["Spectate"]:StartSpectate()
            return 
        else
            self.Controllers["Spectate"]:StopSpectate()
        end
        UserInputService.MouseIconEnabled = false
        local Rot = self.Camera.CFrame:ToObjectSpace(self.CacheValues.LastCF)
        local X, Y, Z = Rot:ToOrientation()
        self.CacheValues.SOffset = self.CacheValues.SOffset:Lerp(CFrame.Angles(math.sin(X) ,math.sin(Y), 0), 0.1)        
        self.CacheValues.CameraOffset = self.CacheValues.CameraOffset:Lerp(CFrame.new(self.CacheValues.CameraOffset.X, (self.CacheValues.IsCrouching == true and -2 or self:IsDowned() and -1.5 or 0), (self:IsDowned() and 1.5 or 0)), 0.1)

        self:UpdatePoints()

        if UserInputService:IsKeyDown(Enum.KeyCode.G) and not self:IsSliding() and not self:IsThrowing() and (tick() - self.CacheValues.LastGrenade) > 2 and Player.Character and Player.Character:FindFirstChildWhichIsA("Humanoid") and Player.Character:FindFirstChildWhichIsA("Humanoid").Health > 0 and not UserInputService:GetFocusedTextBox() then
            self.CacheValues.IsThrowing = true
            self.CacheValues.HoldStart = tick()
            if not self.Instances["Viewmodel"]:FindFirstChild("Grenade") then
                local Grenade = ReplicatedStorage.GameAssets.Throwables.Grenade:Clone()
                Grenade.Parent = self.Instances["Viewmodel"]
                self:RenderSound(Grenade.Sounds.Pin, Grenade.PrimaryPart)

                self.Instances["Viewmodel"]["LeftArm"].Attach.Part1 = Grenade.PrimaryPart
                self.Grenade:Play()
                local Event 
                Event = self.Grenade:GetMarkerReachedSignal("Hold"):Connect(function()
                    if self:IsThrowing() then
                        self.Grenade:AdjustSpeed(0)
                    else
                        self.Grenade:Stop()
                    end
                    Event:Disconnect()
                end)
            end
        end

        if (tick() - self.CacheValues.HoldStart) > 3 and UserInputService:IsKeyDown(Enum.KeyCode.G) then
            local ClientGrenade = self.Instances["Viewmodel"]:FindFirstChild("Grenade")

            if ClientGrenade then
                self.CacheValues.LastGrenade = tick()
                self.CacheValues.IsThrowing = false
                self.Grenade:Stop()

                self:RenderSound(ClientGrenade.Sounds.Explode, ClientGrenade.PrimaryPart)
                self:RenderVFX(ReplicatedStorage.GameAssets.VFX.Particles.Explosion, ClientGrenade.PrimaryPart.Position, 70)
                
                Player.Character.Humanoid:TakeDamage(100)
                ClientGrenade:Destroy()
            end
        end

        if not UserInputService:IsKeyDown(Enum.KeyCode.G) and self:IsThrowing() then
            self.Services.WeaponServer:Grenade(self.Mouse.Hit.p, self.Camera.CFrame.Position)
            local ClientGrenade = self.Instances["Viewmodel"]:FindFirstChild("Grenade")
            ClientGrenade.Parent = workspace.Ignore
            self:RenderSound(ClientGrenade.Sounds.Throw, ClientGrenade.PrimaryPart)

            if ClientGrenade then
                self.Grenade:AdjustSpeed(1)
                self.Instances["Viewmodel"]["LeftArm"].Attach.Part1 = nil
                
                local Path = self:CalculateGrenade(self.Mouse.Hit.p, self.Camera.CFrame.Position)
                Trajectory:Travel(ClientGrenade.PrimaryPart, Path)
                Debris:AddItem(ClientGrenade, 3)
            end

            self.CacheValues.IsThrowing = false
            self.CacheValues.LastGrenade = tick()
        end

        if Player.Character and Player.Character:FindFirstChild("HumanoidRootPart") then
            SlideParams.FilterDescendantsInstances = {Player.Character, self.Instances["Viewmodel"]}
            local RayDown = workspace:Raycast(Player.Character.PrimaryPart.Position, Player.Character.PrimaryPart.CFrame.UpVector * -1000, SlideParams)

            if RayDown and RayDown.Instance.Name == "Slide" and not self:IsSliding() then
                self:Slide(workspace.SlideCam.CFrame.LookVector, true)
            end

            local MovementSwayAmount = Vector3.new(self:GetBobbing(10, 1, .2), self:GetBobbing(5, 1, .2), self:GetBobbing(5, 1, .2))
            MovementSway.Velocity += ((MovementSwayAmount / (self:IsAiming() and 60 or 25)) * DT * 60 * Player.Character.HumanoidRootPart.AssemblyLinearVelocity.Magnitude)
            if self:IsAiming() and self.Instances["Gun"] then
                local GoodRun = true
                if self.CacheValues.IsReloading == true and self.Instances["Gun"].Values.MagCur.Value ~= self.Instances["Gun"].Values.MagSize.Value then
                    --self.Services.WeaponServer:CancelReload()
                    --self.CacheValues.Animations["Reloading"]:Stop()
                    --self.CacheValues.IsReloading = false
                    GoodRun = true
                end
                if self.CacheValues.IsReloading == false then
                    GoodRun = true
                end

                if GoodRun and self.Camera.Viewmodel:FindFirstChildWhichIsA("Model") and self.Camera.Viewmodel:FindFirstChildWhichIsA("Model"):FindFirstChild("AimPart") then
                    Aim = Aim:Lerp(self.Camera.Viewmodel:FindFirstChildWhichIsA("Model").AimPart.CFrame:ToObjectSpace(NewViewmodel.PrimaryPart.CFrame), 0.15)
                    self.CacheValues.SOffset = CFrame.new()
                    self.Crosshair:Disable()
                end
            else
                Aim = Aim:Lerp(CFrame.new() * self.CacheValues.ViewmodelOffset, 0.1)
                self.Crosshair:Enable()
            end

            NewViewmodel:PivotTo(
                self.Camera.CFrame * CFrame.new(MovementSway.Position.X / 2, MovementSway.Position.Y / 2, 0)
                * CFrame.Angles(RecoilSpring.Position.Y, 0, RecoilSpring.Position.X)
                * CFrame.Angles(RecoilCounterSpring.Position.Y, 0, RecoilCounterSpring.Position.X)
                * Aim
                * CFrame.Angles(0, MovementSway.Position.Y, MovementSway.Position.X)
                * self.CacheValues.SOffset
                * self.CacheValues.CameraOffset
            )
            self.Interfaces["Gun"]:PivotTo(
                self.Camera.CFrame * CFrame.new(2, -1, -2) 
                * CFrame.Angles(0, -math.pi / 6, 0)
                * CFrame.new(MovementSway.Position.X / 2, MovementSway.Position.Y / 2, 0)
                * CFrame.Angles(RecoilSpring.Position.Y, 0, RecoilSpring.Position.X)
                --* CFrame.Angles(0, MovementSway.Position.Y, MovementSway.Position.X)
                * self.CacheValues.SOffset
                * self.CacheValues.CameraOffset
            )
            self.Interfaces["Points"].CFrame = (
                self.Camera.CFrame * CFrame.new(-2.9, 0.625, -3)
                * CFrame.Angles(0, math.pi / 6, 0)
                * CFrame.new(MovementSway.Position.X / 2, MovementSway.Position.Y / 2, 0)
                * CFrame.Angles(RecoilSpring.Position.Y, 0, RecoilSpring.Position.X)
                * self.CacheValues.SOffset
                * self.CacheValues.CameraOffset
            )
            self.Camera.CFrame *= CFrame.Angles(RecoilSpring.Position.Y/4 , 0, RecoilSpring.Position.X)
            self.Camera.CFrame *= CFrame.Angles(RecoilCounterSpring.Position.Y/4, 0, RecoilCounterSpring.Position.X)
            if self:IsDowned() and self.Instances["ClientGun"] then
                local X, Y, Z = self.Camera.CFrame:ToOrientation()
                local newX = math.clamp(math.deg(X), 0, 80)
                self.Camera.CFrame = CFrame.new(self.Camera.CFrame.Position) * CFrame.fromOrientation(math.rad(newX), Y, Z)
                self.CacheValues.ViewmodelOffset = CFrame.new(-1, self.CacheValues.ViewmodelOffset.Y, self.Instances["ClientGun"].Values.Offset.Value.Z - 0.3)
            end
        end

        self.Camera.CFrame = self.Camera.CFrame * self.CacheValues.CameraOffset
        self.CacheValues.LastCF = self.Camera.CFrame
        if self.Instances["Gun"] and self.CacheValues.Animations["Idle"] then
            if self:IsSprinting() and self.CacheValues.IsReloading == false and not self:IsDowned() then
                self.CacheValues.IsCrouching = false
                self.CacheValues.Animations["Sprinting"]:Play()
                Player.Character.Humanoid.WalkSpeed = 18
                self.Crosshair:Shove(25)
            else
                self.CacheValues.Animations["Idle"]:Play()
                self.CacheValues.Animations["Replicate_Idle"]:Play()

                self.CacheValues.Animations["Sprinting"]:Stop()
                if self:IsCrouching() then
                    Player.Character.Humanoid.WalkSpeed = 6
                elseif self.CacheValues.IsReviving == true then
                    Player.Character.Humanoid.WalkSpeed = 0
                else
                    Player.Character.Humanoid.WalkSpeed = 10
                end
                --Crosshair:Set(15)
            end
        end
        self:UpdateHUD()
    end) --// 300 is camera so we up priority by 1
end

function WeaponClient:LoadAnimations(Folder, Replicates, Animator)
    self.CacheValues.Animations = {}
    for i,v in pairs(Folder:GetChildren()) do
        self.CacheValues.Animations[v.Name] = Animator:LoadAnimation(v)
    end
    for i,v in pairs(Replicates:GetChildren()) do
        self.CacheValues.Animations["Replicate_" .. v.Name] = Player.Character.Humanoid:LoadAnimation(v)
    end
    self.Downed = self.AnimationHandler:CreateAnimation(Player.Character.Humanoid, "14594773177")
end

function WeaponClient:Equip(Type)
    if self:IsEquipping() then return end
    if Player.Character and Player.Character:FindFirstChild("Humanoid") and Player.Character:FindFirstChild("Humanoid").Health > 0 then
        else 
        return 
    end

    local Async, GunName = self.Services["WeaponServer"]:GetGun(Type):await()
    if GunName == "None" then
        return --warn("No gun in slot:", Type)
    end
    if self:HasGun() then
        if self:HasGun().Name == GunName then
            return
        end
        self.CacheValues.IsEquipping = true
        self:Unequip()
    end

    local Async, Gun = self.Services["WeaponServer"]:Equip(Type):await()
    repeat task.wait() until Gun:FindFirstChildWhichIsA("BasePart") 

    local GunClone = Gun:Clone()
    GunClone.Parent = self.Instances["Viewmodel"]
    GunClone.PrimaryPart.Anchored = false
    self.Instances["Viewmodel"].RightArm.Attach.Part1 = GunClone.PrimaryPart
    self:LoadAnimations(Gun.Animations, Gun.ReplicateAnimations, self.Instances["Viewmodel"].Humanoid.Animator)

    self.CacheValues.ViewmodelOffset = Gun.Values.Offset.Value
    self.CacheValues.Events["Reload"] = self.CacheValues.Animations["Reloading"].KeyframeReached:Connect(function(Name)
        self:RenderSound(Gun.Sounds:FindFirstChild(Name), Gun.PrimaryPart)
    end)

    for i,v in pairs(Gun:GetDescendants()) do
        if v:IsA("BasePart") and Gun.PrimaryPart ~= v then
            if v.Transparency == 1 then
                continue
            end
            v:Destroy()
        end
        if Gun.PrimaryPart == v then
            v.Transparency = 1
        end
    end

    self.Instances["Gun"] = Gun
    self.Instances["ClientGun"] = GunClone
    self.CacheValues.IsEquipping = false
end

function WeaponClient:Unequip()
    local Gun = self.Instances["ClientGun"]
    if Gun then
        for i,v in pairs(self.CacheValues.Animations) do
            v:Stop()
        end
        Gun:Destroy()
        self.CacheValues.Animations = {}
        self.Services.WeaponServer:Unequip():await()
        self.Instances["Gun"] = nil
        self.Instances["ClientGun"] = nil
    end
end

function WeaponClient:CloseConnection()
    table.foreach(self.Connections, function(i, v)
        RunService:UnbindFromRenderStep(v)
    end)
end

function WeaponClient:KnitInit()
    for i,v in pairs(self.Services) do
        self.Services[i] = Knit.GetService(i)
    end
    for i,v in pairs(self.Controllers) do
        self.Controllers[i] = Knit.GetController(i)
    end

    -- UI
    local GunUI = Player.PlayerGui.Gun:Clone()
    GunUI.Parent = self.Camera
    self.Interfaces["Gun"] = GunUI

    local PointsUI = Player.PlayerGui.Points:Clone()
    PointsUI.Parent = self.Camera
    self.Interfaces["Points"] = PointsUI

    RunService.RenderStepped:Connect(function(deltaTime)
        if not Player.Character or Player.Character and not Player.Character.PrimaryPart then return end

        if Player:GetAttributes()["Dead"] then
            Player.PlayerGui.HUD.Spectate.Visible = true
        else
            Player.PlayerGui.HUD.Spectate.Visible = false
        end

        if self.CurrentPlayer == "" then
            local Any = false
            for i,v in pairs(workspace["Perk Machines"]:GetChildren()) do
                if not Player.Character and not Player.Character.PrimaryPart then return end
                local PerkPos = v.WorldPivot.Position
                local PlayerPos = Player.Character.PrimaryPart.Position
                local Dist = math.abs((PerkPos-PlayerPos).Magnitude)
    
                if Dist < 5 then
                    Any = true
                    if workspace:GetAttribute("Power") == true then
                        Player.PlayerGui.HUD.Perk.Text = ('Press [<font color="#FF7800">E</font>] to purchase %s ($%d)'):format(v.Name, v:GetAttribute("Price"))
                    else
                        Player.PlayerGui.HUD.Perk.Text = "The power is off"
                    end
                    self.CurrentPerk = v.Name
                end
            end
            if not Any then
                self.CurrentPerk = ""
                Player.PlayerGui.HUD.Perk.Text = ""
            end

            local Barrier = nil
            for i,v in pairs(workspace.Map.Barriers:GetChildren()) do
                if not Player.Character and not Player.Character.PrimaryPart then return end
                local BarrierPos = v.WorldPivot.Position
                local PlayerPos = Player.Character.PrimaryPart.Position
                local Dist = math.abs((BarrierPos-PlayerPos).Magnitude)

                if Dist < 5 then
                    Barrier = v
                end
            end

            if Barrier ~= nil then
                Player.PlayerGui.HUD.Barrier.Visible = true
                self.CurrentBarrier = Barrier
            else
                Player.PlayerGui.HUD.Barrier.Visible = false
                self.CurrentBarrier = ""
            end

            local Door = nil
            for i,v in pairs(workspace.DoorBuys:GetChildren()) do
                if not Player.Character and not Player.Character.PrimaryPart then return end
                local DoorPos = v.Position
                local PlayerPos = Player.Character.PrimaryPart.Position
                local Dist = math.abs((DoorPos-PlayerPos).Magnitude)

                if Dist < 5 then
                    Door = v
                end
            end

            if Door ~= nil then
                local Str = 'Hold [<font color="#FF7800">F</font>] to open Door [Cost: $%d]'
                Player.PlayerGui.HUD.Door.Visible = true
                Player.PlayerGui.HUD.Door.Text = Str:format(Door.Price.Value)
                self.CurrentDoor = Door
            else
                Player.PlayerGui.HUD.Door.Visible = false
                self.CurrentDoor = ""
            end

            local Part = nil
            for i,v in pairs(workspace.Power.Buildables:GetChildren()) do
                if not Player.Character and not Player.Character.PrimaryPart then return end
                local PartPos = v.WorldPivot.Position
                local PlayerPos = Player.Character.PrimaryPart.Position
                local Dist = math.abs((PartPos-PlayerPos).Magnitude)

                if Dist < 10 then
                    Part = v
                end
            end

            if Part ~= nil then
                Player.PlayerGui.HUD.Power.Visible = true
                self.CurrentPart = Part
            else
                Player.PlayerGui.HUD.Power.Visible = false
                self.CurrentPart = ""
            end

            if workspace.Power:FindFirstChild("Area") and table.find(workspace:GetPartsInPart(Player.Character.PrimaryPart), workspace.Power.Area) and workspace:GetAttribute("Power") == false then
                local Enabled = true
                for i,v in pairs(Player.PlayerGui.HUD.Parts:GetChildren()) do
                    if v.Visible == false then
                        Enabled = false
                    end
                end

                if Enabled == true then
                    Player.PlayerGui.HUD.PowerOn.Text = ('Hold [<font color="#FF7800">F</font>] to enable power')
                    self.CacheValues.Power = true
                else
                    Player.PlayerGui.HUD.PowerOn.Text = ("You are missing parts")
                end
            else
                Player.PlayerGui.HUD.PowerOn.Text = ""
                self.CacheValues.Power = false
            end
        end

        local RevPlayer = nil
        for i,v in pairs(Players:GetPlayers()) do
            if v == Player then continue end
            local Char = v.Character
            local SelfPlayerChar = Player.Character
            if Char and Char.PrimaryPart and Char:FindFirstChild("Humanoid") and Char.Humanoid.Health <= 1 and SelfPlayerChar and SelfPlayerChar:FindFirstChild("Humanoid") and SelfPlayerChar.Humanoid.Health > 0 then
                if not Player.Character and not Player.Character.PrimaryPart then return end
                local PartPos = Char.PrimaryPart.Position
                local PlayerPos = Player.Character.PrimaryPart.Position
                local Dist = math.abs((PartPos-PlayerPos).Magnitude)

                if Dist < 7 then
                    RevPlayer = Char
                end
            end
        end

        if RevPlayer then
            Player.PlayerGui.HUD.Revive.Visible = true
            self.CurrentPlayer = RevPlayer
        else
            Player.PlayerGui.HUD.Revive.Visible = false
            self.CurrentPlayer = ""
        end

        local Character = Player.Character
        if Character and Character:FindFirstChildWhichIsA("Humanoid") then
            local Humanoid = Character:FindFirstChildWhichIsA("Humanoid")
            if Humanoid and Humanoid.Health <= 1 then
                Humanoid.Health = 1
                Humanoid.WalkSpeed = 2
                Humanoid.JumpPower = 0
                if self.CacheValues.IsDowned == false then
                    self.Services.Gameplay:Downed()
                end
                self.CacheValues.IsDowned = true

                Character.Torso.LocalTransparencyModifier = 0
                Character["Left Leg"].LocalTransparencyModifier = 0
                Character["Right Leg"].LocalTransparencyModifier = 0

                local DeathTick = Player:GetAttribute("Downed")
                if DeathTick then
                    game.Lighting.ColorCorrection.Saturation = self:Lerp(0, 1, (tick()-DeathTick)/27)
                    Player.PlayerGui:FindFirstChild("HUD").Blood.ImageTransparency = self:Lerp(1, 0.5, (tick()-DeathTick)/30)
                end

                self.Downed:Play()
            else
                self.CacheValues.IsDowned = false
                Humanoid.JumpPower = 35
                game.Lighting.ColorCorrection.Saturation = 0
                Player.PlayerGui:FindFirstChild("HUD").Blood.ImageTransparency = 1


                if self.Downed ~= "None" then
                    self.Downed:Stop()
                end
            end
        end
    end) --// Client game loop

    print("[Knit Client] Weapon System initialised!")
end

return WeaponClient