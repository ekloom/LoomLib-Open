--!strict

local CharacterState = require(script.Parent.CharacterState)
local MovementInput = require(script.Parent.MovementInput)
local MovementRuntime = require(script.Parent.MovementRuntime)

local MovementContext = {}
MovementContext.__index = MovementContext

export type MovementContext = typeof(setmetatable(
	{} :: {
		CharacterState: CharacterState.CharacterState,
		MovementInput: MovementInput.MovementInput,
		MovementRuntime: MovementRuntime.MovementRuntime,

		RayParams: RaycastParams,
		raycastVisuals: Instance?,
		_wasOnWall: boolean,
	},
	MovementContext
))

function MovementContext.New(humanoid: Humanoid, hrp: BasePart, rootParts: { BasePart }): MovementContext
	local self = setmetatable({}, MovementContext)

	self.CharacterState = CharacterState.New(humanoid, hrp, rootParts)
	self.MovementInput = MovementInput.New()
	self.MovementRuntime = MovementRuntime.New()

	self.RayParams = RaycastParams.new()
	self.RayParams.FilterType = Enum.RaycastFilterType.Exclude

	local ignoreList = { humanoid.Parent :: Instance }
	for _, p in ipairs(rootParts) do
		table.insert(ignoreList, p)
	end

	self.RayParams.FilterDescendantsInstances = ignoreList

	self.raycastVisuals = nil
	self._wasOnWall = false

	return self
end

return MovementContext
