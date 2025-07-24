local net = require("@lune/net")
local serde = require("@lune/serde")
local stdio = require("@lune/stdio")
local task = require("@lune/task")

local types = require("../types")

local BASE_URL = "https://apis.roblox.com"

type LuauExecutionSessionTask = types.LuauExecutionSessionTask
type LuauExecutionSessionTaskLog = types.LuauExecutionSessionTaskLog

type Array<T> = { T }

export type ExecuteTaskOptions = {
    universeId: number,
    placeId: number,
    placeVersion: number,

    apiKey: string,

    script: string,
}

return function(options: ExecuteTaskOptions)
    local universeId = options.universeId
    local placeId = options.placeId
    local placeVersion = options.placeVersion
    local apiKey = options.apiKey
    local script = options.script

    local executionTask: LuauExecutionSessionTask? = nil

    local function createTaskAsync(): boolean
        local res = net.request({
            url = `{BASE_URL}/cloud/v2/universes/{universeId}/places/{placeId}/versions/{placeVersion}/luau-execution-session-tasks`,
            method = "POST",
            body = serde.encode("json", {
                script = script,
            }),
            headers = {
                ["x-api-key"] = apiKey,
                ["Content-Type"] = "application/json",
                ["Accept"] = "application/json",
            },
        })

        local decodedBody = serde.decode("json", res.body)
        if res.ok then
            executionTask = decodedBody
            return true
        else
            warn(`Failed to create execution task ({res.statusMessage})`)
            print(decodedBody)
            return false
        end
    end

    local function pollForTaskCompletionAsync(): boolean
        if executionTask == nil then
            error("Execution task is nil")
        end

        while true do
            local res = net.request({
                url = `{BASE_URL}/cloud/v2/{executionTask.path}`,
                method = "GET",
                headers = {
                    ["x-api-key"] = apiKey,
                    ["Accept"] = "application/json",
                },
            })

            local decodedBody = serde.decode("json", res.body)
            if not res.ok then
                warn(`Execution task failed`)
                print(decodedBody)
                return false
            end

            executionTask = decodedBody
            if executionTask.state ~= "PROCESSING" and executionTask.state ~= "QUEUED" then
                return executionTask.state == "COMPLETE"
            end

            task.wait(1)
        end
    end

    local function getTaskLogsAsync(): Array<string>
        if executionTask == nil then
            error("Execution task is nil")
        end

        local res = net.request({
            url = `{BASE_URL}/cloud/v2/{executionTask.path}/logs`,
            method = "GET",
            headers = {
                ["x-api-key"] = apiKey,
                ["Accept"] = "application/json",
            },
        })

        local decodedBody: LuauExecutionSessionTaskLog = serde.decode("json", res.body)
        if not res.ok then
            warn(`Failed to fetch task logs ({res.statusMessage})`)
            print(decodedBody)
            return {}
        end

        local logs: Array<string> = {}
        for _, log in decodedBody.luauExecutionSessionTaskLogs do
            for _, message in ipairs(log.messages) do
                table.insert(logs, message)
            end
        end

        return logs
    end

    local createTaskSuccess = createTaskAsync()
    if not createTaskSuccess then
        return false
    end

    local pollTaskSuccess = pollForTaskCompletionAsync()

    local logs = getTaskLogsAsync()
    for _, message in logs do
        stdio.write(message .. `\n`)
    end

    return pollTaskSuccess
end
