--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local ServicesFolder = Shared:WaitForChild("Services")

local CLIENT_SERVICE_ORDER = {
	"DataService",
	"SessionService",
	"LockerService",
	"NoteService",
	"HandOffService",
	"ArcadeService",
}

local loadedClients: { any } = {}

for _, serviceName in CLIENT_SERVICE_ORDER do
	local serviceFolder = ServicesFolder:WaitForChild(serviceName)
	local clientModule = serviceFolder:WaitForChild(`{serviceName}Client`)
	local ok, client = pcall(require, clientModule)

	if ok then
		table.insert(loadedClients, client)
	else
		warn(`[Hinomori] Failed to require {serviceName}Client: {client}`)
	end
end

local function runLifecycle(methodName: string)
	for _, client in loadedClients do
		local method = (client :: any)[methodName]

		if type(method) == "function" then
			local ok, err = pcall(method, client)

			if not ok then
				warn(`[Hinomori] Client {methodName} failed: {err}`)
			end
		end
	end
end

runLifecycle("Init")
runLifecycle("Start")

require(ReplicatedStorage:WaitForChild("UI"))

print("[Hinomori] Client startup complete")
