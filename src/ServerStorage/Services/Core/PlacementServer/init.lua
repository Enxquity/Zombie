local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages.Knit)

--// Interclasses
local Piping = require(script.Piping)

local PlacementServer = Knit.CreateService {
    Name = "PlacementServer",
    Client = {},
}

function PlacementServer.Client:Place(Player, Item, CFrame)
    return self.Server:Place(Item, CFrame)
end

function PlacementServer.Client:Connect(Player, PipeA, PipeB)
    return self.Server:Connect(PipeA, PipeB)
end

function PlacementServer.Client:GetConnections(Player, Pipe)
    return Piping:GetConnections(Pipe)
end

function PlacementServer:Place(Item, CFrame)
    local NewItem = Item:Clone()
    NewItem.Parent = workspace
    NewItem:PivotTo(CFrame)

    if CollectionService:HasTag(Item, "Pipe") then
        for _, Dir in pairs(NewItem:GetChildren()) do
            if Dir.Name ~= "Direction" then continue end
            for i,v in pairs(Dir:GetChildren()) do
                v.Transparency = 1
            end
        end
        local Connection = Piping:FindDirectPipe(NewItem.FrontConnector)
        if Connection and Connection.Name ~= "FrontConnector" and Connection.Name:find("Connector") and not Connection:HasTag("Output") then
            for _, Connect in pairs(NewItem.PipeInfo.Connections:GetChildren()) do
                Connect.Value = Connection
               break
            end
        end
    end

    return NewItem
end

function PlacementServer:Connect(PipeA, PipeB)
    return Piping:Connect(PipeA, PipeB)
end

function PlacementServer:KnitStart()
    
end


function PlacementServer:KnitInit()
    
end


return PlacementServer
