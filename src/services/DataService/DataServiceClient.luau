--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Data = require(Shared.Data)

local DataServiceClient = {}
DataServiceClient.__index = DataServiceClient

export type DataServiceClient = typeof(setmetatable(
	{} :: {
		_data: any,
	},
	DataServiceClient
))

function DataServiceClient.Init(self: DataServiceClient)
	self._data = Data.client
end

function DataServiceClient.Start(_self: DataServiceClient)
	-- Profile replication is handled by DataServiceTyped.
end

function DataServiceClient.GetData(self: DataServiceClient)
	return self._data
end

return setmetatable({} :: DataServiceClient, DataServiceClient)
