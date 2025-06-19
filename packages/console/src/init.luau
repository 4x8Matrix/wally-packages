local DIM = "\27\91\50\109"
local BOLD = "\27\91\49\109"

local RESET = "\27\91\48\109"

local CYAN = "\27\91\51\54\109"
local BLUE = "\27\91\51\52\109"
local YELLOW = "\27\91\51\51\109"
local RED = "\27\91\51\49\109"

local LOG_LEVEL_COLORS = {
	["Debug"] = `{DIM}`,
	["Info"] = `{CYAN}`,
	["Notice"] = `{BLUE}`,
	["Warn"] = `{YELLOW}`,
	["Error"] = `{RED}`,
	["Critical"] = `{RED}`,
	["Alert"] = `{BOLD}{RED}`,
	["Emergency"] = `{BOLD}{RED}`,
}

local LOG_LEVEL_PRIORITIES = { "Debug", "Info", "Notice", "Warn", "Error", "Critical", "Alert", "Emergency" }

local configurations: { [string]: Configuration } = {}
local globalConfiguration = {
	LogLevel = "Debug",
	Format = "%*[%*][%*][%*]: %*%*%*",
	Timestamps = false,
	ANSI = false,
	Tracebacks = false,
}

--[=[
    @class Console

    A comprehensive logging package for Luau, providing configurable logging levels, formatted output, ANSI color support (won't work in Roblox),
    timestamps, and traceback integration - it's intention is to make what limited control we have over the output, easier to work with.

    This console library implements the following APIs as to remain in parity with the following document:
        - https://www.sumologic.com/glossary/log-levels

    Simple usage of this library:
    ```luau
    Console:Debug("This is a debug message.")
    Console:Info("This is an informational message.")
    Console:Warn("This is a warning!")
    Console:Error("Something went wrong!")
    ```

    Configuration of this library:
    ```luau
    Console:Configure({
        LogLevel = "Info", -- Only show messages at Info level or higher
        Timestamps = true, -- Enable timestamps
        ANSI = true,       -- Enable ANSI colors (requires an ANSI-compatible console)
        Name = "MyAwesomeScript", -- Custom name for the logger instance
        Format = "[%*][%*][%*][%*]: %*%*%*" -- Custom format string (see Console.Configure for details)
    })

    Console:Debug("This debug message will not appear due to LogLevel configuration.")
    Console:Info("This info message will appear with timestamp and ANSI colors.")
    ```

    Advanced usage of this library:
    ```luau
    Console:Debug("My Part:", workspace.Part)
    Console:Info("Player Position:", game.Players.LocalPlayer.Character.HumanoidRootPart.Position)
    Console:Warn("Configuration Table:", { enabled = true, maxAttempts = 5, data = { a = 1, b = "hello" } })
    ```
]=]
local Console = {}

Console.Prototype = {}
Console.Public = {}

--[[
    Responsible for taking an input of any type, and formatting it in a way which makes it human readable.
]]
local function formatValue(value: any, config: Configuration, seen: { [{}]: boolean }?): string
	local type = typeof(value)

	if type == "table" then
		local seenStore = seen or {}

		if seenStore[value] then
			return "*** cycle table reference detected ***"
		end

		seenStore[value] = true

		local parts = {}

		for valueKey, valueValue in value do
			local key = formatValue(valueKey, config, seenStore)
			local formattedVal = formatValue(valueValue, config, seenStore)

			table.insert(parts, string.format("[%*] = %*", key, formattedVal))
		end

		return "{" .. table.concat(parts, ", ") .. "}"
	elseif type == "string" then
		return string.format('"%*"', tostring(value))
	elseif type == "Instance" then
		return string.format("Instance<'%*'>", tostring(value))
	elseif type == "EnumItem" then
		return string.format("EnumItem<'%*.%*'>", value.EnumType.Name, value.Name)
	elseif type == "CFrame" then
		local x, y, z = value.X, value.Y, value.Z
		local r00, r01, r02, r10, r11, r12, r20, r21, r22 = value:GetComponents()
		return string.format(
			"CFrame<'Pos:(%.2f,%.2f,%.2f) Rot:[%.2f %.2f %.2f; %.2f %.2f %.2f; %.2f %.2f %.2f]'>",
			x,
			y,
			z,
			r00,
			r01,
			r02,
			r10,
			r11,
			r12,
			r20,
			r21,
			r22
		)
	elseif type == "Vector3" then
		return string.format("Vector3<'X:%.2f,Y:%.2f,Z:%.2f'>", value.X, value.Y, value.Z)
	elseif type == "Vector2" then
		return string.format("Vector2<'X:%.2f,Y:%.2f'>", value.X, value.Y)
	elseif type == "UDim" then
		return string.format("UDim<'Scale:%.2f,Offset:%*'>", value.Scale, value.Offset)
	elseif type == "UDim2" then
		return string.format(
			"UDim2<'X:Scale%.2f+Offset%*, Y:Scale%.2f+Offset%*'>",
			value.X.Scale,
			value.X.Offset,
			value.Y.Scale,
			value.Y.Offset
		)
	elseif type == "Color3" then
		return string.format("Color3<'R:%.2f,G:%.2f,B:%.2f'>", value.R, value.G, value.B)
	elseif type == "BrickColor" then
		return string.format("BrickColor<'%*'>", value.Name)
	elseif type == "NumberRange" then
		return string.format("NumberRange<'Min:%.2f,Max:%.2f'>", value.Min, value.Max)
	elseif type == "NumberSequence" then
		return string.format("NumberSequence<'%* points'>", #value.Keypoints)
	elseif type == "ColorSequence" then
		return string.format("ColorSequence<'%* points'>", #value.Keypoints)
	elseif type == "Rect" then
		return string.format(
			"Rect<'Min:(%.2f,%.2f),Max:(%.2f,%.2f)'>",
			value.Min.X,
			value.Min.Y,
			value.Max.X,
			value.Max.Y
		)
	elseif type == "Ray" then
		return string.format(
			"Ray<'Origin:(%.2f,%.2f,%.2f),Dir:(%.2f,%.2f,%.2f)'>",
			value.Origin.X,
			value.Origin.Y,
			value.Origin.Z,
			value.Direction.X,
			value.Direction.Y,
			value.Direction.Z
		)
	elseif type == "Region3" then
		local min, max = value.CFrame.Position - value.Size / 2, value.CFrame.Position + value.Size / 2
		return string.format(
			"Region3<'Min:(%.2f,%.2f,%.2f),Max:(%.2f,%.2f,%.2f)'>",
			min.X,
			min.Y,
			min.Z,
			max.X,
			max.Y,
			max.Z
		)
	end

	-- Fallback for primitive Luau types: nil, boolean, number, string, function, thread, userdata
	return tostring(value)
end

--[[
    Responsible for taking in an array of unknown types, will then format - and return a concatenated version
    of these unknown types merged together.
]]
local function stringify(configuration: Configuration, ...): string
	local values = {}

	for _, object in { ... } do
		table.insert(values, formatValue(object, configuration))
	end

	return table.concat(values, " ")
end

--[[
    Will return the configuration for the script that is calling a function in the Console library.
]]
local function getScriptConfiguration(hash: string): Configuration
	if not configurations[hash] then
		configurations[hash] = {}
	end

	return configurations[hash]
end

--[[
    Will fetch the name of this script, supports Unix, Windows and Roblox paths.

    If this fails, it'll fallback to returning the full path name.
]]
local function getScriptName(hash: string): string
	return hash
end

--[[
    Will construct the message that you'll see in the output.
]]
local function constructContent(hash: string, ...): string
	local configuration = getScriptConfiguration(hash)
	local scriptName = getScriptName(hash)
	local logLevel = debug.info(2, "n")
	local message = stringify(configuration, ...)
	local format = configuration.Format or globalConfiguration.Format
	local ansiEnabled = configuration.ANSI or globalConfiguration.ANSI
	local timestampsEnabled = configuration.Timestamps or globalConfiguration.Timestamps
	local tracebackEnabled = configuration.Tracebacks or globalConfiguration.Tracebacks
	local timestamp = os.date("%Y-%m-%d %H:%M:%S", os.time())

	local content = string.format(
		format,
		`{ansiEnabled and LOG_LEVEL_COLORS[logLevel] or ``}`,
		`{timestampsEnabled and `{timestamp}` or `-`}`,
		`{configuration.Name or scriptName}`,
		logLevel,
		message,
		`{ansiEnabled and RESET or ""}`,
		`{tracebackEnabled and `\n{debug.traceback("", 3)}` or ``}`
	)

	return content
end

--[[
    returns a boolean that defines if the API that calls this function is able to log to the output.
]]
local function meetsLogLevelRequirement(hash: string): boolean
	local configuration = getScriptConfiguration(hash)
	local targetLoglevel = configuration.LogLevel or globalConfiguration.LogLevel
	local targetLoglevelPriority = table.find(LOG_LEVEL_PRIORITIES, targetLoglevel)
	local currentLogLevel = debug.info(2, "n")
	local currentLogLevelPriority = table.find(LOG_LEVEL_PRIORITIES, currentLogLevel)

	return currentLogLevelPriority >= targetLoglevelPriority
end

--[=[
    @within Console

    Will take a value, and return the stringified version of said value.
]=]
function Console.Prototype.Stringify(self: Console, value): string
	return stringify(getScriptConfiguration(self.Name), value)
end

--[=[
    @within Console

    Debug logs are given the numerical value “7.” These logs typically contain information that is only useful
    during the debug phase and may be of little value during production.
]=]
function Console.Prototype.Debug(self: Console, ...)
	if meetsLogLevelRequirement(self.Name) then
		local content = constructContent(self.Name, ...)

		print(content)
	end
end

--[=[
    @within Console

    Informational logs are given the numerical value “6.” They include information about successful operations
    within the application, such as a successful start, pause, or exit of the application.
]=]
function Console.Prototype.Info(self: Console, ...)
	if meetsLogLevelRequirement(self.Name) then
		local content = constructContent(self.Name, ...)

		print(content)
	end
end

--[=[
    @within Console

    Notice logs are given the numerical value “5.” They include information about events that may be unusual but
    are not errors. Notice logs are technically normal, but still significant enough to have their own severity
    level between information and warning.
]=]
function Console.Prototype.Notice(self: Console, ...)
	if meetsLogLevelRequirement(self.Name) then
		local content = constructContent(self.Name, ...)

		print(content)
	end
end

--[=[
    @within Console

    Warning logs are given the numerical value “4.” Warning conditions are slightly less severe than error conditions.
    Error conditions happen when an operation fails, while a warning might indicate that an operation will fail in the
    future if action is not taken now.
]=]
function Console.Prototype.Warn(self: Console, ...)
	if meetsLogLevelRequirement(self.Name) then
		local content = constructContent(self.Name, ...)

		warn(content)
	end
end

--[=[
    @within Console

    Error logs are given the numerical value “3.” This category is assigned to event logs that contain an application
    error message.
]=]
function Console.Prototype.Error(self: Console, ...)
	if meetsLogLevelRequirement(self.Name) then
		local content = constructContent(self.Name, ...)

		error(content, math.huge)
	end
end

--[=[
    @within Console

    Critical logs are given the numerical value “2.” This category is assigned for critical errors, such as hardware
    failure.
]=]
function Console.Prototype.Critical(self: Console, ...)
	if meetsLogLevelRequirement(self.Name) then
		local content = constructContent(self.Name, ...)

		error(content, math.huge)
	end
end

--[=[
    @within Console

    Alert logs are given the numerical value “1.” This category is assigned when an event log requires an immediate
    response, such as when a system database becomes corrupted and must be restored to prevent the loss of critical
    data or services.
]=]
function Console.Prototype.Alert(self: Console, ...)
	if meetsLogLevelRequirement(self.Name) then
		local content = constructContent(self.Name, ...)

		error(content, math.huge)
	end
end

--[=[
    @within Console

    Emergency logs are given the numerical value “0”. This category is assigned when an event log indicates that the
    system is completely unusable.
]=]
function Console.Prototype.Emergency(self: Console, ...)
	if meetsLogLevelRequirement(self.Name) then
		local content = constructContent(self.Name, ...)

		error(content, math.huge)
	end
end

--[=[
    @within Console

    Configures the logging behavior specifically for the **calling script**.
    Each script maintains its own configuration, allowing for granular control over its logging output.
    Settings applied here will override any global defaults set by `Console.SetDefaults`.
]=]
function Console.Prototype.Configure(self: Console, config: Configuration)
	local scriptConfig = getScriptConfiguration(self.Name)

	for key, value in config do
		scriptConfig[key] = value
	end
end

--[=[
    @within Console

    Establishes the **global default configuration** for the Console logger.
    These defaults apply to all scripts that use the Console package unless a script
    explicitly overrides them using `Console.Configure()`.
]=]
function Console.Public.setDefaults(config: Configuration)
	for key, value in config do
		if globalConfiguration[key] ~= nil then
			globalConfiguration[key] = value
		end
	end
end

--[=[
    @within Console

	Will instantiate a new console object, this is how you'll communicate with the 
	console library.
]=]
function Console.Public.new(name: string, config: Configuration?)
	local object = setmetatable(
		{
			Name = name,
		} :: Console,
		{ __index = Console.Prototype }
	)

	if config then
		object:Configure(config)
	end

	return object
end

export type LogLevel = "Debug" | "Info" | "Notice" | "Warn" | "Error" | "Critical" | "Alert" | "Emergency"
export type Configuration = {
	LogLevel: LogLevel?,
	Format: string?,
	Name: string?,

	Tracebacks: boolean?,
	Timestamps: boolean?,
	ANSI: boolean?,
}
export type Console = typeof(Console.Prototype) & {
	Name: string,
}

return Console.Public
