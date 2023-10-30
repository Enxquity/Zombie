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
