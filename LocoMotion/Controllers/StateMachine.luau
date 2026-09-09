--!strict

--[[
    StateMachine — handles state lifecycle only (load, transitions,
    prediction, server reconciliation). Knows nothing about input,
    sensors, or networking. MovementManager owns one of these and
    forwards state-related calls to it.
]]

local StateFolder = script.Parent.Parent.States
local StateConfig = require(script.Parent.Parent.StateConfig)

type StateInterface = {
	Name: string,
	Enter: (self: any, manager: any, context: any) -> (),
	Handle: (self: any, manager: any, context: any, dt: number) -> (),
	Exit: (self: any, manager: any, context: any) -> (),
}

local StateMachine = {}
StateMachine.__index = StateMachine

export type StateMachine = typeof(setmetatable(
	{} :: {
		_states: { [string]: StateInterface },
		_currentState: StateInterface?,
		_lastStateName: string?,
		_pendingState: string?,
		_manager: any,
		_context: any,
	},
	StateMachine
))

function StateMachine.New(): StateMachine
	local self = setmetatable({}, StateMachine)

	self._states = {}
	self._currentState = nil
	self._lastStateName = nil
	self._pendingState = nil
	self._manager = nil
	self._context = nil

	self:_LoadStates()

	return self
end

--[[
    Provides the manager and context refs needed when calling
    state lifecycle methods. Call from MovementManager:Init once context exists.
]]
function StateMachine:Setup(manager: any, context: any)
	self._manager = manager
	self._context = context
end

--[[
    Loads enabled states from the States folder
]]
function StateMachine:_LoadStates()
	table.clear(self._states)

	for _, module in ipairs(StateFolder:GetChildren()) do
		if not module:IsA("ModuleScript") then
			continue
		end

		local ok, stateContent = pcall(require, module)
		if not ok or type(stateContent) ~= "table" or not stateContent.Name then
			warn("[StateMachine] Failed to load state:", module:GetFullName())
			continue
		end

		if StateConfig[stateContent.Name] == nil then
			warn("[StateMachine] State missing in StateConfig:", stateContent.Name)
			continue
		end

		if StateConfig[stateContent.Name].enabled then
			self._states[stateContent.Name] = stateContent
		else
			warn("[StateMachine] State disabled:", stateContent.Name)
		end
	end
end

--[[
    Internal: performs the actual transition (Exit current, Enter new)
]]
function StateMachine:_SetState(stateName: string)
	local newState = self._states[stateName]
	if not newState then
		warn(("[StateMachine]: Unknown state '%s'"):format(stateName))
		return
	end

	if self._currentState and self._currentState.Name == stateName then
		return
	end

	if self._currentState and self._context then
		self._currentState:Exit(self._manager, self._context)
	end

	self._lastStateName = self._currentState and self._currentState.Name or nil
	self._currentState = newState

	if self._context and self._currentState and self._context.CharacterState.HumanoidRootPart.Parent then
		self._context.CharacterState.HumanoidRootPart.Parent:SetAttribute("MovementState", stateName)
		self._currentState:Enter(self._manager, self._context)
	end
end

--[[
    Client-side prediction. Pure state-machine concern — no networking.
    MovementManager wraps this to fire the server report.
]]
function StateMachine:Predict(stateName: string)
	if self:GetCurrentStateName() == stateName then
		return
	end

	print("[StateMachine]: State " .. stateName .. " has been predicted")
	self:_SetState(stateName)
end

--[[
    Action-driven transition. Looks up the action in StateConfig for the
    current state and transitions if there's a mapped target.
]]
function StateMachine:PredictFromAction(actionName: string)
	local currentState = self:GetCurrentStateName()
	local stateData = StateConfig[currentState]

	if not stateData or not stateData.actions then
		return
	end

	local nextState = stateData.actions[actionName]
	if not nextState then
		return
	end

	self:Predict(nextState)
end

--[[
    Authoritative server state, with a small delay so a recently-predicted
    client state has time to settle.
]]
function StateMachine:ApplyServerState(stateName: string)
	local current = self:GetCurrentStateName()
	if current == stateName then
		return
	end

	if self._pendingState == stateName then
		return
	end

	self._pendingState = stateName

	task.delay(0.05, function()
		if self:GetCurrentStateName() ~= stateName then
			self:_SetState(stateName)
		end
		self._pendingState = ""
	end)
end

--[[
    Per-frame tick on the current state. Called from MovementManager:Update.
]]
function StateMachine:Handle(dt: number)
	if not self._currentState or not self._context then
		return
	end
	self._currentState:Handle(self._manager, self._context, dt)
end

function StateMachine:GetCurrentStateName(): string
	return self._currentState and self._currentState.Name or "None"
end

function StateMachine:GetLastStateName(): string
	return self._lastStateName or "None"
end

return StateMachine
