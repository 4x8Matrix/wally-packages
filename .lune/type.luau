--# selene: allow(incorrect_standard_library_use)

local process = require("@lune/process")
local net = require("@lune/net")
local fs = require("@lune/fs")

local TYPE_CHECK_ENABLED = true

local function execute(application, arguments, spawnOptions): string
	local result = process.exec(application, arguments, spawnOptions)

	if not result.ok then
		print(`Executing application '{application}' failed: '{result.stderr}'`)

		return process.exit(result.code)
	end

	return result.stdout
end

local function downloadRobloxTypes(): ()
	local response = net.request({
		url = "https://raw.githubusercontent.com/JohnnyMorganz/luau-lsp/main/scripts/globalTypes.d.lua",
		method = "GET",
	})

	if not response.ok then
		print(`Failed to publish to Roblox: {response.statusCode} - '{response.statusMessage}'`)

		return process.exit(1)
	end

	fs.writeFile("roblox.d.lua", response.body)

	return
end

local function main()
	if not fs.isFile("roblox.d.lua") then
		downloadRobloxTypes()
	end

	execute("pesde", {
		"install",
	})

	execute("rojo", {
		"sourcemap",
		`test.project.json`,
		"-o",
		`sourcemap.json`,
	})

	execute("luaulsp", {
		"analyze",
		"--defs=roblox.d.lua",
		`--sourcemap=sourcemap.json`,
		`--base-luaurc=.luaurc`,
		`--platform=roblox`,
		`--settings=.vscode/settings.json`,
		`packages/`,
	})

	print(`[Type-Projects]: projects pass luau lsp OK`)
end

if TYPE_CHECK_ENABLED then
	return main()
end
