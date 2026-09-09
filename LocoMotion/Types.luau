--!strict
-- Server/Types.lua
local LocoMotion = script.Parent

-- require every module once, here only
local MovementManager = require(LocoMotion.MovementManager)
local MovementContext = require(LocoMotion.Contexts.MovementContext)

export type MovementManager = MovementManager.MovementManager
export type MovementContext = MovementContext.MovementContext

return {}
