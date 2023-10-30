local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages.Knit)

local SFXService = Knit.CreateService {
    Name = "SFXService",
    Client = {},
}

function SFXService.Client:PlayAt(Player, SFXName, Inst, Yield, Properties)
    self.Server:PlayAt(SFXName, Inst, Yield, Properties)
end

function SFXService:PlayAt(SFXName, Inst, Yield, Properties)
    local Sound = ReplicatedStorage.GameAssets.SFX:FindFirstChild(SFXName)
    if Sound then
        local NewSound = Sound:Clone()
        NewSound.Parent = Inst

        local Props = Properties or {}
        for PropIndex, PropValue in pairs(Props) do
            NewSound[PropIndex] = PropValue
        end
        
        NewSound:Play()
        if Yield and Yield == true then
            Sound.Finished:Wait()
        end
        Debris:AddItem(NewSound, NewSound.TimeLength + 0.1)
    end
end

function SFXService:PlayBreak(Material, Inst)
    local Sound = ReplicatedStorage.GameAssets.SFX.Breaking:FindFirstChild(Material)
    if Sound then
        local NewSound = Sound.Sound:Clone()
        NewSound.Parent = Inst
        
        NewSound:Play()
        Debris:AddItem(NewSound, NewSound.TimeLength + 0.1)
    end
end

function SFXService:KnitStart()
    
end


function SFXService:KnitInit()
    print("[Knit] SFX service initialised!")
end


return SFXService
