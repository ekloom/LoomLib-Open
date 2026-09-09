# LoomLib Open

A collection of Luau libraries that I built from scratch to deepen my understanding of the language and to serve as reusable building blocks across my Roblox projects.

## Projects

### Signal
A custom event/signal implementation using a doubly linked list for managing connections. Supports `Connect`, `Once`, `Wait` (with optional timeout), `Fire`, and `DisconnectAll`. Includes a thread pool (`ThreadHandler`) that recycles coroutines to reduce allocation overhead when firing signals.

### NetLib
A buffer-based networking library that multiplexes multiple channels over a single `RemoteEvent`. Each channel defines typed fields using codecs (uint8, uint16, int32, string, Vector3, etc.) that serialize directly into a binary buffer. Outbound data is flushed every frame on a heartbeat interval. Supports namespaces to group channels, and has a request-response pattern where a client can send a request and await a typed reply from the server.

### Bootstrapper
A service initialization framework that auto-discovers `ModuleScripts` from specified folders, resolves their dependencies, and initializes them in the correct order. Detects circular dependencies, warns on services that take too long to initialize, and coordinates client/server startup so the client waits for the server to finish before running its own initialization.

### LocoMotion
A client-side character movement system built around a state machine. States like Idle, Walking, Falling, Dashing, and Flying each define their own `Enter`, `Handle`, and `Exit` logic. Transitions are driven by a configurable `StateConfig` that maps allowed transitions and action triggers per state. Includes client-side prediction with server reconciliation, movement sensors (raycasts for ground/wall detection), and a movement context that tracks runtime data like speed, direction, and jump counts.

### Toolbox
A collection of small standalone utilities:
- **AwaitingTaskDelay** — A debounce helper that schedules a delayed callback and resets the timer on repeated calls, useful for postponing work until input settles.
- **DebugService** — A logger that formats output with the caller's script name and line number in Studio, and becomes a no-op in production.
- **TokenBucket** — A per-player rate limiter with configurable capacity and time-based refill, used to throttle actions on the server.
