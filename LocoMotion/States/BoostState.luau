--!strict

local Types = require(script.Parent.Parent.Types)

type StateType = {}

local DashState = {}
DashState.Name = "BoostState"

function DashState.Enter(self: StateType, _manager: Types.MovementManager, _context: Types.MovementContext)
	-- Air dash logic is cleaner now:
	-- instead of checking only a boolean like hasAirDashed,
	-- the state uses dashCount >=  maxDashes, making dash limits easier to scale.
end

function DashState.Handle(
	self: StateType,
	manager: Types.MovementManager,
	context: Types.MovementContext,
	_dt: number
)
end

function DashState.Exit(self: StateType, _manager: Types.MovementManager, _context: Types.MovementContext) end

return DashState
