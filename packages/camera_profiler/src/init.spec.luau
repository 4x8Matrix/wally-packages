local ReplicatedStorage = game:GetService("ReplicatedStorage")

local JestGlobals = require(ReplicatedStorage.Packages.JestGlobals)

local BASE_CAMERA = workspace.CurrentCamera:Clone()

local mainModule = script.Parent
local clonedModule

local requiredModule = require(mainModule)

local describe = JestGlobals.describe :: (...any) -> ...any
local it = JestGlobals.it :: (...any) -> ...any
local expect = JestGlobals.expect :: (...any) -> ...any
local beforeEach = JestGlobals.beforeEach :: (...any) -> ...any
local afterEach = JestGlobals.afterEach :: (...any) -> ...any

beforeEach(function()
	local testCamera = BASE_CAMERA:Clone()

	testCamera.Name = `Test Camera`

	clonedModule = mainModule:Clone()
	clonedModule.Name = `Tmp`
	clonedModule.Parent = mainModule.Parent

	requiredModule = (require :: any)(clonedModule)

	--selene: allow(incorrect_standard_library_use)
	workspace.CurrentCamera = testCamera
end)

afterEach(function()
	clonedModule:Destroy()
end)

describe("Construction and Destruction of camera objects", function()
	it("should be able to construct a camera object", function()
		local camera = requiredModule:Profile({
			Name = "Profile",

			Construct = function() end,
			Start = function() end,
			Stop = function() end,
		})

		expect(camera).toBeTruthy()
		expect(camera.Name).toBe("Profile")
	end)

	it("should be able to construct a camera object around a camera instance", function()
		local instance = workspace.CurrentCamera
		local camera = requiredModule:Profile({
			Name = "Profile",

			Construct = function() end,
			Start = function() end,
			Stop = function() end,
		}, instance)

		expect(camera).toBeTruthy()
		expect(camera.Name).toBe("Profile")
		expect(camera.Instance).toBe(instance)
	end)

	it("should be able to deconstruct a camera object", function()
		local camera = requiredModule:Profile({
			Name = "Profile",

			Construct = function() end,
			Start = function() end,
			Stop = function() end,
		})

		requiredModule:Set("Profile")

		expect(requiredModule:Get()).toBeTruthy()

		camera:Destroy()

		expect(requiredModule:Get()).toBe(nil)
	end)
end)

describe("Standard cases for camera objects", function()
	it("should call the construct lifecycle when the camera object is constructed", function()
		local constructedCalled = false

		requiredModule:Profile({
			Name = "Profile",

			Construct = function()
				constructedCalled = true
			end,
		})

		expect(constructedCalled).toBe(false)

		task.wait()

		expect(constructedCalled).toBe(true)
	end)

	it("should call the start lifecycle when the camera is set to active.", function()
		local startCalled = false

		requiredModule:Profile({
			Name = "Profile",

			Start = function()
				startCalled = true
			end,
		})

		expect(startCalled).toBe(false)

		requiredModule:Set("Profile")

		expect(startCalled).toBe(true)
	end)

	it("should call the stop lifecycle when the active camera is changed", function()
		local startCalled = false
		local stopCalled = false

		requiredModule:Profile({
			Name = "ProfileA",

			Start = function()
				startCalled = true
			end,

			Stop = function()
				stopCalled = true
			end,
		})

		requiredModule:Profile({
			Name = "ProfileB",
		})

		expect(stopCalled).toBe(false)
		expect(startCalled).toBe(false)

		requiredModule:Set("ProfileA")

		expect(stopCalled).toBe(false)
		expect(startCalled).toBe(true)

		requiredModule:Set("ProfileB")

		expect(stopCalled).toBe(true)
		expect(startCalled).toBe(true)

		expect(requiredModule:Get()).toBe("ProfileB")
	end)

	it("camera started signal is fired a frame after the camera is set", function()
		local cameraSetTo = nil

		requiredModule:Profile({
			Name = "ProfileA",
		})

		local thread = task.spawn(function()
			cameraSetTo = requiredModule.CameraStarted:Wait()
		end)

		requiredModule:Set("ProfileA")

		expect(cameraSetTo).toBe(nil)

		task.wait()

		expect(cameraSetTo).toBe("ProfileA")

		task.cancel(thread)
	end)

	it("camera stopped signal is fired a frame after the camera is set to something else", function()
		local cameraSetTo = nil

		requiredModule:Profile({
			Name = "ProfileA",
		})

		requiredModule:Profile({
			Name = "ProfileB",
		})

		local thread = task.spawn(function()
			cameraSetTo = requiredModule.CameraStopped:Wait()
		end)

		requiredModule:Set("ProfileA")
		requiredModule:Set("ProfileB")

		expect(cameraSetTo).toBe(nil)

		task.wait()

		expect(cameraSetTo).toBe("ProfileA")

		task.cancel(thread)
	end)
end)

describe("Edge cases for camera objects", function()
	it("camera singleton should throw an error given an invalid value", function()
		expect(function()
			requiredModule:Set("IllegalCamera")
		end).toThrow()
	end)
end)

describe("Bugs that have been fixed", function() end)
