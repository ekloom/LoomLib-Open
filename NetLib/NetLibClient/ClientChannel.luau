--!strict
-- Client side of a channel. Inherits everything from Channel and adds the
-- "send up to server" method + the OnClientEvent signal.
-- If :Returns() was called, also supports :Request() for request response.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Channel = require(script.Parent.Parent.Channel)
local Signal = require(ReplicatedStorage.LoomLib.Signal)

local ClientChannel = setmetatable({}, { __index = Channel })
ClientChannel.__index = ClientChannel

export type ClientChannel<T... = ()> = Channel.InternalChannel<T...> & {
	SendToServer: (self: ClientChannel<T...>, T...) -> (),
	Request: (self: ClientChannel<T...>, T...) -> ...any,
	OnClientEvent: Signal.Signal<T...>,
}

-- ring buffer for correlating outbound requests with inbound responses.
-- shared across all request channels on this client.
local requestID: { [number]: number } = {}
local threads: { [number]: { YieldingThread: thread, TimeoutThread: thread, requestID: number } } = {}
local cursor = 0

local MAX_SLOTS = 256
local DEFAULT_TIMEOUT = 10

function ClientChannel.New<T...>(
	id: number?,
	namespace: string,
	channelName: string,
	getWriter,
	...: T...
): ClientChannel<T...>
	local self = Channel.New(id, namespace, channelName, getWriter, ...) :: any
	return setmetatable(self, ClientChannel) :: ClientChannel<T...>
end

function ClientChannel.SendToServer<T...>(self: ClientChannel<T...>, ...: T...)
	self:_assertEvent("SendToServer")
	local outbound = self._getWriter("server")
	self:_write(outbound, ...)
end

-- called by the client dispatch loop when a response comes back from the server.
-- matches the slot index to the waiting coroutine and resumes it with the data.
function ClientChannel.ResumeRequest(slotIndex: number, reqID: number, ...: any)
	local query = threads[slotIndex]

	-- the query under the same slot as the previous "owner"" has already been handled
	if not query or query.requestID ~= reqID then
		return
	end

	-- cancel the timeout so it doesn't fire after we've already resumed
	task.cancel(query.TimeoutThread)
	threads[slotIndex] = nil
	coroutine.resume(query.YieldingThread, ...)
end

-- sends a request to the server and yields until a response arrives or timeout.
-- only works on channels where :Returns() was called.
-- returns nil if all slots are full or if the request times out.
function ClientChannel.Request<T...>(self: ClientChannel<T...>, ...: T...)
	self:_assertRequest("Request")
	local attempts = 0

	-- find the next free slot in the ring buffer
	while threads[cursor] ~= nil and attempts < MAX_SLOTS do
		cursor = (cursor + 1) % MAX_SLOTS
		attempts += 1
	end

	if attempts == MAX_SLOTS then
		warn("All 256 request slots are occupied")
		return nil
	end

	local slotIndex = cursor
	-- advance cursor for the next request
	cursor = (cursor + 1) % MAX_SLOTS

	-- makes sure the currentSlot index will get his response and not a response from the data of previous
	-- slotowner that already had been timedout before server responded
	requestID[slotIndex] = ((requestID[slotIndex] or 0) + 1) % 256

	local query = {
		YieldingThread = coroutine.running(),
		TimeoutThread = nil :: any,
		requestID = requestID[slotIndex],
	}

	local timeout = self.requestTimeout or DEFAULT_TIMEOUT

	-- timeout safety net: if server never responds, resume with nil and free the slot
	query.TimeoutThread = task.delay(timeout, function()
		local entry = threads[slotIndex]
		if entry and entry.YieldingThread == query.YieldingThread then
			threads[slotIndex] = nil
			coroutine.resume(query.YieldingThread, nil)
		end
	end)

	threads[slotIndex] = query

	-- write request using input formats with the slot index for correlation
	local outbound = self._getWriter("server")
	self:_writeRequest(outbound, slotIndex, query.requestID, self.fieldCount, self.writeFns, ...)

	-- freeze here until ResumeRequest or timeout resumes us
	return coroutine.yield()
end

return ClientChannel
