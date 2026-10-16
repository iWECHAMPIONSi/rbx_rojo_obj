local m = {}
local data = require("roblox_insert.data")

local function window()
	local buf = vim.api.nvim_create_buf(false, true)

	local width = 60
	local height = 20
	local opts = {
		relative = "editor",
		width = width,
		height = height,
		col = math.floor((vim.o.columns - width) / 2),
		row = math.floor((vim.o.lines - height) / 2),
		border = "rounded",
	}
	local win = vim.api.nvim_open_win(buf, true, opts)
end

m.window = window

return m
