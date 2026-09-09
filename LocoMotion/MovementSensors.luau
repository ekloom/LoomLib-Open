--!strict
local Debris = game:GetService("Debris")
local MovementContext = require(script.Parent.Contexts.MovementContext)

local MovementSensors = {}

local DEBUG_RAYS = false

local function buildRaycastFilter(context: MovementContext.MovementContext)
	local ignoreList = { context.CharacterState.Humanoid.Parent :: Instance }

	if context.raycastVisuals then
		table.insert(ignoreList, context.raycastVisuals)
	end

	for _, rootPart in ipairs(context.CharacterState.CharacterRootParts) do
		table.insert(ignoreList, rootPart)
	end

	context.RayParams.FilterDescendantsInstances = ignoreList
end

local function ensureDebugFolder(context: MovementContext.MovementContext)
	if not DEBUG_RAYS then
		return
	end

	if not context.raycastVisuals then
		print("Raycast folder created")
		local folder = Instance.new("Folder")
		folder.Name = "raycastvisuals"
		folder.Parent = workspace
		context.raycastVisuals = folder
		buildRaycastFilter(context)
	end
end

local function visualizeRay(context: MovementContext.MovementContext, originPosition: Vector3, direction: Vector3): Part
	local length = direction.Magnitude
	local midpoint = originPosition + (direction * 0.5)

	local ray = Instance.new("Part")
	ray.Anchored = true
	ray.CanCollide = false
	ray.Material = Enum.Material.Neon
	ray.Color = Color3.fromRGB(255, 0, 0)
	ray.Size = Vector3.new(0.5, 0.5, length)
	ray.CFrame = CFrame.new(midpoint, originPosition + direction)
	ray.Parent = context.raycastVisuals
	return ray
end

local function getRayResult(
	context: MovementContext.MovementContext,
	origin: Vector3,
	direction: Vector3,
	raycastParams: RaycastParams
): RaycastResult?
	if DEBUG_RAYS then
		ensureDebugFolder(context)
		if context.raycastVisuals then
			local visual = visualizeRay(context, origin, direction)
			Debris:AddItem(visual, 0.01)
		end
	end

	return workspace:Raycast(origin, direction, raycastParams)
end

local function getCorners(hrp: BasePart): { Vector3 }
	local pos = hrp.Position
	local right = hrp.CFrame.RightVector
	local front = hrp.CFrame.LookVector
	local halfWidth = hrp.Size.X * 0.5
	local halfDepth = hrp.Size.Z * 0.5

	return {
		pos + (right * halfWidth) + (front * halfDepth),
		pos + (-right * halfWidth) + (front * halfDepth),
		pos + (right * halfWidth) + (-front * halfDepth),
		pos + (-right * halfWidth) + (-front * halfDepth),
	}
end

local function checkGrounded(context: MovementContext.MovementContext, raycastParams: RaycastParams): boolean
	local groundDir = Vector3.new(0, -(context.CharacterState.Humanoid.HipHeight + 1.1), 0)

	for _, corner in getCorners(context.CharacterState.HumanoidRootPart) do
		if getRayResult(context, corner, groundDir, raycastParams) then
			return true
		end
	end
	return false
end

-- local function checkOnWall(context: MovementContext.MovementContext, raycastParams: RaycastParams): boolean
-- 	local hrp = context.HumanoidRootPart
-- 	local halfWidth = hrp.Size.X * 0.5
-- 	local halfDepth = hrp.Size.Z * 0.5
-- 	local offset = 1.5

-- 	local rays = {
-- 		{ side = "Right", dir = hrp.CFrame.RightVector * (halfWidth + offset) },
-- 		{ side = "Left", dir = -hrp.CFrame.RightVector * (halfWidth + offset) },
-- 		{ side = "Front", dir = hrp.CFrame.LookVector * (halfDepth + offset) },
-- 	}

-- 	for _, rayGoal in rays do
-- 		local result = getRayResult(context, hrp.Position, rayGoal.dir, raycastParams)

