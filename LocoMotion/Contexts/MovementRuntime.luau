--!strict

local MovementRuntime = {}
MovementRuntime.__index = MovementRuntime

type wallContext = {
	wallSide: "Left" | "Right" | "Front" | nil,
	wallNormal: Vector3?,
	wallSize: Vector3?,
	wallPos: Vector3?,
	wallName: string?,
	wallCFrame: CFrame?,
	wallEdgeDistance: number?,
	wallBottomDistance: number?,
}

export type MovementRuntime = typeof(setmetatable(
	{} :: {
		moveDirection: Vector3,

		isGrounded: boolean,
		isLocked: boolean,
		isNearWall: boolean,

		jumpCount: number,
		dashCount: number,

		lastWallRunTime: number,
		lastGroundedTime: number,
		lastJumpTime: number,

		wallContext: wallContext,
	},
	MovementRuntime
))

function MovementRuntime.New(): MovementRuntime
	local self = setmetatable({}, MovementRuntime)

	self.moveDirection = Vector3.zero

	self.isGrounded = true
	self.isLocked = false
	self.isNearWall = false

	self.jumpCount = 0
	self.dashCount = 0

	self.lastGroundedTime = 0
	self.lastJumpTime = 0
	self.lastWallRunTime = 0
	self.DashCooldownTime = 0

	self.wallContext = {
		wallSide = nil,
		wallNormal = nil,
		wallSize = nil,
		wallPos = nil,
		wallName = nil,
		wallCFrame = nil,
		wallEdgeDistance = nil,
		wallBottomDistance = nil,
	}

	return self
end

return MovementRuntime
