--!strict
local ActionConstants = require(script.Parent.ActionConstants)

type StateEntry = {
	enabled: boolean,
	actionOnly: boolean,
	actions: { [string]: string },
	rules: {
		maxHorizontalSpeed: number?,
		allowVertical: boolean?,
		maxVerticalSpeed: number?,
		[string]: any, -- Allows for other flexible rules
	},
	transitions: { [string]: boolean },
}

local DEVIATION = 2

local StateConfig: { [string]: StateEntry } = {
	["IdleState"] = {
		enabled = true,
		actionOnly = false,
		actions = {
			Jump = "FallingState",
			Dash = "DashState",
			Flight = "FlyingState",
		},
		rules = {
			maxHorizontalSpeed = 8,
			allowVertical = false,
			maxVerticalSpeed = 8,
		},
		transitions = {
			RunningState = true,
			FallingState = true,
			DashState = true,
			WalkingState = true,
			FlyingState = true,
		},
	},

	["RunningState"] = {
		enabled = true,
		actionOnly = true,
		actions = {
			Dash = "DashState",
			Flight = "FlyingState",
		},
		rules = {
			maxHorizontalSpeed = 55 + DEVIATION,
			allowVertical = false,
			maxVerticalSpeed = 8,
		},
		transitions = {
			IdleState = true,
			FallingState = true,
			DashState = true,
			WalkingState = true,
		},
	},

	["FallingState"] = {
		enabled = true,
		actionOnly = false,
		actions = {
			Jump = "FallingState",
			Flight = "FlyingState",
		},
		rules = {
			maxHorizontalSpeed = 55 + DEVIATION,
			allowVertical = true,
			maxVerticalSpeed = math.huge,
		},
		transitions = {
			IdleState = true,
			RunningState = true,
			DashState = true,
			WalkingState = true,
			WallRunningState = true,
			FlyingState = true,
		},
	},

	["DashState"] = {
		enabled = true,
		actionOnly = true,
		actions = {},
		rules = {
			maxHorizontalSpeed = ActionConstants.Dash.force + DEVIATION,
			allowVertical = true,
			maxVerticalSpeed = math.huge,
		},
		transitions = {
			IdleState = true,
			RunningState = true,
			FallingState = true,
			WalkingState = true,
			WallRunningState = true,
		},
	},

	["WalkingState"] = {
		enabled = true,
		actionOnly = false,
		actions = {
			Jump = "FallingState",
			Flight = "FlyingState",
		},
		rules = {},
		transitions = {
			IdleState = true,
			RunningState = true,
			FallingState = true,
			WalkingState = true,
			WallRunningState = true,
		},
	},

	["LandingState"] = {
		enabled = false,
		actionOnly = false,
		rules = {},
		transitions = {},
		actions = {},
	},

	["FlyingState"] = {
		enabled = false,
		actionOnly = true,
		actions = {
			Flight = "FallingState",
		},
		rules = {},
		transitions = {
			IdleState = true,
			FallingState = true,
			FlyingState = false,
			WalkingState = true,
			WallRunningState = false,
		},
	},

	["BoostState"] = {
		enabled = false,
		actionOnly = true,
		actions = {},

		rules = {},
		transitions = {},
	},

	["TakeoffState"] = {
		enabled = false,
		actionOnly = false,
		actions = {},
		rules = {},
		transitions = {},
	},

	["WallRunningState"] = {
		enabled = false,
		actionOnly = false,
		actions = {},
		rules = {},
		transitions = {},
	},
}

-- CONFIG FILTERING

-- collects every state that is a target of an action
local actionTargets: { [string]: boolean } = {}
for _, config in pairs(StateConfig) do
	for _, targetState in pairs(config.actions) do
		actionTargets[targetState] = true
	end
end

-- removes action only targets from transitions ;)))
for _, config in pairs(StateConfig) do
	if not config.enabled or not config.transitions then
		continue
	end
	--checks if the config has transitions
	if config.transitions then
		-- gets the target state from the transitions from the config
		for targetState in pairs(config.transitions) do
			--checks if action target has the targetstate and checks if stateconfig if this targetState is actionOnly
			if actionTargets[targetState] and StateConfig[targetState].actionOnly then
				-- removes the transitions from the current config if the targetstate in stateconfig was set to actionOnly
				config.transitions[targetState] = nil
			end
		end
	end
end

-- removes disabled states from config
for name, config in pairs(StateConfig) do
	if not config.enabled then
		--might want to change this
		-- StateConfig[name] = nil
		continue
	end

	if config.transitions then
		for targetState in pairs(config.transitions) do
			local targetConfig = StateConfig[targetState]

			if not targetConfig or not targetConfig.enabled then
				config.transitions[targetState] = nil
			end
		end
	end
end

return StateConfig
