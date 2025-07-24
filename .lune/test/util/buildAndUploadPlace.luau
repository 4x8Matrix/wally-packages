local fs = require("@lune/fs")
local net = require("@lune/net")
local process = require("@lune/process")
local serde = require("@lune/serde")

export type BuildUploadPlaceOptions = {
	universeId: number,
	placeId: number,
	apiKey: string,
	filePath: string,
	rojoProjectFile: string,
}

export type BuildUploadPlaceResult = {
	versionNumber: number,
}

local function buildUploadPlaceAsync(options: BuildUploadPlaceOptions): BuildUploadPlaceResult?
	local universeId = options.universeId
	local placeId = options.placeId
	local apiKey = options.apiKey
	local filePath = options.filePath
	local rojoProjectFile = options.rojoProjectFile

	local function buildPlaceAsync(): boolean
		local result = process.exec("rojo", {
			"build",
			rojoProjectFile,
			"--output",
			filePath,
		})

		if result.ok then
			return true
		else
			warn("Failed to build place file")
			print(result.stderr)
			return false
		end
	end

	local function uploadPlaceAsync(): (boolean, number?)
		local readSuccess, placeFile = pcall(fs.readFile, filePath)
		if not readSuccess then
			warn("Failed to read place file")
			return false
		end

		warn("header value:", string.sub(apiKey, 1, 10))

		local res = net.request({
			url = `https://apis.roblox.com/universes/v1/{universeId}/places/{placeId}/versions`,
			method = "POST",
			body = placeFile,
			query = {
				versionType = "Published",
			},
			headers = {
				["x-api-key"] = apiKey,
				["Content-Type"] = "application/octet-stream",
				["Accept"] = "application/json",
			},
		})

		local decodedBody = serde.decode("json", res.body)
		if res.ok then
			return true, decodedBody.versionNumber
		else
			warn("Failed to upload place file")
			print(decodedBody)

			return false
		end
	end

	local buildSuccess = buildPlaceAsync()
	if not buildSuccess then
		return nil
	end

	local uploadSuccess, versionNumber = uploadPlaceAsync()
	if not uploadSuccess then
		return nil
	end

	return {
		versionNumber = versionNumber :: number,
	}
end

return buildUploadPlaceAsync