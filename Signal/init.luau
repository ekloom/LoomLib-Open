--!optimize 2
--!strict
local Connection = require(script.Connection)
local ThreadHandler = require(script.ThreadHandler)
local Signal = {}

Signal.__index = Signal

export type Signal<T...> = {
	HasConnections: (self: Signal<T...>) -> boolean,
	ConnectionAmount: number,
	Fire: (self: Signal<T...>, T...) -> (),
	Connect: (self: Signal<T...>, callback: (T...) -> ()) -> Connection.Connection<T...>,
	Once: (self: Signal<T...>, callback: (T...) -> ()) -> Connection.Connection<T...>,
	DisconnectAll: (self: Signal<T...>) -> (),
	Subscribers: Connection.Connection<T...>,
}

function Signal.New<T...>(): Signal<T...>
	local self = setmetatable({ Subscribers = {} :: any } :: any, Signal) :: Signal<T...>

	-- avoid having to mess with "nil" pointers so Subscribers is here as a dummy
	-- head (points to the first real item in the list)
	self.Subscribers.next = self.Subscribers
	-- tail (points to the last real item in the list)
	self.Subscribers.prev = self.Subscribers

	--[[
    Because 'self.Subscribers.next' points back to 'self.Subscribers':
    Evaluating 'self.Subscribers.next.prev' on an empty list resolves directly to 
    'self.Subscribers.prev' and vice versa.
]]
	self.ConnectionAmount = 0
	return self
end

function Signal.HasConnections(self): boolean
	return self.Subscribers.next ~= self.Subscribers
end

-- Adds the connector to thje subscribers list
function Signal.Connect<T...>(self: Signal<T...>, Callback: (T...) -> ()): Connection.Connection<T...>
	local connection: Connection.Connection<T...> = Connection.New(self, Callback)

	-- sets the next value to the old "Subscribers.next" (we take over the next value of it)
	connection.next = self.Subscribers.next
	-- this would be "nil" without the Subscribers dummy but now we have the Subscribers taking it up for us
	-- So now the previous value of this connection would be eaqaul with 'self.Subscribers'
	connection.prev = self.Subscribers

	-- updating the list

	-- Update the old head node's 'prev' pointer to point to our new connection
	self.Subscribers.next.prev = connection
	-- sets the next of the Subscribers  equal with this new "connection" that we made
	self.Subscribers.next = connection

	return connection
end

-- Adds the connector to thje subscribers list
function Signal.Once<T...>(self: Signal<T...>, Callback: (T...) -> ())
	local connection: Connection.Connection<T...> = Connection.New(self, Callback, true)
	connection.next = self.Subscribers.next
	connection.prev = self.Subscribers
	self.Subscribers.next.prev = connection
	self.Subscribers.next = connection
	return connection
end

function Signal.Wait<T...>(self: Signal<T...>, duration: number?)
	local connection: Connection.Connection<T...> = Connection.New(self, nil, true)

	connection.thread = coroutine.running()
	connection.next = self.Subscribers.next
	connection.prev = self.Subscribers

	self.Subscribers.next.prev = connection
	self.Subscribers.next = connection
	if duration then
		connection.timeout = task.delay(duration, function()
			connection:Disconnect()
			coroutine.resume(connection.thread)
		end)
	end
	return coroutine.yield()
end

function Signal.DisconnectAll<T...>(self: Signal<T...>)
	local node = self.Subscribers.next
	while node ~= self.Subscribers do
		local nextnode = node.next
		node:Disconnect()
		node = nextnode
	end
end

function Signal.Fire<T...>(self: Signal<T...>, ...: T...)
	local node = self.Subscribers.next

	while node ~= self.Subscribers do
		-- this will store the node in "node.next"
		--[[
			scenario: if after the callback it disconnnects the node (fire once and disconnect)
			if we don't store 'node.next' in 'nextnode' we will lose our reference to 'node.next' since the
			disconnect function does "	self.prev.next = self.next
	self.next.prev = self.prev"
		]]
		local nextnode = node.next
		if node.connected then
			if node.callback then
				ThreadHandler.Spawn(node.callback, ...)
			else
				-- no need for threadhandler since thread has it's own couritine
				task.spawn(node.thread, ...)
				if node.timeout then
					task.cancel(node.timeout)
				end
			end

			if node.once then
				node:Disconnect()
			end
		end

		-- sets node now to the "nextnode" which is the next value of
		node = nextnode
	end
end

return Signal
