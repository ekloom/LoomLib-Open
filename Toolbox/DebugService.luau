--!strict

local RunService = game:GetService("RunService")

local IS_STUDIO = RunService:IsStudio()

local noop = function(...: any) end

local function formatPrefix(name: string): string
	return ("[%s]:"):format(name)
end

local function getCaller(): string
	local source = debug.info(3, "s") or "Unknown"
	local line = debug.info(3, "l") or 0
	local scriptName = source:match("([^%.]+)$") or source
	return ("%s:%d"):format(scriptName, line)
end

local function createLogger(prefix: string)
	return {
		Warn = function(...: any)
			warn(prefix, ...)
		end,
		Print = function(...: any)
			print(prefix, ...)
		end,
	}
end

local SILENT = {
	Warn = noop,
	Print = noop,
}

local function shouldLog(logInProduction: boolean?): boolean
	return IS_STUDIO or logInProduction == true
end

local Logger = {
	For = function(name: string, logInProduction: boolean?)
		if shouldLog(logInProduction) then
			return createLogger(formatPrefix(name))
		end
		return SILENT
	end,

	Warn = function(...: any)
		if IS_STUDIO then
			warn(formatPrefix(getCaller()), ...)
		end
	end,

	Print = function(...: any)
		if IS_STUDIO then
			print(formatPrefix(getCaller()), ...)
		end
	end,

	WarnProduction = function(...: any)
		warn(formatPrefix(getCaller()), ...)
	end,

	PrintProduction = function(...: any)
		print(formatPrefix(getCaller()), ...)
	end,
}

return setmetatable({}, {
	__index = Logger,
	__call = function(_, name: string, logInProduction: boolean?)
		if shouldLog(logInProduction) then
			return createLogger(formatPrefix(name))
		end
		return SILENT
	end,
})
