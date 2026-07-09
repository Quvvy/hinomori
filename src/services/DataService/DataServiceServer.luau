--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Janitor = require(ReplicatedStorage.Packages.Janitor)
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Data = require(Shared.Data)

local DataServiceServer = {}
DataServiceServer.__index = DataServiceServer

export type DataServiceServer = typeof(setmetatable(
	{} :: {
		_janitor: Janitor.Janitor,
		_data: any,
	},
	DataServiceServer
))

function DataServiceServer.Init(self: DataServiceServer)
	self._janitor = Janitor.new()
	self._data = Data.server
end

function DataServiceServer.Start(_self: DataServiceServer)
	-- DataServiceTyped handles player sessions automatically via ProfileStore.
end

function DataServiceServer.GetProfile(self: DataServiceServer, player: Player)
	return self._data[player]
end

function DataServiceServer.GetService(self: DataServiceServer)
	return self._data.Service
end

function DataServiceServer.Destroy(self: DataServiceServer)
	self._janitor:Destroy()
end

return setmetatable({} :: DataServiceServer, DataServiceServer)
