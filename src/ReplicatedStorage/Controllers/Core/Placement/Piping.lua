local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Knit = require(ReplicatedStorage.Packages.Knit)
local Serializer = require(ReplicatedStorage.Source.Serializer)

local Piping = {
    Enabled = false;
    Mouse = Players.LocalPlayer:GetMouse();
    BoxCache = {};
    Blacklist = {};
    IndependentCache = {};
    Connections = {};
}

function Piping.clear_arrows()
    if workspace:FindFirstChild("Arrows") then 
        for _, Arrow in pairs(workspace.Arrows:GetChildren()) do
            Arrow:Destroy()
        end
    end
end

function Piping.update_arrows(Library)
    Piping.clear_arrows()
    for _, Pipe in pairs(CollectionService:GetTagged("Pipe")) do
        local Arrows = {}
        if not Pipe.Parent:HasTag("Connectable") then
            for _, Connection in pairs(Pipe.PipeInfo.Connections:GetChildren()) do
                if Connection.Value ~= nil then
                    local Arrow = Library:Arrow((Pipe:GetPivot() + Vector3.new(0, Pipe:GetExtentsSize().Y/2, 0)).Position, (Connection.Value.Parent:GetPivot() + (Vector3.yAxis * Pipe:GetExtentsSize().Y/2)).Position, Color3.fromRGB(123, 154, 255))
                    table.insert(Arrows, Arrow)
                end
            end
        else
            for _, Connection in pairs(Pipe.PipeInfo.Connections:GetChildren()) do
                if Connection.Value ~= nil then
                    local Arrow = Library:Arrow((Pipe:GetPivot() + Vector3.new(0, Connection.Value.Parent:GetExtentsSize().Y/2, 0)).Position, (Connection.Value.Parent:GetPivot() + (Vector3.yAxis * Connection.Value.Parent:GetExtentsSize().Y/2)).Position, Color3.fromRGB(123, 154, 255), true)
                    table.insert(Arrows, Arrow)
                end
            end
        end
        if #Arrows > 1 then
            for _, ArrowA in pairs(Arrows) do
                for _, ArrowB in pairs(Arrows) do
                    print(ArrowB.CFrame.LookVector:Dot(ArrowA.CFrame.LookVector))
                    if ArrowB.CFrame.LookVector:Dot(ArrowA.CFrame.LookVector) <= -0.99 then
                        local NewSize = Vector3.new(ArrowA.Size.X, ArrowA.Size.Y, ArrowA.Size.Z/1.25)
                        ArrowA.Size = NewSize
                        ArrowB.Size = NewSize
                        ArrowA.CFrame += ArrowA.CFrame.LookVector * ArrowA.Size.Z/6
                        ArrowB.CFrame += ArrowB.CFrame.LookVector * ArrowB.Size.Z/6
                    end
                end
            end
        end
     end
end

function Piping.clear_boxes()
    table.foreach(Piping.Blacklist, function(_, Pipe)
        Pipe:FindFirstChildWhichIsA("SelectionBox"):Destroy()
    end)
    table.foreach(Piping.BoxCache, function(_, Box)
        Box:Destroy()
    end)
    table.foreach(Piping.IndependentCache, function(_, Box)
        Box:Destroy()
    end)
    Piping.BoxCache = {}
    Piping.Blacklist = {}
    Piping.IndependentCache = {}
end

function Piping.disable()
    Piping.Enabled = false
end

