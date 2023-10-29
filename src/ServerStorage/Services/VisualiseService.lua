local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages.Knit)

local VisualiseService = Knit.CreateService {
    Name = "VisualiseService",
    Client = {},
}

function VisualiseService:VisualisePart(Origin, Pos, Length, Props)
    local Dist = (Origin - Pos).Magnitude
    local Part = Instance.new("Part", workspace.Ignore)
    Part.Anchored = true
    Part.CanCollide = false
    Part.Size = Vector3.new(0.1, 0.1, Dist)
    Part.CFrame = CFrame.lookAt(Origin, Pos) * CFrame.new(0, 0, -Dist/2)

    for i,v in pairs(Props) do
        Part[i] = v
    end

    Debris:AddItem(Part, Length or 2)
    return Part
end

function VisualiseService:VisualiseRay(Origin, Dir, Length, Props)
    self:VisualisePart(Origin, Origin+Dir, Length, Props)
end

function VisualiseService:KnitStart()
    
end


function VisualiseService:KnitInit()
    
end


return VisualiseService
