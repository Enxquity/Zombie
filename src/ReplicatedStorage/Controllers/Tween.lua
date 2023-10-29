local Tween = {}

--// Private functions
function IsTweenMethod(TweenTable, RequiredMethods)
    for i,v in pairs(TweenTable) do
        if table.find(RequiredMethods, i) then
            return true
        end
    end
    return false
end

function Tween.Handler(Speed, Method, Direction)
    return setmetatable({
        Method = Method or Enum.EasingStyle.Linear;
        Direction = Direction or Enum.EasingDirection.Out;
        Speed = 500;
        TaskStop = false;

        Tweens = {};
        TweenService = game:GetService("TweenService");
    }, Tween)
end

function Tween:Create(Obj, TweenMovement)
    local Object = Obj
    if Obj.ClassName == "Model" then
        Object = Obj.PrimaryPart or Obj:GetChildren()[math.random(1, #Obj:GetChildren())]
    end
    local TweenAsset = self.TweenService:Create(Obj, TweenInfo.new((IsTweenMethod(TweenMovement, {"CFrame"} and (Obj.Position - TweenMovement["CFrame"].Position).Magnitude / self.Speed or IsTweenMethod(TweenMovement, {"Position"}) and (Obj.Position - TweenMovement["Position"]).Magnitude / self.Speed) == true or self.Speed/250), self.Method, self.Direction, 0, false, 0), TweenMovement)

    local TweenMethods = {}
    function TweenMethods:Play()
        TweenAsset:Play() 
    end
    function TweenMethods:Stop()
        TweenAsset:Cancel()
    end
    function TweenMethods.Finished()
        local Methods = {}
        function Methods:Connect(Function)
            TweenAsset.Completed:Connect(Function)
        end
        function Methods:Wait(YieldTime)
            TweenAsset.Completed:Wait()
            task.wait(YieldTime)

            local Methods = {}
            function Methods:AndThen(Function, NewThread, ...) --// Inspired by promises
                if (NewThread and NewThread == true) then
                    task.spawn(Function, ...)
                else
                    pcall(Function, ...)
                end
            end
            return Methods
        end
        return Methods
    end
    function TweenMethods:TimedPlay(Time)
        TweenAsset:Play()
        task.delay(Time, function()
            TweenAsset:Cancel()
        end)
    end

    table.insert(self.Tweens, TweenAsset)
    return TweenMethods
end

function Tween:StopAll()
    for i,v in pairs(self.Tweens) do
        v:Cancel()
        table.remove(self.Tweens, i)
    end
end

function Tween:PlayAll(WaitForEach)
    task.spawn(function()
        for i,v in pairs(self.Tweens) do
            v:Play()
            if WaitForEach then
                v.Completed:Wait()
            end
            if self.TaskStop == true then
                v:Cancel()
                self.TaskStop = false
                break
            end
        end
    end)
    local Methods = {}
    function Methods:Break()
        self.TaskStop = true
    end
    return Methods
end

function Tween:SetSpeed(Speed)
    self.Speed = Speed
end

return Tween