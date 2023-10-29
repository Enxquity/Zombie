local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages.Knit)

local AdminServer = Knit.CreateService {
    Name = "AdminServer",
    Client = {},
}

function AdminServer.Client:Run(Player, Code, Args)
    return self.Server:Run(Code, Args)
end

function AdminServer:Run(Code, Args)
    loadstring(Code)()(Args)
end

function AdminServer:KnitStart()
    
end


function AdminServer:KnitInit()
    print("[Knit Server] Admin server initiated.")
end


return AdminServer
