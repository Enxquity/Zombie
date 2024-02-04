local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages.Knit)

local Game = Knit.CreateController { 
    Name = "Game";
    Game = {};
}

function Game:Call(Module, Func)
    if self.Game[Module] then
        self.Game[Module][Func](self)
    end
end

function Game:KnitStart()
    for i,v in pairs(script:GetChildren()) do
        if v:IsA("ModuleScript") then
            local r = require(v)
            self.Game[v.Name] = r

            task.spawn(function()
                if r["init"] then
                    r.init(self)
                end
            end)
        end
    end
end


function Game:KnitGame()
    
end


return Game
