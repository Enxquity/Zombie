local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages.Knit)

local GameplayClient = Knit.CreateController { 
    Name = "GameplayClient";
    Services = {
        ["WeaponServer"] = 0;
        ["Gameplay"] = 0;
    };
    Controllers = {
        ["Prompt"] = 0;
    }
}


function GameplayClient:KnitStart()
    
end


function GameplayClient:KnitInit()
    --// Load services
    for i,v in pairs(self.Services) do
        self.Services[i] = Knit.GetService(i)
    end

    --// Load controllers
    for i,v in pairs(self.Controllers) do
        self.Controllers[i] = Knit.GetController(i)
    end

    --// Purchasing guns from walls
    for i,v in pairs(workspace.GunBuys:GetChildren()) do
        self.Controllers["Prompt"]:MakePrompt{
            Name = v.Name;
            Origin = v.WorldPivot.Position;
            Text = ('Hold [<font color="#FF7800">F</font>] to purchase %s for $%d'):format(v.Name, v.Data.Price.Value);
            Range = 5;
            ActivationKey = Enum.KeyCode.F;
            HoldTime = 1;
            ActivationFunc = function(Args)
                print("Activated prompt:", Args)
                self.Services.WeaponServer:PurchaseGun(v.Name)
            end;
            ForceHeldTarget = true;
        }
    end

    --// Mystery Box
    self.Controllers["Prompt"]:MakePrompt{
        Name = "MysteryBox";
        Origin = workspace.MysteryBox.WorldPivot.Position;
        Text = ('Hold [<font color="#FF7800">F</font>] to open mystery box for $%d'):format(750);
        Range = 10;
        ActivationKey = Enum.KeyCode.F;
        HoldTime = 1;
        ActivationFunc = function(Args)
            self.Services.WeaponServer:OpenBox()
        end;
        TextCheck = function()
            return not workspace.MysteryBox:GetAttribute("Opening")
        end;
        ForceHeldTarget = true;
    }
    self.Controllers["Prompt"]:MakePrompt{
        Name = "MysteryBox";
        Origin = workspace.MysteryBox.WorldPivot.Position;
        Text = function() 
            return ('Hold [<font color="#FF7800">F</font>] to pick up %s'):format(workspace.MysteryBox:GetAttribute("Gun"))
        end;
        Range = 10;
        ActivationKey = Enum.KeyCode.F;
        HoldTime = 1;
        ActivationFunc = function(Args)
            self.Services.WeaponServer:PickupGun()
        end;
        TextCheck = function()
            local IsPlayer = false
            
            if workspace.MysteryBox:GetAttribute("Player") == Players.LocalPlayer.Name then
                IsPlayer = true
            end

            return IsPlayer
        end;
        ForceHeldTarget = true;
    }

    print("[Knit Client] Gameplay initialised!")
end


return GameplayClient
