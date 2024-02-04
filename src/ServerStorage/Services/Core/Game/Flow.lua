local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages.Knit)

local Flow = Knit.CreateService {
    Name = "Flow",
    Client = {},
}


function Flow:KnitStart()
    while task.wait(1) do
        --// Electricity flow
        for _, Power in pairs(CollectionService:GetTagged("Power")) do
            if Power:HasTag("Output") then
                for _, ConnectionA in pairs(Power.PowerInfo.Outputs:GetChildren()) do
                    if Power.PowerInfo.Power.Value > 0 then
                        local Connection = ConnectionA.Value
                        local PowerChange = math.min(Power.PowerInfo.Flowrate.Value, Connection.PowerInfo.Flowrate.Value)
                        if PowerChange >= Power.PowerInfo.Power.Value then
                            PowerChange = Power.PowerInfo.Power.Value
                        end
                        if Connection.PowerInfo.Power.Value + PowerChange >= Connection.PowerInfo.PowerMax.Value then
                            PowerChange = Connection.PowerInfo.PowerMax.Value-Connection.PowerInfo.Power.Value
                        end
                        
                        Power.PowerInfo.Power.Value = math.clamp(Power.PowerInfo.Power.Value - PowerChange, 0, Power.PowerInfo.PowerMax.Value)
                        Connection.PowerInfo.Power.Value = math.clamp(Connection.PowerInfo.Power.Value + PowerChange, 0, Connection.PowerInfo.PowerMax.Value)
                    end
                end
            end
        end
    end
end


function Flow:KnitInit()
    
end


return Flow
