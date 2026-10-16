local writer = require("roblox_insert.writer")

local m = {}

---@param file_name string
---@param class string
---@return nil
local function create_file(file_name, class, dir)
	if type(file_name) ~= "string" then
		vim.notify("name of the file must be a valid string", vim.log.levels.ERROR)
		return
	end

	if type(class) ~= "string" then
		vim.notify("name of the class must be a string", vim.log.levels.ERROR)
	end

	writer.create_file(file_name, class, nil, dir)
end

m.create_file = create_file

return m
