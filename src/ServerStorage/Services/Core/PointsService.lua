local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages.Knit)
local Admins = require(ReplicatedStorage.Source.Admins)

local PointsService = Knit.CreateService {
    Name = "PointsService",
    Client = {
        PointsChanged = Knit.CreateSignal()
    },
    PlayersPoints = {}
}

function PointsService.Client:AddPoints(Player, PlayerTo, Points)
    self.Server:AddPointsAdmin(Player, PlayerTo, Points)
end

function PointsService.Client:GetPoints(LPlayer, Player)
    return self.Server:GetPoints(Player)
end

function PointsService:AddPointsAdmin(Player, PlayerTo, Points)
    if not table.find(Admins, Player.Name) then return end
    self.PlayersPoints[PlayerTo] += Points * (workspace:GetAttribute("DoublePoints") == true and 2 or 1)

    for i,v in pairs(Players:GetPlayers()) do
        self.Client.PointsChanged:Fire(v, PlayerTo, self.PlayersPoints[PlayerTo], Points * (workspace:GetAttribute("DoublePoints") == true and 2 or 1))
    end
end

function PointsService:AddPoints(Player, Points)
    self.PlayersPoints[Player] += Points * (workspace:GetAttribute("DoublePoints") == true and 2 or 1)

    for i,v in pairs(Players:GetPlayers()) do
        self.Client.PointsChanged:Fire(v, Player, self.PlayersPoints[Player], Points * (workspace:GetAttribute("DoublePoints") == true and 2 or 1))
    end
end

function PointsService:RemovePoints(Player, Points)
    self.PlayersPoints[Player] -= Points
    for i,v in pairs(Players:GetPlayers()) do
        self.Client.PointsChanged:Fire(v, Player, self.PlayersPoints[Player], -Points)
    end
end

function PointsService:GetPoints(Player)
    return self.PlayersPoints[Player]
end

function PointsService:KnitInit()
    for i,v in pairs(Players:GetPlayers()) do
        self.PlayersPoints[v] = 0
    end
    Players.PlayerAdded:Connect(function(Player)
        self.PlayersPoints[Player] = 0
    end)

    print("[Knit] Points service initialised!")
end


return PointsService
