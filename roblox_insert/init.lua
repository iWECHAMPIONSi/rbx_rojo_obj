local t = require("rbx_rojo_obj.rbx_insert.data")
require("rbx_rojo_obj.rbx_insert.writer")

local file, err = io.open("output.txt", "w")
if not file then
	print("Could not open file: " .. err)
	return
end

local str = ""

-- local function recurse(spaces, ta)
-- local ret_str = ""
-- for name, val in pairs(ta) do
-- ret_str = ret_str .. string.rep(" ", spaces) .. name
-- if type(val) ~= "table" then
-- ret_str = ret_str .. val .. ": " .. tostring(val) .. "\n"
-- else
-- ret_str = ret_str .. ":\n" .. recurse(spaces + 1, val)
-- end
-- end
-- return ret_str
-- end

-- str = recurse(0, temp)

for _, cat in ipairs(t.catkeys) do
	str = str .. cat .. ":\n"
	for _, class in ipairs(t.categories[cat]) do
		str = str .. "    " .. class .. "\n"
	end
end

file:write(str)
file:close()
