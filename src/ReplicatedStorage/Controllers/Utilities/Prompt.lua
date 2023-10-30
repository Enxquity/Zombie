local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Knit = require(ReplicatedStorage.Packages.Knit)

local Prompt = Knit.CreateController { 
    Name = "Prompt";
    Prompts = {};
}

function Prompt:GetCharcterDistance(FromPoint)
    local Character = Players.LocalPlayer.Character
    if Character and Character.PrimaryPart then
        return math.abs((Character.PrimaryPart.Position-FromPoint).Magnitude)
    else
        warn(("Failed to get character or no primary part :: %d :: src/ReplicatedStorage/Controllers/Prompt.lua"):format(debug.traceback():match("%w:(%d+)")))
        return math.huge;
    end
end

function Prompt:MakePrompt(Prompt)
    --// Example prompt table
    --[[ * = required
        local Prompt = {
            Name* = "Thing"; <string>
            Origin* = Position; <vector3>
            Text* = "Hold F to pick up" (rich text compatible); <string> or <function> for dynamic text
            Range* = 15; <integer>
            ActivationKey = Enum.KeyCode.F; <enum>
            HoldTime = 2; <integer>
            ActivationFunc = function(Arguments)
                -- Arguments consist of
                Arguments.CharacterPosition
                Arguments.CharacterDistance
                Arguments.ActivatedTimestamp
                Arguments.HeldLength
                Arguments.HitHeldTarget

            end; <function>
            TextCheck = function()
                -- This function expects a true or false return value, this will be ran before hand if there's an extra check required to see if the prompt can be shown
            end; <function>
            ForceHeldTarget = true; <boolean> --// If disabled then function wont call upon hold length reached but will rather wait till key up
        }
    ]]
    if typeof(Prompt) ~= "table" then return warn(("Invalid argument :: %d :: src/ReplicatedStorage/Controllers/Prompt.lua"):format(debug.traceback():match("%w:(%d+)"))) end
    if not Prompt["Name"] or typeof(Prompt["Name"]) ~= "string" then
        warn(("No name provided or wrong datatype :: %d :: src/ReplicatedStorage/Controllers/Prompt.lua"):format(debug.traceback():match("%w:(%d+)")))
    elseif not Prompt["Origin"] or typeof(Prompt["Origin"]) ~= "Vector3" then
        warn(("No origin provided or wrong datatype :: %d :: src/ReplicatedStorage/Controllers/Prompt.lua"):format(debug.traceback():match("%w:(%d+)")))
    elseif not Prompt["Text"] or (typeof(Prompt["Text"]) ~= "string" and typeof(Prompt["Text"]) ~= "function") then
        warn(("No text provided or wrong datatype :: %d :: src/ReplicatedStorage/Controllers/Prompt.lua"):format(debug.traceback():match("%w:(%d+)")))
    elseif not Prompt["Range"] or typeof(Prompt["Range"]) ~= "number" then
        warn(("No range provided or wrong datatype :: %d :: src/ReplicatedStorage/Controllers/Prompt.lua"):format(debug.traceback():match("%w:(%d+)")))
    end
    local CloneTable = Prompt
    CloneTable["ID"] = math.random(100000, 999999999)
    CloneTable["KeyTimestamp"] = 0
    CloneTable["Enabled"] = false
    table.insert(self.Prompts, CloneTable)
end

function Prompt:EditPrompt(Name, NewValues)
    local _Prompt = self.Prompts[Name]
    if _Prompt then
        for i,v in pairs(NewValues) do
            _Prompt[i] = v
        end
    end
end

function Prompt:KnitStart()
    
end


