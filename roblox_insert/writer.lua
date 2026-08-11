local data = require("rbx_rojo_obj.rbx_insert.data")

local t = {}

local category_table = data.categories
local classes = data.catkeys
local class_data, enum_data = data.raw.classes, data.raw.enums

local complex_types = {
	vector2 = { "number", "number" },
	vector3 = { "number", "number", "number" },
	color3 = { "number", "number", "number" },
	cframe = {
		{ "number", "number", "number", "number", "number", "number", "number", "number", "number", "number" },
		{ "number", "number", "number" },
	},
}

---@param str string
---@return table
local function split(str)
	local ret = {}
	for word in string.gmatch(str, ".") do
		table.insert(ret, word)
	end
	return ret
end

---@param enum string
---@param name string
---@return number?
local function check_enum(enum, name)
	local str = split(name)
	if #str == 0 then
		return nil
	end
	return enum_data[str[#str]]
end

---@param param table
---@return table?, string?
local function convert_complex_type(param) end

---@param class string
---@param params {string: any}?
---@return table?, string?
local function create_file_data(class, params)
	params = params or {}
	local class_table = data.raw[class]
	local file = {}
	file.ClassName = class
	file.Properties = {}

	return file
end

t.create_file_data = create_file_data

return t
