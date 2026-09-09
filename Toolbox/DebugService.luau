--!strict

local RunService = game:GetService("RunService")

local IS_STUDIO = RunService:IsStudio()

local function getCaller(): string
	local source = debug.info(3, "s") or "Unknown"
	local line = debug.info(3, "l") or 0

	-- Get only the last part after the final '.'
	local scriptName = source:match("([^%.]+)$") or source

	return ("%s:%d"):format(scriptName, line)
end

local Logger

if IS_STUDIO then
	local function format(prefix)
		return ("[%s]:"):format(prefix)
	end

	Logger = {
		For = function(name: string)
			local prefix = format(name)

			return {
				Warn = function(...: any)
					warn(prefix, ...)
				end,

				Print = function(...: any)
					print(prefix, ...)
				end,
			}
		end,

		Warn = function(...: any)
			warn(format(getCaller()), ...)
		end,

		Print = function(...: any)
			print(format(getCaller()), ...)
		end,
	}
else
	local noop = function(...: any) end

	Logger = {
		For = function(_name: string)
			return {
				Warn = noop,
				Print = noop,
			}
		end,

		Warn = noop,
		Print = noop,
	}
end

return Logger
