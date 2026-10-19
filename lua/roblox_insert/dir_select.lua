local vim = vim

local src_name = "src"
local root_dir = nil

local directory_contents = {}

local dir_ref = {
	{ t = "src", name = src_name },
	{ t = "parent", name = ".." },
	{ t = nil, name = "./" },
}

local dir_ref_start = {
	{ t = "src", name = src_name },
	{ t = "parent", name = ".." },
	{ t = nil, name = "./" },
}

local m = {}

local function create_input(field, t, initial_value, on_submit, title)
	local buf = vim.api.nvim_create_buf(false, true)
	vim.bo[buf].buftype = "prompt"
	vim.fn.prompt_setprompt(buf, field .. ": ")
	local width = 40
	local win = vim.api.nvim_open_win(buf, true, {
		relative = "editor",
		width = width,
		height = 1,
		row = math.floor(vim.o.lines / 2),
		col = math.floor((vim.o.columns - width) / 2),
		border = "rounded",
		style = "minimal",
		title = title or "Input",
		footer = t,
	})

	vim.fn.prompt_setcallback(buf, function(value)
		vim.schedule(function()
			if value == "" then
				value = nil
			end
			on_submit(value)
			if vim.api.nvim_win_is_valid(win) then
				vim.api.nvim_win_close(win, true)
			end
		end)
	end)

	vim.keymap.set("n", "Q", function()
		vim.api.nvim_win_close(win, true)
	end, { buffer = buf })

	vim.cmd("startinsert")
	if initial_value ~= nil then
		vim.schedule(function()
			if not vim.api.nvim_win_is_valid(win) then
				return
			end

			local prompt = vim.fn.prompt_getprompt(buf)
			local value = tostring(initial_value)

			vim.api.nvim_buf_set_text(buf, 0, #prompt, 0, #prompt, { value })

			vim.api.nvim_win_set_cursor(win, {
				1,
				#prompt + #value,
			})
		end)
	end
	return buf, win
end

m.create_input = create_input

local function render_new_dir(buf, path_buf, path, all)
	directory_contents = {}
	dir_ref = vim.deepcopy(dir_ref_start)
	local dirs = {}

	for name, kind in vim.fs.dir(path) do
		table.insert(directory_contents, { t = kind, name = name })
		if all or kind == "directory" then
			table.insert(dirs, { t = kind == "directory" and "dir" or nil, name = name })
		end
	end

	table.sort(dirs, function(a, b)
		if not (a.name < b.name) and (a.t == "dir") and (b.t ~= "dir") then
			return true
		end
		return a.name < b.name
	end)

	for _, dir in ipairs(dirs) do
		table.insert(dir_ref, dir)
	end
	local str = {}
	for _, dir in ipairs(dir_ref) do
		table.insert(str, dir.name .. (dir.t and "/" or ""))
	end

	vim.api.nvim_set_option_value("modifiable", true, { buf = buf })
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, str)
	vim.api.nvim_set_option_value("modifiable", false, { buf = buf })

	if path_buf then
		path = string.gsub(path, root_dir or "", "") -- should be impossible for root_dir to be nil at this stage
		vim.api.nvim_set_option_value("modifiable", true, { buf = path_buf })
		vim.api.nvim_buf_set_lines(path_buf, 0, -1, false, { path })
		vim.api.nvim_set_option_value("modifiable", false, { buf = path_buf })
	end
end

