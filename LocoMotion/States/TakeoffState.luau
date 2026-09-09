--!strict
local Types = require(script.Parent.Parent.Types)

type StateType = {}

local TakeoffState = {}
TakeoffState.Name = "TakeoffState"

function TakeoffState.Enter(self: StateType, _manager: Types.MovementManager, _context: Types.MovementContext) end

function TakeoffState.Handle(
	self: StateType,
	manager: Types.MovementManager,
	context: Types.MovementContext,
	_dt: number
)
end

function TakeoffState.Exit(self: StateType, _manager: Types.MovementManager, _context: Types.MovementContext) end

return TakeoffState
