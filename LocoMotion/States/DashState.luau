--!strict
local ActionConstants = require(script.Parent.Parent.ActionConstants)
local MovementAbilityHelpers = require(script.Parent.Parent.MovementAbilityHelpers)
local Types = require(script.Parent.Parent.Types)

type StateType = {}

local DashState = {}
DashState.Name = "DashState"

function DashState.Enter(self: StateType, _manager: Types.MovementManager, _context: Types.MovementContext)
	-- Air dash logic is cleaner now:
	-- instead of checking only a boolean like hasAirDashed,
	-- the state uses dashCount >=  maxDashes, making dash limits easier to scale.
	if _context.MovementRuntime.dashCount >= ActionConstants.Dash.maxDashes then
		_manager:PredictState(_manager:GetLastStateName())
		return
	end

	local dashDirection = _context.MovementRuntime.moveDirection
	if dashDirection.Magnitude == 0 then
		dashDirection = _context.CharacterState.HumanoidRootPart.CFrame.LookVector
	end

	MovementAbilityHelpers:DoDash(_context, dashDirection)
end

function DashState.Handle(
	self: StateType,
	_manager: Types.MovementManager,
	_context: Types.MovementContext,
	_dt: number
)
	if _context.MovementInput.jumpRequested and _context.MovementRuntime.jumpCount < ActionConstants.Jump.maxJumps then
		_context.MovementRuntime.jumpCount += 1
		_manager:RequestAction("Jump")
		return
	end

	if _context.MovementRuntime.isGrounded then
		if _context.MovementRuntime.moveDirection.Magnitude > 0 then
			_manager:PredictState("RunningState")
		else
			_manager:PredictState("IdleState")
		end
		return
	end

	-- if context.isNearWall then
	-- 	manager:SetState("WallRunningState")
	-- 	return
	-- end

	_manager:PredictState("FallingState")
end

function DashState.Exit(self: StateType, _manager: Types.MovementManager, _context: Types.MovementContext) end

return DashState