m.render_new_dir = render_new_dir

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
			on_ready = function(buf, win)
				vim.api.nvim_set_current_win(win)
				vim.api.nvim_set_option_value("modifiable", true, { buf = buf })
				vim.api.nvim_buf_set_lines(buf, 0, -1, false, { src_name })
				vim.api.nvim_set_option_value("modifiable", false, { buf = buf })
			end,
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
			keybinds = function(buf, win, p_buf, p_win, gen_func)
				local path = vim.fs.joinpath(root_dir, src_name)
				vim.api.nvim_set_current_win(win)
				render_new_dir(buf, p_buf, path)
				local display_all = false
				vim.keymap.set("n", "<CR>", function()
					display_all = false
					local line = vim.api.nvim_win_get_cursor(win)[1]
					local selection = dir_ref[line]

					if not selection.t then
						return
					elseif selection.t == "src" then
						path = vim.fs.joinpath(root_dir, src_name)
						render_new_dir(buf, p_buf, path)
					elseif selection.t == "parent" then
						if vim.fs.dirname(path) == root_dir then
							return
						end
						path = vim.fs.dirname(path)
						render_new_dir(buf, p_buf, path)
					else
						path = vim.fs.joinpath(path, selection.name)
						render_new_dir(buf, p_buf, path)
					end
				end, { buffer = buf })

				vim.keymap.set("n", "d", function()
					create_input("/", nil, nil, function(value)
						if value then
							if string.match(value, "%s") then
								vim.notify("Directory names cannot contain spaces", vim.log.levels.ERROR)
								return
							end
							local is_windows = vim.fn.has("win32") == 1
							local illegal_pattern

							if is_windows then
								illegal_pattern = '[\\/:*?"<>|]'
							else
								illegal_pattern = "[/]"
							end

							if string.match(value, illegal_pattern) then
								vim.notify("Directory name contains invalid characters", vim.log.levels.ERROR)
								return
							end
							local full_path = vim.fs.joinpath(path, value)
							if
								vim.uv.fs_stat(full_path)
								or vim.uv.fs_stat(full_path .. ".luau")
								or vim.uv.fs_stat(full_path .. ".model.json")
								or vim.uv.fs_stat(full_path .. ".project.json")
								or vim.uv.fs_stat(full_path .. ".rbxmx")
								or vim.uv.fs_stat(full_path .. ".rbxm")
								or vim.uv.fs_stat(full_path .. ".csv")
								or vim.uv.fs_stat(full_path .. ".txt")
								or vim.uv.fs_stat(full_path .. ".toml")
								or vim.uv.fs_stat(full_path .. ".server.luau")
								or vim.uv.fs_stat(full_path .. ".client.luau")
							then
								vim.notify(
									'A file or directory with the name "' .. value .. '" already exists',
									vim.log.levels.ERROR
								)
								return
							end
							vim.fn.mkdir(vim.fs.joinpath(path, value), "p")
							render_new_dir(buf, nil, path)
						end
					end, "Name of new directory")
				end, { buffer = buf })

				vim.keymap.set("n", "%", function()
					create_input("name", nil, nil, function(value)
						if value then
							if string.match(value, "%s") then
								vim.notify("File names cannot contain spaces", vim.log.levels.ERROR)
								return
							end
							local is_windows = vim.fn.has("win32") == 1
							local illegal_pattern

							if is_windows then
								illegal_pattern = '[\\/:*?"<>|]'
							else
								illegal_pattern = "[/]"
							end

							if string.match(value, illegal_pattern) then
								vim.notify("File name contains invalid characters", vim.log.levels.ERROR)
								return
							end
							local full_path = vim.fs.joinpath(path, value)
							if
								vim.uv.fs_stat(full_path)
								or vim.uv.fs_stat(full_path .. ".luau")
								or vim.uv.fs_stat(full_path .. ".model.json")
								or vim.uv.fs_stat(full_path .. ".project.json")
								or vim.uv.fs_stat(full_path .. ".rbxmx")
								or vim.uv.fs_stat(full_path .. ".rbxm")
								or vim.uv.fs_stat(full_path .. ".csv")
								or vim.uv.fs_stat(full_path .. ".txt")
								or vim.uv.fs_stat(full_path .. ".toml")
								or vim.uv.fs_stat(full_path .. ".server.luau")
								or vim.uv.fs_stat(full_path .. ".client.luau")
							then
								vim.notify(
									'A file or directory with the name "' .. value .. '" already exists',
									vim.log.levels.ERROR
								)
								return
							end
							vim.print(root_dir)
							vim.print(path)
							gen_func(value, path, string.gsub(path, root_dir or "", ""))
						end
					end, "Name of new file")
				end, { buffer = buf })

				vim.keymap.set("n", "D", function()
					local line = vim.api.nvim_win_get_cursor(win)[1]
					if line <= 3 then
						return
					end
					local selection = dir_ref[line]

					create_input(
						"/",
						"Type in the exact name of the directory to delete it, case sensitive",
						nil,
						function(value)
							if value == selection.name then
								vim.fn.delete(vim.fs.joinpath(path, selection.name), "rf")
							end
						end,
						'Are you sure you want to recursively delete the directory "' .. selection.name .. '"?'
					)
				end, { buffer = buf })

				vim.keymap.set("n", "Q", function()
					vim.api.nvim_win_close(win, true)
					vim.api.nvim_win_close(p_win, true)
				end, { buffer = buf })

				vim.keymap.set("n", "H", function()
					display_all = not display_all
				end, { buffer = buf })
			end,
			current_dir = nil,
		},
	}
end

m.generate_dimensions = generate_dimensions

local function make_dir_windows(args)
	local function is_directory(path)
		local stat = vim.uv.fs_stat(path)
		return stat ~= nil and stat.type == "directory"
	end

	-- Create the directory browser once its starting path is known.
	local function open_browser(path)
		root_dir = vim.fs.normalize(path)

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

		args.buf = buf
		args.win = win
		args.root_dir = root_dir

		if args.on_ready then
			args.on_ready(buf, win)
		end
	end

	-- Find the Rojo project.
	local project_root = vim.fs.root(0, "default.project.json")

	if not project_root then
		vim.notify("Unable to find directory containing default.project.json", vim.log.levels.ERROR)
		return
	end

	-- Use /src/ automatically if it exists.
	local src_dir = vim.fs.joinpath(project_root, "src")

	if is_directory(src_dir) then
		src_name = "src"
		open_browser(project_root)
		return
	end

	-- Otherwise, ask the user for the source directory.
	local function ask_for_src()
		create_input(project_root, "Leave blank to cancel", nil, function(value)
			-- create_input() converts empty input into nil.
			if value == nil then
				return
			end

			local path = vim.fs.joinpath(project_root, value)

			if is_directory(path) then
				src_name = value
				if value[string.len(value)] ~= "/" then
					value = value .. "/"
				end
				-- Continue after the input window closes.
				vim.schedule(function()
					open_browser(project_root)
				end)
			else
				vim.notify(path .. " is not a valid directory", vim.log.levels.ERROR)

				-- Retry after the current prompt closes.
				vim.schedule(ask_for_src)
			end
		end)
	end

	ask_for_src()
end

m.make_dir_windows = make_dir_windows
return m
