local GuiService = game:GetService("GuiService")
local Keybinds = {
    ["Cancel"] = {
        ["PC"] = Enum.KeyCode.Q;
        ["Console"] = Enum.KeyCode.DPadLeft;
    };
    ["Rotate"] = {
        ["PC"] = Enum.KeyCode.R;
        ["Console"] = Enum.KeyCode.ButtonY;
    };
    ["Build"] = {
        ["PC"] = Enum.KeyCode.One;
        ["Console"] = Enum.KeyCode.DPadUp;
    };
    ["Delete"] = {
        ["PC"] = Enum.KeyCode.Two;
        ["Console"] = Enum.KeyCode.DPadRight;
    };
    ["Pipe"] = {
        ["PC"] = Enum.KeyCode.Three;
        ["Console"] = Enum.KeyCode.DPadUp;
    };
    ["Power"] = {
        ["PC"] = Enum.KeyCode.Four;
        ["Console"] = Enum.KeyCode.DPadDown;
    };
}

local IndexTable = {}
IndexTable.__index = function(self, index)
    if Keybinds[index] then
        if GuiService:IsTenFootInterface() == true then --// Console user
            return Keybinds[index].Console
        else --// Else is pc or mobile (however mobile is bad and we DO NOT CARE)
            return Keybinds[index].PC
        end
    end
    return nil
end;

return setmetatable(IndexTable, IndexTable)