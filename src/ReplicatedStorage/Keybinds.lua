local GuiService = game:GetService("GuiService")
local Keybinds = {
    ["Crouch"] = {
        ["PC"] = Enum.KeyCode.LeftControl;
        ["Xbox"] = Enum.KeyCode.Thumbstick2;
    };
    ["Senses"] = {
        ["PC"] = Enum.KeyCode.LeftControl;
        ["Xbox"] = Enum.KeyCode.ButtonX;
    };
    ["Aim"] = {
        ["PC"] = Enum.UserInputType.MouseButton2;
        ["Xbox"] = Enum.KeyCode.ButtonL2;
    };
    ["Fire"] = {
        ["PC"] = Enum.UserInputType.MouseButton1;
        ["Xbox"] = Enum.KeyCode.ButtonR2;
    }
}

local IndexTable = {}
IndexTable.__index = function(self, index)
    if Keybinds[index] then
        if GuiService:IsTenFootInterface() == true then --// Xbox user
            return Keybinds[index].Xbox
        else --// Else is pc or mobile (however mobile is bad and we DO NOT CARE)
            return Keybinds[index].PC
        end
    end
    return nil
end;

return setmetatable(IndexTable, IndexTable)