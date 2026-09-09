--!strict
-- CLIENT implementation. Lives as a child of the NetLib dispatcher in

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = script.Parent.Parent
local NetLibBase = script.Parent

local NamespaceTypes = require(ReplicatedStorage.LoomLib.NetLib.Types.NamespaceTypes)
local Reader = require(NetLibBase.Reader)
local Types = require(NetLibBase.Types.NetLibType)
local Signal = require(ReplicatedStorage.LoomLib.Signal)
local ClientChannel = require(script.ClientChannel)
local Writer = require(script.Parent.Writer)
local Channel = require(NetLibBase.Channel)
local util = require(NetLibBase.util)

local idCodec = (Types.uint8 :: any) :: Types.Codec<number>

-- upvals
local getCursorCount, dump = Writer.GetCursorCount, Writer.Dump
local readOne, readManyAt = Reader.readOne, Reader.readManyAt
local getFullChannelName = util.GetFullChannelName

local idReadFn = idCodec.Deserialize

-- 1 / 60
local FLUSH_INTERVAL = 0.0166666666666667

local _remoteEvent: RemoteEvent
local outbound: Writer.Writer = Writer.New()

local ChannelsById: { [number]: ClientChannel.ClientChannel<...any> } = {}
local nameIndex: { [string]: { [string]: number } } = {}

type Pending<T...> = {
	channel: ClientChannel.ClientChannel<T...>,
	namespace: string,
	channelName: string,
}

-- channels created before the server replicated their id
local pendingChannels: { [string]: Pending<...any> } = {}

local Namespace = {}
Namespace.__index = Namespace

export type Namespace = typeof(setmetatable({} :: NamespaceTypes.NamespaceData, Namespace))

local NetLib = {}

------------------------------------------
local function getByName<T...>(namespace, channelName): ClientChannel.ClientChannel<T...>
	local _namespace = nameIndex[namespace]
	local id = _namespace and _namespace[channelName]
	return id and ChannelsById[id]
end

-- Called when the server fires this client
local function OnClientEvent(data, instances)
	if typeof(data) ~= "buffer" then
		return
	end

	local _cursor = 0
	local bufferLen = buffer.len(data)
	local context = { instances = instances or {}, cursor = 1 }

	while _cursor < bufferLen do
		local ok, id, idCursor = pcall(readOne, data, idReadFn, _cursor)

		if not ok then
			warn("malformed buffer!")
			return
		end

		local channel = ChannelsById[id] :: any

		if not channel then
			warn("Channel not found")
			return
		end

		if channel.outputFieldCount then
			-- Read the slot index
			local slotOk, slotIndex, slotCursor = pcall(readOne, data, idReadFn, idCursor)

			if not slotOk then
				warn("malformed response slot index on channel: " .. channel:GetFullName())
				return
			end

			local reqOk, reqIndex, reqCursor = pcall(readOne, data, idReadFn, slotCursor)

			if not reqOk then
				warn("malformed response request index on channel: " .. channel:GetFullName())
				return
			end

			-- Read the response payload using outputFormats
			local endOk, args, channelEndCursor, n =
				pcall(readManyAt, data, context, channel.outputFieldCount, channel.outputReadFns, reqCursor)

			if not endOk then
				warn("malformed response data on channel: " .. channel:GetFullName())
				return
			end

			-- Resume the waiting coroutine with the response data
			channel.ResumeRequest(slotIndex, reqIndex, table.unpack(args, 1, n))
			_cursor = channelEndCursor
		else
			if not channel.OnClientEvent:HasConnections() then
				warn("Channel: " .. channel:GetFullName() .. " fired from server but nobody is listening to it!")
				return
			end

			local endOk, args, channelEndCursor, n =
				pcall(readManyAt, data, context, channel.fieldCount, channel.readFns, idCursor)

			if not endOk then
				warn("malformed buffer on channel: " .. channel:GetFullName())
				return
			end

			channel.OnClientEvent:Fire(table.unpack(args, 1, n))
			_cursor = channelEndCursor
		end
	end
end

----------- Defining channels -----------

local function _defineChannel<T...>(namespace: string, channelName: string, ...: T...): Channel.Channel<T...>
	local existing = getByName(namespace, channelName)
	if existing then
		return existing :: any
	end

	local fullName = getFullChannelName(namespace, channelName)

	local pending = pendingChannels[fullName] :: Pending<T...>
	if pending then
		return pending.channel :: any
	end

	local id = _remoteEvent:GetAttribute(fullName) :: number?

	local channel = ClientChannel.New(id, namespace, channelName, function(_: "server" | "all" | Player)
		return outbound
	end, ...) :: any

	channel.OnClientEvent = Signal.New()

	if id then
		ChannelsById[id] = channel
		nameIndex[namespace] = nameIndex[namespace] or {}
		nameIndex[namespace][channelName] = id
	else
		pendingChannels[fullName] = {
			channel = channel,
			namespace = namespace,
			channelName = channelName,
		}
	end

	return channel :: any
end

function NetLib.DefineNamespace(
	self,
	namespaceName: string,
	NamespaceConfig: NamespaceTypes.NamespaceConfig?
): Namespace
	local _namespace = setmetatable({}, Namespace) :: Namespace
	_namespace.namespaceName = namespaceName
	_namespace.NamespaceConfig = NamespaceConfig or {}
	return _namespace
end

function NetLib.DefineChannel<T...>(self, channelName: string, ...: T...): Channel.Channel<T...>
	return _defineChannel("__Global", channelName, ...)
end

function Namespace.DefineChannel<T...>(self: Namespace, channelName: string, ...: T...): Channel.Channel<T...>
	return _defineChannel(self.namespaceName, channelName, ...)
end

---------------------------------------------

local f = 0
RunService.Heartbeat:Connect(function(dt)
	f += dt
	if f > FLUSH_INTERVAL then
		if getCursorCount(outbound) > 0 then
			local outboundBuffer = dump(outbound)
			_remoteEvent:FireServer(outboundBuffer)
		end
		f %= FLUSH_INTERVAL
	end
end)

-- Find the bridge the server parented to the shared root.
_remoteEvent = Shared:WaitForChild("NetLibBridge", 10) :: RemoteEvent

-- When the server assigns a channel id after we already parked it, promote it.
_remoteEvent.AttributeChanged:Connect(function(fullName)
	local pending = pendingChannels[fullName]
	if not pending then
		return -- already promoted or not ours
	end

	local newId = _remoteEvent:GetAttribute(fullName) :: number?
	if not newId then
		return -- attribute was cleared, ignore
	end

	pending.channel:_setId(newId)
	ChannelsById[newId] = pending.channel
	nameIndex[pending.namespace] = nameIndex[pending.namespace] or {}
	nameIndex[pending.namespace][pending.channelName] = newId
	pendingChannels[fullName] = nil
end)

_remoteEvent.OnClientEvent:Connect(OnClientEvent)

export type NetLib = typeof(NetLib)
return NetLib :: NetLib
