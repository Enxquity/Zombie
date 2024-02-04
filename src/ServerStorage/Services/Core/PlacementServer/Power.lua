local Power = {}

function Power:Connect(BoxA, BoxB)
    if not BoxA or not BoxB then return end

    for _, Output in pairs(BoxA.PowerInfo.Outputs:GetChildren()) do
        if Output.Value == BoxB then
            Output:Destroy()
            return
        end
    end

    local Dist = (BoxA:GetPivot().Position - BoxB:GetPivot().Position).Magnitude
    print(("Distance %d"):format(Dist))

    local NewObjValue = Instance.new("ObjectValue", BoxA.PowerInfo.Outputs)
    NewObjValue.Value = BoxB
end

return Power