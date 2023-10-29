local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Trajectory = require(ReplicatedStorage.ExternalModules.Trajectory).new(Vector3.new(0, -game.Workspace.Gravity, 0))
local Admins = require(ReplicatedStorage.Source.Admins)

local WeaponServer = Knit.CreateService{
    Name = "WeaponServer",
    Client = {
        Render = Knit.CreateSignal();
        RenderGrenade = Knit.CreateSignal();
        VFX = Knit.CreateSignal();
        SFX = Knit.CreateSignal();
        Shake = Knit.CreateSignal();
        ClientEquip = Knit.CreateSignal();
    },
    Services = {
        ["VFXService"] = 0;
        ["VisualiseService"] = 0;
        ["PointsService"] = 0;
    },
    Inventories = {};
    Equipped = {};
    Perks = {};
    InTask = {Reload = {}; Barrier = {}; Revive = {}};
    PowerupTimes = {};

    HitMultipliers = {
        ["Left Arm"] = 0.8;
        ["Right Arm"] = 0.8;
        ["Left Leg"] = 0.6;
        ["Right Leg"] = 0.6;
        ["Torso"] = 1;
        ["Head"] = 2;
    };

    PenetrationMultipliers = {
        [Enum.Material.Wood] = 0.6;
        [Enum.Material.Metal] = 0.2;
        [Enum.Material.Concrete] = 0.3;
        [Enum.Material.Brick] = 0.3;
        [Enum.Material.Plastic] = 0.7;
        [Enum.Material.SmoothPlastic] = 0.7;
        [Enum.Material.WoodPlanks] = 0.6;
    };

    PerksData = {
        ["Speed Cola"] = 3000;
        ["Quick Revive"] = 500;
        ["Juggernog"] = 2500;
        ["Double Tap"] = 2000;
        ["Pack A Punch"] = 5000;
    }
}


--// Server --> Client
function WeaponServer.Client:Equip(Player, Type, WeaponName)
    return self.Server:Equip(Player, Type, WeaponName)
end

function WeaponServer.Client:Unequip(Player)
    return self.Server:Unequip(Player)
end

function WeaponServer.Client:GetGun(Player, Type)
    return self.Server:GetGun(Player, Type)
end

function WeaponServer.Client:GetInventory(Player)
    return self.Server:GetInventory(Player)
end

function WeaponServer.Client:HandleShot(Player, RayResult, Origins)
    return self.Server:HandleShot(Player, RayResult, Origins)
end

function WeaponServer.Client:GetValues(Player)
    return self.Server:GetValues(Player)
end

function WeaponServer.Client:Reload(Player)
    return self.Server:Reload(Player)
end

function WeaponServer.Client:CancelReload(Player)
    return self.Server:CancelReload(Player)
end

function WeaponServer.Client:Knife(Player)
    return self.Server:Knife(Player)
end

function WeaponServer.Client:Grenade(Player, P1, P2)
    return self.Server:Grenade(Player, P1, P2)
end

function WeaponServer.Client:Flashlight(Player)
    return self.Server:Flashlight(Player)
end

function WeaponServer.Client:GetPerk(Player, Perk)
    return self.Server:GetPerk(Player, Perk)
end

function WeaponServer.Client:HasPerk(Player, Perk)
    return self.Server:HasPerk(Player, Perk)
end

function WeaponServer.Client:GetPerks(Player)
    return self.Server:GetPerks(Player)
end

function WeaponServer.Client:BarrierStart(Player, Barrier)
    return self.Server:BarrierStart(Player, Barrier)
end

function WeaponServer.Client:BarrierStop(Player, Barrier)
    return self.Server:BarrierStop(Player, Barrier)
end

function WeaponServer.Client:ReviveStart(Player, Char)
    return self.Server:ReviveStart(Player, Char)
end

function WeaponServer.Client:ReviveStop(Player)
    return self.Server:ReviveStop(Player)
end

function WeaponServer.Client:UnlockDoor(Player, Door)
    return self.Server:UnlockDoor(Player, Door)
end

function WeaponServer.Client:PurchaseGun(Player, GunName)
    return self.Server:PurchaseGun(Player, GunName)
end

function WeaponServer.Client:OpenBox(Player)
    return self.Server:OpenBox(Player)
end

function WeaponServer.Client:PickupGun(Player)
    return self.Server:PickupGun(Player)
end

function WeaponServer.Client:GiveGun(Player, PlayerTo, Gun)
    return self.Server:GiveGun(Player, PlayerTo, Gun)
end

function WeaponServer.Client:GetPowerup(Player, Powerup)
    return self.Server:CollectPowerup(Player, Powerup);
end

function WeaponServer:FireAll(Signal, ...)
    for i,v in pairs(Players:GetPlayers()) do
        self.Client[Signal]:Fire(v, ...)
    end
end

