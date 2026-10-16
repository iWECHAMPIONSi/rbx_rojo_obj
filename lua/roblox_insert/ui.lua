local m = {}
local data = require("roblox_insert.data")

local vim = vim

local function generate_dimensions()
	local buf_lines = vim.o.lines
	local buf_columns = vim.o.columns

	local width = math.ceil((160 / 209) * vim.o.columns)
	local height = math.ceil((40 / 55) * vim.o.lines)

	if height - 6 <= 0 then
		vim.notify("Neovim window is too small, please make it larger", vim.log.levels.ERROR)
		return nil
	end

	local row = math.floor((vim.o.lines - height - 2) / 2)
	local col = math.floor((vim.o.columns - width - 2) / 2)
	return {
		path_bar = {
			title = "Path",
			title_pos = "left",
			width = width,
			height = 1,
			col = col,
			row = row,
			border = {
				{ "╭", "FloatBorder" },
				{ "─", "FloatBorder" },
				{ "╮", "FloatBorder" },
				{ "│", "FloatBorder" },
				{ "│", "FloatBorder" },
				{ "", "FloatBorder" },
				{ "│", "FloatBorder" },
				{ "│", "FloatBorder" },
			},
			contents = { "/src/shared/" },
		},
		search_bar = {
			footer = "Search",
			footer_pos = "left",
			width = width,
			height = 1,
			col = col,
			row = row + height - 2,
			border = {
				{ "│", "FloatBorder" },
				{ "", "FloatBorder" },
				{ "│", "FloatBorder" },
				{ "│", "FloatBorder" },
				{ "╯", "FloatBorder" },
				{ "─", "FloatBorder" },
				{ "╰", "FloatBorder" },
				{ "│", "FloatBorder" },
			},
		},
		class_list = {
			title = "Classes",
			title_pos = "center",
			width = math.ceil(width / 2) - 1,
			height = height - 6,
			col = col,
			row = row + 2,
			border = {
				{ "├", "FloatBorder" },
				{ "─", "FloatBorder" },
				{ "┬", "FloatBorder" },
				{ "│", "FloatBorder" },
				{ "┴", "FloatBorder" },
				{ "─", "FloatBorder" },
				{ "├", "FloatBorder" },
				{ "│", "FloatBorder" },
			},
			contents = {
				"GUI/",
				"  TextButton",
				"  Frame",
				"Constraints/",
				"  WeldConstraint",
			},
		},
		class_display = {
			title = "Class",
			title_pos = "center",
			width = math.floor(width / 2),
			height = height - 6,
			col = col + math.ceil(width / 2) + 1,
			row = row + 2,
			border = {
				{ "─", "FloatBorder" },
				{ "─", "FloatBorder" },
				{ "┤", "FloatBorder" },
				{ "│", "FloatBorder" },
				{ "┤", "FloatBorder" },
				{ "─", "FloatBorder" },
				{ "─", "FloatBorder" },
				{ "", "FloatBorder" },
			},
			contents = {
				"TextButton",
				"",
				"Text: string",
				"Size: UDim2",
				"Position: UDim2",
			},
		},
	}
end

m.generate_dimensions = generate_dimensions

local function create_window(args)
	local buf = vim.api.nvim_create_buf(false, true)

	vim.api.nvim_buf_set_lines(buf, 0, -1, false, args.contents or {})

	local win = vim.api.nvim_open_win(buf, false, {
		relative = "editor",
		width = args.width,
		height = args.height,
		col = args.col,
		row = args.row,
		style = "minimal",
		border = args.border or "rounded",
		title = args.title,
		title_pos = args.title_pos,
		footer = args.footer,
		footer_pos = args.footer_pos,
	})

	vim.keymap.set("n", "q", function()
		vim.api.nvim_win_close(win, true)
	end, { buffer = buf })

	return buf, win
end

m.create_window = create_window

local function window()
	local buf = vim.api.nvim_create_buf(false, true)

	vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
		"Roblox Object Creator",
		"",
		"Testing the floating window API.",
	})

	local width = 160
	local height = 40

	local col = math.floor((vim.o.columns - width - 2) / 2)
	local row = math.floor((vim.o.lines - height - 2) / 2)

	local win = vim.api.nvim_open_win(buf, true, {
		relative = "editor",
		width = width,
		height = height,
		col = col,
		row = row,
		style = "minimal",
		border = "rounded",
		title = "rbx_rojo_obj",
		title_pos = "center",
	})

	vim.keymap.set("n", "q", function()
		vim.api.nvim_win_close(win, true)
	end, { buffer = buf })

	return buf, win
end

m.window = window

return m
