local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages.Knit)

function ConvertInstanceToList(InstanceList)
    local NewList = {}
    for i,v in pairs(InstanceList) do
        table.insert(NewList, v.Name)
    end
    return NewList
end

return {{

    ["money"] = {
        Arguments = {"player", "value"};
        Description = "Appends value to points.";
        Callback = function (Args)
            local PointsServ = Knit.GetService("PointsService")
            PointsServ:AddPoints(Args[1], Args[2])
        end;
    };

    ["weapon"] = {
        Arguments = {"player", "gun"};
        Description = "Grants a weapon via the name.";
        Callback = function(Args)
            local WeaponServ = Knit.GetService("WeaponServer")
            WeaponServ:GiveGun(Args[1], Args[2])
        end
    };

    ["get_powerup"] = {
        Arguments = {"powerup"};
        Description = "Grants the server a perk via name";
        Callback = function(Args)
            local WeaponServ = Knit.GetService("WeaponServer")
            WeaponServ:GetPowerup(Args[1])
        end
    };

    ["kill"] = {
        Arguments = {"player"};
        Description = "Kills a player.";
        Callback = function(Args)
            local AdminServ = Knit.GetService("AdminServer")

            AdminServ:Run(
                [[
                    return function(Args)
                        local Char = Args[1].Character
                        if Char and Char:FindFirstChild("Humanoid") then
                            Char:FindFirstChild("Humanoid").Health = 0
                        end
                        Args[1]:SetAttribute("Dead", true)
                    end
                ]], Args
            )
        end;
    };

    ["down"] = {
        Arguments = {"player"};
        Description = "Downs a player.";
        Callback = function(Args)
            local AdminServ = Knit.GetService("AdminServer")

            AdminServ:Run(
                [[
                    return function(Args)
                        local Char = Args[1].Character
                        if Char and Char:FindFirstChild("Humanoid") then
                            Char:FindFirstChild("Humanoid").Health = 1
                        end
                    end
                ]], Args
            )
        end;
    };

    ["kick"] = {
        Arguments = {"player", "reason"};
        Description = "Kills a player.";
        Callback = function(Args)
            local AdminServ = Knit.GetService("AdminServer")

            AdminServ:Run(
                [[
                    return function(Args)
                        local Player = Args[1]
                        if Player.Parent == game.Players then
                            Player:Kick(Args[2])
                        end
                    end
                ]], Args
        )
        end
    }
}, {
    powerup = {
        "Nuke";
        "InstaKill";
        "DoublePoints";
        "MaxAmmo";
    }
}}
