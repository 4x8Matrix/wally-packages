--[=[
	@class Logger

	The `Logger` class provides a highly configurable logging system for Luau, supporting:
	- Multiple log levels (Debug, Info, Notice, Warn, Error, etc.)
	- ANSI color formatting (for compatible environments)
	- Timestamps and traceback inclusion
	- Per-script and global logger configurations
	- Rich object serialization and formatting

	Logger is designed for use in both development tooling and in-engine debugging (e.g. Roblox).

	## Basic Usage

	```lua
	local logger = Console.new("MyScript")

	logger:Info("Hello, world!")
	logger:Warn("This is a warning!")
	logger:Error("This is an error.")
	```

	## Custom Configuration

	```lua
	local logger = Console.new("MyGameScript", {
		LogLevel = "Info",
		Timestamps = true,
		ANSI = true,
		Tracebacks = true,
		Format = "[%*][%*][%*][%*]: %*%*%*",
	})
	```
]=]

--[=[
	@prop Name string
	@within Logger
	The name of this logger instance, used for configuration routing and logging output.
]=]

--[=[
	@method Debug
	@within Logger
	@param ... any
	@return ()

	Logs a debug message (priority 7). Used during development; typically suppressed in production.
]=]

--[=[
	@method Info
	@within Logger
	@param ... any
	@return ()

	Logs an informational message (priority 6). Useful for tracking general application events.
]=]

--[=[
	@method Notice
	@within Logger
	@param ... any
	@return ()

	Logs a notice message (priority 5). Indicates noteworthy events that are not errors.
]=]

--[=[
	@method Warn
	@within Logger
	@param ... any
	@return ()

	Logs a warning message (priority 4). Something unexpected occurred, but the application can continue.
]=]

--[=[
	@method Error
	@within Logger
	@param ... any
	@return ()

	Logs an error message (priority 3). Indicates application errors.
]=]

--[=[
	@method Critical
	@within Logger
	@param ... any
	@return ()

	Logs a critical error (priority 2). Indicates severe issues like subsystem failure.
]=]

--[=[
	@method Alert
	@within Logger
	@param ... any
	@return ()

	Logs an alert (priority 1). Requires immediate attention, such as a corrupted database.
]=]

--[=[
	@method Emergency
	@within Logger
	@param ... any
	@return ()

	Logs an emergency (priority 0). System is unusable.
]=]

--[=[
	@method Stringify
	@within Logger
	@param value any
	@return string

	Converts the provided value to a human-readable string with type annotations and formatting.
	Supports primitives, Roblox instances, CFrames, tables, and more.
]=]

--[=[
	@method Configure
	@within Logger
	@param config Configuration
	@return ()

	Applies per-instance configuration overrides for this logger.
	Useful for setting ANSI, format string, log level, etc. for just one logger.
]=]