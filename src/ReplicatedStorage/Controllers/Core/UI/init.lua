local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages.Knit)

local UI = Knit.CreateController { 
    Name = "UI";
    UI = {};
}

function UI:GetInterface(Name)
    for _, Interface in pairs(Players.LocalPlayer.PlayerGui:GetDescendants()) do
        if Interface.Name == Name then
            return Interface
        end
    end
    return nil
end

function UI:Call(Module, Func)
    if self.UI[Module] then
        self.UI[Module][Func](self)
    end
end

function UI:KnitStart()
    for i,v in pairs(script:GetChildren()) do
        if v:IsA("ModuleScript") then
            local r = require(v)
            self.UI[v.Name] = r

            task.spawn(function()
                r.init(self)
            end)
        end
    end
end


function UI:KnitUI()
    
end


return UI
