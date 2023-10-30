local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")
local Knit = require(ReplicatedStorage.Packages.Knit)

local Matchmaking = Knit.CreateService {
    Name = "Matchmaking",
    Client = {},
}

function Matchmaking:KnitStart()

end


function Matchmaking:KnitInit()
    print("[Knit] Matchmaking initialised!")
    coroutine.wrap(function()
        for i = 30, 0, -1 do
            for _, plr in pairs(Players:GetPlayers()) do
                local PGui = plr:FindFirstChild("PlayerGui")
                if PGui then
                    local HUD = PGui:FindFirstChild("HUD")
                    if HUD then
                        HUD.Countdown.Label.Text = i .. "s"
                    end
                end
            end
            task.wait(1)
        end
        workspace:SetAttribute("Begin", true)
    end)()
end


return Matchmaking
