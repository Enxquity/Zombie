local Animations = {}
Animations.__index = Animations

function Animations.AnimationClass()
    return setmetatable({
        Animations = {};
    }, Animations)
end

function Animations:CreateAnimation(AnimationController, Id)
    local Animation = {Animation = nil};
    Animation.Animation = Instance.new("Animation", AnimationController)
    Animation.Animation.AnimationId = "rbxassetid://"..Id;
    Animation.Animation = AnimationController:LoadAnimation(Animation.Animation)
    Animation.Id = Id

    function Animation:Play()
        local Play = {}
        Animation.Animation:Play()
        function Play:OnEnd(Func)
            Animation.Animation.Stopped:Connect(Func)
        end
        function Play:Wait()
            Animation.Animation.Stopped:Wait()
        end
        function Play:PauseAt(Time, Speed)
            Animation.Animation:AdjustSpeed(Speed)
            task.wait(Time)
            Animation.Animation:AdjustSpeed(0)
        end
        return Play
    end

    function Animation:AdjustSpeed(Speed)
        Animation.Animation:AdjustSpeed(Speed)
    end

    function Animation:Stop()
        Animation.Animation:Stop()
    end

    function Animation:IsPlaying()
        return Animation.Animation.IsPlaying;
    end

    function Animation:GetLength()
        return Animation.Animation.Length
    end

    table.insert(self.Animations, Animation)
    return Animation
end

function Animations:StopAll()
    for i,v in pairs(self.Animations) do
        v:Stop()
    end
    return
end

function Animations:StopId(id)
    for i,v in pairs(self.Animations) do
        if tonumber(v.Id) == id then
            v:Stop()
        end
    end
    return
end

return Animations