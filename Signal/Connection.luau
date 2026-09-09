--!strict
local Connection = {}

Connection.__index = Connection

type ConnectionData<T...> = {
	callback: (T...) -> ()?,
	prev: Connection<T...>,
	next: Connection<T...>,
	once: boolean,
	connected: boolean,
	event: any,
	thread: thread,
	timeout: thread,
}

export type Connection<T...> = typeof(setmetatable({} :: ConnectionData<T...>, Connection))

function Connection.New<T...>(event, callback: (T...) -> ()?, fireOnce: boolean?): Connection<T...>
	local self = setmetatable({}, Connection) :: Connection<T...>

	self.event = event
	self.event.ConnectionAmount += 1
	self.callback = callback
	self.once = fireOnce or false
	self.connected = true
	return self
end

function Connection.Disconnect<T...>(self: Connection<T...>)
	if not self.connected then
		return
	end
	self.connected = false

	self.event.ConnectionAmount -= 1

	-- re-assigning the next value of the previous node
	self.prev.next = self.next
	-- re-assigning the previous value of our next node
	self.next.prev = self.prev

	self.next = nil :: any
	self.prev = nil :: any
end

return Connection
