local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Knit = require(ReplicatedStorage.Packages.Knit)

local Gameplay = Knit.CreateService {
    Name = "Gameplay",
    Client = {},
    Parts = {};
}

function Gameplay.Client:PickupPart(Player, Part)
    return self.Server:PickupPart(Player, Part)
end

function Gameplay.Client:GetParts()
    return self.Server:GetParts()
end

function Gameplay.Client:Power()
    return self.Server:Power()
end

function Gameplay.Client:Downed(Player)
    return self.Server:Downed(Player)
end

function Gameplay:Start()
    
end

function Gameplay:PickupPart(Player, Part)
    if not Part then return end
    local Char = Player.Character
    if Char and Char.PrimaryPart then
        local CharPos = Char.PrimaryPart.Position
        local PartPos = Part.WorldPivot.Position
        local Dist = math.abs((CharPos-PartPos).Magnitude)
        if Dist < 15 then
            table.insert(self.Parts, Part.Name)
            Part:Destroy()
        end
    end
end

function Gameplay:GetParts()
    return self.Parts
end

function Gameplay:Power()
    if workspace:GetAttributes()["Power"] == true then return end 
    local Parts = self:GetParts()
    if #Parts >= 3 then
        workspace:SetAttribute("Power", true)
        ReplicatedStorage.GameAssets.SFX.Power:Play()
    end
end

function Gameplay:Downed(Player)
    local DownedTime = Player:SetAttribute("Downed", tick())
    while task.wait() do
        local Char = Player.Character
        if tick() - Player:GetAttribute("Downed") >= 30 then
            if Char then
                if Char.Humanoid.Health <= 1 then
                    Char:PivotTo(workspace.SpawnLocation.CFrame + Vector3.yAxis * 5)
                    Player:SetAttribute("Dead", true)
                    Player:SetAttribute("Downed", nil)
                end
            end
            break
        end
        if Char and Char:FindFirstChild("Humanoid") then
            if Char.Humanoid.Health > 1 then
                Player:SetAttribute("Downed", nil)
                break
            end
        end
        if Player:GetAttributes()["Reviving"] and Player:GetAttributes()["Downed"] then
            local Diff = 30 - (tick() - Player:GetAttribute("Downed"))
            Player:SetAttribute("Downed", tick() - Diff)
        end
    end
end

function Gameplay:KnitStart()
    
end


function Gameplay:KnitInit()
    
end


return Gameplay
