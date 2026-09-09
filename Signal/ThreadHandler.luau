--!optimize 2
local ThreadHandler = {}

export type ThreadHandler = typeof(ThreadHandler)

local ThreadPool: { thread } = {}
local MAX_POOL = 50

local function traceHandler(err: string): string
	return debug.traceback(tostring(err), 2)
end

local function runAndRecycle(func, ...)
	local ok, err = xpcall(func, traceHandler, ...)
	-- makes sure that if listener errors it drops the listener but the thread is still able to be pooled
	if not ok then
		warn("[ThreadHandler] job errored:\n" .. err)
	end

	-- re-pool this thread for reuse, unless the pool is already full
	local poolCount = #ThreadPool

	if poolCount < MAX_POOL then
		--indexing the current thread
		ThreadPool[poolCount + 1] = coroutine.running()
	end
end

-- The worker keeps running, and yielding for the next job
local function worker(func, ...)
	runAndRecycle(func, ...)
	while true do
		runAndRecycle(coroutine.yield())
	end
end

function ThreadHandler.Spawn<T...>(func: (T...) -> (), ...: T...)
	local thread = table.remove(ThreadPool)
	if thread then
		-- This will resume the thread with the args (func, ...) which would passed tpto 'runAndRecycle'
		task.spawn(thread, func, ...)
	else
		task.spawn(coroutine.create(worker), func, ...)
	end
end

return ThreadHandler
