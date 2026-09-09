--!strict
local ActionConstants = require(script.Parent.Parent.ActionConstants)
local FlightConstraintClass = require(script.Parent.Parent.Utils.FlightConstraintClass)
local Types = require(script.Parent.Parent.Types)

type StateType = {
	_constraint: FlightConstraintClass.FlightConstraint?,
}
local WallRunningState = {}
WallRunningState.Name = "WallRunningState"

function WallRunningState.Enter(self: StateType, _manager: Types.MovementManager, _context: Types.MovementContext)
	_manager:ResetAirActions()

	self._constraint = FlightConstraintClass.new(_context.CharacterState.HumanoidRootPart)
	_context.MovementRuntime.lastWallRunTime = os.clock()
end

function WallRunningState.Handle(
	self: StateType,
	_manager: Types.MovementManager,
	_context: Types.MovementContext,
	_dt: number
)
	local normal = _context.MovementRuntime.wallContext.wallNormal
	local hrp = _context.CharacterState.HumanoidRootPart

	if _context.MovementRuntime.isGrounded then
		_manager:RequestAction("RunningState")
		return
	end

	if not _context.MovementRuntime.isNearWall or not normal then
		_manager:PredictState("FallingState")
		return
	end

	if _context.MovementInput.dashRequested then
		_manager:RequestAction("Dash")
	end

	local look = hrp.CFrame.LookVector
	local projected = look - (look:Dot(normal) * normal)

	if projected.Magnitude == 0 then
		_manager:PredictState("FallingState")
		return
	end

	local moveDir = projected.Unit

	local speed = ActionConstants.WallRun.speed
	if self._constraint then
		self._constraint:SetVelocity(moveDir * speed)

		hrp.CFrame = CFrame.lookAt(hrp.Position, hrp.Position + moveDir)
	end

	if _context.MovementInput.jumpRequested then
		_manager:RequestAction("Jump")
		return
	end
end

function WallRunningState.Exit(self: StateType, _manager: Types.MovementManager, _context: Types.MovementContext)
	if self._constraint then
		self._constraint:Destroy()
	end
end

return WallRunningState
