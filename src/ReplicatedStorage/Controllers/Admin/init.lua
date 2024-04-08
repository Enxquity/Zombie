local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Knit = require(ReplicatedStorage.Packages.Knit)
local Commands, Cycles = require(script.Commands)[1], require(script.Commands)[2]

local Admin = Knit.CreateController {
    Name = "Admin";
    IsOpen = false; -- Flag to determine if the admin UI is open
    Tweens = {}; -- List to store tweens
    SuggestTweens = {}; -- List to store suggestion tweens
    Suggestion = ""; -- Current suggestion text
    Index = 1; -- Index for cycling through arguments
    CurrentIndex = 1; -- Current index for cycling through arguments
}


-- Function to create tweens
function Admin:CreateTween(Instance, TInfo, TweenData, NewList)
    -- If NewList is not provided, add the tween to self.Tweens, otherwise add it to NewList
    if not NewList then
        self.Tweens[#self.Tweens+1] = TweenService:Create(Instance, TInfo, TweenData)
        self.Tweens[#self.Tweens]:Play()
    else
        self[NewList][#self[NewList]+1] = TweenService:Create(Instance, TInfo, TweenData)
        self[NewList][#self[NewList]]:Play()
    end
end

-- Function to parse text into command and arguments
function Admin:ParseText(Text)
    local Args = Text:split(" ")
    local Command = Args[1]
    
    -- Remove the command from the list of arguments
    table.remove(Args, 1)
    return Command, Args
end

-- Function to find player by name
function Admin:FindPlayer(String)
    local Player = nil
    -- Iterate through all players and check if the provided string matches any player name
    for _, Plr in pairs(Players:GetPlayers()) do
        if Plr.Name:lower():sub(1, #String) == String:lower() then
            Player = Plr
        end
    end
    return Player
end

-- Function to find key in a table by matching string
function Admin:FindKey(String, Arr)
    -- If the string is empty, return nil
    if String == "" then return nil end
    local KeyFound = nil
    -- Iterate through the provided table and check if any key matches the provided string
    for Key, _ in pairs(Arr) do
        if Key:lower():sub(1, #String) == String:lower() then
            KeyFound = Key
        end
    end
    return KeyFound
end

-- Function to run a command
function Admin:Run(Text)
    local Command, ParsedList = self:ParseText(Text)
    Command = Commands[Command]
    if Command then
        local NewArguments = {}
        -- Iterate through command arguments and parse them accordingly
        for i,v in pairs(Command.Arguments) do
            if not ParsedList[i] then continue end
            if v == "player" then
                -- Handle player argument
                if ParsedList[i] == "all" then
                    -- Execute command for all players if "all" is provided
                    for i,v in pairs(Players:GetPlayers()) do
                        self:Run(Text:gsub("all", v.Name))
                    end
                else
                    -- Find the player by the provided name
                    local ParsedPlayer = ParsedList[i]
                    local Player = self:FindPlayer(ParsedPlayer)
                    if Player then
                        table.insert(NewArguments, i, Player)
                    end
                end
            elseif v == "reason" then
                -- Handle reason argument
                local NewList = {}
                -- Concatenate the remaining parts of the argument as reason
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
        -- Execute the command callback if all arguments are provided
        if #NewArguments == #Command.Arguments then
            Command.Callback(NewArguments)
        end
    end
end

-- Function to get the next item in a cycle for argument suggestion
function Admin:GetArgumentCycle(Text, OnlyList)
    local CMD = Commands[Text:split(" ")[1]]
    if CMD then
        local CurrentArg = #Text:split(" ")-1
        local ArgumentType = CMD.Arguments[CurrentArg]
        if ArgumentType == "player" then
            -- Handle player argument
            if OnlyList then
                local pList = Players:GetPlayers()
                local nList = {}
                -- Generate a list of player names
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
            -- Handle cycle arguments
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
    -- Finding and handling admin UI
    local UI = Players.LocalPlayer:WaitForChild("PlayerGui"):FindFirstChild("Admin")
    -- If admin UI is not found, log a warning and exit
    if not UI then 
        return warn("Admin UI wasn't found!") 
    end

    -- Listening for user input events
    UserInputService.InputBegan:Connect(function(Input, IsTyping)
        -- Recheck admin UI existence
        UI = Players.LocalPlayer:WaitForChild("PlayerGui"):FindFirstChild("Admin")
        -- Check if the quote key is pressed (opening/closing admin UI)
        if Input.KeyCode == Enum.KeyCode.Quote then
            -- Cancel all existing tweens
            for i,v in pairs(self.Tweens) do
                v:Cancel()
            end

            -- Handling opening/closing of admin UI
            if self.IsOpen == false then
                -- Opening admin UI
                local TI = TweenInfo.new(0.3)
                self:CreateTween(Lighting.Blur, TI, {Size = 12})
                self:CreateTween(UI.Back, TI, {BackgroundTransparency = 0.5})
                self:CreateTween(UI.Fade, TI, {Position = UDim2.fromScale(0, 0.8)})
                self:CreateTween(UI.Main, TI, {Position = UDim2.fromScale(0.5, 0.9)})

                UI.Main.Text = ""
                self.IsOpen = not self.IsOpen

                -- Loop until the UI is closed
                repeat
                    if UI.Main:IsFocused() == false then
                        UI.Main:CaptureFocus()
                    end
                    task.wait()
                until not self.IsOpen
            else
                -- Closing admin UI
                local TI = TweenInfo.new(0.3)
                self:CreateTween(Lighting.Blur, TI, {Size = 0})
                self:CreateTween(UI.Back, TI, {BackgroundTransparency = 1})
                self:CreateTween(UI.Fade, TI, {Position = UDim2.fromScale(0, 1)})
                self:CreateTween(UI.Main, TI, {Position = UDim2.fromScale(0.5, 1)})
                self.IsOpen = not self.IsOpen
                UI.Main:ReleaseFocus()
            end
        end
        -- Check if the tab key is pressed (handling argument suggestion)
        if Input.KeyCode == Enum.KeyCode.Tab then
            if self.Suggestion ~= "" and #UI.Main.Text:split(" ") > 1 then
                -- Get the next cycle item for the argument and update UI text
                local CycleText = self:GetArgumentCycle(UI.Main.Text)
                UI.Main.Text = CycleText
                UI.Main.CursorPosition = #UI.Main.Text
            elseif self.Suggestion ~= "" and #UI.Main.Text:split(" ") == 1 then
                -- Auto-complete command and add a space
                UI.Main.Text = self.Suggestion:split(" ")[1] .. " "
                UI.Main.CursorPosition = #UI.Main.Text
            end
        end
    end)

    -- Handling focus lost event for the main UI text box
    UI.Main.FocusLost:Connect(function()
        -- If the admin UI is closed, exit
        if self.IsOpen == false then 
            return 
        end
        -- Run the command provided in the main UI text box
        self:Run(UI.Main.Text)
        -- Clear the main UI text box after command execution
        UI.Main.Text = ""
    end)

    -- Listening for changes in the main UI text box text property
    UI.Main:GetPropertyChangedSignal("Text"):Connect(function()
        -- Clean the text input, removing single quotes and tabs
        UI.Main.Text = UI.Main.Text:gsub("'", "")
        UI.Main.Text = UI.Main.Text:gsub("\t", "")
        -- Reset argument cycle index if the last character is a space
        if UI.Main.Text:sub(#UI.Main.Text, #UI.Main.Text) == " " then
            self.Index = 1
        end

        -- Check if the entered text corresponds to a valid command
        local ViableCommand = self:FindKey(UI.Main.Text:split(" ")[1], Commands)
        -- Cancel existing suggestion tweens
        for i,v in pairs(self.SuggestTweens) do
            v:Cancel()
        end
        -- If a valid command is found, display its syntax as a suggestion
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
            -- If no valid command is found, hide the suggestion UI
            local TInfo = TweenInfo.new(0.2)
            self:CreateTween(UI.Suggestion, TInfo, {Position = UDim2.fromScale(0.5, 0.9), BackgroundTransparency = 1})
            self:CreateTween(UI.Suggestion.Info, TInfo, {TextTransparency = 1})
            self.Suggestion = ""
        end

        -- Check if the entered text corresponds to an argument
        local CycleList = self:GetArgumentCycle(UI.Main.Text, true)
        if CycleList then
            -- If argument is found, display its options
            local ListLength = #CycleList
            UI.Cycle.Size = UDim2.fromScale(0.063, 0.06 * ListLength) --// Static math used to decide size of cycle UI
            UI.Cycle.UIStroke.Transparency = 0

            for i, v in CycleList do
                if UI.Cycle:FindFirstChild(v) then continue end
                local NewTemp = UI.Template:Clone()
                NewTemp.Parent = UI.Cycle
                NewTemp.Size = UDim2.fromScale(1, 1/ListLength) --// Math used to decide how large each template should be (if the list length is 5 each template should be 0.2 since 1 results in the full size)
                NewTemp.Name = v
                NewTemp.Visible = true
                NewTemp.Text = v
            end
            -- Highlight the current cycle option
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
            -- If no argument is found, hide the cycle UI
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
