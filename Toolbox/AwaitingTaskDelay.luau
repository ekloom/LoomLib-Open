--[[
	AwaitTaskDelay

	A small utility object for scheduling a delayed callback that can be reset.
	Calling :Wait() will cancel any previously scheduled delayed task and start a new one.

	Behavior:
	- New(duration, callback) creates an instance with a default delay and callback.
	- Wait(duration, callback) schedules the callback to run after the given delay.
	- If Wait() is called again before the delay finishes, the previous delayed task is canceled.
	- This makes it useful for debounce-like behavior, where you only want the callback
	  to run after calls have stopped for a certain amount of time.

	Example use cases:
	- delaying UI updates until input stops changing
	- postponing expensive work until repeated triggers settle down
	- resetting a timeout each time an event happens
]]

local AwaitTaskDelay = {}

AwaitTaskDelay.__index = AwaitTaskDelay

export type AwaitTaskDelay = typeof(setmetatable(
	{} :: {
		duration: number,
		callback: () -> (),
		IsWaiting: boolean,
		waitingTask: thread,
	},
	AwaitTaskDelay
))

function AwaitTaskDelay.New(duration, callback)
	local self = setmetatable({
		duration = duration or 0,
		callback = callback or nil,
		IsWaiting = false,
	}, AwaitTaskDelay)

	return self
end

function AwaitTaskDelay.Wait(self: AwaitTaskDelay, duration, callback)
	if not callback and not self.callback then
		return
	end

	if self.IsWaiting then
		task.cancel(self.waitingTask)
		self.IsWaiting = false
	end

	self.IsWaiting = true
	self.waitingTask = task.delay(duration or self.duration, callback or self.callback)
end

return AwaitTaskDelay
