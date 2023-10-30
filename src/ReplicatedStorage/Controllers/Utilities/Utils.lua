local ReplicatedStorage = game:GetService("ReplicatedStorage");
local UserInputService = game:GetService("UserInputService")
local Player = game:GetService("Players").LocalPlayer

local Knit = require(ReplicatedStorage.Packages.Knit)
local Animations = require(ReplicatedStorage.Source.Controllers.Classes.Animations)

local Utils = Knit.CreateController { 
    Name = "Utils" 
}

function Utils:WaitForKeyEnd(Key, MaxLength, LoopFunc)
    local Start = tick()
    while true do
        if UserInputService:IsKeyDown(Key) == false then
            break
        end
        if LoopFunc and (LoopFunc(tick()-Start) == true) then
            break
        end
        if tick()-Start >= MaxLength then
            break
        end
        task.wait()
    end
end

function Utils:KnitStart()
    
end


function Utils:KnitInit()
    print("[Knit] Utility controller initialised!")
end


return Utils
