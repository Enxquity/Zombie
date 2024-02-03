local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local Piping = {}

function Piping:FindDirectPipe(Connector)
    local ConnectorCF = Connector.CFrame
    local Left, Right, Back, Front = -ConnectorCF.RightVector, ConnectorCF.RightVector, -ConnectorCF.LookVector, ConnectorCF.LookVector

    local FilterList = {Connector.Parent, workspace.Debris}
    for _, Pipe in pairs(CollectionService:GetTagged("Pipe")) do
        table.insert(FilterList, Pipe.PrimaryPart)
    end

    local Params = RaycastParams.new()
    Params.FilterDescendantsInstances = FilterList
    Params.FilterType = Enum.RaycastFilterType.Exclude

    local RayLeft, RayRight, RayBack, RayFront = workspace:Raycast(Connector.Position, Left, Params), workspace:Raycast(Connector.Position, Right, Params), workspace:Raycast(Connector.Position, Back, Params), workspace:Raycast(Connector.Position, Front, Params)

    if RayLeft then
        return RayLeft.Instance;
    elseif RayRight then
        return RayRight.Instance;
    elseif RayBack then
        return RayBack.Instance;
    elseif RayFront then
        return RayFront.Instance;
    end

    return nil
end

function Piping:GetConnections(Pipe)
    local Connections = {}
    for _, Connector in pairs(Pipe:GetChildren()) do
        if Connector.Name:find("Connector") then
            print("Finding direct pipe")
            local Connection = Piping:FindDirectPipe(Connector)

            if Connection and Connection.Name:find("Connector") then
                table.insert(Connections, Connection)
            end
        end
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