function Piping.toggle(Library)
    Piping.Enabled = not Piping.Enabled

    if Piping.Enabled == true then
        Piping.update_arrows(Library)
        Piping.Connections["ClickDetector"] = UserInputService.InputBegan:Connect(function(Input, IsTyping)
            if IsTyping then return end
            if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                if #Piping.Blacklist == 0 then
                    local Target = nil
                    for i,v in pairs(Piping.BoxCache) do
                        Target = v
                        break
                    end
                    if not Target then return end

                    Target.Color3 = Color3.fromRGB(189, 187, 97)
                    Target.Name = "Selected"
                    table.remove(Piping.BoxCache, table.find(Piping.BoxCache, Target))
                    table.insert(Piping.Blacklist, Target.Parent)

                    Library:ServiceCall("PlacementServer", "GetConnections", Target.Parent):andThen(function(Connections)
                        table.foreach(Connections, function(a, b)
                            if b.Parent.Parent:HasTag("Connectable") and not b.Parent.Parent:HasTag("HasInput") then
                                print("Can't connect here")
                            else
                                local Box = Library:SelectionBox(b.Parent)
                                Box.Color3 = Color3.fromRGB(118, 230, 151)
                                Box.SurfaceColor3 = Color3.fromRGB(118, 230, 151)
                                Box.LineThickness = 0.025
                                Box.SurfaceTransparency = 0.85
    
                                if b.Parent.Name == "Solid" then
                                    Box.Adornee = b.Parent.Parent
                                end

                                table.insert(Piping.IndependentCache, Box)
                            end
                        end)
                    end)
                else
                    local PipeA = nil
                    local PipeB = nil
                    table.foreach(Piping.Blacklist, function(_, Pipe)
                        PipeA = Pipe
                        PipeA:FindFirstChild("Selected"):Destroy()
                    end)
                    table.foreach(Piping.BoxCache, function(_, Box)
                        PipeB = Box.Parent
                        Box:Destroy()
                    end)
                    table.foreach(Piping.IndependentCache, function(_, Box)
                        Box:Destroy()
                    end)
                    Piping.BoxCache = {}
                    Piping.Blacklist = {}
                    Piping.IndependentCache = {}

                    if PipeA:HasTag("Connectable") then
                        Library:ServiceCall("PlacementServer", "GetConnections", PipeA, true):andThen(function(Connections)
                            local Deserialized = Serializer.Deserialize(Connections)
                            for Connector, Connection in pairs(Deserialized) do
                                if Connection.Parent == PipeB then
                                    PipeA = Connector.Parent
                                    return
                                end
                            end
                        end):await()

                        Library:ServiceCall("PlacementServer", "Connect", PipeA, PipeB):andThen(function(Result)
                            print("The result of the pipe connection was:", Result)
                            Piping.update_arrows(Library)
                        end)
                    else
                        Library:ServiceCall("PlacementServer", "Connect", PipeA, PipeB):andThen(function(Result)
                            print("The result of the pipe connection was:", Result)
                            Piping.update_arrows(Library)
                        end)
                    end
                end
            end
        end)
    end

    while Piping.Enabled == true do
        Piping.Mouse.TargetFilter = workspace.Arrows
        local Target = Piping.Mouse.Target
        if not Target then task.wait() continue end
        Target = Target.Parent
        if CollectionService:HasTag(Target, "Pipe") or CollectionService:HasTag(Target, "Connectable") then
            if #Piping.Blacklist ~= 0 and CollectionService:HasTag(Target, "Connectable") and not CollectionService:HasTag(Target, "HasInput") then
                task.wait()
                continue
            end
            if not Target:FindFirstChild("Select") and not table.find(Piping.Blacklist, Target) and not Target:HasTag("Machine") then
                table.foreach(Piping.BoxCache, function(_, Box)
                    Box:Destroy()
                end)
                Piping.BoxCache = {}
                local NewBox = Library:SelectionBox(Target)
                NewBox.LineThickness = 0.05
                NewBox.Name = "Select"
                table.insert(Piping.BoxCache, NewBox)
            end
        else
            table.foreach(Piping.BoxCache, function(_, Box)
                Box:Destroy()
            end)
            Piping.BoxCache = {}
        end
        task.wait()
    end
    Piping.clear_arrows();
    Piping.clear_boxes();
    Piping.Connections["ClickDetector"]:Disconnect()
end

return Piping