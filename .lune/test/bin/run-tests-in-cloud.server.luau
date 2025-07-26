local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Jest = require(ReplicatedStorage.Packages.Jest)

local processServiceExists, ProcessService = pcall(function()
	-- selene: allow(incorrect_standard_library_use)
	return game:GetService("ProcessService")
end)

local status, result = Jest.runCLI(ReplicatedStorage.Packages, {
	ci = false,
	verbose = false,

	testMatch = { "**/*.spec" },
}, {
	ReplicatedStorage.Packages.CameraProfiler,
	ReplicatedStorage.Packages.Console,
}):awaitStatus()

if status == "Rejected" then
	print(result)

	ProcessService:ExitAsync(1)
end

if status == "Resolved" and result.results.numFailedTestSuites == 0 and result.results.numFailedTests == 0 then
	if processServiceExists then
		ProcessService:ExitAsync(0)
	end
end

return nil
