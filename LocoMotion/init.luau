--!strict
local MovementContext = require(script.Contexts.MovementContext)
local MovementSensors = require(script.MovementSensors)
local StateMachine = require(script.Controllers.StateMachine)

type MovementContextType = MovementContext.MovementContext
type StateMachineType = StateMachine.StateMachine

--[[
    MovementManager — public face of the LocoMotion library.
    Owns input intents, the per-frame Update loop, player tracking,
    and network wiring. Delegates state lifecycle to StateMachine.
]]
local MovementManager = {}
MovementManager.__index = MovementManager

function MovementManager.New(): MovementManager
	local self = setmetatable({}, MovementManager)

	self._context = nil
	self._stateMachine = StateMachine.New()
	self._netLib = nil
	self._characterModels = {}

	return self
end

function MovementManager:Init(netLib, humanoid: Humanoid, hrp: BasePart)
	self._netLib = netLib
	self._context = MovementContext.New(humanoid, hrp, self._characterModels)

	-- give the state machine its refs now that context exists
	self._stateMachine:Setup(self, self._context)

	netLib:Subscribe("Movement", "StateChanged", function(stateName)
		self._stateMachine:ApplyServerState(stateName)
	end)

	self:PredictState("IdleState")
end

-- ============================================================
-- State forwarders
-- ============================================================

function MovementManager:PredictState(stateName: string)
	if self._netLib then
		self._netLib:SendToServer("Movement", "ReportState", stateName)
	end
	self._stateMachine:Predict(stateName)
end

function MovementManager:RequestAction(actionName: string)
	if not self._context then
		return
	end

	print("[MovementManager]: Action " .. actionName .. " has been requested!")

	self._stateMachine:PredictFromAction(actionName)

	if self._netLib then
		self._netLib:SendToServer("Movement", "RequestAction", actionName)
	end
end

function MovementManager:GetCurrentStateName(): string
	return self._stateMachine:GetCurrentStateName()
end

function MovementManager:GetLastStateName(): string
	return self._stateMachine:GetLastStateName()
end

-- ============================================================
-- Input / intent setters
-- ============================================================

function MovementManager:SetMoveDirection(direction: Vector3)
	local context = self._context
	if not context then
		return
	end
	context.MovementRuntime.moveDirection = direction
end

function MovementManager:SetFlySpeedDelta(delta: number)
	local context = self._context
	if not context then
		return
	end
	context.CharacterState.flySpeedDelta = delta
end

function MovementManager:SetDesiredYaw(yaw: number)
	local context = self._context
	if not context then
		return
	end
	context.MovementInput.desiredYaw = yaw
end

function MovementManager:RequestJump()
	local context = self._context
	if not context then
		return
	end
	context.MovementInput.jumpRequested = true
	context.MovementRuntime.lastJumpTime = os.clock()
end

function MovementManager:RequestDash()
	local context = self._context
	if not context then
		return
	end
	context.MovementInput.dashRequested = true
end

function MovementManager:RequestFlying()
	local context = self._context
	if not context or context.MovementInput.flightRequested then
		return
	end
	context.MovementInput.flightRequested = true
end

function MovementManager:ResetAirActions()
	local context = self._context
	if not context then
		return
	end
	context.MovementRuntime.dashCount = 0
	context.MovementRuntime.jumpCount = 0
end

-- ============================================================
-- Player tracking (for raycast filter)
-- ============================================================

function MovementManager:PlayerAdded(humanoidRootPart: BasePart)
	local character = humanoidRootPart.Parent
	if character and character:IsA("Model") then
		table.insert(self._characterModels, character)

		if self._context and self._context.RayParams then
			local newFilter = { self._context.CharacterState.Humanoid.Parent :: Instance }
			for _, model in ipairs(self._characterModels) do
				table.insert(newFilter, model)
			end
			self._context.RayParams.FilterDescendantsInstances = newFilter
		end
	end
end

function MovementManager:PlayerRemoved(humanoidRootPart: BasePart)
	local character = humanoidRootPart.Parent
	if not character or not character:IsA("Model") then
		return
	end

	for i, model in ipairs(self._characterModels) do
		if model == character then
			table.remove(self._characterModels, i)
			break
		end
	end
end

-- ============================================================
-- Misc accessors
-- ============================================================

function MovementManager:GetCurrentContext(): MovementContextType?
	return self._context
end

function MovementManager:SendToServer(packet: any)
	if not self._netLib then
		return
	end
	self._netLib:SendToServer(packet)
end

-- ============================================================
-- Heartbeat
-- ============================================================

function MovementManager:Update(dt: number)
	local context = self._context
	if not context then
		return
	end

	MovementSensors.Update(context)
	self._stateMachine:Handle(dt)

	-- one-frame intent flags reset
	context.MovementInput.jumpRequested = false
	context.MovementInput.dashRequested = false
	context.MovementInput.flightRequested = false
end

export type MovementManager = typeof(setmetatable(
	{} :: {
		_context: MovementContextType?,
		_stateMachine: StateMachineType,
		_netLib: any,
		_characterModels: { Model },
	},
	MovementManager
))

return MovementManager
