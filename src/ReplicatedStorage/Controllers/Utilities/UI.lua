local ReplicatedStorage = game:GetService("ReplicatedStorage");

local Knit = require(ReplicatedStorage.Packages.Knit)

local UI = Knit.CreateController{
    Name = "UI";
    CachedInterfaces = {}
}

function UI:GetInterface(InterfaceName)
    if self.CachedInterfaces[InterfaceName] then
        return self.CachedInterfaces[InterfaceName]
    end
    local PlayerGui = game:GetService("Players").LocalPlayer:FindFirstChild("PlayerGui")
    if PlayerGui:FindFirstChild(InterfaceName) then
        self.CachedInterfaces[InterfaceName] = PlayerGui:FindFirstChild(InterfaceName)
        return self.CachedInterfaces[InterfaceName]
    end
    return nil
end

function UI:KnitStart()

end

function UI:KnitInit()
    print("[Knit] UI Controller initialised!")
end

return UI