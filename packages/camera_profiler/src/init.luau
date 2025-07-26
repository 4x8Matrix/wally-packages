local Signal = require(script.Parent.Signal)

local baseCameraInstance = workspace.CurrentCamera:Clone()

local profiles: { [string]: Profile } = {}
local activeProfile: Profile?

--[=[
	@class CameraProfiler
	@__index CameraProfiler.Prototype

	The Camera Profiler package represents a singleton that you can use to better leverage the Camera system wihin the Roblox Environment. This camera system
	works through setting `Workspace.CurrentCamera` to the camera the developer wants to see.

	Example of how you would create a profile
	```luau
	local BlimpCameraProfile = CameraProfiler:Profile({
		Name = "BlimpCamera"
	})

	function BlimpCameraProfile.Construct(self: BlimpCameraProfile)
		print("Setup blimp camera variables!")
	end

	function BlimpCameraProfile.Start(self: BlimpCameraProfile)
		print("Camera started, do things!")
	end

	function BlimpCameraProfile.Stop(self: BlimpCameraProfile)
		print("Camera stopped, clean things up!")
	end

	export type BlimpCameraProfile = typeof(BlimpCameraProfile)

	return BlimpCameraProfile
	```

	Example of how you would use the newly created profile
	```luau
	CameraProfiler:Set("BlimpCamera")
	```

	Example of how you would integrate a Profile with the default Camera Roblox creates.
	```luau
	local DefaultCameraProfile = CameraProfiler:Profile({
		Name = "DefaultCamera"
	}, workspace.CurrentCamera)
	```
]=]
local CameraProfiler = {}

--[[
	@prop CameraStarted Signal<Name: string>
	@within CameraProfiler

	 This signal is fired after a camera has started.
]]
CameraProfiler.CameraStarted = Signal.new()

--[[
	@prop CameraStopped Signal<Name: string>
	@within CameraProfiler

	This signal is fired after a camera has stopped.
]]
CameraProfiler.CameraStopped = Signal.new()

--[[
	Simple function for calling the lifecycles of an object, the object in this case represents a table.
]]
local function callLifecycle(object: TableLike, lifecycle: string)
	if object[lifecycle] then
		object[lifecycle](object)
	end
end

--[=[
	@method Profile
	@within CameraProfiler

	Call this function to register your camera profile, a camera profile is a Roblox table that wraps around a camera instance, the goal of this table
		is to make interacting and handling with cameras easier within the engine.

	Example:
	```luau
	local CameraProfile = CameraProfiler:Profile({
		Name = "CameraProfile"
	})

	function CameraProfile.Construct(self: CameraProfile)
		...
	end

	export type CameraProfile = typeof(CameraProfile)

	return CameraProfile
	```
]=]
function CameraProfiler.Profile(
	self: CameraProfiler,
	profilePrototype: ProfilePrototype,
	cameraInstance: Camera?
): Profile
	assert(profiles[profilePrototype.Name] == nil, `Profile: '{profilePrototype.Name}' already exists!`)

	local camera: Camera = cameraInstance or baseCameraInstance:Clone()

	camera.Name = `CameraProfile<'{profilePrototype.Name}'>`

	local profile: Profile = {
		Instance = camera,

		Name = profilePrototype.Name,
		Construct = profilePrototype.Construct,
		Start = profilePrototype.Start,
		Stop = profilePrototype.Stop,

		Destroy = function()
			if activeProfile == profiles[profilePrototype.Name] then
				callLifecycle(profiles[profilePrototype.Name], "Stop")

				self.CameraStopped:FireDeferred(profilePrototype.Name)

				activeProfile = nil
			end

			profiles[profilePrototype.Name] = nil
		end,
	}

	profiles[profilePrototype.Name] = profile

	task.defer(function()
		callLifecycle(profile, "Construct")

		if workspace.CurrentCamera == profile.Instance then
			callLifecycle(profile, "Start")
			self.CameraStarted:FireDeferred(profile.Name)
		end
	end)

	return profile
end

--[=[
	@method Set
	@within CameraProfiler

	Will set what the active camera should be, sideeffects of calling this method are:
		- Will call the `Stop` lifecycle on the current camera instance.
		- Will set the `Workspace.CurrentCamera` property to the updated camera instance.
		- Will call the `Start` lifecycleo n the new camera instance. 
]=]
function CameraProfiler.Set(self: CameraProfiler, profileName: string): ()
	local newProfile = profiles[profileName]
	local oldProfile = activeProfile

	assert(newProfile, `Camera '{profileName}' not found!`)

	if oldProfile == newProfile then
		return
	end

	if oldProfile then
		callLifecycle(oldProfile, "Stop")
		self.CameraStopped:FireDeferred(oldProfile.Name)
	end

	activeProfile = newProfile

	callLifecycle(newProfile, "Start")
	self.CameraStarted:FireDeferred(newProfile.Name)

	newProfile.Instance.Parent = workspace
	-- selene: allow(incorrect_standard_library_use)
	workspace.CurrentCamera = newProfile.Instance
end

--[=[
	@method Get
	@within CameraProfiler

	Will return the name of the currently active camera, or nil.
]=]
function CameraProfiler.Get(_: CameraProfiler): string?
	return activeProfile and activeProfile.Name
end

export type TableLike = { [any]: any }
export type CameraProfiler = typeof(CameraProfiler)

export type Profile = ProfilePrototype & {
	Instance: Camera,

	Destroy: (self: Profile) -> (),
}

export type ProfilePrototype = {
	Name: string,

	Construct: ((self: Profile) -> ())?,
	Start: ((self: Profile) -> ())?,
	Stop: ((self: Profile) -> ())?,
}

return CameraProfiler
