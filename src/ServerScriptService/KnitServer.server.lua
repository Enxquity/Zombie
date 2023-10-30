local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage");
local ServerStorage = game:GetService('ServerStorage');

local Knit = require(ReplicatedStorage.Packages.Knit)
Knit.AddServicesDeep(ServerStorage.Source.Services)

Knit.Start():andThen(function()
    print("[Knit Server] Started")

    local WeaponServer = Knit.GetService("WeaponServer")
    local RoundServer = Knit.GetService("RoundService")

    --// Barrier fixer
    coroutine.wrap(function()
        while task.wait(1) do
            for i,v in pairs(workspace.Map.Barriers:GetChildren()) do
                if v.Occupied.Value ~= nil and v.Occupied.Value.Parent == nil then
                    v.Occupied.Value = nil 
                end
            end
        end
    end)()

    Players.PlayerAdded:Connect(function(Player)
        --WeaponServer:ChangeGun(Player, "Primary", "AK47")
        WeaponServer:ChangeGun(Player, "Secondary", "M9")
        Player.CharacterAdded:Connect(function(Character)
            local Humanoid = Character:FindFirstChildOfClass("Humanoid")
            if Humanoid then
                --Humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
            end
            for i,v in pairs(Character:GetDescendants()) do
                if v:IsA("BasePart") then
                    v.CollisionGroup = "Players"
                end
            end
        end)

        for i, v in pairs(Players:GetPlayers()) do
            local HUD = v.PlayerGui:WaitForChild("HUD", 10)
            if HUD then
                for _, NewPlr in pairs(Players:GetPlayers()) do
                    if not HUD.Scoreboard.Main.PlayerHolder:FindFirstChild(NewPlr.Name) then
                        local NewTemplate = ReplicatedStorage.GameAssets.UI.Player:Clone()
                        NewTemplate.Parent = HUD.Scoreboard.Main.PlayerHolder
                        NewTemplate.User.Text = NewPlr.Name
                        NewTemplate.Name = NewPlr.Name
                        NewTemplate.Rank.Text = "0"
                        if NewPlr == v then
                            NewTemplate.LayoutOrder = -1
                            for i,v in pairs(NewTemplate:GetChildren()) do
                                if v:IsA("TextLabel") and v.Name ~= "Rank" then
                                    v.TextColor3 = Color3.fromRGB(255, 217, 3)
                                end
                            end
                        end
                    end
                end
            end
        end
    end)
    Players.PlayerRemoving:Connect(function(Player)
        for i, v in pairs(Players:GetPlayers()) do
            local HUD = v.PlayerGui:FindFirstChild("HUD") 
            if HUD then
                if HUD.Scoreboard.Main.PlayerHolder:FindFirstChild(Player.Name) then
                    HUD.Scoreboard.Main.PlayerHolder:FindFirstChild(Player.Name):Destroy()
                end
            end
        end
    end)

    repeat task.wait() until workspace:GetAttribute("Begin") == true
    for _, plr in pairs(Players:GetPlayers()) do
        local Char = plr.Character
        if Char then
            for i,v in pairs(workspace.SpawnLocs:GetChildren()) do
                Char:PivotTo(CFrame.new(v.Position + Vector3.new(0, 5, 0)))
                v:Destroy()
                break
            end
        end
    end

    RoundServer:Init()
end):catch(warn)
