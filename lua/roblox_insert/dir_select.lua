local config = require("roblox_insert.config")
local assign_command = config.assign_command
local vim = vim

local src_name = config.config.src_name
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
	local width = math.max(string.len(t or "") + 2, string.len(title or "") + 2, 40)
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

	local function close_input()
		vim.api.nvim_win_close(win, true)
	end

	assign_command(buf, "CloseInput", config.config.keybinds.close_input, close_input)

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

local function check_name_collision(path, name, on_success)
	if string.match(name, "%s") then
		vim.notify("Directory or file name contains spaces", vim.log.levels.ERROR)
		return
	end
	local is_windows = vim.fn.has("win32") == 1
	local illegal_pattern

	if is_windows then
		illegal_pattern = '[\\/:*?"<>|]'
	else
		illegal_pattern = "[/]"
	end

	if string.match(name, illegal_pattern) then
		vim.notify("Directory or file name contains invalid characters", vim.log.levels.ERROR)
		return
	end

	local full_path = vim.fs.joinpath(path, name)
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
		if config.config.allow_overwrite then
			if config.config.confirm_overwrite then
				create_input("Input", "Return 'yes' to overwrite, file or directory", "no", function(value)
					if value == "yes" then
						on_success()
						return
					end
				end, "A file or directory with the same name already exists")
			else
				on_success()
			end
		else
			vim.notify('A file or directory with the name "' .. name .. '" already exists', vim.log.levels.ERROR)
		end
		return
	end
	on_success()
end

m.check_name_collision = check_name_collision

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
		if (a.t == "dir") ~= (b.t == "dir") then
			return a.t == "dir"
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
		local _, end_index = string.find(path, root_dir or "", 1, true)
		path = string.sub(path, end_index or 1)
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
			keybinds = function(buf, win, p_buf, p_win, gen_func, name, focus_win)
				local path = vim.fs.joinpath(root_dir, src_name)
				vim.api.nvim_set_current_win(win)
				local display_all = config.config.files_visible
				render_new_dir(buf, p_buf, path, display_all)

				local function select_dir()
					local line = vim.api.nvim_win_get_cursor(win)[1]
					local selection = dir_ref[line]

					if not selection.t then
						return
					elseif selection.t == "src" then
						path = vim.fs.joinpath(root_dir, src_name)
						render_new_dir(buf, p_buf, path, display_all)
					elseif selection.t == "parent" then
						if vim.fs.dirname(path) == root_dir then
							return
						end
						path = vim.fs.dirname(path)
						render_new_dir(buf, p_buf, path, display_all)
					else
						path = vim.fs.joinpath(path, selection.name)
						render_new_dir(buf, p_buf, path, display_all)
					end
				end

				assign_command(buf, "SelectDir", config.config.keybinds.select_dir, select_dir)

				local function create_dir()
					create_input("/", nil, nil, function(value)
						if value then
							check_name_collision(path, value, function()
								vim.fn.mkdir(vim.fs.joinpath(path, value), "p")
								render_new_dir(buf, nil, path, display_all)
							end)
						end
					end, "Name of new directory")
				end

				assign_command(buf, "CreateDir", config.config.keybinds.create_dir, create_dir)

				local function name_file()
					local function check_name(value)
						local function on_success()
							local selected_path = path
							local visual_path = string.sub(path, string.find(path, src_name or "", 1, true) or 1)
							vim.schedule(function()
								gen_func(value, selected_path, visual_path)
							end)
						end
						check_name_collision(path, value, on_success)
					end
					local function on_success()
						create_input("Name", nil, nil, function(value)
							if value then
								check_name(value)
							end
						end, "Name of new file")
					end
					if not name then
						on_success()
					else
						check_name(name)
					end
				end

				assign_command(buf, "NameFile", config.config.keybinds.name_file, name_file)

				local function delete_dir()
					local line = vim.api.nvim_win_get_cursor(win)[1]
					if line <= 3 then
						return
					end
					local selection = dir_ref[line]
					if selection.t == "dir" then
						if config.config.confirm_delete then
							create_input(
								"/",
								"Type in the exact name of the directory to delete it, case sensitive",
								nil,
								function(value)
									if value == selection.name then
										vim.fn.delete(vim.fs.joinpath(path, selection.name), "rf")
										render_new_dir(buf, p_buf, path, display_all)
									end
								end,
								'Are you sure you want to recursively delete the directory "' .. selection.name .. '"?'
							)
						else
							vim.fn.delete(vim.fs.joinpath(path, selection.name), "rf")
							render_new_dir(buf, p_buf, path, display_all)
						end
					end
				end

				assign_command(buf, "DeleteDir", config.config.keybinds.delete_dir, delete_dir)

				local function close_dir_window()
					vim.api.nvim_win_close(win, true)
					vim.api.nvim_win_close(p_win, true)
					if focus_win then
						vim.api.nvim_set_current_win(focus_win)
					end
				end

				assign_command(buf, "CloseDir", config.config.keybinds.close_dir_window, close_dir_window)

				local function toggle_file_visibility()
					display_all = not display_all
					render_new_dir(buf, p_buf, path, display_all)
				end

				assign_command(
					buf,
					"ToggleFileVisibility",
					config.config.keybinds.toggle_file_visibility,
					toggle_file_visibility
				)

				local function enable_file_visibility()
					if not display_all then
						display_all = true
						render_new_dir(buf, p_buf, path, display_all)
					end
				end

				assign_command(
					buf,
					"EnableFileVisibility",
					config.config.keybinds.enable_file_visibility,
					enable_file_visibility
				)
				local function disable_file_visibility()
					if display_all then
						display_all = false
						render_new_dir(buf, p_buf, path, display_all)
					end
				end

				assign_command(
					buf,
					"DisableFileVisibility",
					config.config.keybinds.disable_file_visibility,
					disable_file_visibility
				)
			end,

			current_dir = nil,
		},
	}