-- 		if result then
-- 			-- print(result.Instance.Name)
-- 			context.wallSide = rayGoal.side :: "Left" | "Right" | "Front"
-- 			context.wallNormal = result.Normal
-- 			context.wallName = result.Instance.Name
-- 			context.wallCFrame = result.Instance.CFrame
-- 			context.wallPos = result.Instance.Position
-- 			context.wallSize = result.Instance.Size
-- 			return true
-- 		end
-- 	end
-- 	return false
-- end

-- local function updateWallDistances(context: MovementContext.MovementContext)
-- 	context.wallEdgeDistance = nil
-- 	context.wallBottomDistance = nil
-- 	context.worldHeight = 0

-- 	if context.wallPos and context.wallSize and context.wallCFrame and not context.isGrounded then
-- 		-- print( "Checking wall distance" )
-- 		local cf = context.wallCFrame
-- 		local size = context.wallSize

-- 		context.worldHeight = math.abs(cf.UpVector.Y * size.Y)
-- 			+ math.abs(cf.RightVector.Y * size.X)
-- 			+ math.abs(cf.LookVector.Y * size.Z)

-- 		context.wallEdgeDistance = (context.wallPos.Y + (context.worldHeight * 0.5))
-- 			- (context.HumanoidRootPart.Position.Y + (context.HumanoidRootPart.Size.Y * 0.5))

-- 		context.wallBottomDistance = (context.HumanoidRootPart.Position.Y - context.Humanoid.HipHeight)
-- 			- (context.wallPos.Y - (context.worldHeight * 0.5))
-- 	end
-- end

-- local function updateWallPosition(context: MovementContext.MovementContext, raycastParams: RaycastParams)
-- 	if context.isNearWall and not context._wasOnWall then
-- 		context.approachingFromBelow = false
-- 		context.isPartAboveGround = false

-- 		if context.wallPos and context.worldHeight then
-- 			local wallBottom = context.wallPos.Y - (context.worldHeight * 0.5)
-- 			local origin = Vector3.new(context.wallPos.X, wallBottom, context.wallPos.Z)
-- 			local direction = Vector3.new(0, -1000, 0)
-- 			local result = getRayResult(context, origin, direction, raycastParams)
-- 			context.isPartAboveGround = result ~= nil and result.Distance > 1
-- 			context.approachingFromBelow = context.isPartAboveGround
-- 				and context.wallBottomDistance ~= nil
-- 				and context.wallBottomDistance < 0
-- 		end
-- 	end
-- end

-- local function updateApproachState(context: MovementContext.MovementContext, raycastParams: RaycastParams)
-- 	if context.isNearWall and not context._wasOnWall and not context.isGrounded then
-- 		context.approachingFromBelow = false
-- 		context.isAboveGroundThreshold = false

-- 		local feetPosition = Vector3.new(
-- 			context.HumanoidRootPart.Position.X,
-- 			context.HumanoidRootPart.Position.Y - context.Humanoid.HipHeight,
-- 			context.HumanoidRootPart.Position.Z
-- 		)

-- 		local result = getRayResult(context, feetPosition, Vector3.new(0, -1000, 0), raycastParams)
-- 		context.isAboveGroundThreshold = result ~= nil and result.Distance > 10
-- 		context.approachingFromBelow = context.isAboveGroundThreshold
-- 			and context.wallBottomDistance ~= nil
-- 			and context.wallBottomDistance < 0
-- 	end
-- 	-- print(context.approachingFromBelow)

-- 	if not context.isNearWall then
-- 		context.approachingFromBelow = false
-- 	end
-- end

function MovementSensors.Update(context: MovementContext.MovementContext)
	-- context.wallSide = nil
	-- context.wallNormal = nil
	-- context.wallName = nil
	-- context.wallCFrame = nil
	-- context.wallPos = nil
	-- context.wallSize = nil

	local raycastParams = context.RayParams

	context.MovementRuntime.isGrounded = checkGrounded(context, raycastParams)
	-- context.isNearWall = checkOnWall(context, raycastParams)

	-- updateWallDistances(context)
	-- updateApproachState(context, raycastParams)
	-- updateWallPosition(context, raycastParams)
	-- context._wasOnWall = context.isNearWall
end

return MovementSensors
