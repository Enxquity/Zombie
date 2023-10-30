local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage");

local Knit = require(ReplicatedStorage.Packages.Knit)

local RoundService = Knit.CreateService{
    Name = "RoundService";
    Client = {
        RoundStarted = Knit.CreateSignal();
        RoundEnd = Knit.CreateSignal();
    };
    Zombies = {};
    MinimumRound = {
        ["Zombie"] = 1;
        ["Sprinting Zombie"] = 10;
        ["Crawling Zombie"] = 15;
    };
    Round = 1;
    TotalZombies = 0;
}

function RoundService:Spawn(Zombie)
    local NewZombie = ReplicatedStorage.GameAssets.Zombies[Zombie]:Clone()
    NewZombie.Parent = workspace.Zombies

    local SpawnLocation = workspace.ZombieSpawns:GetChildren()[math.random(1, 3)]
    NewZombie:PivotTo(SpawnLocation.CFrame + Vector3.new(0, NewZombie.PrimaryPart.Size.Y, 0))
    NewZombie.BarrierHandler.Enabled = true

    table.insert(self.Zombies, NewZombie)
    self.TotalZombies += 1

    NewZombie.Humanoid.Died:Connect(function()
		table.remove(self.Zombies, table.find(self.Zombies, NewZombie))
		task.wait(5)
		NewZombie:Destroy()
    end)
end

function RoundService:ClearDeadZombies()
	for i,v in pairs(workspace.Zombies:GetChildren()) do
		v:Destroy()
	end
end

function RoundService:Init()
    while true do
        if #Players:GetPlayers() <= 0 then task.wait() continue end
        local Alive = false
        for i,v in pairs(Players:GetPlayers()) do
            local Char = v.Character
            if Char and Char:FindFirstChildWhichIsA("Humanoid") then
                local Hum = Char:FindFirstChildWhichIsA("Humanoid")
                if Hum.Health > 0 then
                    Alive = true
                end
            else
                Alive = true
            end
        end
        if Alive == false then
            break 
        end
        if #self.Zombies >= 25 then task.wait() continue end

        for i,v in pairs(Players:GetPlayers()) do
            local PlrGui = v.PlayerGui
            if PlrGui and PlrGui:FindFirstChild("HUD") then
                PlrGui.HUD.Round.Text = self.Round
            end
        end

        if self.TotalZombies >= 15 + (self.Round * 2) then
            if #self.Zombies <= 0 then
                self.Round += 1
				self.TotalZombies = 0
                task.wait(1.5)
				ReplicatedStorage.GameAssets.SFX["(G) Round End"]:Play()
				self:ClearDeadZombies()
				task.wait(14)
				ReplicatedStorage.GameAssets.SFX["(G) Round Start"]:Play()
				task.wait(9)
            else
                task.wait()
                continue
            end
        end

        local RanNum = math.random(1, 10)
        if RanNum >= 7 and RanNum <= 8 and self.Round >= self.MinimumRound["Sprinting Zombie"] then
            self:Spawn("Sprinting Zombie")
        elseif RanNum >= 9 and RanNum <= 10 and self.Round >= self.MinimumRound["Crawling Zombie"] then
            self:Spawn("Crawling Zombie")
        else
            self:Spawn("Zombie")
        end
        task.wait(4)
    end
    for i,v in pairs(Players:GetPlayers()) do
        v.PlayerGui.HUD.GameOver.GameOver.Visible = true
        v.PlayerGui.HUD.GameOver.Survived.Visible = true
        v.PlayerGui.HUD.GameOver.Fade.Visible = true
        v.PlayerGui.HUD.GameOver.Survived.Text = v.PlayerGui.HUD.GameOver.Survived.Text:format(self.Round)
    end
end

function RoundService:KnitInit()
    print("[Knit] Round service initialised!")
end

return RoundService