--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Signal = require(ReplicatedStorage.LoomLib.Signal)
local DebugService = require(ReplicatedStorage.LoomLib.Toolbox.DebugService)

-- Only Services that are services aka things that initialize once, run for the whole session, and have no constructor arguments.
local runContext: "server" | "client" = if RunService:IsServer() then "server" else "client"

local next = next

local Bootstrapper = {}

Bootstrapper.__index = Bootstrapper
local _registeredNames: { [string]: boolean } = {}
export type Bootstrapper = typeof(Bootstrapper) & {
	_name: string,
	_serviceFolders: { Instance },
	_currentCount: number,
	IsInitialized: boolean,
	OnScriptsInitialized: Signal.Signal<string, number>,
	OnScriptsLoaded: Signal.Signal<Player>,
	TotalServices: number,
	WaitOnServer: boolean,
}

local function loadModule(self: Bootstrapper, ServicesModule): string?
	local moduleName = ServicesModule.Name
	local ok, moduleContent = pcall(require, ServicesModule)

	if not ok then
		warn("[Bootstrapper] Failed to require module '" .. moduleName .. "': " .. tostring(moduleContent))
		return nil
	end

	if moduleContent == nil then
		warn("[Bootstrapper] Module '" .. moduleName .. "' returned nil.")
		return nil
	end

	-- next used to check if the table is empty
	if type(moduleContent) == "table" and next(moduleContent) == nil then
		warn(
			"[Bootstrapper] Module '"
				.. moduleName
				.. "' returned an empty table, so this can't be stored in the registry!"
		)
		return nil
	end

	print("Module '" .. moduleName .. "' successfully loaded!")

	self[0][moduleName] = moduleContent
	return moduleName
end

local function FetchServices(self: Bootstrapper)
	for _, folder in ipairs(self._serviceFolders) do
		for _, module in pairs(folder:GetDescendants()) do
			if module:IsA("ModuleScript") then
				local _m = loadModule(self, module)
				if _m then
					self.TotalServices += 1
				end
			end
		end
	end
end

local function InitializeService(self: Bootstrapper, serviceName: string, calledFrom: string?)
	local service = self[0][serviceName]

	if not service then
		local message = "The module with the name '" .. serviceName .. "' doesn't exist!"

		if calledFrom then
			message ..= " (called from class '" .. calledFrom .. "')"
		end

		error(message)
	end

	if service.Initialized then
		return
	end

	-- checking for circular dependency
	if service.Initializing then
		error("Circular dependency detected for service: " .. serviceName)
	end

	service.Initializing = true

	if service.Dependencies then
		for _, dependencyName in pairs(service.Dependencies) do
			InitializeService(self, dependencyName, serviceName)
			service[dependencyName] = self[0][dependencyName]
		end
	end

	if service.Init then
		if type(service.Init) ~= "function" then
			error(
				string.format(
					"Service '%s' has an invalid Init member. Expected a function, got '%s'.",
					serviceName,
					typeof(service.Init)
				)
			)
		end

		task.delay(5, function()
			if not service.Initialized then
				warn(
					"Service '"
						.. serviceName
						.. "' Init() has been running for 5+ seconds. Possible yield/infinite loop."
				)
			end
		end)

		service:Init()
		print("Module '" .. serviceName .. "' successfully initialized!")
	else
		warn(string.format("Service '%s' has no Init() function. Skipping initialization.", serviceName))
	end

	self._currentCount += 1
	self.OnScriptsInitialized:Fire(serviceName, self._currentCount)
	service.Initialized = true
	service.Initializing = false
end

local function InvokeServices(self: Bootstrapper)
	for serviceName in pairs(self[0]) do
		InitializeService(self, serviceName)
	end
end

local function RunInit(self: Bootstrapper)
	FetchServices(self)
	InvokeServices(self)

	self.IsInitialized = true
	if runContext == "server" then
		script:SetAttribute("ServerInitialized_" .. self._name, true)
	elseif runContext == "client" then
		script:SetAttribute("ClientInitialized_" .. self._name, true)
	end

	print("Services loaded for: " .. runContext)
end

function Bootstrapper.GetService(self: Bootstrapper, name: string)
	local module = self[0][name]
	if not module then
		error("The module with the name: " .. name .. " doesn't exist!")
	end
	return module
end

function Bootstrapper.RegisterService(self: Bootstrapper, ServicesModule: ModuleScript)
	if self.IsInitialized then
		error("bootstrapper has already been initiallized, you have to register before invoking the initilaize method!")
		return
	end
	if ServicesModule:IsA("ModuleScript") then
		loadModule(self, ServicesModule)
	end
end

function Bootstrapper.GetServices(self: Bootstrapper)
	return table.freeze(self[0])
end

function Bootstrapper.Initialize(self: Bootstrapper, serviceFolders: { Instance }?)
	if self.IsInitialized then
		return
	end

	if serviceFolders then
		for _, folder in ipairs(serviceFolders) do
			assert(folder:IsA("Folder"), "Bootstrapper: expected Folder, got " .. folder.ClassName)
		end

		self._serviceFolders = serviceFolders
	end

	if runContext == "client" then
		if self.WaitOnServer then
			local attrName = "ServerInitialized_" .. self._name
			local isInit = script:GetAttribute(attrName)

			if not isInit then
				task.delay(5, function()
					if not isInit then
						warn(
							"[Bootstrapper] Client is waiting for server to initialize '"
								.. attrName
								.. "'. If this hangs, the server may not have a matching Bootstrapper. You might want to set the flag 'WaitOnServer' to false "
								.. "if the server does not have a bootstrapper instance under the same name!"
						)
					end
				end)

				script:GetAttributeChangedSignal(attrName):Wait()
				isInit = true
			end
		end
		RunInit(self)
	end

	if runContext == "server" then
		RunInit(self)
	end
end

local function New(name: string)
	-- this means that you can't create a bootstrapper that has the same name
	-- but this also means that i couldn not use the all declaraed bootstrapper
	-- i might store the bootstrap instances and return the stored bootstrap instance
	if _registeredNames[name] then
		error("Bootstrapper: name '" .. name .. "' is already registered")
	end
	_registeredNames[name] = true

	return setmetatable(
		{
			[0] = {},
			_name = name,
			_serviceFolders = {},
			_currentCount = 0,
			TotalServices = 0,
			OnScriptsInitialized = Signal.New(),
			OnScriptsLoaded = Signal.New(),
			IsInitialized = false,
			WaitOnServer = true,
		} :: Bootstrapper,
		Bootstrapper
	)
end

local Singleton = New("Global")

return setmetatable({ New = New }, {
	__index = function(proxy, key)
		-- this would break if the instantiatable class has an extra key that singleton does not have, so for that you would need
		-- to add either the key to table or just use the instantiable version :)
		local value: any = Singleton[key]

		-- redirecting the dot-colon functionality
		if type(value) == "function" then
			-- return a wrapper after index invoke "table.index"
			return function(firstArg, ...)
				-- to find out if the user is 'using' the colon method we check the first argument
				--  exports:Method == exports.Method(exports), so the first argument is the proxy which means the user if using the colon method
				-- firstarg (exports:Method) = exports
				-- exports:Method <-- key and gives "exports" as the proxy. exports.Method(exports <-- firstArg)
				if firstArg == proxy then
					-- colon call: exports:Method(a, b)
					-- executing function "table.index()"
					return value(Singleton, ...)
				else
					-- this is where the other
					-- dot call: exports.Method(a, b)
					return value(firstArg, ...)
				end
			end
		end

		return value
	end,

	__call = function(_, name: string)
		return New(name)
	end,
})
