--!strict

local MovementInput = {}
MovementInput.__index = MovementInput

export type MovementInput = typeof(setmetatable({
	jumpRequested = false,
	dashRequested = false,
	runningRequested = false,
	flightRequested = false,
	desiredYaw = 0,
}, MovementInput))

function MovementInput.New(): MovementInput
	local self = setmetatable({}, MovementInput)

	self.jumpRequested = false
	self.dashRequested = false
	self.runningRequested = false
	self.flightRequested = false
	self.desiredYaw = 0

	return self
end

return MovementInput
