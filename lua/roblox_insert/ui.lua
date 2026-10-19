local m = {}
local data = require("roblox_insert.data")
local writer = require("roblox_insert.writer")
local dir_select = require("roblox_insert.dir_select")
local helpers = require("roblox_insert.helpers")
local create_input = dir_select.create_input

local roblox_types = require("roblox_insert.roblox_types")

local current_class = nil

local function handle_nil(t)
	if t == "nil" then
		return nil
	end
	return t
end
local vim = vim

local class_list_ref = {}
local properties_list_ref = {}
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

local function create_window(args)
	local buf = vim.api.nvim_create_buf(false, true)
	args.buf = buf

	vim.api.nvim_buf_set_lines(buf, 0, -1, false, args.contents or {})

	vim.api.nvim_set_option_value("buftype", args.buffer_type or "nofile", { buf = buf })
	vim.api.nvim_set_option_value("modifiable", args.buffer_type == "prompt", { buf = buf })
	if args.buffer_type then
		vim.fn.prompt_setprompt(buf, "")
	end

	local win = vim.api.nvim_open_win(buf, args.focus == true, {
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

local function disp_property(t, properties_table, name, dimensions, when_done, enumeration)
	local value_type = roblox_types[t]

	local function disp_table(props, value_ref, field_ref, buf, win, override_table, str)
		str = str or {}
		local add_index = #str
		vim.api.nvim_set_option_value("modifiable", true, { buf = buf })
		vim.api.nvim_buf_set_lines(buf, 0, -1, false, str)
		vim.api.nvim_set_option_value("modifiable", false, { buf = buf })

		if override_table or props and props.value then
			for i, field in ipairs(value_type.fields) do
				table.insert(str, field .. ": " .. (value_ref[field] or ""))
				table.insert(field_ref, function()
					create_input(field, t, value_ref[field], function(value)
						value_ref[field] = value or value_ref[field]
						value_ref[field] = handle_nil(value_ref[field])
						str[i + add_index] = field .. ": " .. (value_ref[field] or "")
						vim.api.nvim_set_option_value("modifiable", true, { buf = buf })
						vim.api.nvim_buf_set_lines(buf, i - 1 + add_index, i + add_index, false, { str[i + add_index] })
						vim.api.nvim_set_option_value("modifiable", false, { buf = buf })
					end)
				end)
			end
		else
			for i, field in ipairs(value_type.fields) do
				table.insert(str, field .. ":")
				table.insert(field_ref, function()
					create_input(field, t, value_ref[field], function(value)
						value_ref[field] = value or value_ref[field]
						value_ref[field] = handle_nil(value_ref[field])
						str[i + add_index] = field .. ": " .. (value_ref[field] or "")
						vim.api.nvim_set_option_value("modifiable", true, { buf = buf })
						vim.api.nvim_buf_set_lines(buf, i - 1 + add_index, i + add_index, false, { str[i + add_index] })
						vim.api.nvim_set_option_value("modifiable", false, { buf = buf })
					end)
				end)
			end
		end
		vim.api.nvim_set_option_value("modifiable", true, { buf = buf })
		vim.api.nvim_buf_set_lines(buf, 0, -1, false, str)
		vim.api.nvim_set_option_value("modifiable", false, { buf = buf })
		vim.keymap.set("n", "<CR>", function()
			local line = vim.api.nvim_win_get_cursor(win)[1]
			field_ref[line]()
		end, { buffer = buf })
	end

	if value_type.lua_type == "enum" then
		create_input(name, t, properties_table[name] and properties_table[name].value or nil, function(value)
			local success, val = value_type.verification(enumeration, value)
			if success then
				if val == nil then
					properties_table[name] = nil
				else
					properties_table[name] = {
						json = {
							Enum = val,
						},
						value = value,
					}
				end
			end
			when_done()
		end)
		return
	end

	if value_type.lua_type ~= "table" and value_type.lua_type ~= "nested table" then
		create_input(
			value_type.fields[1],
			t,
			properties_table[name] and properties_table[name].value or nil,
			function(value)
				-- vim.print(type(value))
				local success, val = value_type.verification(value)
				if success then
					if val == nil then
						properties_table[name] = nil
					else
						properties_table[name] = {
							json = {
								[t] = val,
							},
							value = value,
						}
					end
				end
				when_done()
			end
		)
		return
	end

	if value_type.lua_type == "table" then
		local field_ref = {}
		local value_ref = {}
		local props = properties_table[name]
		dimensions.title = t
		dimensions.focus = true

		local buf, win = create_window(dimensions)
		if props and props.value then
			value_ref = vim.deepcopy(props.value)
		end
		disp_table(props, value_ref, field_ref, buf, win, nil, nil)
		vim.keymap.set("n", "<C-e>", function()
			local valid, value, validated_table = value_type.verification(value_ref)
			if valid then
				properties_table[name] = {
					json = {
						[t] = value,
					},
					value = vim.deepcopy(validated_table),
				}
			elseif properties_table[name] and not properties_table[name].json or not properties_table[name] then
				properties_table[name] = {
					value = vim.deepcopy(value_ref),
				}
			end
			when_done(true)
			props = properties_table[name]
			if props and props.value then
				value_ref = vim.deepcopy(props.value)
			end
			field_ref = {}
			disp_table(props, value_ref, field_ref, buf, win)
		end, { buffer = buf })
		vim.keymap.set("n", "Q", function()
			vim.api.nvim_win_close(win, true)
			when_done()
		end, { buffer = buf })
	end

	if value_type.lua_type == "nested table" then
		local props = properties_table[name]

		local value_ref = props and vim.deepcopy(props.value) or { {} }

		local index = 1
		dimensions.title = t
		dimensions.focus = true
		local buf, win = create_window(dimensions)
		disp_table(
			nil,
			value_ref[index],
			{ function() end },
			buf,
			win,
			value_ref[index],
			{ index .. "/" .. #value_ref }
		)

		vim.keymap.set("n", "<", function()
			if index == 1 then
				return
			end
			if next(value_ref[index]) == nil then
				table.remove(value_ref, index)
			end
			index = index - 1
			disp_table(
				nil,
				value_ref[index],
				{ function() end },
				buf,
				win,
				value_ref[index],
				{ index .. "/" .. #value_ref }
			)
		end, { noremap = true, buffer = buf })

		vim.keymap.set("n", ">", function()
			if next(value_ref[index]) == nil then
				return
			end
			index = index + 1
			value_ref[index] = value_ref[index] or {}
			disp_table(
				nil,
				value_ref[index],
				{ function() end },
				buf,
				win,
				value_ref[index],
				{ index .. "/" .. #value_ref }
			)
		end, { noremap = true, buffer = buf })

		vim.keymap.set("n", "Q", function()
			vim.api.nvim_win_close(win, true)
			when_done()
		end, { buffer = buf })

		vim.keymap.set("n", "<C-e>", function()
			local valid, value, validated_table = value_type.verification(value_ref)
			if valid then
				properties_table[name] = {
					json = {
						[t] = value,
					},
					value = vim.deepcopy(validated_table),
				}
			elseif properties_table[name] and not properties_table[name].json or not properties_table[name] then
				properties_table[name] = {
					value = vim.deepcopy(value_ref),
				}
			end
			when_done(true)
			props = properties_table[name]
			value_ref = props and vim.deepcopy(props.value) or value_ref
			if not value_ref[index] then
				index = math.min(#value_ref, 1)
			end
			disp_table(
				nil,
				value_ref[index],
				{ function() end },
				buf,
				win,
				value_ref[index],
				{ index .. "/" .. #value_ref }
			)
		end, { buffer = buf })
	end
end

local function disp_class(buf, class, inside_buf)
	local class_def = data.raw.Classes[class]
	if not class_def then
		error("unreachble state reached! Class: " .. class)
	end

	local saved_object_properties = data.saved_object_configs[class]
	local index = saved_object_properties.index or 1
	saved_object_properties.index = index
	local saved_property_tables = saved_object_properties.property_tables
	local saved_properties = saved_property_tables[index] or { properties = {} }
	saved_property_tables[index] = saved_properties
	local properties = saved_properties.properties

	if inside_buf then
		properties_list_ref = {
			{ t = "name", name = class },
			{ t = "config", name = class },
			{ t = "config", name = class },
			{ t = "name", name = class },
		}
	end

	local str = {
		class,
		"Current Config: " .. (saved_properties.name or ""),
		"Config: " .. index .. "/" .. #saved_property_tables,
		"Properties:",
	}

	for _, p in ipairs(class_def.PropertyKeys) do
		local pre = properties[p] and properties[p].json and " *" or "  "
		local lstr = pre .. p .. ": "
		local ref_table
		if class_def.Properties[p].ValueType.Category == "Enum" then
			lstr = lstr .. "Enum."
			if inside_buf then
				ref_table = { t = "Enum", enum = class_def.Properties[p].ValueType.Name, name = p }
			end
		else
			if inside_buf then
				ref_table = { t = class_def.Properties[p].ValueType.Name, name = p }
			end
		end
		lstr = lstr .. class_def.Properties[p].ValueType.Name
		if #class_def.Properties[p].Tags > 0 then
			local tag_str = " [Tags: " .. table.concat(class_def.Properties[p].Tags, ", ") .. "]"
			lstr = lstr .. tag_str
		end
		table.insert(str, lstr)
		if inside_buf then
			ref_table.props = saved_properties.properties
			ref_table.tags = class_def.Properties[p].Tags
			table.insert(properties_list_ref, ref_table)
		end
	end

	vim.api.nvim_set_option_value("modifiable", true, { buf = buf })
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, str)
	vim.api.nvim_set_option_value("modifiable", false, { buf = buf })
end

m.disp_class = disp_class

local function disp_class_list(buf, init)
	if init then
		class_list_ref = {}
	end
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
			if init then
				table.insert(str, "v " .. key .. "/")
			end
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

local function generate_dimensions(name, path, visual_path)
	local width = math.ceil((160 / 209) * vim.o.columns)
	local height = math.ceil((40 / 55) * vim.o.lines)

	if height - 6 <= 0 then
		vim.notify("Neovim window is too small, please make it larger", vim.log.levels.ERROR)
		return nil
	end

	vim.print(visual_path)

	local row = math.floor((vim.o.lines - height - 2) / 2)
	local col = math.floor((vim.o.columns - width - 2) / 2)
	return {
		path_bar = {
			title = 'Directory for "' .. name .. '"',
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
			contents = { visual_path },
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
			buffer_type = "prompt",
			keybinds = function(buf, win, l_buf, l_win, p_win, d_win)
				vim.keymap.set("n", "Q", function()
					vim.api.nvim_win_close(win, true)
					vim.api.nvim_win_close(d_win, true)
					vim.api.nvim_win_close(l_win, true)
					vim.api.nvim_win_close(p_win, true)
				end, { buffer = buf })

				vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
					buffer = buf,
					callback = function()
						local query = vim.fn.prompt_getinput(buf)
						if string.len(query) == 0 or query == "" then
							disp_class_list(l_buf, true)
							return
						end
						local str = {}
						local refs = {}
						local matches = {}

						query = string.lower(query)

						for class, _ in pairs(data.browsable_classes) do
							table.insert(matches, { name = class, lower_class = string.lower(class) })
						end

						matches = helpers.refine_search(vim.deepcopy(matches), query)

						for _, class in ipairs(matches) do
							local pre = data.favorites[class.name] and "* " or "  "

							table.insert(str, pre .. class.name)
							table.insert(refs, {
								t = "class",
								name = class.name,
							})
						end

						if #str == 0 then
							str = { "No matching classes" }
							refs = { { t = "nil", name = "" } }
						end

						class_list_ref = refs

						vim.api.nvim_set_option_value("modifiable", true, { buf = l_buf })
						vim.api.nvim_buf_set_lines(l_buf, 0, -1, false, str)
						vim.api.nvim_set_option_value("modifiable", false, { buf = l_buf })
					end,
				})

				vim.keymap.set("n", "<CR>", function()
					vim.api.nvim_set_current_win(l_win)
				end, { buffer = buf })

				vim.keymap.set("i", "<CR>", function()
					vim.cmd.stopinsert()
					vim.api.nvim_set_current_win(l_win)
				end, { buffer = buf })
			end,
		},

		class_edit_box = {
			width = math.ceil(width / 2) - 1,
			height = height - 6,
			col = col,
			row = row + 2,
			focus = true,
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
		},

		class_list = {
			title = "Classes",
			title_pos = "center",
			width = math.ceil(width / 2) - 1,
			height = height - 6,
			col = col,
			row = row + 2,
			focus = true,
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
			keybinds = function(buf, win, d_buf, d_win, p_win, s_win)
				vim.keymap.set("n", "Q", function()
					vim.api.nvim_win_close(win, true)
					vim.api.nvim_win_close(d_win, true)
					vim.api.nvim_win_close(s_win, true)
					vim.api.nvim_win_close(p_win, true)
				end, { buffer = buf })
				vim.keymap.set("n", "/", function()
					vim.api.nvim_set_current_win(s_win)
					vim.cmd.startinsert()
				end, { buffer = buf })
				vim.keymap.set("n", "<CR>", function()
					local line = vim.api.nvim_win_get_cursor(win)[1]
					if class_list_ref[line].t == "class" then
						current_class = class_list_ref[line].name
						vim.api.nvim_set_current_win(d_win)
						disp_class(d_buf, class_list_ref[line].name, true)
					elseif class_list_ref[line].t == "category" then
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
							current_class = ref.name
							disp_class(d_buf, ref.name)
						end
					end,
				})
				vim.keymap.set("n", "F", function()
					local line = vim.api.nvim_win_get_cursor(win)[1]
					if class_list_ref[line].t == "class" then
						data.toggle_favorite(class_list_ref[line].name)
						if class_list_ref[1].t == "category" then
							modify_class_list(buf, "Favorites", 1, true, class_list_ref[line].name)
						end
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
			keybinds = function(buf, win, class_edit_box, l_win, s_win, p_win)
				vim.keymap.set("n", "Q", function()
					vim.api.nvim_win_close(win, true)
					vim.api.nvim_win_close(l_win, true)
					vim.api.nvim_win_close(s_win, true)
					vim.api.nvim_win_close(p_win, true)
				end, { buffer = buf })
				vim.keymap.set("n", "<CR>", function()
					local line = vim.api.nvim_win_get_cursor(win)[1]
					local prop = properties_list_ref[line]
					if prop.t ~= "name" and prop.t ~= "config" then
						local function when_done(stay)
							local pre = prop.props[prop.name] and prop.props[prop.name].json and " *" or "  "
							local lstr = pre .. prop.name .. ": "
							if prop.t == "Enum" then
								lstr = lstr .. "Enum."
							end
							lstr = lstr .. prop.t
							if #prop.tags > 0 then
								local tag_str = " [Tags: " .. table.concat(prop.tags, ", ") .. "]"

								lstr = lstr .. tag_str
							end
							vim.api.nvim_set_option_value("modifiable", true, { buf = buf })
							vim.api.nvim_buf_set_lines(buf, line - 1, line, false, { lstr })
							vim.api.nvim_set_option_value("modifiable", false, { buf = buf })
							if not stay then
								vim.api.nvim_set_current_win(win)
							end
						end
						disp_property(prop.t, prop.props, prop.name, class_edit_box, when_done, prop.enum)
					end
				end, { buffer = buf })
				vim.keymap.set("n", "<C-e>", function()
					local saved_object_properties = data.saved_object_configs[current_class]
					local index = saved_object_properties.index or 1
					saved_object_properties.index = index
					local properties = saved_object_properties.property_tables[index] or { properties = {} }
					saved_object_properties.property_tables[index] = properties
					local json_table = {}
					for property, i in pairs(properties.properties) do
						json_table[property] = i.json
					end
					create_input("Input", "Return 'yes' to use current config", "yes", function(value)
						if value ~= "yes" then
							json_table = vim.deepcopy({})
						end
						if current_class then
							writer.create_file(
								name,
								current_class,
								json_table,
								path,
								string.match(current_class, "Script")
							)
						end
					end, "Do you want to use the current config?")
				end, { buffer = buf })
				vim.keymap.set("n", "S", function()
					local line = vim.api.nvim_win_get_cursor(win)[1]
					if line <= 4 then
						return
					end
					local prop = properties_list_ref[line]
					prop.props[prop.name] = nil
					local pre = "  "
					local lstr = pre .. prop.name .. ": "
					if prop.t == "Enum" then
						lstr = lstr .. "Enum."
					end
					lstr = lstr .. prop.t
					if #prop.tags > 0 then
						local tag_str = " [Tags: " .. table.concat(prop.tags, ", ") .. "]"

						lstr = lstr .. tag_str
					end
					vim.api.nvim_set_option_value("modifiable", true, { buf = buf })
					vim.api.nvim_buf_set_lines(buf, line - 1, line, false, { lstr })
					vim.api.nvim_set_option_value("modifiable", false, { buf = buf })
				end, { buffer = buf })
				vim.keymap.set("n", "C", function()
					local saved_object_properties = data.saved_object_configs[current_class]
					local index = saved_object_properties.index
					local properties = saved_object_properties.property_tables[index] or { properties = {} }
					saved_object_properties.property_tables[index] = properties
					create_input("Name", "duplicate names are valid, leave blank to cancel", nil, function(value)
						if not value then
							return
						end
						properties.name = value
						disp_class(buf, current_class, true)
					end, "Name of config")
				end, { buffer = buf })
				vim.keymap.set("n", "<", function()
					local saved_object_properties = data.saved_object_configs[current_class]
					local index = saved_object_properties.index
					if index == 1 then
						return
					end
					index = index - 1
					saved_object_properties.index = index

					disp_class(buf, current_class, true)
				end, { buffer = buf })
				vim.keymap.set("n", ">", function()
					local saved_object_properties = data.saved_object_configs[current_class]
					local index = saved_object_properties.index
					if not saved_object_properties.property_tables[index].name then
						return
					end
					index = index + 1

					disp_class(buf, current_class, true)
				end, { buffer = buf })
				vim.keymap.set("n", "D", function()
					create_input("Confirm", "Return 'yes' to delete current config", "no", function(value)
						if value ~= "yes" then
							return
						end
						local saved_object_properties = data.saved_object_configs[current_class]
						local index = saved_object_properties.index
						table.remove(saved_object_properties.property_tables, index)
						disp_class(buf, current_class, true)
					end, "Are you sure you want to delete the current config?")
				end, { buffer = buf })

				vim.keymap.set("n", "<Esc>", function()
					vim.api.nvim_set_current_win(l_win)
				end, { buffer = buf })
			end,
		},
	}
end

m.generate_dimensions = generate_dimensions
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