function WeaponServer:GetPlayersInRange(Position, Range)
    local PlayersList = workspace.Zombies:GetChildren()
    local RangeList = {}

    for i,v in pairs(PlayersList) do
        local Character = v.Character
        if Character then
            local HRPos = Character.PrimaryPart.Position
            if math.abs((HRPos-Position).Magnitude) <= Range then
                RangeList[v] = math.abs((HRPos-Position).Magnitude)
            end
        end
    end

    return RangeList
end

function WeaponServer:MakeInventory(Player)
    if not self.Inventories[Player.UserId] then
        self.Inventories[Player.UserId] = {
            Primary = {"None", {}};
            Secondary = {"None", {}};
            Knife = {"None", {}};
        }
        self.Perks[Player] = {}
    end
    if not self.Equipped[Player.UserId] then
        self.Equipped[Player.UserId] = {"None", "None"}
    end
end

function WeaponServer:ChangeGun(Player, Type, WeaponName)
    self:MakeInventory(Player)
    self.Inventories[Player.UserId][Type][1] = WeaponName
    self.Inventories[Player.UserId][Type][2] = {}
end

function WeaponServer:Equip(Player, Type)
    --// From server end
    --[[ 
        We need to
        1. Check if player has weapon in inventory
        2. We clone the weapon into character
        3. Return weapon to client so that it can add it to viewmodel and such
    ]]

    self:MakeInventory(Player)
    local WeaponName = self.Inventories[Player.UserId][Type][1]
    if WeaponName ~= nil and self.Inventories[Player.UserId][Type][1] == WeaponName then
        local NewWeapon = ReplicatedStorage.GameAssets.Weapons[WeaponName]:Clone()

        if not self.Inventories[Player.UserId][Type][2]["Ammo"] then
            for i,v in pairs(NewWeapon.Values:GetChildren()) do
                self.Inventories[Player.UserId][Type][2][v.Name] = v.Value
            end
        else
            for i,v in pairs(self.Inventories[Player.UserId][Type][2]) do
                NewWeapon.Values[i].Value = v
            end
        end

        repeat task.wait() until Player.Character
        local Joint = Instance.new("Motor6D", Player.Character["Right Arm"])
        Joint.Part0 = Player.Character["Right Arm"]
        Joint.Part1 = NewWeapon.PrimaryPart
        NewWeapon.Parent = Player.Character

        local WeaponTag = Instance.new("StringValue", NewWeapon)
        WeaponTag.Name = "Tag"
        WeaponTag.Value = Player.UserId

        self.Equipped[Player.UserId] = {Type, WeaponName}
        return NewWeapon
    end

    return nil
end

function WeaponServer:Unequip(Player)
    if Player.Character then
        local Char = Player.Character
        local Gun = Char:FindFirstChildWhichIsA("Model")
        if Gun then
            if #self.Inventories[Player.UserId][self.Equipped[Player.UserId][1]][2] ~= 0 then
                for i,v in pairs(Gun.Values:GetChildren()) do
                    self.Inventories[Player.UserId][self.Equipped[Player.UserId][1]][2][v.Name] = v.Value
                end
            end
            Gun:Destroy()
        end
        self.Equipped[Player.UserId] = {"None", "None"}
    end
end

function WeaponServer:GetGun(Player, Type)
    return self.Inventories[Player.UserId][Type][1]
end

