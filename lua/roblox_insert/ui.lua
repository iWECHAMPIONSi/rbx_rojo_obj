local m = {}
local data = require("roblox_insert.data")

local vim = vim

local class_list_ref = {}

local roblox_types = {
	name = {
		lua_type = "string",
		fields = {
			"",
		},
		verification = function(t)
			if type(t) == "string" then
				return string.len(t) > 0, t
			end
			return false, nil
		end,
	},
	bool = {
		lua_type = "bool",
		verification = function(t)
			if t == "true" or t == "false" then
				if t == "true" then
					return true, true
				else
					return true, false
				end
			end
			return false, nil
		end,
	},
	int = {
		lua_type = "number",
		fields = {
			"",
		},
		verification = function(t)
			local i = tonumber(t)
			if i == nil then
				return false
			end
			return math.floor(i) == i, i
		end,
	},
	int64 = {
		lua_type = "number",
		fields = {
			"",
		},
		verification = function(t)
			local i = tonumber(t)
			if i == nil then
				return false
			end
			return math.floor(i) == i, i
		end,
	},
	float = {
		lua_type = "number",
		fields = {
			"",
		},
		verification = function(t)
			return tonumber(t) ~= nil, tonumber(t)
		end,
	},
	string = {
		lua_type = "string",
		fields = {
			"",
		},
		verification = function(t)
			if type(t) == "string" then
				return string.len(t) > 0, t
			end
			return false, nil
		end,
	},
	Vector2 = {
		lua_type = "table",
		fields = {
			"X",
			"Y",
		},
		verification = function(t)
			local return_val = {}
			local indexes = 0
			for k, i in pairs(t) do
				indexes = indexes + 1
				if tonumber(i) == nil then
					return false, nil
				end
				return_val[k] = tonumber(i)
			end
			if indexes == 2 then
				return true, return_val
			end
			return false
		end,
	},
	Vector3 = {
		lua_type = "table",
		fields = {
			"X",
			"Y",
			"Z",
		},
		verification = function(t)
			local return_val = {}
			local indexes = 0
			for k, i in pairs(t) do
				indexes = indexes + 1
				if tonumber(i) == nil then
					return false, nil
				end
				return_val[k] = tonumber(i)
			end
			if indexes == 3 then
				return true, return_val
			end
			return false
		end,
	},
	Color3 = {
		lua_type = "table",
		fields = {
			"Hex",
			"R",
			"G",
			"B",
		},
		verification = function(t)
			local return_val = {}
			if t.Hex then
				if type(t.Hex) == "string" then
					if string.len(t.Hex) == 6 then
						return_val = {
							R = tonumber(string.sub(t.Hex, 1, 2), 16),
							G = tonumber(string.sub(t.Hex, 3, 4), 16),
							B = tonumber(string.sub(t.Hex, 5, 6), 16),
						}
						return true, return_val
					end
				end
				return false, nil
			end
			local indexes = 0
			for k, i in pairs(t) do
				indexes = indexes + 1
				if tonumber(i) == nil then
					return false, nil
				end
				return_val[k] = tonumber(i)
			end
			if indexes == 3 then
				return true, return_val
			end
			return false
		end,
	},
	UDim2 = {
		lua_type = "table",
		fields = {
			"X",
			"Y",
			"Width",
			"Height",
		},
		verification = function(t)
			local return_val = {}
			local indexes = 0
			for k, i in pairs(t) do
				indexes = indexes + 1
				if tonumber(i) == nil then
					return false, nil
				end
				return_val[k] = tonumber(i)
			end
			if indexes == 4 then
				return true, return_val
			end
			return false
		end,
	},

	CFrame = {
		lua_type = "table",
		fields = {
			"X",
			"Y",
			"Z",
		},
		verification = function(t)
			local return_val = {}
			local indexes = 0
			for k, i in pairs(t) do
				indexes = indexes + 1
				if tonumber(i) == nil then
					return false, nil
				end
				return_val[k] = tonumber(i)
			end
			if indexes == 3 then
				return true, return_val
			end
			return false
		end,
	},
}

