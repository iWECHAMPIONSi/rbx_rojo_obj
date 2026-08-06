local t = {}

local category_keys = require("rbx_rojo_obj.roblox_insert.category_data")

local function get_plugin_root()
	local source = debug.getinfo(1, "S").source:gsub("^@", "")

	local module_directory = assert(vim.fs.dirname(source), "Unable to locate roblox_insert module directory")

	local lua_directory = assert(vim.fs.dirname(module_directory), "Unable to locate the plugin's lua directory")

	return assert(vim.fs.dirname(lua_directory), "Unable to locate the plugin root directory")
end

local function read_file(path)
	local file, open_error = io.open(path, "rb")

	if file == nil then
		return nil, string.format("Attempt to open data.json failed: %s", tostring(open_error))
	end

	local contents = file:read("*a")

	if contents == nil then
		file:close()

		return nil, string.format("Attempt to read data.json failed: %s", path)
	end

	local close_success, close_error = file:close()

	if close_success == nil then
		return nil, string.format("Attempt to close data.json failed: %s", tostring(close_error))
	end

	return contents, nil
end

function t.load()
	path = vim.fs.joinpath(get_plugin_root(), "rbx_rojo_obj", "data", "data.json")

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
	return decoded, nil
end

local raw, err = t.load()

t.raw = raw
t.err = err

if not raw then
	return t
end

local iter_table = {}

local tempkeys = {}
local permkeys = {}

for name, _ in pairs(raw) do
	tempkeys[name] = true
end

local cat = nil
local super = nil
local classes = nil

local to_remove = {}

for _, category in ipairs(category_keys) do
	cat = category.Category
	iter_table[cat] = {}
	table.insert(permkeys, cat)
	super = category.Superclasses
	for _, class in ipairs(super) do
		for name, _ in pairs(tempkeys) do
			for _, superclass in ipairs(raw[name].nested_classes) do
				if superclass == class then
					table.insert(iter_table[cat], name)
					table.insert(to_remove, name)
					break
				end
			end
		end
		for _, name in ipairs(to_remove) do
			tempkeys[name] = nil
		end
		to_remove = {}
	end
	classes = category.Classes
	for _, class in ipairs(classes) do
		table.insert(iter_table[cat], class)
		for name, _ in pairs(tempkeys) do
			if name == class then
				table.insert(to_remove, name)
			end
		end
	end
	for _, name in ipairs(to_remove) do
		tempkeys[name] = nil
	end
	to_remove = {}
	table.sort(iter_table[cat], function(a, b)
		return a < b
	end)
end

t.categories = iter_table
t.catkeys = permkeys

return t
