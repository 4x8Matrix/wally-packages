--[=[
	@class Profile

	The `Profile` class represents a camera wrapper that follows a basic lifecycle. These profiles are used with the `CameraProfiler`
	system to manage multiple camera states in Roblox. Each profile is tied to a camera instance and can implement optional lifecycle
	methods like `Construct`, `Start`, and `Stop`.

	You can define custom profiles using `CameraProfiler:Profile()` and implementing optional methods for setup and teardown.

	Example:
	```lua
	local MyProfile = CameraProfiler:Profile({
		Name = "MyCamera"
	})

	function MyProfile.Construct(self)
		print("Setup camera.")
	end

	function MyProfile.Start(self)
		print("Camera active.")
	end

	function MyProfile.Stop(self)
		print("Camera stopping.")
	end

	return MyProfile
	```
]=]

--[=[
	@prop Instance Camera
	@within Profile

	The actual `Camera` instance associated with this profile. This is the object that will be set as `workspace.CurrentCamera`
	when the profile is activated.
]=]

--[=[
	@prop Name string
	@within Profile

	The name of the camera profile. Used to identify and switch between profiles via `CameraProfiler:Set(name)`.
]=]

--[=[
	@method Construct
	@within Profile

	Optional lifecycle method.

	Called once after the profile is created and added to the `CameraProfiler`. Use this for initialization logic such as
	variable setup or preparing the camera instance.
]=]

--[=[
	@method Start
	@within Profile

	Optional lifecycle method.

	Called when this camera profile becomes the active one (i.e., when `CameraProfiler:Set(name)` is called with this profile's name).
	Used to begin camera behaviors or transitions.
]=]

--[=[
	@method Stop
	@within Profile

	Optional lifecycle method.

	Called when this camera profile is no longer the active camera. Used to clean up behaviors or reset state as needed.
]=]

--[=[
	@method Destroy
	@within Profile

	Removes this profile from the `CameraProfiler`. If it was the active camera, the profile's `Stop` lifecycle is called,
	the `CameraStopped` signal is fired, and the active camera reference is cleared.
]=]