local expanded_categories = {
	["Favorites"] = true,
	["3D Interfaces"] = true,
	["Adornments"] = true,
	["Ads"] = true,
	["Animations"] = true,
	["Avatar"] = true,
	["Constraints"] = true,
	["Effects"] = true,
	["Environment"] = true,
	["GUI"] = true,
	["Input"] = true,
	["Interaction"] = true,
	["Lights"] = true,
	["Localization"] = true,
	["Parts"] = true,
	["Post Processing Effects"] = true,
	["Scripting"] = true,
	["Sensors"] = true,
	["Sounds"] = true,
	["Styling"] = true,
	["Text Chat"] = true,
	["Uncategorized"] = true,
	["Values"] = true,
	["World"] = true,
	["AnimationInfo"] = true,
	["Backpack"] = true,
	["Controllers"] = true,
	["Data Store"] = true,
	["Dragger"] = true,
	["Other"] = true,
	["Posing"] = true,
	["Text Chat Properties"] = true,
}

local function query_path() end

local function disp_class(buf, class)
	vim.api.nvim_set_option_value("modifiable", true, { buf = buf })
	local class_def = data.raw.Classes[class]
	if not class_def then
		error("unreachble state reached! Class: " .. class)
	end
	if not class_def.Str then
		local str = {
			class,
			"",
			"Properties:",
		}
		for _, p in ipairs(class_def.PropertyKeys) do
			local lstr = "  " .. p .. ": "
			if class_def.Properties[p].ValueType.Category == "Enum" then
				lstr = lstr .. "Enum."
			end
			lstr = lstr .. class_def.Properties[p].ValueType.Name
			if #class_def.Properties[p].Tags > 0 then
				local tag_str = " [Tags: " .. table.concat(class_def.Properties[p].Tags, ", ") .. "]"
				lstr = lstr .. tag_str
			end
			table.insert(str, lstr)
		end
		data.raw.Classes[class].Str = str
	end
	vim.api.nvim_set_option_value("modifiable", true, { buf = buf })
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, data.raw.Classes[class].Str)
	vim.api.nvim_set_option_value("modifiable", false, { buf = buf })
end

m.disp_class = disp_class

local function disp_class_list(buf, init)
	local str = {}
	local keys = data.catkeys
	local categories = data.categories

	for _, key in ipairs(keys) do
		if not data.browsable_categories[key] then
			break
		end
		if init then
			table.insert(class_list_ref, { t = "category", name = key })
		end
		if expanded_categories[key] then
			table.insert(str, "v " .. key .. "/")
			for _, class in ipairs(categories[key]) do
				if data.browsable_classes[class] then
					if init then
						table.insert(class_list_ref, { t = "class", name = class })
					end
					local pre = "  "
					if data.favorites[class] then
						pre = "* "
					end
					table.insert(str, pre .. class)
				end
			end
		else
			table.insert(str, "> " .. key .. "/")
		end
	end

	vim.api.nvim_set_option_value("modifiable", true, { buf = buf })
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, str)
	vim.api.nvim_set_option_value("modifiable", false, { buf = buf })

	return str
end

local function user_input(query, t) end

m.user_input = user_input

