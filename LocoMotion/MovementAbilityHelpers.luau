--!strict
local ActionConstants = require(script.Parent.ActionConstants)
local MovementContext = require(script.Parent.Contexts.MovementContext)
local MovementActions = require(script.Parent.MovementActions)

type MovementContextType = MovementContext.MovementContext

local MovementAbilityHelpers = {}

export type MovementAbilityHelpers = typeof(MovementAbilityHelpers)

function MovementAbilityHelpers:DoDash(_context: MovementContextType, direction: Vector3)
	local context = _context
	if not context then
		return
	end

	if context.MovementRuntime.dashCount >= context.CharacterState.maxDashes then
		return
	end

	context.MovementRuntime.dashCount += 1

	local dir = context.MovementRuntime.moveDirection

	MovementActions.DoDash(context, direction, ActionConstants.Dash.force)
end

function MovementAbilityHelpers:AdjustFlySpeed(_context: MovementContextType, dir, lvInstance: LinearVelocity)
	local context = _context
	if not context then
		return
	end

	context.CharacterState.flySpeed = math.clamp(
		context.CharacterState.flySpeed + (ActionConstants.Flying.speedConstant * context.CharacterState.flySpeedDelta),
		ActionConstants.Flying.minSpeed,
		ActionConstants.Flying.maxSpeed
	)

	MovementActions.AdjustFlySpeed(context, dir, lvInstance)
end

--[[
 Jumps by using the function from the MovementActions class
]]
function MovementAbilityHelpers:DoJump(_context: MovementContextType)
	local context = _context
	if not context then
		return
	end
	-- Ground
	if context.MovementRuntime.isGrounded then
		MovementActions.DoJump(context, ActionConstants.Jump.power)
		context.MovementRuntime.lastJumpTime = os.clock()
		return
	end

	-- Wall
	-- if (not context.isGrounded) and context.isNearWall and context.wallNormal then
	-- 	MovementActions.DoWallJump(
	-- 		context,
	-- 		context.wallNormal,
	-- 		ActionConstants.WallJump.horizontalSpeed,
	-- 		ActionConstants.WallJump.verticalSpeed
	-- 	)
	-- 	context.lastJumpTime = os.clock()
	-- 	self:SetState("FallingState")
	-- 	return
	-- end

	-- Double jump
	-- if context.jumpCount == 1 then
	-- 	print(context.jumpCount)
	-- 	context.airJumpsUsed += 1
	-- 	MovementActions.DoJump(context, ActionConstants.DoubleJump.power)
	-- 	context.lastJumpTime = os.clock()
	-- 	self:SetState("FallingState")
	-- 	return
	-- end

	-- Air jump
	-- if context.airJumpsUsed < context.maxAirJumps then
	-- 	print("Air jump")
	-- 	-- context.airJumpsUsed += 1
	-- 	MovementActions.DoJump(context, ActionConstants.Jump.power)
	-- 	context.lastJumpTime = os.clock()
	-- 	self:SetState("FallingState")
	-- 	return
	-- end
end

return MovementAbilityHelpers
