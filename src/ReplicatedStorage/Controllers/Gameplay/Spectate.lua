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

    ====================

    Client's task:
    
    Create a loop to make a request to the server really often
    Wait for the return of the server's request to the spectatee's client and back (more info in the SpectateService script)
    The data returned from the spectatee comes in this form {PartName = PartCFrame;}
    Use this data to change each part in our current clients viewmodel so that it's the same as spectatee's viewmodel

    ====================

    Undone currently:

    - Need to make it so that the gun also replicates, have a plan currently this is what im thinking
            - Check if the client's viewmodel has a gun
                - If yes, then check if the name of the clients gun and spectatee's gun is the same
                    - If yes then replicate the cframes from the spectatee's viewmodel data                    <-----------------^
                    - If no, delete the current client gun, find the new one in RepStorage.GameAssets.Weapons and clone it in ->|
                - If no then copy the same gun as the spectatee has from GameAssets and then use the viewmodel data
    
    - Need to see if animations replicate (i believe they should replicate with CFrame, but not sure)
    - Need to pass through camera CFrame data aswell so that camera shake & etc.. also replicate
    - Need to pass through UI data aswell
    - Need to make sure it is also performant as alot of remote event calls will be made (like alotttttt)
]]

function Spectate:StartSpectate()
    self.IsSpectating = true
    self.CurrentSpectating = Players:GetPlayers()[1]
    RunService:BindToRenderStep("ClientSpectate", 1, function()
        local Coordinates = self.Services.SpectateService:GetCoordinates(self.CurrentSpectating)
        local Viewmodel = workspace.CurrentCamera:FindFirstChild("Viewmodel")

        local Gun = Coordinates["Gun"]
        local CurrentGun = Viewmodel:FindFirstChildWhichIsA("Model")

        if Viewmodel and #Coordinates > 0 then
            for Key, Value in pairs(Coordinates) do
                Viewmodel[Key].CFrame = Value 
            end
            if Gun and CurrentGun and Gun["Name"] == CurrentGun.Name then
                CurrentGun:PivotTo(Gun["CFrame"])
                table.foreach(Gun["Stats"], function(Key, Value)
                    CurrentGun.Values[Key].Value = Value
                end)
            else
                local GunExists = ReplicatedStorage.GameAssets.Weapons:FindFirstChild(Gun["Name"])
                if GunExists then
                    local NewGun = GunExists:Clone()
                    NewGun.Parent = Viewmodel
                end
            end

            workspace.CurrentCamera.CFrame = Coordinates["Camera"]
        end

        print("Processed spectate step:", Coordinates)
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
                ViewmodelDataArr["Camera"] = workspace.CurrentCamera.CFrame

                local Gun = Viewmodel:FindFirstChildWhichIsA("Model")
                if Gun then
                    ViewmodelDataArr["Gun"] = {}
                    ViewmodelDataArr["Gun"]["Name"] = Gun.Name
                    ViewmodelDataArr["Gun"]["CFrame"] = Gun:GetPivot()
                    ViewmodelDataArr["Gun"]["Stats"] = {}

                    table.foreach(Gun.Values:GetDescendants(), function(Key, Value)
                        ViewmodelDataArr["Gun"]["Stats"][Value.Name] = Value.Value 
                    end)
                end
            end
        end

        return ViewmodelDataArr
    end)
    
    print("[Knit Client] Spectate initialised!")
end


return Spectate