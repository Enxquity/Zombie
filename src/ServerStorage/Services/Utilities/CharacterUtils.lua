local ReplicatedStorage = game:GetService("ReplicatedStorage");

local Knit = require(ReplicatedStorage.Packages.Knit)

local CharacterUtils = Knit.CreateService{
    Name = "CharacterUtils";
    Client = {};
}

--// Client side calls (promises)

function CharacterUtils.Client:GetCharacter(Player)
    return self.Server:GetCharacter(Player);
end

function CharacterUtils.Client:GetSpeed(Player)
    return self.Server:GetSpeed(Player)
end

function CharacterUtils.Client:GetHumanoid(Player)
    return self.Server:GetHumanoid(Player)
end

function CharacterUtils.Client:GetWalkSpeed(Player)
    return self.Server:GetWalkSpeed(Player)
end

--// Server side main functions

function CharacterUtils:GetCharacter(Player)
    if Player.Character then
        return Player.Character
    else
        return Player.CharacterAdded:Wait()
    end
end

function CharacterUtils:GetHumanoid(Player)
    local Character = self:GetCharacter(Player)
    if Character and Character:FindFirstChildWhichIsA("Humanoid") then
        return Character:FindFirstChildWhichIsA("Humanoid")
    else
        repeat 
            task.wait()
        until Character:FindFirstChildWhichIsA("Humanoid")
        return Character:FindFirstChildWhichIsA("Humanoid")
    end
end

function CharacterUtils:GetWalkSpeed(Player)
    local Humanoid = self:GetHumanoid(Player)
    if Humanoid then
        return Humanoid.WalkSpeed
    end
end

function CharacterUtils:GetSpeed(Player)
    local Character = self:GetCharacter(Player)

    if Character and Character:FindFirstChildWhichIsA("Humanoid") then
        local Humanoid = Character:FindFirstChildWhichIsA("Humanoid")
        return Humanoid.MoveDirection.Magnitude
    end
end

function CharacterUtils:KnitInit()
    print("[Knit] CharacterUtils service initialised!")
end

return CharacterUtils