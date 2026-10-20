local vim = vim

local t = {}

t.actions = {
	"open_browser",
	"select_dir",
	"enter_parent_dir",
	"add_dir",
	"delete_dir",
	"name_file",
	"close_dir_window",
	"toggle_file_visibility",
	"enable_file_visibility",
	"disable_file_visibility",

	"close_input",
	"save_input",

	"start_search",
	"close_browser_window",
	"rename_file",
	"choose_new_dir",
	"select_class",
	"toggle_favorite_class",
	"favorite_class",
	"unfavorite_class",
	"toggle_category",
	"show_category",
	"hide_category",

	"close_browser_window",
	"rename_file",
	"choose_new_dir",
	"select_param",
	"export_class",
	"clear_param",
	"save_class_config",
	"prev_class_config",
	"next_class_config",
	"enter_list",
	"delete_config",
	"duplicate_config",

	"close_property",
	"export_property",
	"select_param_field",
	"next_keypoint",
	"prev_keypoint",

	"search_close_browser_window",
	"search_enter_list",
}

t.command_names = {
	"OpenBrowser",
	"SelectDir",
	"EnterParentDir",
	"AddDir",
	"DeleteDir",
	"NameFile",
	"CloseDirWindow",
	"ToggleFileVisibility",
	"EnableFileVisibility",
	"DisableFileVisibility",

	"CloseInput",
	"SaveInput",

	"StartSearch",
	"CloseBrowser",
	"RenameFile",
	"ChooseNewDir",
	"SelectClass",
	"ToggleFavorite",
	"FavoriteClass",
	"UnfavoriteClass",
	"ToggleCategory",
	"ShowCategory",
	"HideCategory",

	"CloseBrowser",
	"RenameFile",
	"ChooseNewDir",
	"SelectParam",
	"ExportClass",
	"ClearParam",
	"SaveConfig",
	"PrevConfig",
	"NextConfig",
	"EnterList",
	"DeleteConfig",

	"CloseEditParam",
	"SaveParam",
	"SelectParamField",
	"NextKeypoint",
	"PrevKeypoint",

	"CloseBrowser",
	"EnterList",
}

local function assign_command(buf, command_name, keybinds, func)
	vim.api.nvim_buf_create_user_command(buf, command_name, func, {
		desc = command_name,
	})

	if keybinds then
		for keybind, _ in pairs(keybinds) do
			vim.keymap.set("n", keybind, func, {
				buffer = buf,
				desc = command_name,
			})
		end
	end
end

t.assign_command = assign_command

t.default_keybinds = {
	groups = {
		export = {
			keybind = "<C-e>",
			actions = {
				"export_class",
				"export_property",
			},
		},

		select = {
			keybind = "<CR>",
			actions = {
				"select_class",
				"select_dir",
				"select_param",
				"select_param_field",
				"search_enter_list",
			},
		},

		close_window = {
			keybind = "Q",
			actions = {
				"close_browser_window",
				"close_input",
				"close_dir_window",
				"close_property",
			},
		},

		delete = {
			keybind = "D",
			actions = {
				"delete_config",
				"delete_dir",
			},
		},

		next = {
			keybind = ">",
			actions = {
				"next_config",
				"next_keypoint",
			},
		},

		prev = {
			keybind = "<",
			actions = {
				"prev_config",
				"prev_keypoint",
			},
		},
	},

	actions = {
		duplicate_config = "P",
		toggle_favorite_class = "F",
		start_search = "/",
		rename_file = "R",
		choose_new_dir = "d",
		create_dir = "d",
		class_enter_list = "<Esc>",
		name_class_config = "C",
		toggle_file_visibility = "H",
		name_file = "%",
	},
}

local defaults = {
	custom_keybinds = {
		groups = {},
		actions = {},
	},

	keybinds = {},
	src_name = "src",

	confirm_delete = true,

	files_visible = true,

	allow_overwrite = false,
	confirm_overwrite = true,

	enable_default_keybinds = true,
}

t.config = vim.deepcopy(defaults)
local function convert_keybind_config(opts, k, d)
	for _, group in pairs(k.groups) do
		for _, action in ipairs(group.actions) do
			if not opts.keybinds[action] then
				opts.keybinds[action] = {}
				opts.keybinds[action][group.keybind] = true
			elseif not d then
				opts.keybinds[action][group.keybind] = true
			end
		end
	end

	for action, keybind in pairs(k.actions) do
		if not opts.keybinds[action] then
			opts.keybinds[action] = {}
			opts.keybinds[action][keybind] = true
		elseif not d then
			opts.keybinds[action][keybind] = true
		end
	end
end

local function assign_keybinds(opts)
	convert_keybind_config(opts, opts.custom_keybinds)
	if opts.enable_default_keybinds then
		convert_keybind_config(opts, t.default_keybinds, true)
	end
end

assign_keybinds(t.config)

local function setup(opts)
	opts = opts or {}
	t.config = vim.tbl_deep_extend("force", vim.deepcopy(defaults), opts)
	assign_keybinds(t.config)
end

t.setup = setup

return t
