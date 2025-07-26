local LogService = game:GetService("LogService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local JestGlobals = require(ReplicatedStorage.Packages.JestGlobals)

local mainModule = script.Parent
local clonedModule

local requiredModule = require(mainModule)

local describe = JestGlobals.describe :: (...any) -> ...any
local it = JestGlobals.it :: (...any) -> ...any
local expect = JestGlobals.expect :: (...any) -> ...any
local beforeEach = JestGlobals.beforeEach :: (...any) -> ...any
local afterEach = JestGlobals.afterEach :: (...any) -> ...any

beforeEach(function()
	clonedModule = mainModule:Clone()
	clonedModule.Name = `Tmp`
	clonedModule.Parent = mainModule.Parent

	requiredModule = (require :: any)(clonedModule)
end)

afterEach(function()
	clonedModule:Destroy()
end)

describe("Standard cases for console objects", function()
	it("Is able to create a console object", function()
		local console = requiredModule.new("Console")

		expect(console).toBeTruthy()
	end)

	it("Is able to create a console object with a config", function()
		local console = requiredModule.new("Console", {
			LogLevel = "Debug",
			Format = "%*[%*][%*][%*]: %*%*%*",
			Timestamps = false,
			ANSI = false,
			Tracebacks = false,
		})

		expect(console).toBeTruthy()
	end)

	it("Is able to parse and write a stringified version of various datatypes", function()
		local console = requiredModule.new("Console")

		for value, expected in
			{
				[{ a = 1 }] = '{["a"] = 1}',
				[{ a = {} }] = '{["a"] = {}}',
				[Vector3.new(1, 5, 3)] = "Vector3<'X:1.00,Y:5.00,Z:3.00'>",
				[CFrame.new(6, 2, 2)] = "CFrame<'Pos:(6.00,2.00,2.00) Rot:[6.00 2.00 2.00; 1.00 0.00 0.00; 0.00 1.00 0.00]'>",
				[true] = "true",
				["YMCA"] = '"YMCA"',
				[game] = "Instance<'Game'>",
			} :: { [any]: string }
		do
			local parsed = console:Stringify(value)

			expect(parsed).toBe(expected)
		end
	end)

	it("Is able to parse and handle recursive datatypes", function()
		local console = requiredModule.new("Console")
		local value = {}

		value.a = value
		value.b = value
		value.c = value

		local parsed = console:Stringify(value)

		expect(parsed).toBe(
			'{["a"] = *** cycle table reference detected ***, ["c"] = *** cycle table reference detected ***, ["b"] = *** cycle table reference detected ***}'
		)
	end)

	it("Log levels are functional", function()
		local console = requiredModule.new("Console")

		console:Configure({
			LogLevel = "Error",
		})

		local capturedLog
		local messageType

		LogService.MessageOut:Once(function(...)
			capturedLog, messageType = ...
		end)

		console:Debug(`Test Function!`)

		task.spawn(function()
			console:Error(`Test Function!`)
		end)

		task.wait()

		expect(capturedLog).toBe('[-][Console][Error]: "Test Function!"')
		expect(messageType).toBe(Enum.MessageType.MessageError)
	end)

	describe("All general logging functions work as expected", function()
		it("Debug function works", function()
			local console = requiredModule.new("Console")
			local capturedLog
			local messageType

			LogService.MessageOut:Once(function(...)
				capturedLog, messageType = ...
			end)

			console:Debug(`Test Function!`)

			task.wait()

			expect(capturedLog).toBe('[-][Console][Debug]: "Test Function!"')
			expect(messageType).toBe(Enum.MessageType.MessageOutput)
		end)

		it("Info function works", function()
			local console = requiredModule.new("Console")
			local capturedLog
			local messageType

			LogService.MessageOut:Once(function(...)
				capturedLog, messageType = ...
			end)

			console:Info(`Test Function!`)

			task.wait()

			expect(capturedLog).toBe('[-][Console][Info]: "Test Function!"')
			expect(messageType).toBe(Enum.MessageType.MessageOutput)
		end)

		it("Notice function works", function()
			local console = requiredModule.new("Console")
			local capturedLog
			local messageType

			LogService.MessageOut:Once(function(...)
				capturedLog, messageType = ...
			end)

			console:Notice(`Test Function!`)

			task.wait()

			expect(capturedLog).toBe('[-][Console][Notice]: "Test Function!"')
			expect(messageType).toBe(Enum.MessageType.MessageOutput)
		end)

		it("Warn function works", function()
			local console = requiredModule.new("Console")
			local capturedLog
			local messageType

			LogService.MessageOut:Once(function(...)
				capturedLog, messageType = ...
			end)

			console:Warn(`Test Function!`)

			task.wait()

			expect(capturedLog).toBe('[-][Console][Warn]: "Test Function!"')
			expect(messageType).toBe(Enum.MessageType.MessageWarning)
		end)

		it("Error function works", function()
			local console = requiredModule.new("Console")
			local capturedLog
			local messageType

			LogService.MessageOut:Once(function(...)
				capturedLog, messageType = ...
			end)

			task.spawn(function()
				console:Error(`Test Function!`)
			end)

			expect(function()
				console:Error(`Test Function!`)
			end).toThrow()

			task.wait()

			expect(capturedLog).toBe('[-][Console][Error]: "Test Function!"')
			expect(messageType).toBe(Enum.MessageType.MessageError)
		end)

		it("Critical function works", function()
			local console = requiredModule.new("Console")
			local capturedLog
			local messageType

			LogService.MessageOut:Once(function(...)
				capturedLog, messageType = ...
			end)

			task.spawn(function()
				console:Critical(`Test Function!`)
			end)

			expect(function()
				console:Critical(`Test Function!`)
			end).toThrow()

			task.wait()

			expect(capturedLog).toBe('[-][Console][Critical]: "Test Function!"')
			expect(messageType).toBe(Enum.MessageType.MessageError)
		end)

		it("Alert function works", function()
			local console = requiredModule.new("Console")
			local capturedLog
			local messageType

			LogService.MessageOut:Once(function(...)
				capturedLog, messageType = ...
			end)

			task.spawn(function()
				console:Alert(`Test Function!`)
			end)

			expect(function()
				console:Alert(`Test Function!`)
			end).toThrow()

			task.wait()

			expect(capturedLog).toBe('[-][Console][Alert]: "Test Function!"')
			expect(messageType).toBe(Enum.MessageType.MessageError)
		end)

		it("Emergency function works", function()
			local console = requiredModule.new("Console")
			local capturedLog
			local messageType

			LogService.MessageOut:Once(function(...)
				capturedLog, messageType = ...
			end)

			task.spawn(function()
				console:Emergency(`Test Function!`)
			end)

			expect(function()
				console:Emergency(`Test Function!`)
			end).toThrow()

			task.wait()

			expect(capturedLog).toBe('[-][Console][Emergency]: "Test Function!"')
			expect(messageType).toBe(Enum.MessageType.MessageError)
		end)
	end)

	describe("Configurations are modifiable and have an effect", function()
		it("Should modify the custom Name and affect output", function()
			local console = requiredModule.new("Console")
			local capturedLog

			console:Configure({
				Name = "MyTestLogger",
			})

			LogService.MessageOut:Once(function(...)
				capturedLog = ...
			end)

			console:Info("Test")
			task.wait()

			expect(capturedLog).toBe('[-][MyTestLogger][Info]: "Test"')
		end)

		it("Should modify the Format and affect output", function()
			local console = requiredModule.new("Console")
			local capturedLog

			console:Configure({
				Format = "%*<%*|%*|%*> %* %*",
			})

			LogService.MessageOut:Once(function(...)
				capturedLog = ...
			end)

			console:Debug("Test")
			task.wait()

			expect(capturedLog).toBe('<-|Console|Debug> "Test" ')
		end)

		it("Should toggle Timestamps and affect output", function()
			local console = requiredModule.new("Console")
			local capturedLog

			console:Configure({
				Timestamps = true,
			})

			LogService.MessageOut:Once(function(...)
				capturedLog = ...
			end)

			console:Info("Test")
			task.wait()

			expect(string.match(capturedLog, "%d%d%d%d%-%d%d%-%d%d %d%d:%d%d:%d%d")).toBeTruthy()

			console:Configure({
				Timestamps = false,
			})

			LogService.MessageOut:Once(function(...)
				capturedLog = ...
			end)

			console:Info("Test")
			task.wait()

			expect(capturedLog).toBe('[-][Console][Info]: "Test"')
		end)

		it("Should toggle ANSI color codes and affect output", function()
			local console = requiredModule.new("Console")
			local capturedLog

			console:Configure({
				ANSI = true,
			})

			LogService.MessageOut:Once(function(...)
				capturedLog = ...
			end)

			console:Info("Test")
			task.wait()

			expect(string.find(capturedLog, "\27") ~= nil).toBe(true)

			console:Configure({
				ANSI = false,
			})

			LogService.MessageOut:Once(function(...)
				capturedLog = ...
			end)

			console:Info("Test")
			task.wait()

			expect(string.find(capturedLog, "\27") ~= nil).toBe(false)
		end)

		it("Should toggle Tracebacks and affect output", function()
			local console = requiredModule.new("Console")
			local capturedLog

			console:Configure({
				Tracebacks = true,
			})

			LogService.MessageOut:Once(function(...)
				capturedLog = ...
			end)

			console:Debug("Test")

			task.wait()

			expect(capturedLog ~= nil).toBe(true)
			expect(string.find(capturedLog, "stack traceback") ~= nil).toBe(true)

			capturedLog = nil

			console:Configure({
				Tracebacks = false,
			})

			LogService.MessageOut:Once(function(...)
				capturedLog = ...
			end)

			console:Debug("Test")

			task.wait()

			expect(capturedLog ~= nil).toBe(true)
			expect(string.find(capturedLog, "stack traceback") == nil).toBe(true)
		end)
	end)
end)

describe("Bugs that have been fixed", function() end)
