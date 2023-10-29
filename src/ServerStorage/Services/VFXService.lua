local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

local Knit = require(ReplicatedStorage.Packages.Knit)
--local RayHitbox = require(ReplicatedStorage.ExternalModules.RayHitbox)

local VFXService = Knit.CreateService {
    Name = "VFXService",
    Client = {},
    Services = {
        ["VisualiseService"] = nil;
    }
}

function VFXService:Lerp(a, b, t)
    return a + (b - a) * t
end

function VFXService:MakeParticle(Particle, BasePart, ExtraProperties)
    local ClonedParticle = Particle:Clone()
    ClonedParticle.Parent = BasePart

    if ClonedParticle:IsA("BasePart") then
        for _, Emitter in pairs(ClonedParticle:GetDescendants()) do
            if Emitter:IsA("ParticleEmitter") then
                for PropIndex, PropValue in pairs(ExtraProperties) do
                    Emitter[PropIndex] = PropValue
                end
            end
        end
    elseif ClonedParticle:IsA("ParticleEmitter") then
        for PropIndex, PropValue in pairs(ExtraProperties) do
            ClonedParticle[PropIndex] = PropValue
        end
    end

    return ClonedParticle
end

function VFXService:EmitPart(BasePart, Amount)
    local HighestTime = 0
    for i,v in pairs(BasePart:GetDescendants()) do
        if v:IsA("ParticleEmitter") then
            v:Emit(Amount)
            if v.Lifetime.Max > HighestTime then
                HighestTime = v.Lifetime.Max
            end
        end
        if v:IsA("Attachment") then
            v.WorldCFrame = BasePart.CFrame
        end 
    end
    return HighestTime
end

function VFXService:GetLength(Part)
    local HighestTime = 0
    for i,v in pairs(Part:GetDescendants()) do
        if v:IsA("ParticleEmitter") then
            if v.Lifetime.Max > HighestTime then
                HighestTime = v.Lifetime.Max
            end
        end
    end
    return HighestTime
end

function VFXService:Emit(Particle, BasePart, Amount, Props, Dir)
    local NewParticle = self:MakeParticle(Particle, BasePart, {
        Enabled = false;
    })
    if Props then
        for i,v in pairs(Props) do
            NewParticle[i] = v
        end
    end
    if NewParticle:IsA("BasePart") then
        if BasePart:IsA("Attachment") then
            NewParticle.CFrame = BasePart.WorldCFrame
            if Dir then
                NewParticle.CFrame = CFrame.lookAt(NewParticle.Position + Dir*25, Dir * 5)
            end
        else
            NewParticle.Position = BasePart.Position
        end
        Debris:AddItem(NewParticle, self:EmitPart(NewParticle, Amount))
        return NewParticle
    elseif NewParticle:IsA("ParticleEmitter") then
        NewParticle:Emit(Amount)
        Debris:AddItem(NewParticle, NewParticle.Lifetime.Max)
        return NewParticle
    end
end

function VFXService:Add(Particle, BasePart, Time)
    local NewParticle = self:MakeParticle(Particle, BasePart, {
        Enabled = true;
    })
    local Particles = {}
    Particles[1] = NewParticle
    if NewParticle:IsA("BasePart") then
        for i,v in pairs(NewParticle:GetDescendants()) do
            if v:IsA("ParticleEmitter") then
                v.Parent = BasePart
                Particles[#Particles+1] = v
            end
        end
    end
    if Time then
        task.delay(Time, function()
            for i,v in pairs(Particles) do
                v:Destroy()
            end
        end)
    end
    return Particles
end

function VFXService:HasParticle(BasePart, ParticleName)
    return BasePart:FindFirstChild(ParticleName)
end

function VFXService:GetGround(Pos, Ignore)
    local Params = RaycastParams.new()
    Params.FilterDescendantsInstances = Ignore or {}
    Params.FilterType = Enum.RaycastFilterType.Exclude
    Params.IgnoreWater = false
    Params.RespectCanCollide = false

    local Ray_Cast = workspace:Raycast(Pos, Vector3.new(0, -10000, 0), Params)
    if Ray_Cast then
        return Ray_Cast.Position
    end
    return nil
end

function VFXService:GetMaterial(RayResult)
    for i,v in pairs(ReplicatedStorage.GameAssets.SFX.Breaking:GetChildren()) do
        if v:GetAttributes()[RayResult.Material.Name] then
            return v.Name
        else
            return "None"
        end
    end
end

function VFXService:Projectile(Obj, Direction, Distance, Speed, Caster, OnHit)
    local Params = RaycastParams.new()
    Params.FilterDescendantsInstances = {workspace.Visuals, workspace.Visualise, workspace.Dummies, Caster}
    Params.IgnoreWater = true
    Params.RespectCanCollide = true
    Params.FilterType = Enum.RaycastFilterType.Exclude
    --[[local Hitbox = RayHitbox.new(Obj)
    Hitbox.RaycastParams = Params
    Hitbox.DetectionMode = 2
    Hitbox:HitStart()

    local Rotation = 0
    local B = false
    while true do
        if B == true then break end
        Rotation += 0.03
        Obj.CFrame = Obj.CFrame:Lerp(CFrame.new(Obj.Position + Direction * Distance), Speed)
        Obj.CFrame = CFrame.lookAt(Obj.Position, (Obj.Position + Direction * Distance)) * CFrame.Angles(0, math.pi, Rotation)
        Obj.Hitbox.Position = Obj.Position

    
        --[[
        local ProjectileRay = workspace:Raycast(Obj.Position, -Obj.CFrame.LookVector * 25, Params)
        if ProjectileRay then
            OnHit(ProjectileRay)
            break
        end--]
        Hitbox.OnHit:Connect(function(Hit, Hum, ProjectileRay)
            OnHit(ProjectileRay)
            B = true
            Hitbox:HitStop()
            return
        end)
        task.wait()
    end--]]
end

function VFXService:AddVFX(Obj, Attachment)
    local NewObj = Obj:Clone()
    NewObj.Parent = workspace.Visuals
    NewObj.CFrame = Attachment.WorldCFrame
    return NewObj
end

function VFXService:Shockwave(CF, Size, Speed)
    local Shockwave = ReplicatedStorage.GameAssets.VFX.Parts.Shockwave:Clone()
    Shockwave.Parent = workspace.Visuals
    Shockwave.CFrame = (typeof(CF) == "Vector3" and CFrame.new(CF) or CF)
    Shockwave.Anchored = true
    Shockwave.CanCollide = false

    local Shock
    Shock = game:GetService("RunService").Heartbeat:Connect(function()
        Shockwave.Size = Vector3.new(self:Lerp(Shockwave.Size.X, Size or 25, Speed or 0.05), Shockwave.Size.Y, self:Lerp(Shockwave.Size.Z, Size or 25, Speed or 0.05))
        Shockwave.Transparency = self:Lerp(Shockwave.Transparency, 1, Speed or 0.05)    

        if Shockwave.Transparency == 1 then
            Shockwave:Destroy()
            Shock:Disconnect()
        end
    end)
end

function VFXService:KnitStart()
    --self.Services.VisualiseService = Knit.GetService("VisualiseService")
end


function VFXService:KnitInit()
    print("[Knit] VFX service initialised!")
end

return VFXService
