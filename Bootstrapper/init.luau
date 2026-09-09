local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local NetLib = require(script.Parent.NetLib)

local Signal = require(ReplicatedStorage.LoomLib.Signal)
local IsInitialized = false

local _serviceFolders: { Instance } = {}
local OnScriptsInitialized = Signal.New() :: Signal.Signal<string, number>

-- Only Services that are services aka things that initialize once, run for the whole session, and have no constructor arguments.
local runContext: "server" | "client" = if RunService:IsServer() then "server" else "client"

-- Source - https://stackoverflow.com/a/1252776
-- Posted by Norman Ramsey, modified by community.
-- Retrieved 2026-03-05, License - CC BY-SA 4.0
local next = next
local OnPlayerdataLoaded = NetLib:DefineChannel("OnPlayerdataLoaded")
-- :SetConfig({ capacity = 1, timeoutDuration = math.huge, refillRate = 0.001 })

local CurrentCount = 0
local Bootstrapper = {}
Bootstrapper.OnScriptsLoaded = Signal.New()
Bootstrapper.TotalServices = 0

Bootstrapper["Services"] = {}

local function loadModule(ServicesModule): string?
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
		warn("[Bootstrapper] Module '" .. moduleName .. "' returned an empty table.")
		return nil
	end

	print("Module '" .. moduleName .. "' successfully loaded!")

	Bootstrapper["Services"][moduleName] = moduleContent
	return moduleName
end

local function FetchServices()
	for _, folder in ipairs(_serviceFolders) do
		for _, module in pairs(folder:GetDescendants()) do
			if module:IsA("ModuleScript") then
				local _m = loadModule(module)
				if _m then
					Bootstrapper.TotalServices += 1
				end
			end
		end
	end
end

local function InitializeService(serviceName: string, calledFrom: string?)
	local service = Bootstrapper.Services[serviceName]

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
			InitializeService(dependencyName, serviceName)
			service[dependencyName] = Bootstrapper.Services[dependencyName]
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

	CurrentCount += 1
	OnScriptsInitialized:Fire(serviceName, CurrentCount)
	service.Initialized = true
	service.Initializing = false
end

local function InvokeServices()
	for serviceName in pairs(Bootstrapper["Services"]) do
		InitializeService(serviceName)
	end
end

function Bootstrapper.GetService(name)
	local module = Bootstrapper["Services"][name]
	if not module then
		error("The module with the name: " .. name .. " doesn't exist!")
	end
	return module
end

function Bootstrapper.RegisterService(ServicesModule: ModuleScript)
	if IsInitialized then
		error("bootstrapper has already been initiallized, you have to register before invoking the initilaize method!")
		return
	end
	if ServicesModule:IsA("ModuleScript") then
		loadModule(ServicesModule)
	end
end

local function RunInit()
	FetchServices()
	InvokeServices()

	IsInitialized = true
	if runContext == "server" then
		script:SetAttribute("ServerInitialized", true)
	elseif runContext == "client" then
		script:SetAttribute("ClientInitialized", true)
	end

	print("Services loaded for: " .. runContext)
end

function Bootstrapper.Initialize(serviceFolders: { Instance }?)
	if IsInitialized then
		return
	end

	if serviceFolders then
		for _, folder in ipairs(serviceFolders) do
			assert(folder:IsA("Folder"), "Bootstrapper: expected Folder, got " .. folder.ClassName)
		end

		_serviceFolders = serviceFolders
	end

	if runContext == "client" then
		local isInit = script:GetAttribute("ServerInitialized")

		if not isInit then
			script:GetAttributeChangedSignal("ServerInitialized"):Wait()
		end
		RunInit()
		OnPlayerdataLoaded:SendToServer()
	end

	if runContext == "server" then
		OnPlayerdataLoaded.OnServerEvent:Connect(function(player: Player)
			Bootstrapper.OnScriptsLoaded:Fire(player)
		end)
		RunInit()
	end
end

export type Bootstrapper = typeof(Bootstrapper)

return Bootstrapper
