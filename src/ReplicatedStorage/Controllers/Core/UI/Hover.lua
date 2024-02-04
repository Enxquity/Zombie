local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages.Knit)

local Build
Build = {

    Cache = {Power={}};
    init = function(Library)
        task.wait(2) --// init delay
        local Mouse = Players.LocalPlayer:GetMouse()
        
        while task.wait() do
            local Target = Mouse.Target
            if not Target then task.wait() continue end
            Target = Target.Parent

            for _, B in pairs(Build.Cache.Power) do
                B:Destroy()
            end
            if Target:HasTag("Power") then
                local NewUI = ReplicatedStorage.Game.UI.Power:Clone()
                NewUI.Parent = Target
                NewUI.Adornee = Target
                NewUI.Name = "PowerDisplayUI"
                NewUI.Holder.Label.Text = Target.PowerInfo.Power.Value .. "/" .. Target.PowerInfo.PowerMax.Value .. "kW"
                NewUI.Holder.Info.Text = (Target:HasTag("Output") and "Output" or "Input") .. "<br/>" .. "Flowrate: 0kW/s"
                table.insert(Build.Cache.Power, NewUI)
            end
        end

    end;

}

return Build