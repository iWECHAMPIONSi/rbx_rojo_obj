local data = require("roblox_insert.data")
local helpers = require("roblox_insert.helpers")

local t = {}

local category_table = data.categories
local classes = data.catkeys
local class_data, enum_data = data.raw.Classes, data.raw.Enums

local complex_types = {
	vector2 = { "number", "number" },
	vector3 = { "number", "number", "number" },
	color3 = { "number", "number", "number" },
	cframe = {
		{ "number", "number", "number", "number", "number", "number", "number", "number", "number", "number" },
		{ "number", "number", "number" },
	},
}

local function find_closest_class(class)
	local closest_match = nil
	local closest_score = 5
	for i in pairs(data.raw.Classes) do
		local distance = helpers.levenshtein(class, i)
		if distance <= closest_score then
			closest_score = distance
			closest_match = i
		end
	end

	return closest_match
end

---@param class string
---@param params {string: any}?
---@return table?, string?
local function create_file_data(class, params)
	local class_table = data.raw.Classes[class]
	if not class_table then
		local estimate = find_closest_class(class)
		if estimate then
			vim.notify(
				"No class with the name '" .. class .. "' found, did you mean '" .. estimate .. "'?",
				vim.log.levels.ERROR
			)
		else
			vim.notify("No class with the name '" .. class .. "' found.", vim.log.levels.ERROR)
		end
		return nil
	end
	local file = {}
	file.ClassName = class
	file.Properties = params or vim.empty_dict()
	return file
end

t.create_file_data = create_file_data

---@param file_name string
---@param class string
---@param params {string: any}?
---@param dir string?
---@return nil
local function create_file(file_name, class, params, dir)
	dir = dir or vim.fn.expand("%:p:h")
	local contents = create_file_data(class, params)
	if not contents then
		return nil
	end
	local json = vim.json.encode(contents, {
		indent = "    ",
	})

	local path = vim.fs.joinpath(dir, file_name .. ".model.json")

	local result = vim.fn.writefile(vim.split(json, "\n", { plain = true }), path)

	if result ~= 0 then
		vim.notify("Failed to write file: " .. path, vim.log.levels.ERROR)
	end
end

t.create_file = create_file

return t
