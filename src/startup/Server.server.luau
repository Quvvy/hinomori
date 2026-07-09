--!strict

local ServerScriptService = game:GetService("ServerScriptService")

local ServicesFolder = ServerScriptService:WaitForChild("Services")

local SERVICE_ORDER = {
	"DataService",
	"SessionService",
	"LockerService",
	"NoteService",
	"HandOffService",
	"ArcadeService",
}

local loadedServices: { any } = {}

for _, serviceName in SERVICE_ORDER do
	local serviceFolder = ServicesFolder:WaitForChild(serviceName)
	local serverModule = serviceFolder:WaitForChild(`{serviceName}Server`)
	local ok, service = pcall(require, serverModule)

	if ok then
		table.insert(loadedServices, service)
	else
		warn(`[Hinomori] Failed to require {serviceName}Server: {service}`)
	end
end

local function runLifecycle(methodName: string)
	for _, service in loadedServices do
		local method = (service :: any)[methodName]

		if type(method) == "function" then
			local ok, err = pcall(method, service)

			if not ok then
				warn(`[Hinomori] {methodName} failed for a service: {err}`)
			end
		end
	end
end

runLifecycle("Init")
runLifecycle("Start")

print("[Hinomori] Server startup complete")
