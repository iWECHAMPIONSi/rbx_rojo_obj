local ui = require("roblox_insert.ui")

local vim = vim

local dir_ref = {
	{ t = "src", name = "/src/" },
	{ t = "parent", name = "../" },
	{ t = nil, name = "./" },
}

local dir_ref_start = {
	{ t = "src", name = "/src/" },
	{ t = "parent", name = "../" },
	{ t = nil, name = "./" },
}

local t = {}

local function render_new_dir(buf, path)
	dir_ref = dir_ref_start
	local dirs = {}

	for name, kind in vim.fs.dir(path) do
		if kind == "directory" then
			table.insert(dirs, { t = "dir", name = name })
		end
	end
	table.sort(dirs, function(a, b)
		return a.name < b.name
	end)
	for _, dir in ipairs(dirs) do
		table.insert(dir_ref, dir)
	end
	local str = {}
	for _, dir in ipairs(dir_ref) do
		table.insert(str, dir.name)
	end

	vim.api.nvim_set_option_value("modifiable", true, { buf = buf })
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, str)
	vim.api.nvim_set_option_value("modifiable", false, { buf = buf })
end

t.render_new_dir = render_new_dir

local function make_new_dir(buf, path) end

t.make_new_dir = make_new_dir

local function generate_dimensions()
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
			title = "Select destination directory",
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
			contents = { "/src/" },
		},
		directory = {
			footer = "Enter: open/select",
			footer_pos = "left",
			width = width,
			height = height - 2,
			col = col,
			row = row + 2,
			border = {
				{ "├", "FloatBorder" },
				{ "─", "FloatBorder" },
				{ "┤", "FloatBorder" },
				{ "│", "FloatBorder" },
				{ "╯", "FloatBorder" },
				{ "─", "FloatBorder" },
				{ "╰", "FloatBorder" },
				{ "│", "FloatBorder" },
			},
			keybinds = function(buf, win, p_buf, p_win) end,
		},
	}
end

t.generate_dimensions = generate_dimensions

local function make_dir_windows(args)
	local buf = vim.api.nvim_create_buf(false, true)

	vim.api.nvim_set_option_value("buftype", "nofile", { buf = buf })
	vim.api.nvim_set_option_value("modifiable", false, { buf = buf })

	local win = vim.api.nvim_open_win(buf, false, {
		relative = "editor",
		width = args.width,
		height = args.height,
		col = args.col,
		row = args.row,
		style = "minimal",
		border = args.border,
		title = args.title,
		title_pos = args.title_pos,
		footer = args.footer,
		footer_pos = args.footer_pos,
	})

	return buf, win
end

t.make_dir_windows = make_dir_windows
return t
