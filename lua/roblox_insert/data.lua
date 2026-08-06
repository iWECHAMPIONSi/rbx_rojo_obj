local t = {}

category_keys = require("category_data")

local categories = {}

t.categories = categories

local function get_plugin_root()
	local source = debug.getinfo(1, "S").source:gsub("^@", "")

	local module_directory = assert(vim.fs.dirname(source), "Could not determine the roblox_insert module directory")

	local lua_directory = assert(vim.fs.dirname(module_directory), "Could not determine the plugin's lua directory")

	return assert(vim.fs.dirname(lua_directory), "Could not determine the plugin root directory")
end

local function get_default_data_path()
	return vim.fs.joinpath(get_plugin_root(), "data", "data.json")
end

local function read_file(path)
	local file, open_error = io.open(path, "rb")

	if file == nil then
		return nil, string.format("Could not open Roblox class data file '%s': %s", path, tostring(open_error))
	end

	local contents = file:read("*a")

	if contents == nil then
		file:close()

		return nil, string.format("Could not read Roblox class data file '%s'", path)
	end

	local close_success, close_error = file:close()

	if close_success == nil then
		return nil, string.format("Could not close Roblox class data file '%s': %s", path, tostring(close_error))
	end

	return contents, nil
end

function t.load(path)
	path = path or get_default_data_path()

	local contents, read_error = read_file(path)

	if contents == nil then
		return nil, read_error
	end

	local decode_success, decoded = pcall(vim.json.decode, contents)

	if not decode_success then
		return nil, string.format("Could not decode Roblox class data file '%s': %s", path, tostring(decoded))
	end

	if type(decoded) ~= "table" then
		return nil, string.format("Roblox class data file '%s' did not contain a JSON object", path)
	end
end

-- categories["3D Interfaces"]

return t
