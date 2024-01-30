local ReplicatedStorage = game:GetService("ReplicatedStorage");
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService");
local RunService = game:GetService("RunService");
local Player = game:GetService("Players").LocalPlayer;

local Knit = require(ReplicatedStorage.Packages.Knit)
local Keybinds = require(ReplicatedStorage.Source.Keybinds)
--local Key = require(ReplicatedStorage.ExternalModules.Key)
Knit.AddControllersDeep(ReplicatedStorage.Source.Controllers)
