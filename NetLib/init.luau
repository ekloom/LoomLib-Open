local RunService = game:GetService("RunService")

if RunService:IsServer() then
	local ServerScriptService = game:GetService("ServerScriptService")

	return require(ServerScriptService.LoomLib.NetLibServer)
end

return require(script.NetLibClient)
