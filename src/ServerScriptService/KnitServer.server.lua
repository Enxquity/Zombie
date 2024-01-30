local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage");
local ServerStorage = game:GetService('ServerStorage');

local Knit = require(ReplicatedStorage.Packages.Knit)
Knit.AddServicesDeep(ServerStorage.Source.Services)

Knit.Start():andThen(function()
    print("[Knit Server] Started")  
end):catch(warn)
