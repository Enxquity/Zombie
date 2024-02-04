local CollectionService = game:GetService("CollectionService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local Power = {
    Mouse = Players.LocalPlayer:GetMouse();

    Enabled = false;
    BoxCache = {};
    IndependentCache = {};
    Blacklist = {};
    Connections = {}
}

function Power.clear_connections()
    if workspace:FindFirstChild("Connections") then 
        for _, Connection in pairs(workspace.Connections:GetChildren()) do
            Connection:Destroy()
        end
    end
end

function Power.update_connections(Library)
    Power.clear_connections();
    for _, Connection in pairs(CollectionService:GetTagged("Power")) do
        for _, Output in pairs(Connection.PowerInfo.Outputs:GetChildren()) do
            local Obj = Output.Value
            Library:Cylinder(Connection:GetPivot().Position, Obj:GetPivot().Position, Connection, Color3.fromRGB(144, 144, 144))
        end
    end
end

function Power.clear_boxes()
    table.foreach(Power.Blacklist, function(_, Pipe)
        Pipe:FindFirstChildWhichIsA("SelectionBox"):Destroy()
    end)
    table.foreach(Power.BoxCache, function(_, Box)
        Box:Destroy()
    end)
    table.foreach(Power.IndependentCache, function(_, Box)
        Box:Destroy()
    end)
    Power.BoxCache = {}
    Power.Blacklist = {}
    Power.IndependentCache = {}
end

function Power.toggle(Library)
    Power.Enabled = not Power.Enabled

    if Power.Enabled == true then
        Power.update_connections(Library);
        Power.Connections["ClickDetector"] = UserInputService.InputBegan:Connect(function(Input, IsTyping)
            if IsTyping then return end
            if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                if #Power.Blacklist == 0 then
                    local Target = nil
                    for i,v in pairs(Power.BoxCache) do
                        Target = v
                        break
                    end
                    if not Target then return end

                    Target.Color3 = Color3.fromRGB(189, 187, 97)
                    Target.Name = "Selected"
                    table.remove(Power.BoxCache, table.find(Power.BoxCache, Target))
                    table.insert(Power.Blacklist, Target.Parent)
                else
                    local PowerA = nil
                    local PowerB = nil
                    table.foreach(Power.Blacklist, function(_, Pipe)
                        PowerA = Pipe
                        PowerA:FindFirstChild("Selected"):Destroy()
                    end)
                    table.foreach(Power.BoxCache, function(_, Box)
                        PowerB = Box.Parent
                        Box:Destroy()
                    end)
                    table.foreach(Power.IndependentCache, function(_, Box)
                        Box:Destroy()
                    end)
                    Power.BoxCache = {}
                    Power.Blacklist = {}
                    Power.IndependentCache = {}

                    Library:ServiceCall("PlacementServer", "ConnectPower", PowerA, PowerB):andThen(function()
                        print("Connected!")
                        Power.update_connections(Library);
                    end)
                end
            end
        end)
    end

    while Power.Enabled == true do
        local Target = Power.Mouse.Target
        if not Target then task.wait() continue end
        Target = Target.Parent

        if Target:FindFirstChild("Power") then
            Target = Target.Power
        end

        if CollectionService:HasTag(Target, "Power") then
            if not Target:FindFirstChild("Select") and not table.find(Power.Blacklist, Target) then
                if CollectionService:HasTag(Target, "Input") and #Power.Blacklist <= 0 then
                    task.wait()
                    continue
                end
                table.foreach(Power.BoxCache, function(_, Box)
                    Box:Destroy()
                end)
                Power.BoxCache = {}
                local NewBox = Library:SelectionBox(Target)
                NewBox.LineThickness = 0.05
                NewBox.Name = "Select"
                table.insert(Power.BoxCache, NewBox)
            end
        else
            table.foreach(Power.BoxCache, function(_, Box)
                Box:Destroy()
            end)
            Power.BoxCache = {}
        end
        print("Power")
        task.wait()
    end
    Power.clear_boxes();
    Power.Connections["ClickDetector"]:Disconnect()
end

return Power