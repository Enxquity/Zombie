local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages.Knit)

local Placement = Knit.CreateController { 
    Name = "Placement";
    Placement = false;
    Mouse = Players.LocalPlayer:GetMouse();

    Modules = {};
    Services = {
        ["PlacementServer"] = "None";
    };   

    Settings = {
        SnapX = 2;
        SnapZ = 2;
        Rotation = 0;
    };
    CurrentItem = nil;
    CurrentCFrame = nil;
}

function Placement:Call(Module, Func)
    if self.Modules[Module] then
        self.Modules[Module][Func](self)
    end
end

function Placement:ServiceCall(Module, Func, ...)
    if self.Services[Module] then
        return self.Services[Module][Func](self, ...)
    end
end

function Placement:Repropertise(Item, List)
    for Property, NewProperty in pairs(List) do
        for i,v in pairs(Item:GetDescendants()) do
            if v:IsA("BasePart") then
                v[Property] = NewProperty
            end
        end
    end
end

function Placement:BoundingBox(Item)
    local NewBoundingBox = Instance.new("BoxHandleAdornment")
    NewBoundingBox.Size = Item:GetExtentsSize()
    NewBoundingBox.Adornee = Item
    NewBoundingBox.Parent = Item
    return NewBoundingBox
end

function Placement:SelectionBox(Item)
    local NewSelectionBox = Instance.new("SelectionBox")
    NewSelectionBox.Adornee = Item
    NewSelectionBox.Parent = Item
    return NewSelectionBox
end

function Placement:Hitbox(Item)
    local NewHitbox = Instance.new("Part")
    NewHitbox.CanCollide = false
    NewHitbox.Anchored = true
    NewHitbox.Size = Item:GetExtentsSize()
    NewHitbox.CFrame = Item:GetPivot()
    NewHitbox.Parent = Item
    NewHitbox.Transparency = 1

    return NewHitbox
end

function Placement:Arrow(From, To, Color)
    local NewArrow = workspace.Arrow:Clone()
    NewArrow.Parent = workspace.Arrows

    local ArrowOrigin = CFrame.new(From)
    NewArrow.CFrame = CFrame.lookAt(ArrowOrigin.Position, To)
    NewArrow.Color = Color

    return NewArrow
end

function Placement:Rotate()
    if self.Settings.Rotation >= math.pi*2 then
        self.Settings.Rotation = 0
        return
    end
    self.Settings.Rotation += math.pi/2
end

function Placement:Start(Item)
    if self.Placement == true then
        self:Stop()
        task.wait()
    end
    self.Placement = true

    local NewItem = Item:Clone()
    NewItem.Parent = workspace.Debris

    self:Repropertise(NewItem, {
        CanCollide = false;
    })
    local Box = self:BoundingBox(NewItem)
    local HitBox = self:Hitbox(NewItem)
    Box.Transparency = 0.6

    while self.Placement == true do
        self.Mouse.TargetFilter = NewItem
        local MousePosition = self.Mouse.Hit.Position
        local RoundedPosition = Vector3.new(
            math.round(MousePosition.X / self.Settings.SnapX) * self.Settings.SnapX, 
            NewItem.PrimaryPart.Size.Y/2,
            --0,
            math.round(MousePosition.Z / self.Settings.SnapZ) * self.Settings.SnapZ
        )

        NewItem:SetPrimaryPartCFrame(CFrame.new(RoundedPosition) * CFrame.Angles(0, self.Settings.Rotation, 0))

        for i,v in pairs(NewItem:GetChildren()) do
            if v.Name == "Direction" then
                v.Texture.OffsetStudsV += 0.01
            end
        end

        local Event = HitBox.Touched:Connect(function() end)
        if #HitBox:GetTouchingParts() > #Item:GetChildren() then
            Box.Color3 = Color3.fromRGB(255, 0, 0)
        else
            Box.Color3 = Color3.fromRGB(97, 185, 112)
        end
        Event:Disconnect()

        self.CurrentItem = Item
        self.CurrentCFrame = NewItem:GetPivot()
        task.wait()
    end

    NewItem:Destroy()
    self.CurrentItem = nil
end

function Placement:Stop()
    self.Placement = false
end

function Placement:Place()
    if self.CurrentItem == nil then return end
    local PlacementService = Knit.GetService("PlacementServer")
    PlacementService:Place(self.CurrentItem, self.CurrentCFrame)
    --self:Stop()
end

function Placement:KnitStart()
    for i,v in pairs(script:GetChildren()) do
        if v:IsA("ModuleScript") then
            local r = require(v)
            self.Modules[v.Name] = r

            if r["init"] then
                r.init(self)
            end
        end
    end
    for i,v in pairs(self.Services) do
        self.Services[i] = Knit.GetService(i)
    end
end


function Placement:KnitInit()
    
end


return Placement
