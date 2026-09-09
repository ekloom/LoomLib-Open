--!strict
local FlightConstraintClass = require(script.Parent.Parent.Utils.FlightConstraintClass)
local MovementAbilityHelpers = require(script.Parent.Parent.MovementAbilityHelpers)
local Types = require(script.Parent.Parent.Types)
type StateType = {
	_constraint: FlightConstraintClass.FlightConstraint?,
}
local FlyingState = {}
FlyingState.Name = "FlyingState"

function FlyingState.Enter(self: StateType, _manager: Types.MovementManager, _context: Types.MovementContext)
	_context.CharacterState.Humanoid.PlatformStand = true
	self._constraint = FlightConstraintClass.new(_context.CharacterState.HumanoidRootPart)
end

function FlyingState.Handle(
	self: StateType,
	_manager: Types.MovementManager,
	_context: Types.MovementContext,
	_dt: number
)
	-- if context.dashRequested and context.dashCount < context.maxDashes then
	-- 	manager:SetState("DashState")
	-- 	return
	-- end

	if _context.MovementInput.flightRequested then
		_manager:RequestAction("Flight")
	else
		if self._constraint then
			local moveDir = _context.MovementRuntime.moveDirection
			local speed = _context.CharacterState.flySpeed
			self._constraint:SetVelocity(moveDir * speed)

			MovementAbilityHelpers:AdjustFlySpeed(
				_context,
				_context.MovementRuntime.moveDirection,
				self._constraint._lv
			)
		end
	end
end

function FlyingState.Exit(self: StateType, _manager: Types.MovementManager, _context: Types.MovementContext)
	local hrp = _context.CharacterState.HumanoidRootPart
	if self._constraint then
		-- Clean up the lineairVelocity
		self._constraint:Destroy()
		self._constraint = nil
	end

	-- Reset physics
	hrp.AssemblyLinearVelocity = Vector3.zero
	hrp.AssemblyAngularVelocity = Vector3.zero

	_context.CharacterState.Humanoid.PlatformStand = false
end

return FlyingState
