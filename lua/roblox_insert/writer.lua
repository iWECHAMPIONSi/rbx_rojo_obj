local data = require("roblox_insert.data")
local helpers = require("roblox_insert.helpers")

local vim = vim

local t = {}

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
---@param params {string: any}
---@return table?, string?
local function create_file_data(class, params, script)
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
	if not script then
		file.className = class
	end
	file.properties = next(params) and params or vim.empty_dict()
	return file
end

t.create_file_data = create_file_data

---@param file_name string
---@param class string
---@param params {string: any}
---@param dir string?
---@return nil
local function create_file(file_name, class, params, dir, script)
	dir = dir or vim.fn.expand("%:p:h")
	local contents = create_file_data(class, params, script)
	if not contents then
		return nil
	end
	local json = vim.json.encode(contents, {
		indent = "    ",
	})
	local path
	local full_path = vim.fs.joinpath(dir, file_name)
	if
		vim.uv.fs_stat(full_path)
		or vim.uv.fs_stat(full_path .. ".luau")
		or vim.uv.fs_stat(full_path .. ".model.json")
		or vim.uv.fs_stat(full_path .. ".meta.json")
		or vim.uv.fs_stat(full_path .. ".project.json")
		or vim.uv.fs_stat(full_path .. ".rbxmx")
		or vim.uv.fs_stat(full_path .. ".rbxm")
		or vim.uv.fs_stat(full_path .. ".csv")
		or vim.uv.fs_stat(full_path .. ".txt")
		or vim.uv.fs_stat(full_path .. ".toml")
		or vim.uv.fs_stat(full_path .. ".server.luau")
		or vim.uv.fs_stat(full_path .. ".client.luau")
	then
		vim.notify('A file or directory with the name "' .. file_name .. '" already exists', vim.log.levels.ERROR)
		return
	end
	if not script then
		path = vim.fs.joinpath(dir, file_name .. ".model.json")
	else
		path = vim.fs.joinpath(dir, file_name .. ".meta.json")
		local result
		local script_name
		if class == "LocalScript" then
			script_name = vim.fs.joinpath(dir, file_name .. ".client.luau")
			result = vim.fn.writefile(vim.split('print("Hello World!")\n', "\n", { plain = true }), script_name)
		elseif class == "ModuleScript" then
			script_name = vim.fs.joinpath(dir, file_name .. ".luau")
			result =
				vim.fn.writefile(vim.split("local module = {}\n\nreturn module\n", "\n", { plain = true }), script_name)
		elseif class == "Script" then
			script_name = vim.fs.joinpath(dir, file_name .. ".server.luau")
			result = vim.fn.writefile(vim.split('print("Hello World!")\n', "\n", { plain = true }), script_name)
		end
		if result ~= 0 then
			vim.notify("Failed to write file: " .. script_name, vim.log.levels.ERROR)
		end
		if not next(params) then
			return
		end
	end

	local result = vim.fn.writefile(vim.split(json, "\n", { plain = true }), path)

	if result ~= 0 then
		vim.notify("Failed to write file: " .. path, vim.log.levels.ERROR)
	end
end

t.create_file = create_file

return t
