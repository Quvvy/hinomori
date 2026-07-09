--!strict

local Logger = {}

local PREFIX = "[Hinomori]"

function Logger.info(scope: string, message: string)
	print(`{PREFIX} [{scope}] {message}`)
end

function Logger.warn(scope: string, message: string)
	warn(`{PREFIX} [{scope}] {message}`)
end

return Logger
