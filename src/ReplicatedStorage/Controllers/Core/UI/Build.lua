local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages.Knit)
local Build = {

    init = function(Library)
        task.wait(2) --// init delay

        local UI = Library:GetInterface("BuildFrame")
        local Template = UI:FindFirstChild("Template")

        for _, Buildable in pairs(ReplicatedStorage.Game.Buildables:GetDescendants()) do
            if Buildable:IsA("Model") and Buildable.Parent:IsA("Folder") then
                local NewTemplate = Template:Clone()
                NewTemplate.Parent = UI
                NewTemplate.Visible = true
                NewTemplate.Text = Buildable.Name

                NewTemplate.MouseButton1Click:Connect(function()
                    local Controller = Knit.GetController("Placement")
                    Controller:Call("Piping", "disable")
                    Controller:Start(Buildable)
                end)
            end
        end
    end;

    toggle = function(Library)
        local UI = Library:GetInterface("BuildFrame")
        UI.Visible = not UI.Visible
    end
}

return Build