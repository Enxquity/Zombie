local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Knit = require(ReplicatedStorage.Packages.Knit)

local Spectate = Knit.CreateController {
    Name = "Spectate";
    CurrentSpectating = nil;
    IsSpectating = false;

    Services = {
        ["SpectateService"] = 0;
    }
}

--[[
    Current plan here is that
    1. We use the client to always lock into the first person view of the spectating client
    2. We make sure to avoid other dead players
    3. We send info to the client that then calls another event to the spectate client which will return the viewmodel CFrames
    4. We apply these CFrames to our clients viewmodels

    Things to be aware of:
        We will have to replicate their UI too and all the effects.
        We will have to make sure to not display the gun in the current character and do a 1:1 replication
        We will also have to allow the toggling of the third person and first person views
        We will have to make sure the gun is cloned correctly to the gun that the client currently has and also make it work with switching
        

    Once again this will be improved on but i am currently coding from a MacBook therefore unable to test it and hope everything
    just works correctly!

]]

function Spectate:StartSpectate()
    self.IsSpectating = true
    self.CurrentSpectating = Players:GetPlayers()[1]
    RunService:BindToRenderStep("ClientSpectate", 1, function()
        local Coordinates = self.Services.SpectateService:GetCoordinates(self.CurrentSpectating)
        local Viewmodel = workspace.CurrentCamera:FindFirstChild("Viewmodel")
        if Viewmodel and #Coordinates > 0 then
            for Key, Value in pairs(Coordinates) do
                Viewmodel[Key].CFrame = Value 
            end
        end
    end)
end

function Spectate:Next()
    assert(self.IsSpectating, "Not currently in spectate!")
    local SpectateList = Players:GetPlayers()
    local CurrentIndex = table.find(SpectateList, self.CurrentSpectating)

    if CurrentIndex then
        self.CurrentSpectating = SpectateList[(CurrentIndex + 1) > #SpectateList and 1 or CurrentIndex + 1]
    end
end

function Spectate:Back()
    assert(self.IsSpectating, "Not currently in spectate!")
    local SpectateList = Players:GetPlayers()
    local CurrentIndex = table.find(SpectateList, self.CurrentSpectating)

    if CurrentIndex then
        self.CurrentSpectating = SpectateList[(CurrentIndex - 1) < 1 and #SpectateList or CurrentIndex - 1]
    end
end

function Spectate:KnitStart()
    
end

function Spectate:KnitInit()
    for Service, _ in pairs(self.Services) do
        self.Services[Service] = Knit.GetService(Service)
    end
    self.Services.SpectateService.Signals.GetViewmodelCoordinates:Connect(function()
        local ViewmodelDataArr = {}
        local Viewmodel = workspace.CurrentCamera:FindFirstChild("Viewmodel")

        if Viewmodel then
            for i,v in pairs(Viewmodel:GetChildren()) do
                if v:IsA("BasePart") then
                    ViewmodelDataArr[v.Name] = v.CFrame
                end
            end
        end

        return ViewmodelDataArr
    end)
    
    print("[Knit Client] Spectate initialised!")
end


return Spectate