--# selene: allow(incorrect_standard_library_use)

local process = require("@lune/process")
local fs = require("@lune/fs")

local function execute(application, arguments, spawnOptions): string
	local result = process.exec(application, arguments, spawnOptions)

	if not result.ok then
		print(`Executing application '{application}' failed: '{result.stderr}'`)

		return process.exit(result.code)
	end

	return result.stdout
end

local function main()
	if not fs.isDir("binaries") then
		fs.writeDir("binaries")
	end

	for _, packageName in fs.readDir("packages") do
		execute("wally", { "install" }, { cwd = `packages/{packageName}` })
		execute("rojo", { "build", "-o", `../../binaries/{packageName}.rbxm` }, { cwd = `packages/{packageName}` })

		print(`[Build-Projects]: project '{packageName}' built OK`)
	end
end

return main()