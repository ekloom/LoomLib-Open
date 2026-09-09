--!strict
local MovementContext = require(script.Parent.Contexts.MovementContext)

type MovementContextType = MovementContext.MovementContext

--[[ 
 A singlton class specific for executing actions instead of the states doing it individually (false)
 it's not like an object with ownership, it's more like a namespace of movement functions.

 it's a stateless utility module not a singleton class 
]]
local MovementActions = {}

--[[
	Makes the player jump doing it manually instead of using the roblox standard jump mechanism.
	Makes it easier to implement jumping instructions in different states
]]
function MovementActions.DoJump(context: MovementContextType, power: number)
	local hrp = context.CharacterState.HumanoidRootPart
	local velocity = hrp.AssemblyLinearVelocity

	context.MovementRuntime.jumpCount += 1
	hrp.AssemblyLinearVelocity = Vector3.new(velocity.X, power, velocity.Z)
end

--[[ 
	Gives the player a boost bump on the x and z axis
]]
function MovementActions.DoDash(context: MovementContextType, direction: Vector3, speed: number)
	local hrp = context.CharacterState.HumanoidRootPart
	local velocity = hrp.AssemblyLinearVelocity

	local flatDirection = Vector3.new(direction.X, 0, direction.Z)
	if flatDirection.Magnitude <= 0 then
		return
	end

	flatDirection = flatDirection.Unit

	hrp.AssemblyLinearVelocity = Vector3.new(flatDirection.X * speed, velocity.Y, flatDirection.Z * speed)
end

function MovementActions.AdjustFlySpeed(context: MovementContextType, direction: Vector3, lvInstance: LinearVelocity)
	local hrp = context.CharacterState.HumanoidRootPart

	-- if direction.Magnitude == 0 then
	-- 	hrp.AssemblyLinearVelocity = Vector3.zero
	-- 	return
	-- end

	lvInstance.VectorVelocity = direction * context.CharacterState.flySpeed
end

--[[ 
	Makes the player jump off the wall
]]
function MovementActions.DoWallJump(
	context: MovementContextType,
	normal: Vector3,
	horizontalSpeed: number,
	verticalSpeed: number
)
	local hrp = context.CharacterState.HumanoidRootPart

	local away = Vector3.new(normal.X, 0, normal.Z)
	if away.Magnitude <= 0 then
		return
	end

	away = away.Unit
	context.MovementRuntime.jumpCount += 1
	local launchVelocity = away * horizontalSpeed + Vector3.yAxis * verticalSpeed
	hrp.AssemblyLinearVelocity = launchVelocity
end

return MovementActions
