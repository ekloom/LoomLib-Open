--!strict

local CharacterState = {}
CharacterState.__index = CharacterState

export type CharacterState = typeof(setmetatable(
	{} :: {
		Humanoid: Humanoid,
		HumanoidRootPart: BasePart,
		CharacterRootParts: { BasePart },

		maxJumps: number,
		maxDashes: number,

		flySpeed: number,
		flySpeedDelta: number,

		DashCooldown: number,
	},
	CharacterState
))

function CharacterState.New(humanoid: Humanoid, hrp: BasePart, rootParts: { BasePart })
	local self = setmetatable({}, CharacterState)

	self.Humanoid = humanoid
	self.HumanoidRootPart = hrp
	self.CharacterRootParts = rootParts

	self.maxJumps = 2
	self.maxDashes = 2

	self.flySpeed = 50
	self.flySpeedDelta = 1

	self.DashCooldown = 0

	return self
end

return CharacterState
