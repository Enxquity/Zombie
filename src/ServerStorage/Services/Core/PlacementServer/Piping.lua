local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Knit = require(ReplicatedStorage.Packages.Knit)
local Serializer = require(ReplicatedStorage.Source.Serializer)
local Piping = {}

function Piping:FindDirectPipe(Connector)
    local ConnectorCF = Connector.CFrame
    local Left, Right, Back, Front = -ConnectorCF.RightVector, ConnectorCF.RightVector, -ConnectorCF.LookVector, ConnectorCF.LookVector

    local FilterList = {Connector.Parent, workspace.Debris, workspace.Terrain}
    for _, Pipe in pairs(CollectionService:GetTagged("Pipe")) do
        table.insert(FilterList, Pipe.PrimaryPart)
    end

    local Params = RaycastParams.new()
    Params.FilterDescendantsInstances = FilterList
    Params.FilterType = Enum.RaycastFilterType.Exclude

    local RayLeft, RayRight, RayBack, RayFront = workspace:Raycast(Connector.Position, Left, Params), workspace:Raycast(Connector.Position, Right, Params), workspace:Raycast(Connector.Position, Back, Params), workspace:Raycast(Connector.Position, Front, Params)

    if RayLeft and RayLeft.Instance.Name:find("Connector") then
        return RayLeft.Instance;
    end
    if RayRight and RayRight.Instance.Name:find("Connector") then
        return RayRight.Instance;
    end
    if RayBack and RayBack.Instance.Name:find("Connector") then
        return RayBack.Instance;
    end
    if RayFront and RayFront.Instance.Name:find("Connector") then
        return RayFront.Instance;
    end

    return nil
end

function Piping:GetConnections(Pipe, Serialize)
    if not Pipe then return end
    local Connections = {}
    for _, Connector in pairs(Pipe:GetDescendants()) do
        if Connector.Name:find("Connector") then
            if Connector.Parent:HasTag("Input") then continue end
            local Connection = Piping:FindDirectPipe(Connector)

            if Connection then
                Connections[Connector] = Connection
            end
        end
    end

    if Serialize == true then
        Connections = Serializer.Serialize(Connections)
    end

    return Connections
end

function Piping:Connect(PipeA, PipeB)
    if not PipeA or not PipeB then return end
    --[[if PipeA.PipeInfo.Connection.Value ~= nil then
        PipeA.PipeInfo.Connection.Value = nil
    end--]]
    --[[if PipeB.PipeInfo.Connection.Value ~= nil then
        PipeB.PipeInfo.Connection.Value = nil
    end--]]
    for _, Connection in pairs(PipeA.PipeInfo.Connections:GetChildren()) do
        if Connection.Value ~= nil and Connection.Value.Parent == PipeB then
            Connection.Value = nil
            return
        end
    end
    for _, Connection in pairs(PipeB.PipeInfo.Connections:GetChildren()) do
        if Connection.Value ~= nil and Connection.Value.Parent == PipeA then
            Connection.Value = nil
        end
    end

    local Connections = Piping:GetConnections(PipeA)

    for _, Connection in pairs(Connections) do
        if Connection.Parent == PipeB then
            for _, Connect in pairs(PipeA.PipeInfo.Connections:GetChildren()) do
                if Connect.Value == nil then
                    Connect.Value = Connection
                    break
                else
                    if #PipeA.PipeInfo.Connections:GetChildren() <= 1 then
                        Connect.Value = Connection
                    end
                end
            end
            return true
        end
    end
    return false
end

return Piping