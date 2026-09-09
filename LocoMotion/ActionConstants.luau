local ActionConstants = {
	Dash = {
		force = 125,
		maxDashes = 2,
	},

	WallJump = {
		horizontalSpeed = 80,
		verticalSpeed = 50,
	},

	WallRun = {
		speed = 25,
	},

	Jump = {
		power = 50,
		maxJumps = 2,
	},

	DoubleJump = {
		power = 100,
	},

	Run = {
		speed = 20,
	},

	Flying = {
		maxSpeed = 100,
		minSpeed = 30,
		speedConstant = 1,
	},
}

return ActionConstants