function WeaponServer:HandleShot(Player, RayResult, Origins)
    local Values, Gun = self:GetValues(Player)
    --//Pre Checks
    if Values["MagCur"] <= 0 then
        return
    end
    
    --// Gun fired, take 1 bullet from mag or if shotgun repeat bpr times with spread and only take 1 ammo after that
    if Values["FireType"] == "Shotgun" then
        if Gun.Values.FireType.Load.Value >= Gun.Values.FireType.BulletsPerRound.Value then
            Gun.Values.MagCur.Value -= 1
            Gun.Values.FireType.Load.Value = 0
            return
        else
            local Angle = CFrame.Angles(0, 0, math.pi * 2 * math.random()) * CFrame.Angles(math.random() * Values["Spread"]/10, 0, 0)
            local DirectionalCF = (Origins["OriginDirection"] * Angle).LookVector

            local Params = RaycastParams.new()
            Params.FilterType = Enum.RaycastFilterType.Exclude
            Params.FilterDescendantsInstances = {Player.Character, workspace.Ignore}
            Params.IgnoreWater = true
            local RayResult = workspace:Raycast(Origins["OriginPosition"], DirectionalCF * 10000, Params)

            Gun.Values.FireType.Load.Value += 1
            self:HandleShot(Player, RayResult and {RayResult.Position, RayResult.Normal, RayResult.Instance, RayResult.Distance} or nil, Origins)
        end
    else
        Gun.Values.MagCur.Value -= 1
    end

    --//After checks
    if RayResult == nil then
        return
    end

    --// Parse the data
    local Pos, Normal, Inst, Dist = unpack(RayResult)

    --// Reverify the shot
    local Character = Player.Character
    if Character then
        local Params = RaycastParams.new()
        Params.FilterType = Enum.RaycastFilterType.Exclude
        Params.FilterDescendantsInstances = {Player.Character, workspace.Ignore}
        Params.IgnoreWater = true
        
        local ServerResult = workspace:Raycast(Player.Character.Head.Position, (Pos - Player.Character.Head.Position).Unit * 10000, Params)
        if ServerResult then
            --self.Services.VisualiseService:VisualiseRay(Player.Character.Head.Position, (Pos - Player.Character.Head.Position).Unit * ServerResult.Distance, 15, {Color = Color3.fromRGB(255, 0, 0)})
            if ServerResult.Instance.Parent:FindFirstChildWhichIsA("Humanoid") and ServerResult.Instance.Parent:FindFirstChildWhichIsA("Humanoid").Health > 0 then
                if Players:GetPlayerFromCharacter(ServerResult.Instance.Parent) then return end
                local Name = ServerResult.Instance.Name
                local Multi = 1
                local PackMulti_Def = Gun.Values.PackAPunch.Value == true and 1.25 or 1
                local DoubleTapMulti_Def = 1
                local InstaKillMulti = workspace:GetAttribute("InstaKill") == true and 9999 or 1
                if self.HitMultipliers[Name] then
                    Multi = self.HitMultipliers[Name]
                end
                if PackMulti_Def == 1.25 and table.find(self.Perks[Player], "Double Tap") then
                    DoubleTapMulti_Def = 1.5
                end

                ServerResult.Instance.Parent:FindFirstChildWhichIsA("Humanoid"):TakeDamage(Values["BaseDamage"] * Multi * PackMulti_Def * DoubleTapMulti_Def * InstaKillMulti)
                self.Services.VFXService:Emit(ReplicatedStorage.GameAssets.VFX.Particles.Blood, ServerResult.Instance, 60)

                if ServerResult.Instance.Parent:FindFirstChildWhichIsA("Humanoid").Health <= 0 then
                    self.Services.PointsService:AddPoints(Player, 50)
                    local DropChance = math.random(1, 2)
                    if DropChance == 2 then
                        local DropStart = tick()
                        local Drops = ReplicatedStorage.GameAssets.VFX.Powerups:GetChildren()
                        local PowerupOrg = Drops[math.random(1, #Drops)]
                        local Powerup = PowerupOrg:Clone()
                        Powerup.Parent = workspace.Ignore
                        Powerup.Position = ServerResult.Instance.Parent.PrimaryPart.Position

                        while Powerup.Parent == workspace.Ignore do
                            Powerup.CFrame *= CFrame.Angles(0, 0.03, 0)

                            if (tick() - DropStart) >= 30 then
                                Powerup:Destroy()
                            end

                            local Touching = workspace:GetPartsInPart(Powerup)
                            if #Touching > 0 then
                                for i,v in pairs(Touching) do
                                    if v.Parent:FindFirstChildWhichIsA("Humanoid") and Players:GetPlayerFromCharacter(v.Parent) then
                                        for i,v in pairs(PowerupOrg:GetChildren()) do
                                            if v:IsA("Sound") then
                                                local NewSound = v:Clone()
                                                NewSound.Parent = ReplicatedStorage
                                                NewSound:Play()
                                                NewSound.Ended:Connect(function()
                                                    NewSound:Destroy()
                                                end)
                                            end
                                        end
                                        self:CollectPowerup(Players:GetPlayerFromCharacter(v.Parent), Powerup.Name)
                                        Powerup:Destroy()
                                        break
                                    end
                                end
                            end

                            task.wait()
                        end
                    end
                else
                    self.Services.PointsService:AddPoints(Player, 10)
                end
            else
                local NewBulletHole = ReplicatedStorage.GameAssets.Parts.BulletHole:Clone()
                NewBulletHole.Parent = workspace.Ignore
                NewBulletHole.CFrame = CFrame.lookAt(Pos, Pos + Normal)
                Debris:AddItem(NewBulletHole, 20)

                if ReplicatedStorage.GameAssets.VFX.Bullet:FindFirstChild(ServerResult.Material.Name) then
                   local NewPart = ReplicatedStorage.GameAssets.VFX.Bullet:FindFirstChild(ServerResult.Material.Name):Clone()
                   NewPart.Parent = workspace.Ignore
                   NewPart.CFrame = CFrame.lookAt(Pos, Pos + Normal)

                   wait()
                   for i,v in pairs(NewPart:GetChildren()) do
                        if v:IsA("ParticleEmitter") then
                            --[[local H, S, V = ServerResult.Instance.Color:ToHSV()
                            v.Color = ColorSequence.new{
                                ColorSequenceKeypoint.new(0, Color3.fromHSV(H, S * 2, V));
                                ColorSequenceKeypoint.new(1, Color3.fromHSV(H, S * 2, V));
                            }--]]
                            v:Emit(NewPart.Emit.Value)
                        end
                   end
                   Debris:AddItem(NewPart, self.Services.VFXService:GetLength(NewPart))
                end

                --// Wallbang check
                local Characters = {}
                for i,v in pairs(Players:GetPlayers()) do
                    if v == Player then continue end
                    if v.Character then table.insert(Characters, v.Character) end
                end
                for i,v in pairs(workspace:GetChildren()) do
                    if v:FindFirstChildWhichIsA("Humanoid") and not Players:GetPlayerFromCharacter(v) then
                        table.insert(Characters, v)
                    end
                end

                local CharParams = RaycastParams.new()
                CharParams.FilterType = Enum.RaycastFilterType.Include
                CharParams.FilterDescendantsInstances = Characters
                CharParams.IgnoreWater = true
                local SecondaryRaycast = workspace:Raycast(Player.Character.Head.Position, (Pos - Player.Character.Head.Position).Unit * 10000, CharParams)
                if SecondaryRaycast and SecondaryRaycast.Instance.Parent:FindFirstChildWhichIsA("Humanoid") and SecondaryRaycast.Instance.Parent:FindFirstChildWhichIsA("Humanoid").Health > 0 then
                    if Players:GetPlayerFromCharacter(SecondaryRaycast.Instance.Parent) then return end
                    --self.Services.VisualiseService:VisualiseRay(Player.Character.Head.Position, (Pos - Player.Character.Head.Position).Unit * SecondaryRaycast.Distance, 15, {Color = Color3.fromRGB(0, 255, 0)})
                    local WallCheck = workspace:Raycast(SecondaryRaycast.Position, (Player.Character.Head.Position - SecondaryRaycast.Position).Unit * 10000, Params)
                    if WallCheck and WallCheck.Instance == ServerResult.Instance then
                        self.Services.VisualiseService:VisualiseRay(SecondaryRaycast.Position, (Player.Character.Head.Position - SecondaryRaycast.Position).Unit * WallCheck.Distance, 15, {Color = Color3.fromRGB(0, 0, 255)})
                        local WallThickness = math.abs((ServerResult.Position-WallCheck.Position).Magnitude)
                        local Material = WallCheck.Material
                        local WallName = WallCheck.Instance:GetFullName()
                        local PenetrationMulti = self.PenetrationMultipliers[Material] or 0.5
                        local PackMulti = Gun.Values.PackAPunch.Value == true and 1.25 or 1
                        local DoubleTapMulti = 1
                        local InstaKillMulti = workspace:GetAttribute("InstaKill") == true and 9999 or 1

                        if PackMulti == 1.25 and table.find(self.Perks[Player], "Double Tap") then
                            DoubleTapMulti = 1.5
                        end

                        local Name = SecondaryRaycast.Instance.Name
                        local Multi = 1
                        if self.HitMultipliers[Name] then
                            Multi = self.HitMultipliers[Name]
                        end
                        local DamageMulti = (PenetrationMulti/WallThickness) * Multi * PackMulti * DoubleTapMulti

                        --[[warn("Wall intercepted:")
                        warn("BodyPart Hit:", SecondaryRaycast.Instance:GetFullName())
                        warn("Material:", Material)
                        warn("Thickness:", WallThickness)
                        warn("WallInstance:", WallName)
                        warn("Base Multi:", self.PenetrationMultipliers[Material])
                        warn("Body Part Multi:", Multi)
                        warn("End Mutli:", (self.PenetrationMultipliers[Material]/WallThickness)*Multi)
                        warn("Damage:", DamageMulti*Values["BaseDamage"])--]]
                        SecondaryRaycast.Instance.Parent:FindFirstChildWhichIsA("Humanoid"):TakeDamage(DamageMulti * Values["BaseDamage"] * InstaKillMulti)
                        self.Services.VFXService:Emit(ReplicatedStorage.GameAssets.VFX.Particles.Blood, SecondaryRaycast.Instance, 60)

                        if SecondaryRaycast.Instance.Parent:FindFirstChildWhichIsA("Humanoid").Health <= 0 then
                            self.Services.PointsService:AddPoints(Player, 50)
                        else
                            self.Services.PointsService:AddPoints(Player, 10)
                        end
                    end
                end
            end
            
            local PlayerList = Players:GetPlayers()
            table.remove(PlayerList, table.find(PlayerList, Player))

            for i,v in pairs(PlayerList) do
                self.Client.Render:Fire(v, Player.Character:FindFirstChildWhichIsA("Model"))
            end
         else
            return nil
        end
    else
        return nil
    end
end

function WeaponServer:Knife(Player)
    local Character = Player.Character
    if Character then
        local RayDir = Player.Character.PrimaryPart.CFrame.LookVector * 6
        local Params = RaycastParams.new()
        Params.FilterType = Enum.RaycastFilterType.Exclude
        Params.FilterDescendantsInstances = {Player.Character, workspace.Ignore}
        Params.IgnoreWater = true

        local ServerResult = workspace:Raycast(Player.Character.PrimaryPart.Position, RayDir, Params)
        if ServerResult then
            if ServerResult.Instance.Parent:FindFirstChildWhichIsA("Humanoid") and ServerResult.Instance.Parent:FindFirstChildWhichIsA("Humanoid").Health > 0 then
                if Players:GetPlayerFromCharacter(ServerResult.Instance.Parent) then return end
                ServerResult.Instance.Parent:FindFirstChildWhichIsA("Humanoid"):TakeDamage(50 * (workspace:GetAttribute("InstaKill") == true and 9999 or 1))

                if ServerResult.Instance.Parent:FindFirstChildWhichIsA("Humanoid").Health <= 0 then
                    self.Services.PointsService:AddPoints(Player, 130)
                else
                    self.Services.PointsService:AddPoints(Player, 20)
                end
            end
        end
    end
end

function WeaponServer:Grenade(Player, P1, P2)
    local Direction = (P1 - P2).Unit
	local x0 = P2 + Direction * 2
	local v0 = Direction * 100

    local Path = Trajectory:Cast(x0, v0, Enum.Material.Plastic, {workspace.Ignore, Player.Character})
    
    local Follow = Instance.new("Part", workspace)
    Follow.CanCollide = true
    Follow.Transparency = 1
    Follow.Size = Vector3.new(0.5, 0.5, 0.5)

    local PlayerList = Players:GetPlayers()
    table.remove(PlayerList, table.find(PlayerList, Player))

    for i,v in pairs(PlayerList) do
        self.Client.RenderGrenade:Fire(v, P2, P1, P2)
    end
    Trajectory:Travel(Follow, Path)

    task.wait(3)
    self:FireAll("VFX", ReplicatedStorage.GameAssets.VFX.Particles.Explosion, Follow.Position, 70)
    self:FireAll("SFX", ReplicatedStorage.GameAssets.Throwables.Grenade.Sounds.Explode, Follow, false)

    local RangeList = self:GetPlayersInRange(Follow.Position, 25)

    for RangePlayer, Distance in pairs(RangeList) do
        local Char = RangePlayer.Character
        if Char and Char:FindFirstChildWhichIsA("Humanoid") and Char:FindFirstChildWhichIsA("Humanoid").Health > 0 then
            local Hum = Char:FindFirstChildWhichIsA("Humanoid")
            Hum:TakeDamage(160 * (math.clamp(28 - Distance, 0, 25)/25) * (workspace:GetAttribute("InstaKill") == true and 9999 or 1))

            if Hum.Health <= 0 then
                self.Services.PointsService:AddPoints(Player, 30)   
            else
                self.Services.PointsService:AddPoints(Player, 10)
            end
        end
    end
    Follow:Destroy()
end

function WeaponServer:GetPerk(Player, Perk)
    if self.PerksData[Perk] and self.Services.PointsService:GetPoints(Player) > self.PerksData[Perk] and not table.find(self.Perks[Player], Perk) and workspace:GetAttribute("Power") == true then
        local Values, Gun = self:GetValues(Player)

        if Perk ~= "Pack A Punch" then
            table.insert(self.Perks[Player], Perk)
        else
            if Gun.Values.PackAPunch.Value == false then
                Gun.Values.PackAPunch.Value = true
            else
                return false
            end
        end
        local PerkPrice = self.PerksData[Perk]
        self.Services.PointsService:RemovePoints(Player, PerkPrice)

        if Perk == "Juggernog" then
            local Char = Player.Character
            if Char and Char:FindFirstChildWhichIsA("Humanoid") then
                Char:FindFirstChildWhichIsA("Humanoid").MaxHealth *= 2.5
                Char:FindFirstChildWhichIsA("Humanoid").Health *= 2.5
            end
        end

        if Perk == "Double Tap" then
            Gun.Values.FireRate.Value *= 0.67
        end

        if Perk == "Quick Revive" then
            Player:SetAttribute("Quick Revive", true)
        end

        return true
    end
    return false
end

function WeaponServer:HasPerk(Player, Perk)
    return table.find(self.Perks[Player], Perk)
end

function WeaponServer:GetPerks(Player)
    return self.Perks[Player]
end

function WeaponServer:PurchaseGun(Player, GunName)
    local Gun = workspace.GunBuys:FindFirstChild(GunName)
    if Gun and Gun:FindFirstChild("Data") then
        local Price = Gun.Data.Price.Value

        if self.Services.PointsService:GetPoints(Player) >= Price and self:GetGun(Player, "Primary") ~= GunName and self:GetGun(Player, "Secondary") ~= GunName then
            --print("Primary:", self:GetGun(Player, "Primary"))
            --print("Secondary:", self:GetGun(Player, "Secondary"))
            self.Services.PointsService:RemovePoints(Player, Price)
            if self:GetGun(Player, "Primary") == "None" then
                self:ChangeGun(Player, "Primary", GunName)
                self.Client.ClientEquip:Fire(Player, "Primary")
            elseif self:GetGun(Player, "Secondary") == "None" then
                self:ChangeGun(Player, "Secondary", GunName)
                self.Client.ClientEquip:Fire(Player, "Secondary")
            else
                self:ChangeGun(Player, self.Equipped[Player.UserId][1], GunName)
                self.Client.ClientEquip:Fire(Player, self.Equipped[Player.UserId][1])
                --// self.Equipped[Player.UserId] = {TYPE, GUN}
            end
        end
    end
end

function WeaponServer:OpenBox(Player)
    if self.Services.PointsService:GetPoints(Player) >= 750 then
        self.Services.PointsService:RemovePoints(Player, 750)
        workspace.MysteryBox:SetAttribute("Opening", true)

        local OpenAnimation = workspace.MysteryBox.Humanoid:LoadAnimation(workspace.MysteryBox.Humanoid.OpenBox)
        local CloseAnimation = workspace.MysteryBox.Humanoid:LoadAnimation(workspace.MysteryBox.Humanoid.CloseBox)
        OpenAnimation:Play()
        task.wait(0.5)

        TweenService:Create(workspace.MysteryBox.PrimaryPart.GunAttachment, TweenInfo.new(3), {CFrame = workspace.MysteryBox.PrimaryPart.GunAttachment.CFrame + Vector3.new(0, 2, 0)}):Play()
        for i = 1, 45 do
            if workspace.MysteryBox:FindFirstChildWhichIsA("Model") then
                workspace.MysteryBox:FindFirstChildWhichIsA("Model"):Destroy()
            end
            local Gun = ReplicatedStorage.GameAssets.MysteryBox:GetChildren()[math.random(1, #ReplicatedStorage.GameAssets.MysteryBox:GetChildren())]
            local FakeGun = Gun:Clone()
            FakeGun.PrimaryPart.Anchored = true
            FakeGun.Parent = workspace.MysteryBox
            FakeGun:PivotTo(workspace.MysteryBox.HumanoidRootPart.GunAttachment.WorldCFrame * CFrame.Angles(0, -math.pi/2, 0))
            
            print(i)

            if i == 45 then
                task.wait(1.2)
            elseif i > 35 then
                task.wait(i/100)
            else
                task.wait(i/200)
            end
        end
        local FinalGun = workspace.MysteryBox:FindFirstChildWhichIsA("Model")
        if FinalGun then
            print("You won:", FinalGun.Name .. "!")
            workspace.MysteryBox:SetAttribute("Gun", FinalGun.Name)
            workspace.MysteryBox:SetAttribute("Player", Player.Name)
            
            local B = tick()
            repeat
                FinalGun:PivotTo(FinalGun.WorldPivot - Vector3.new(0, 0.004, 0))
                task.wait()
            until tick()-B >= 8 or workspace.MysteryBox:GetAttribute("Gun") == ""
            workspace.MysteryBox.HumanoidRootPart.GunAttachment.CFrame -= Vector3.new(0, 2, 0)

            FinalGun:Destroy()
            OpenAnimation:Stop()
            CloseAnimation:Play()
            CloseAnimation.Ended:Wait()
        end
        workspace.MysteryBox:SetAttribute("Opening", false)
        workspace.MysteryBox:SetAttribute("Gun", "")
        workspace.MysteryBox:SetAttribute("Player", "")
    end
end

function WeaponServer:GiveGun(Player, PlayerTo, Gun)
    if not table.find(Admins, Player.Name) then return end

    local FoundGun = ReplicatedStorage.GameAssets.Weapons:FindFirstChild(Gun)
    if FoundGun then
        if self:GetGun(PlayerTo, "Primary") ~= Gun and self:GetGun(PlayerTo, "Secondary") ~= Gun then
            if self:GetGun(PlayerTo, "Primary") == "None" then
                self:ChangeGun(PlayerTo, "Primary", Gun)
                self.Client.ClientEquip:Fire(PlayerTo, "Primary")
            elseif self:GetGun(PlayerTo, "Secondary") == "None" then
                self:ChangeGun(PlayerTo, "Secondary", Gun)
                self.Client.ClientEquip:Fire(PlayerTo, "Secondary")
            else
                self:ChangeGun(PlayerTo, self.Equipped[PlayerTo.UserId][1], Gun)
                self.Client.ClientEquip:Fire(PlayerTo, self.Equipped[PlayerTo.UserId][1])
                --// self.Equipped[Player.UserId] = {TYPE, GUN} for reference
            end
        end
    end
end

function WeaponServer:PickupGun(Player)
    local GunName = workspace.MysteryBox:GetAttribute("Gun")
    if Player.Name == workspace.MysteryBox:GetAttribute("Player") and self:GetGun(Player, "Primary") ~= GunName and self:GetGun(Player, "Secondary") ~= GunName  then
        if self:GetGun(Player, "Primary") == "None" then
            self:ChangeGun(Player, "Primary", GunName)
            self.Client.ClientEquip:Fire(Player, "Primary")
        elseif self:GetGun(Player, "Secondary") == "None" then
            self:ChangeGun(Player, "Secondary", GunName)
            self.Client.ClientEquip:Fire(Player, "Secondary")
        else
            self:ChangeGun(Player, self.Equipped[Player.UserId][1], GunName)
            self.Client.ClientEquip:Fire(Player, self.Equipped[Player.UserId][1])
            --// self.Equipped[Player.UserId] = {TYPE, GUN} for reference
        end
        workspace.MysteryBox:SetAttribute("Gun", "")
        workspace.MysteryBox:SetAttribute("Player", "")
    end
end

function WeaponServer:CollectPowerup(Player, Powerup)
    print(Player.Name, "collected the powerup", Powerup)
    if Powerup == "Nuke" then
        for i,v in pairs(Players:GetPlayers()) do
            task.spawn(function()
                self.Services.PointsService:AddPoints(v, 400)
                local NukeUI = Instance.new("ScreenGui", v.PlayerGui)
                local Frame = Instance.new("Frame", NukeUI)
                Frame.Size = UDim2.fromScale(1, 1.1)
                Frame.Position = UDim2.fromScale(0, -0.1)
                Frame.BackgroundTransparency = 1
                TweenService:Create(Frame, TweenInfo.new(0.4), {BackgroundTransparency = 0.2}):Play()
                for i,v in pairs(workspace.Zombies:GetChildren()) do
                    if v:FindFirstChild("Humanoid") then
                        v.Humanoid.Health = 0
                    end
                end
    
                task.wait(0.4)
                TweenService:Create(Frame, TweenInfo.new(1), {BackgroundTransparency = 1}):Play()
                task.wait(1)
                NukeUI:Destroy()
            end)
        end
    end
    if Powerup == "InstaKill" then
        self.PowerupTimes["InstaKill"] = tick()
    end
    if Powerup == "DoublePoints" then
        self.PowerupTimes["DoublePoints"] = tick()
    end
    if Powerup == "MaxAmmo" then
        for i,v in pairs(Players:GetPlayers()) do
            local Values, Gun = self:GetValues(v)
            if Gun then
                Gun.Values["Ammo"].Value = Gun.Values["MaxAmmo"].Value
            end
        end
    end
end

function WeaponServer:Flashlight(Player)
    local Values, Gun = self:GetValues(Player)
    if Gun then
        for i,v in pairs(Gun:GetDescendants()) do
            if v:IsA("SpotLight") or v:IsA("SurfaceLight") or v:IsA("Beam") then
                v.Enabled = not v.Enabled
            end
        end
    end
    local Click = ReplicatedStorage.GameAssets.SFX.Flashlight:Clone()
    Click.Parent = Gun
    Click:Play()
    Click.Ended:Wait()
    Click:Destroy()
end

function WeaponServer:GetValues(Player)
    if Player.Character then
         local v = Player.Character:FindFirstChildWhichIsA("Model")
         local ScrapeTable = {}
         for i,v in pairs(v.Values:GetChildren()) do
             ScrapeTable[v.Name] = v.Value
         end
         return ScrapeTable, v
     end
end

function WeaponServer:Reload(Player)
    local Values, Gun = self:GetValues(Player)
    local ReloadTime = Values["ReloadTime"]
    local Start = tick()

    self.InTask["Reload"][Player.UserId] = true
    while self.InTask["Reload"][Player.UserId] == true and (tick() - Start < ReloadTime * (not table.find(self.Perks[Player], "Speed Cola") and 1 or 0.5)) do
        task.wait()
    end
    
    if Gun and self.InTask["Reload"][Player.UserId] == true then
        self.InTask["Reload"][Player.UserId] = false
        local CurrentMag, CurrentAmmo = Gun.Values["MagCur"].Value, Gun.Values["Ammo"].Value
        local MaxMag = Gun.Values["MagSize"].Value

        local Need = MaxMag - CurrentMag
        if Need > CurrentAmmo then
            Need = CurrentAmmo
        end

        Gun.Values["Ammo"].Value -= Need
        Gun.Values["MagCur"].Value += Need
    end
end

function WeaponServer:BarrierStart(Player, Barrier)
    if not Barrier or not Player.Character or not Player.Character.PrimaryPart or Barrier:GetAttribute("RepairOccupied") == true or table.find(self.InTask.Barrier, Player.UserId) then return end
    if Barrier.Parent == workspace.Map.Barriers then
        table.insert(self.InTask.Barrier, Player.UserId)
        while table.find(self.InTask.Barrier, Player.UserId) do
            local PrimaryPos = Player.Character.PrimaryPart.Position
            local BarrierPos = Barrier.WorldPivot.Position
            if math.abs((PrimaryPos-BarrierPos).Magnitude) <= 10 then
                Barrier:SetAttribute("RepairOccupied", true)
                for i,v in pairs(Barrier:GetChildren()) do
                    if not table.find(self.InTask.Barrier, Player.UserId) then continue end
                    local BarrierBroken = nil
                    if v.Name == "Break" and v.CFrame ~= v.OriginalCFrame.Value and v.Velocity == Vector3.new(0, 0, 0) then
                        BarrierBroken = v
                    end
                    if not BarrierBroken then
                        task.wait()
                        continue
                    end
                    BarrierBroken.Anchored = true
                    local Tween = TweenService:Create(BarrierBroken, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {CFrame = BarrierBroken.OriginalCFrame.Value + (BarrierBroken.OriginalCFrame.Value.LookVector * -3)})
                    Tween:Play()
                    Tween.Completed:Wait()
                    local Tween2 = TweenService:Create(BarrierBroken, TweenInfo.new(0.3, Enum.EasingStyle.Quint), {CFrame = BarrierBroken.OriginalCFrame.Value})
                    Tween2:Play()
                    task.wait(0.1)
                    self.Services.PointsService:AddPoints(Player, 10)
                    self.Client.Shake:Fire(Player, "Bump")
                    task.wait(0.4) --// Delay
                end
            else
                self:BarrierStop(Player, Barrier)
                break
            end
            task.wait()
        end
    end
end

function WeaponServer:BarrierStop(Player, Barrier)
    if table.find(self.InTask.Barrier, Player.UserId) then
        table.remove(self.InTask.Barrier, table.find(self.InTask.Barrier, Player.UserId))
    end
    if Barrier and Barrier:GetAttribute("RepairOccupied") == true then
        Barrier:SetAttribute("RepairOccupied", false)
    end
end

function WeaponServer:ReviveStart(Player, Char)
    local Plr = Players:GetPlayerFromCharacter(Char)
    if Char and Plr and Plr ~= Player then
        self.InTask.Revive[Player.UserId] = tick()
        Player:SetAttribute("Reviving", true)
        while self.InTask.Revive[Player.UserId] do
            Plr.PlayerGui.HUD.Reviving.Visible = true
            if tick() - self.InTask.Revive[Player.UserId] >= (Player:GetAttributes()["Quick Revive"] == true and 2.5 or 5) then
                Char.Humanoid.Health = 100
                self.InTask.Revive[Player.UserId] = nil
                Player:SetAttribute("Reviving", nil)
            end
            task.wait()
        end
        Plr.PlayerGui.HUD.Reviving.Visible = false
    end
end

function WeaponServer:ReviveStop(Player)
    if self.InTask.Revive[Player.UserId] then self.InTask.Revive[Player.UserId] = nil; Player:SetAttribute("Reviving", nil) end
end

function WeaponServer:UnlockDoor(Player, Door)
    local DoorPrice = Door:FindFirstChild("Price")
    if DoorPrice then
        DoorPrice = DoorPrice.Value
        if self.Services.PointsService:GetPoints(Player) >= DoorPrice then
            self.Services.PointsService:RemovePoints(Player, DoorPrice)
            Door.Parent = workspace.SlideIgnore
            Door.CanCollide = false
            for i,v in pairs(Door:GetChildren()) do
                if v:IsA("BasePart") then
                    v.Anchored = false
                    v.CollisionGroup = "Debris"
                    v:ApplyImpulse(Vector3.new(math.random(1, 15), math.random(1, 15), math.random(1, 15)))
                end
            end
            task.wait(1)
            for i,v in pairs(Door:GetChildren()) do
                if v:IsA("BasePart") then
                    TweenService:Create(v, TweenInfo.new(5), {CFrame = v.CFrame - Vector3.new(0, 15, 0)}):Play()
                    task.delay(5, function()
                        v:Destroy()
                    end)
                end
            end
        end
    end
end

function WeaponServer:CancelReload(Player)
    if self.InTask["Reload"][Player.UserId] == true then
        self.InTask["Reload"][Player.UserId] = false
    end
end

function WeaponServer:GetInventory(Player)
    self:MakeInventory(Player)
    return self.Inventories[Player.UserId]
end

function WeaponServer:KnitStart()
    
end

function WeaponServer:KnitInit()
    for i,v in pairs(self.Services) do
        self.Services[i] = Knit.GetService(i)
    end
    RunService.Heartbeat:Connect(function(deltaTime)
        for i,v in pairs(self.PowerupTimes) do
            if (tick()-v) > 30 then
                workspace:SetAttribute(i, false)
                self.PowerupTimes[i] = nil
            else
                workspace:SetAttribute(i, true)
            end
        end
        for i,v in pairs(Players:GetPlayers()) do
            local Char = v.Character
            if Char and Char:FindFirstChild("Humanoid") then
                local Hum = Char:FindFirstChild("Humanoid")
                if Hum.Health <= 1 then
                    Char.Head.ReviveIcon.Enabled = true
                else
                    Char.Head.ReviveIcon.Enabled = false
                end
            end
        end
    end)--// Game loop
    print("[Knit Server] Weapon System initialised!")
end

return WeaponServer