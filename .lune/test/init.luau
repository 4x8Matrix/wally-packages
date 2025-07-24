local fs = require("@lune/fs")
local process = require("@lune/process")

local ROBLOX_OC_KEY = process.args[1]

local buildAndUploadPlace = require("./test/util/buildAndUploadPlace")
local executeLuauTask = require("./test/util/executeLuauTask")

local testConfig = require("../test-config")

local function main()
    local jestScript = fs.readFile(".lune/test/bin/run-tests-in-cloud.server.luau")

    local uploadResult = buildAndUploadPlace({
        universeId = testConfig.universeId,
        placeId = testConfig.placeId,
        apiKey = ROBLOX_OC_KEY,
        filePath = testConfig.testPlaceFile,
        rojoProjectFile = testConfig.rojoProjectFile,
    })

    if uploadResult then
        local passed = executeLuauTask({
            universeId = testConfig.universeId,
            placeId = testConfig.placeId,
            placeVersion = uploadResult.versionNumber,
            apiKey = ROBLOX_OC_KEY,
            script = jestScript,
        })

        if not passed then
            process.exit(1)
            return
        end
    end

    -- Explicitly exit because Lune sucks at async tasks
    process.exit(0)
end

return main()