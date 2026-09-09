--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Signal = require(ReplicatedStorage.LoomLib.Signal)
local Writer = require(script.Parent.Writer)
local Types = require(script.Parent.Types.NetLibType)

local util = require(script.Parent.util)

local idCodec = (Types.uint8 :: any) :: Types.Codec<number>
local idWriteFn = idCodec.Serialize
local serializeMany = Writer.SerializeMany

local getFullChannelName = util.GetFullChannelName

local Channel = {}
Channel.__index = Channel

type ChannelConfig = {
	rate: number?,
	capacity: number?,
	refillRate: number?,
	timeoutDuration: number,
}

type ChannelData = {
	id: number,
	Namespace: string,
	ChannelName: string,
	_getWriter: (target: "server" | "all" | Player) -> Writer.Writer,
	config: any,
}

-- The channel meta
export type ChannelMeta<T... = ()> = ChannelData & {
	GetFullName: (self: ChannelMeta<T...>) -> string,
	SetConfig: (self: ChannelMeta<T...>, props: ChannelConfig) -> Channel<T...>,
	Returns: (self: ChannelMeta<T...>, ...any) -> Channel<T...>,

	_setId: (self: ChannelMeta<T...>, id: number) -> (),
	_write: (self: ChannelMeta<T...>, buf: Writer.Writer, T...) -> (),
	_writeRequest: (
		self: ChannelMeta<T...>,
		buf: Writer.Writer,
		slotIndex: number,
		requestID: number,
		fieldCount: number,
		writeFns: { (...any) -> () },
		...any
	) -> (),
}

-- The api for the channel
export type Channel<T... = ()> = {
	SendToServer: (T...) -> (),
	SendToClient: (player: Player, T...) -> (),
	SendToAll: (T...) -> (),
	SendToAllExcept: (playerNames: { string }, T...) -> (),
	OnClientEvent: Signal.Signal<T...>,
	OnServerEvent: Signal.Signal<(Player, T...)>,
	Returns: (self: Channel<T...>, ...any) -> Channel<T...>,
	SetConfig: (self: Channel<T...>, props: ChannelConfig) -> Channel<T...>,
	Request: (self: Channel<T...>, T...) -> ...any,
	SetOnRequest: (self: Channel<T...>, callback: (Player, T...) -> ...any) -> (),
	SetRequestTimeout: (self: InternalChannel<T...>, duration: number) -> Channel<T...>,
}

export type InternalChannel<T... = ()> = Channel<T...> & ChannelMeta<T...> & {
	fieldCount: number,
	requestTimeout: number,
	writeFns: { (...any) -> () },
	readFns: { () -> ...any },
	outputFieldCount: number?,
	outputWriteFns: { (...any) -> () }?,
	outputReadFns: { () -> ...any }?,
	rateLimitConfig: (ChannelConfig | boolean)?,
	_assertEvent: (self: InternalChannel<T...>, method: string) -> (),
	_assertRequest: (self: InternalChannel<T...>, method: string) -> (),
}

-- per compiling the types
local function StoredTypes(...)
	local params = table.pack(...)
	local fieldCount = params.n
	local writeFns = table.create(fieldCount)
	local readFns = table.create(fieldCount)

	for i, codec in ipairs(params) do
		writeFns[i] = codec.Serialize
		readFns[i] = codec.Deserialize
	end

	return fieldCount, writeFns, readFns
end

function Channel.New<T...>(
	id: number?,
	namespace: string,
	channelName: string,
	getWriter: (target: "server" | "all" | Player) -> Writer.Writer,
	...
): Channel<T...>
	local self = setmetatable({} :: any, Channel) :: InternalChannel<T...>

	self.ChannelName = channelName
	self.Namespace = namespace
	self.id = id or -1
	self._getWriter = getWriter
	self.requestTimeout = 10
	self.fieldCount, self.writeFns, self.readFns = StoredTypes(...)

	return self
end

function Channel.SetRequestTimeout<T...>(self: InternalChannel<T...>, duration: number): Channel<T...>
	self.requestTimeout = duration
	return self
end

function Channel.Returns<T...>(self: InternalChannel<T...>, ...): Channel<T...>
	if self.outputFieldCount then
		error("Output formats already set for channel: " .. self:GetFullName(), 2)
	end
	self.outputFieldCount, self.outputWriteFns, self.outputReadFns = StoredTypes(...)
	return self
end

-- stamp the channel id, then the payload, into a writer.
function Channel._write<T...>(self: InternalChannel<T...>, buf: Writer.Writer, ...: T...)
	if self.id == -1 then
		return
	end
	idWriteFn(buf, self.id)
	serializeMany(buf, self.fieldCount, self.writeFns, ...)
end

function Channel._writeRequest(
	self: InternalChannel,
	buf: Writer.Writer,
	slotIndex: number,
	requestID: number,
	fieldCount: number,
	writeFns: { (...any) -> () },
	...
)
	if self.id == -1 then
		return
	end
	idWriteFn(buf, self.id)
	idWriteFn(buf, slotIndex)
	idWriteFn(buf, requestID)

	serializeMany(buf, fieldCount, writeFns, ...)
end

function Channel.SetConfig<T...>(self: InternalChannel<T...>, props: ChannelConfig): Channel<T...>
	if self.config ~= nil then
		error("Channel config already set", 2)
	end
	if props.timeoutDuration == nil then
		error("timeoutDuration cannot be nil when configuring rate limit")
	end
	self.config = props
	return self
end

function Channel._setId<T...>(self: InternalChannel<T...>, id: number)
	if self.id ~= nil then
		error("Channel id already set", 2)
	end
	self.id = id
end

function Channel.GetFullName<T...>(self: InternalChannel<T...>): string
	return getFullChannelName(self.Namespace, self.ChannelName)
end

function Channel._assertEvent<T...>(self: InternalChannel<T...>, method: string)
	if self.outputFieldCount ~= nil then
		error(
			("Channel '%s' is a request-response channel (it called :Returns()); %s is not valid on it. Use :Request() / the :SetOnRequest handler's return values."):format(
				self:GetFullName(),
				method
			),
			3
		)
	end
end

function Channel._assertRequest<T...>(self: InternalChannel<T...>, method: string)
	if self.outputFieldCount == nil then
		error(
			("Channel '%s' is not a request-response channel; %s requires :Returns(). Use :SendToServer()."):format(
				self:GetFullName(),
				method
			),
			3
		)
	end
end

return Channel
