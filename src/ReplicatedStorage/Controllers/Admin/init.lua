local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Knit = require(ReplicatedStorage.Packages.Knit)
local Commands, Cycles = require(script.Commands)[1], require(script.Commands)[2]

local Admin = Knit.CreateController {
    Name = "Admin";
    IsOpen = false;
    Tweens = {};
    SuggestTweens = {};
    Suggestion = "";
    Index = 1;
    CurrentIndex = 1;
}

function Admin:CreateTween(Instance, TInfo, TweenData, NewList)
    if not NewList then
        self.Tweens[#self.Tweens+1] = TweenService:Create(Instance, TInfo, TweenData)
        self.Tweens[#self.Tweens]:Play()
    else
        self[NewList][#self[NewList]+1] = TweenService:Create(Instance, TInfo, TweenData)
        self[NewList][#self[NewList]]:Play()
    end
end

function Admin:ParseText(Text)
    local Args = Text:split(" ")
    local Command = Args[1]
    
    table.remove(Args, 1)
    return Command, Args
end

function Admin:FindPlayer(String)
    local Player = nil
    for _, Plr in pairs(Players:GetPlayers()) do
        if Plr.Name:lower():sub(1, #String) == String:lower() then
            Player = Plr
        end
    end
    return Player
end

function Admin:FindKey(String, Arr)
    if String == "" then return nil end
    local KeyFound = nil
    for Key, _ in pairs(Arr) do
        if Key:lower():sub(1, #String) == String:lower() then
            KeyFound = Key
        end
    end
    return KeyFound
end

function Admin:Run(Text)
    local Command, ParsedList = self:ParseText(Text)
    Command = Commands[Command]
    if Command then
        local NewArguments = {}
        for i,v in pairs(Command.Arguments) do
            if not ParsedList[i] then continue end
            if v == "player" then
                if ParsedList[i] == "all" then
                    for i,v in pairs(Players:GetPlayers()) do
                        self:Run(Text:gsub("all", v.Name))
                    end
                else
                    local ParsedPlayer = ParsedList[i]
                    local Player = self:FindPlayer(ParsedPlayer)
                    if Player then
                        table.insert(NewArguments, i, Player)
                    end
                end
            elseif v == "reason" then
                local NewList = {}
                for index, v in pairs(ParsedList) do
                    if index >= i then
                        table.insert(NewList, v)
                    end
                end
                NewArguments[i] = table.concat(NewList,  " ")
            else
                table.insert(NewArguments, i, ParsedList[i])
            end
        end
        if #NewArguments == #Command.Arguments then
            Command.Callback(NewArguments)
        end
    end
end

function Admin:GetArgumentCycle(Text, OnlyList)
    local CMD = Commands[Text:split(" ")[1]]
    if CMD then
        local CurrentArg = #Text:split(" ")-1
        local ArgumentType = CMD.Arguments[CurrentArg]
        if ArgumentType == "player" then
            if OnlyList then
                local pList = Players:GetPlayers()
                local nList = {}
                for i,v in pairs(pList) do
                    table.insert(nList, i, v.Name)
                end
                return nList
            end
            if not Players:GetPlayers()[self.Index] then
                self.Index = 1
            end
            self.CurrentIndex = self.Index

            local Plr = Players:GetPlayers()[self.Index].Name
            local StringList = Text:split(" ")
            StringList[#StringList] = Plr

            self.Index += 1

            return table.concat(StringList, " ")
        elseif Cycles[ArgumentType] then
            if OnlyList then
                return Cycles[ArgumentType]
            end
            if not Cycles[ArgumentType][self.Index] then
                self.Index = 1
            end
            self.CurrentIndex = self.Index

            local CycleStr = Cycles[ArgumentType][self.Index]
            local StringList = Text:split(" ")
            StringList[#StringList] = CycleStr

            self.Index += 1

            return table.concat(StringList, " ")
        end
        return nil
    end
end

function Admin:KnitStart()

end

function Admin:KnitInit()
    local UI = Players.LocalPlayer:WaitForChild("PlayerGui"):FindFirstChild("Admin")
    if not UI then return warn("Admin UI wasn't found!") end
    UserInputService.InputBegan:Connect(function(Input, IsTyping)
        UI = Players.LocalPlayer:WaitForChild("PlayerGui"):FindFirstChild("Admin")
        if Input.KeyCode == Enum.KeyCode.Quote then

            for i,v in pairs(self.Tweens) do
                v:Cancel()
            end

            if self.IsOpen == false then
                local TI = TweenInfo.new(0.3)
                self:CreateTween(Lighting.Blur, TI, {Size = 12})
                self:CreateTween(UI.Back, TI, {BackgroundTransparency = 0.5})
                self:CreateTween(UI.Fade, TI, {Position = UDim2.fromScale(0, 0.8)})
                self:CreateTween(UI.Main, TI, {Position = UDim2.fromScale(0.5, 0.9)})

                UI.Main.Text = ""
                self.IsOpen = not self.IsOpen

                repeat
                    if UI.Main:IsFocused() == false then
                        UI.Main:CaptureFocus()
                    end
                    task.wait()
                until not self.IsOpen
            else
                local TI = TweenInfo.new(0.3)
                self:CreateTween(Lighting.Blur, TI, {Size = 0})
                self:CreateTween(UI.Back, TI, {BackgroundTransparency = 1})
                self:CreateTween(UI.Fade, TI, {Position = UDim2.fromScale(0, 1)})
                self:CreateTween(UI.Main, TI, {Position = UDim2.fromScale(0.5, 1)})
                self.IsOpen = not self.IsOpen
                UI.Main:ReleaseFocus()
            end
        end
        if Input.KeyCode == Enum.KeyCode.Tab then
            if self.Suggestion ~= "" and #UI.Main.Text:split(" ") > 1 then
                local CycleText = self:GetArgumentCycle(UI.Main.Text)
                UI.Main.Text = CycleText
                UI.Main.CursorPosition = #UI.Main.Text
            elseif self.Suggestion ~= "" and #UI.Main.Text:split(" ") == 1 then
                UI.Main.Text = self.Suggestion:split(" ")[1] .. " "
                UI.Main.CursorPosition = #UI.Main.Text
            end
        end
    end)
    UI.Main.FocusLost:Connect(function()
        if self.IsOpen == false then return end
        self:Run(UI.Main.Text)
        UI.Main.Text = ""
    end)
    UI.Main:GetPropertyChangedSignal("Text"):Connect(function()
        UI.Main.Text = UI.Main.Text:gsub("'", "")
        UI.Main.Text = UI.Main.Text:gsub("\t", "")
        if UI.Main.Text:sub(#UI.Main.Text, #UI.Main.Text) == " " then
            self.Index = 1
        end
        local ViableCommand = self:FindKey(UI.Main.Text:split(" ")[1], Commands)
        for i,v in pairs(self.SuggestTweens) do
            v:Cancel()
        end
        if ViableCommand then
            local TInfo = TweenInfo.new(0.2)
            self:CreateTween(UI.Suggestion, TInfo, {Position = UDim2.fromScale(0.5, 0.85), BackgroundTransparency = 0})
            self:CreateTween(UI.Suggestion.Info, TInfo, {TextTransparency = 0})
            
            local str = ViableCommand .. " " 
            for i,v in pairs(Commands[ViableCommand].Arguments) do
                str ..= "[" .. v .. "] "
            end
            UI.Suggestion.Info.Text = str
            self.Suggestion = str
        else
            local TInfo = TweenInfo.new(0.2)
            self:CreateTween(UI.Suggestion, TInfo, {Position = UDim2.fromScale(0.5, 0.9), BackgroundTransparency = 1})
            self:CreateTween(UI.Suggestion.Info, TInfo, {TextTransparency = 1})
            self.Suggestion = ""
        end

        local CycleList = self:GetArgumentCycle(UI.Main.Text, true)
        if CycleList then
            local ListLength = #CycleList
            UI.Cycle.Size = UDim2.fromScale(0.063, 0.06 * ListLength)
            UI.Cycle.UIStroke.Transparency = 0

            for i, v in CycleList do
                if UI.Cycle:FindFirstChild(v) then continue end
                local NewTemp = UI.Template:Clone()
                NewTemp.Parent = UI.Cycle
                NewTemp.Size = UDim2.fromScale(1, 1/ListLength)
                NewTemp.Name = v
                NewTemp.Visible = true
                NewTemp.Text = v
            end
            for i,v in pairs(UI.Cycle:GetChildren()) do
                if v:IsA("TextLabel") and not table.find(CycleList, v.Name) then
                    v:Destroy()
                end
                if v:IsA("TextLabel") then
                    local CycleIndex = table.find(CycleList, v.Name)
                    local Strings = UI.Main.Text:split(" ")
                    if CycleIndex == self.CurrentIndex and Strings[#Strings] == v.Name then
                        v.TextColor3 = Color3.fromRGB(77, 77, 77)
                    else
                        v.TextColor3 = Color3.fromRGB(255, 255, 255)
                    end
                end
            end
        else
            UI.Cycle.Size = UDim2.fromScale(0.063, 0)
            UI.Cycle.UIStroke.Transparency = 1
            for i,v in pairs(UI.Cycle:GetChildren()) do
                if v:IsA("TextLabel") then v:Destroy() end
            end
        end
    end)

    print("[Knit Client] Admin initialised!")
end


return Admin
