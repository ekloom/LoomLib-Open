--!strict
local Types = require(script.Parent.Parent.Types)

type StateType = {}

local WalkingState = {}
WalkingState.Name = "WalkingState"

function WalkingState.Enter(self: StateType, _manager: Types.MovementManager, context: Types.MovementContext)
	-- context.dashCount = 0
	-- context.jumpCount = 0
	_manager:ResetAirActions()
end

function WalkingState.Handle(
	self: StateType,
	manager: Types.MovementManager,
	context: Types.MovementContext,
	_dt: number
)
	if context.MovementInput.jumpRequested then
		manager:RequestAction("Jump")
		return
	end

	if context.MovementInput.dashRequested and context.MovementRuntime.dashCount < context.CharacterState.maxDashes then
		manager:PredictState("DashState")
		return
	end

	if context.MovementInput.flightRequested then
		manager:RequestAction("Flight")
		return
	end

	if not context.MovementRuntime.isGrounded then
		manager:PredictState("FallingState")
		return
	end

	if context.MovementRuntime.moveDirection.Magnitude == 0 then
		manager:PredictState("IdleState")
		return
	end
end

function WalkingState.Exit(self: StateType, _manager: Types.MovementManager, _context: Types.MovementContext) end

return WalkingState