function Prompt:KnitInit()
    --// I should have made this ages ago

    --// Prompt loop
    RunService.RenderStepped:Connect(function()
        for i,v in pairs(self.Prompts) do
            if self:GetCharcterDistance(v.Origin) <= v.Range and (v["TextCheck"] and v["TextCheck"]() == true or not v["TextCheck"] and true) then
                local PlayerGui = Players.LocalPlayer.PlayerGui
                if PlayerGui and not PlayerGui:FindFirstChild(v.ID) then
                    local NewUI = Instance.new("ScreenGui")
                    NewUI.Parent = PlayerGui
                    NewUI.Name = v.ID
                    
                    local NewTextLabel = Instance.new("TextLabel")
                    NewTextLabel.Parent = NewUI
                    NewTextLabel.Position = UDim2.fromScale(0.5, 0.778)
                    NewTextLabel.AnchorPoint = Vector2.new(0.5, 0)
                    NewTextLabel.Size = UDim2.fromScale(0.35, 0.04)
                    NewTextLabel.RichText = true
                    NewTextLabel.TextColor3 = Color3.new(1, 1, 1)
                    NewTextLabel.TextScaled = true
                    NewTextLabel.Font = Enum.Font.Jura
                    NewTextLabel.BackgroundTransparency = 1
                    NewTextLabel.Text = typeof(v["Text"]) == "string" and v["Text"] or v["Text"]()
                    v["Enabled"] = true
                    workspace:SetAttribute("ClientPrompt", true)
                end
            else
                local PlayerGui = Players.LocalPlayer.PlayerGui
                if PlayerGui and PlayerGui:FindFirstChild(v.ID) then
                    PlayerGui:FindFirstChild(v.ID):Destroy()
                    v["Enabled"] = false
                    workspace:SetAttribute("ClientPrompt", false)
                end
            end
        end
    end)

    --// Prompt key processing
    UserInputService.InputBegan:Connect(function(Key, IsTyping)
        if IsTyping then return end
        for i,v in pairs(self.Prompts) do
            if v["ActivationKey"] and v["ActivationKey"] == Key.KeyCode and v["Enabled"] == true then
                v["KeyTimestamp"] = tick()
                if v["ForceHeldTarget"] == true then
                    repeat task.wait() until not UserInputService:IsKeyDown(Key.KeyCode) or self:GetCharcterDistance(v.Origin) > v.Range or tick()-v["KeyTimestamp"] >= (v["HoldTime"] or 0)
                    if tick()-v["KeyTimestamp"] >= (v["HoldTime"] or 0) then
                        v["ActivationFunc"]{
                            CharacterPosition = (Players.LocalPlayer.Character and Players.LocalPlayer.Character.PrimaryPart.Position);
                            CharacterDistance = (Players.LocalPlayer.Character and self:GetCharcterDistance(v["Origin"]));
                            ActivatedTimestamp = v["KeyTimestamp"];
                            HeldLength = tick()-v["KeyTimestamp"];
                            HitHeldTarget = true;
                        }
                    end
                end
            end
        end
    end)
    UserInputService.InputEnded:Connect(function(Key, IsTyping)
        if IsTyping then return end
        for i,v in pairs(self.Prompts) do
            if v["ForceHeldTarget"] then continue end
            if self:GetCharcterDistance(v.Origin) > v.Range then continue end
            if v["ActivationKey"] and v["ActivationKey"] == Key.KeyCode and v["Enabled"] == true then
                if v["ActivationFunc"] then
                    v["ActivationFunc"](
                        {
                            CharacterPosition = (Players.LocalPlayer.Character and Players.LocalPlayer.Character.PrimaryPart.Position);
                            CharacterDistance = (Players.LocalPlayer.Character and self:GetCharcterDistance(v["Origin"]));
                            ActivatedTimestamp = v["KeyTimestamp"];
                            HeldLength = tick()-v["KeyTimestamp"];
                            HitHeldTarget = tick()-v["KeyTimestamp"] >= (v["HoldTime"] and v["HoldTime"] or 0);
                        }
                    )
                end
            end
        end
    end)

    print("[Knit Client] Prompts initialised!")
end


return Prompt