local function modify_class_list(buf, category, line, favorite, added_class)
	if not favorite then
		expanded_categories[category] = not expanded_categories[category]
	end
	if expanded_categories[category] then
		local str = { "v " .. category .. "/" }
		local i = 1
		local len = 0
		if favorite then
			local class_was_added = false
			for _, class in ipairs(data.categories[category]) do
				if class ~= added_class and data.browsable_classes[class] then
					len = len + 1
					table.remove(class_list_ref, 2)
				elseif class == added_class then
					class_was_added = true
				end
			end
			if not class_was_added then
				table.remove(class_list_ref, 2)
				len = len + 1
			end
		end
		for _, class in ipairs(data.categories[category]) do
			if data.browsable_classes[class] then
				table.insert(class_list_ref, line + i, { t = "class", name = class })
				i = i + 1
				local pre = "  "
				if data.favorites[class] then
					pre = "* "
				end
				table.insert(str, pre .. class)
			end
		end
		vim.api.nvim_set_option_value("modifiable", true, { buf = buf })
		if favorite then
			vim.api.nvim_buf_set_lines(buf, line - 1, line + len, false, str)
		else
			vim.api.nvim_buf_set_lines(buf, line - 1, line, false, str)
		end
		vim.api.nvim_set_option_value("modifiable", false, { buf = buf })
	elseif not favorite then
		local len = 0
		for i, class in ipairs(data.categories[category]) do
			if data.browsable_classes[class] then
				len = len + 1
				table.remove(class_list_ref, line + 1)
			end
		end
		vim.api.nvim_set_option_value("modifiable", true, { buf = buf })
		vim.api.nvim_buf_set_lines(buf, line - 1, line + len, false, { "> " .. category .. "/" })
		vim.api.nvim_set_option_value("modifiable", false, { buf = buf })
	end
end

m.disp_class_list = disp_class_list

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
		user_input = {
			width = width,
			height = 1,
			col = col,
			row = vim.o.lines - 2 / 2,
		},
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
			keybinds = function(buf, win, d_buf, d_win, p_win, s_win)
				vim.keymap.set("n", "Q", function()
					vim.api.nvim_win_close(win, true)
					vim.api.nvim_win_close(d_win, true)
					vim.api.nvim_win_close(s_win, true)
					vim.api.nvim_win_close(p_win, true)
				end, { buffer = buf })
				vim.keymap.set("n", "/", function()
					vim.api.nvim_set_current_win(s_win)
				end, { buffer = buf })
				vim.keymap.set("n", "<CR>", function()
					local line = vim.api.nvim_win_get_cursor(win)[1]
					if class_list_ref[line].t == "class" then
						vim.api.nvim_set_current_win(d_win)
					else
						modify_class_list(buf, class_list_ref[line].name, line)
					end
				end, { buffer = buf, noremap = true })
				vim.api.nvim_create_autocmd("CursorMoved", {
					buffer = buf,
					callback = function()
						if not vim.api.nvim_win_is_valid(win) then
							return
						end

						local line = vim.api.nvim_win_get_cursor(win)[1]
						local ref = class_list_ref[line]

						if ref and ref.t == "class" then
							disp_class(d_buf, ref.name)
						end
					end,
				})
				vim.keymap.set("n", "F", function()
					local line = vim.api.nvim_win_get_cursor(win)[1]
					if class_list_ref[line].t == "class" then
						data.toggle_favorite(class_list_ref[line].name)
						modify_class_list(buf, "Favorites", 1, true, class_list_ref[line].name)
						line = vim.api.nvim_win_get_cursor(win)[1]
						local pre = "  "
						if data.favorites[class_list_ref[line].name] then
							pre = "* "
						end
						vim.api.nvim_set_option_value("modifiable", true, { buf = buf })
						vim.api.nvim_buf_set_lines(buf, line - 1, line, false, { pre .. class_list_ref[line].name })
						vim.api.nvim_set_option_value("modifiable", false, { buf = buf })
					end
				end, { buffer = buf })
			end,
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
		},
	}
end

m.generate_dimensions = generate_dimensions

local function create_window(args)
	local buf = vim.api.nvim_create_buf(false, true)
	args.buf = buf

	vim.api.nvim_buf_set_lines(buf, 0, -1, false, args.contents or {})

	vim.api.nvim_set_option_value("buftype", "nofile", { buf = buf })
	vim.api.nvim_set_option_value("modifiable", false, { buf = buf })

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

	args.win = win

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
