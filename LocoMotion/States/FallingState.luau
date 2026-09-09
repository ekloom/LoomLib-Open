--!strict
local Types = require(script.Parent.Parent.Types)
local MovementAbilityHelpers = require(script.Parent.Parent.MovementAbilityHelpers)
--[[
Most improvment: 
-- Improved to a state driven flow: FallingState now requests actions from the manager
-- instead of directly mutating movement flags and humanoid state itself
-- The old version relied heavily on scattered booleans,
-- which made jump flow harder to maintain.

-- The new version moves toward explicit action requests and centralized validation. (As it was intended, (Using ai to validate my actions was the worst thing i could do
it said that what i wanted to do was to complex and that i should just focus on it by doing the 'basics' while that was good i struggled alot with things that could have been
	easier if i went my way (used claude ai with instructions)

	i refactored and gave tailored instructions to chatgpt so that it just listens like a "dog" to my instructions (refactoring the way i intended it to not what the "manager" 
thought was good). Thanks gpt for being a dog i guess.

) )


-- This version reduces state side responsibility:
-- FallingState mainly decides transitions,
-- while the manager owns validation and action execution

-- Before:
--   FallingState handled jump logic itself and manually changed flags like
--   hasJumped, hasAirDashed, and canDoubleJump
-- Now:
--   jump handling is delegated through manager:TryJump(), which centralizes validation
--   and keeps transition logic more consistent across the states


-- Using manager/context as function parameters makes state behavior more explicit
-- and avoids depending on mutable self-assigned references from Enter().

-- Enter and Exit are intentionally minimal now,
-- because this state no longer needs to cache manager/context on self.

-- All that was removed:
-- Humanoid:ChangeState() calls from FallingState.
-- This makes the state less coupled to raw humanoid behavior
-- and keeps movement actions behind the manager abstraction.

]]

type StateType = {}

-- local WALL_RUN_JUMP_COOLDOWN = 0.2

local FallingState = {}
FallingState.Name = "FallingState"

function FallingState.Enter(self: StateType, _manager: Types.MovementManager, _context: Types.MovementContext) end

function FallingState.Handle(
	self: StateType,
	manager: Types.MovementManager,
	context: Types.MovementContext,
	_dt: number
)
	if context.MovementInput.jumpRequested then
		print("[FallingState]: requesting to jump!")
		MovementAbilityHelpers:DoJump(context)
		manager:RequestAction("Jump")
		return
	end

	if context.MovementInput.dashRequested then
		manager:RequestAction("Dash")
		return
	end

	if context.MovementInput.flightRequested then
		manager:RequestAction("Flight")
		return
	end

	-- Landing behavior was improved:
	-- previously landing always returned to RunningState.
	-- now the next grounded state depends on movement input,
	-- allowing a proper transition to either RunningState or IdleState.
	-- if context.isGrounded and not context.isNearWall then
	if context.MovementRuntime.isGrounded then
		-- Air action reset is now centralized through manager:ResetAirActions()
		-- instead of manually resetting individual flags inside this state. (was struggling alot before using it this way)
		manager:ResetAirActions()

		if context.MovementRuntime.moveDirection.Magnitude > 0 then
			manager:PredictState("WalkingState")
		else
			manager:PredictState("IdleState")
		end

		return
	end
end

function FallingState.Exit(self: StateType, _manager: Types.MovementManager, _context: Types.MovementContext) end

return FallingState