end

m.generate_dimensions = generate_dimensions

local function resolve_source_directory(on_resolved)
	local function is_directory(path)
		local stat = vim.uv.fs_stat(path)
		return stat ~= nil and stat.type == "directory"
	end

	if root_dir then
		if not string.find(root_dir, vim.fn.getcwd(), 1, true) then
			root_dir = nil
			src_name = config.config.src_name
			dir_ref = vim.deepcopy(dir_ref_start)
			directory_contents = {}
		end
	end

	local project_root = root_dir
	if not root_dir then
		src_name = config.config.src_name
		project_root = vim.fs.root(0, "default.project.json")

		if not project_root then
			vim.notify("Unable to find directory containing default.project.json", vim.log.levels.ERROR)
			return
		end
	end

	local function finish(source_name)
		root_dir = vim.fs.normalize(project_root)
		src_name = source_name

		-- Keep the directory browser's root entries current.
		dir_ref_start[1].name = src_name
		dir_ref[1].name = src_name

		-- Continue after any active input prompt has closed.
		vim.schedule(function()
			on_resolved()
		end)
	end

	local src_dir = vim.fs.joinpath(project_root, src_name or "src")

	if is_directory(src_dir) then
		src_name = src_name or "src"
		finish(src_name)
		return
	end

	local function ask_for_src()
		create_input(project_root, "Leave blank to cancel", nil, function(value)
			if value == nil then
				return
			end

			local path = vim.fs.joinpath(project_root, value)

			if is_directory(path) then
				finish(value)
			else
				vim.notify(path .. " is not a valid directory", vim.log.levels.ERROR)

				vim.schedule(ask_for_src)
			end
		end, "Unable to find '/src/' dir, enter source directory")
	end

	ask_for_src()
end

m.resolve_source_directory = resolve_source_directory

local function make_dir_windows(args)
	if not root_dir then
		vim.notify("Source directory has not been initialized", vim.log.levels.ERROR)
		return
	end

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

	return buf, win
end

m.make_dir_windows = make_dir_windows

return m
