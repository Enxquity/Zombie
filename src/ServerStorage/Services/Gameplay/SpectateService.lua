local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages.Knit)

local SpectateService = Knit.CreateService {
    Name = "SpectateService",
    Client = {
        Signals = {
            GetViewmodelCoordinates = Knit.CreateSignal();
        }
    },
}

--[[
    Servers task:
    
    Recieve request from the spectator client
    Redirect that request to the person that is being spectated
    Wait for the return of viewmodel data from the spectatee's client
    Redirect that data back to the spectator

    This server is essentially the middleman between the two clients.
]]

function SpectateService.Client:GetCoordinates(PlayerCalling, PlayerSpectating)
    return self.Server:GetCoordinates(PlayerSpectating)
end

function SpectateService:GetCoordinates(PlayerSpectating)
    return self.Client.Signals.GetViewmodelCoordinates:Fire(PlayerSpectating)
end

function SpectateService:KnitStart()
    
end

function SpectateService:KnitInit()
    
end


return SpectateService
