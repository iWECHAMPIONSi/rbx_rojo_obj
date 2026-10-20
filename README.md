# rbx_rojo_obj
This plugin is designed to make creating new objects and scripts as easy as possible

## How to Install
for Lazy just do
```lua
{
    'iWECHAMPIONSi/rbx_rojo_obj',
    opts = {},
},
```

## How to Config

The default configuration is this

```lua
require('rbx_rojo_obj').setup({
	custom_keybinds = {
		groups = {},
		actions = {},
	},

	keybinds = {},
	src_name = "src", -- the default name for your project's source directory (my_project/src)

	confirm_delete = true, -- Asks if you want to delete something if enabled

	files_visible = true, -- If non-directory files are visible be default in the directory browser if enabled

	allow_overwrite = false, -- If it will allow for you to create a file or directory with the same name as one in the current directory if enabled
	confirm_overwrite = true, -- same as confirm_delete but for overwriting a file if enabled

	enable_default_keybinds = true, -- Any unassigned keybinds will default to predefined keybinds if enabled
})
```

Or if you want to do it in Lazy then

```lua
{
    'iWECHAMPIONSi/rbx_rojo_obj',
    opts = {
        custom_keybinds = {
            groups = {},
            actions = {},
        },

        keybinds = {},
        src_name = "src", -- the default name for your project's source directory (my_project/src)

        confirm_delete = true, -- Asks if you want to delete something if enabled

        files_visible = true, -- If non-directory files are visible be default in the directory browser if enabled

        allow_overwrite = false, -- If it will allow for you to create a file or directory with the same name as one in the current directory if enabled
        confirm_overwrite = true, -- same as confirm_delete but for overwriting a file if enabled

        enable_default_keybinds = true, -- Any unassigned keybinds will default to predefined keybinds if enabled
    },
},
```

### How to assign keybinds

There are 2 methods:
```lua
keybinds = {
    export_class = { "<C-e>", "<leader>e" },
}
```
The format is just `<action> = {<keybind1>, <keybind2> ...}`

The second method is usefull for grouping

```lua
custom_keybinds = {
    groups = {
        my_group = {
            keybinds = { "Q", "q", },
            actions = {
                "close_browser_window",
                "close_input",
                "close_dir_window",
                "close_property",
            },
        },
    },
    actions = {
        start_search = { "/" },
    },
}
```

Both methods will apply equally, so if an action is listed in `actions`, `my_group`, and `keybinds`, it will recieve all of those keybinds.

If you choose to list an action, regardless of assigning a keybinding to it or not, the default keybindings will not be assigned to that action. It's reccomended to check and make sure that you aren't assigning keybinds that conflict within the same buffer.

I didn't implement keybind conflict checking, there's a table that shows each action and its assosiated buffer(s).

Buffers:
There are buffers to be aware of when using commands and keybindings.  
`Class List`  
`Class Display`  
`Search Bar`  
`Property Editor`  
`Input`  
`Directory Browser`  

all actions/commands are in `normal` mode

| Action | Buffers | Description | Keybind | Command |
| :----: | :-----: | :---------- | :-----: | :------ |
| `N/A` | `Global` | Opens the browser |`N/A`| `:RbxBrowser` |
| select_dir | `Directory Browser` | Enters/selects the highlighted directory | `<CR>` | `:SelectDir` |
| enter_parent_dir | `Directory Browser` | Enters the parent directory | `-` | `:EnterParentDir` |
| add_dir | `Directory Browser` | Adds a new directory inside the current directory | `d` | `:CreateDir` |
| delete_dir | `Directory Browser` | Recursively deletes the highlighted directory | `D` | `:DeleteDir` |
| name_file | `Directory Browser` | Asks for the name of the file before switching to Class browser | `%` | `:NameFile` |
| close_dir_window | `Directory Browser` | Closes the directory browser | `Q` | `:CloseDirWindow` |
| toggle_file_visibility | `Directory Browser` | Toggles the visibility of non-directory files | `H` | `:ToggleFileVisibility` |
| enable_file_visibility | `Directory Browser` | Enables the visibility of non-directory files | `Not Bound` | `:EnableFileVisibility` |
| disable_file_visibility | `Directory Browser` | Disables the visibility of non-directory files | `Not Bound` | `:DisableFileVisibility` |
| close_input | `Input` | Closes the input without saving | `Q` | `:CloseInput` |
| start_search | `Class List` | Enters the Search Bar | `/` | `:StartSearch` |
| close_browser_window | `Class List` `Class Display` `Search Bar` | Closes Class browser | `Q` | `:CloseBrowser` |
| rename_file | `Class List` `Class Display` | Changes the output filename | `R` | `:RenameFile` |
| choose_new_dir | `Class List` `Class Display` | Changes the output directory | `d` | `:ChooseNewDir` |
| select_class | `Class List` | Selects the highlighted class or toggles the highlighted category | `<CR>` | `:SelectClass` |
| toggle_favorite_class | `Class List` | Toggles favoriting/unfavoriting a class | `F` | `:ToggleFavorite` |
| favorite_class | `Class List` | Adds the highlighted class to favorites | `Not Bound` | `:FavoriteClass` |
| unfavorite_class | `Class List` | Removes the highlighted class from favorites | `Not Bound` | `:UnfavoriteClass` |
| select_property | `Class Display` | Selects highlighted property | `<CR>` | `:SelectProperty` |
| export_class | `Class Display` | Exports the current class as a file | `<C-e>` | `:ExportClass` |
| clear_property | `Class Display` | Clears the saved data from the highlighted property | `S` | `:ClearProperty` |
| save_class_config | `Class Display` | Saves/renames the current class config | `C` | `:SaveConfig` |
| delete_config | `Class Display` | Deletes current class config | `D` | `:DeleteConfig` |
| prev_config | `Class Display` | Switches to the previous class config | `<` | `:PrevConfig` |
| next_config | `Class Display` | Switches to the next class config | `>` | `:NextConfig` |
| duplicate_config | `Class Display` | Duplicates the current named config | `P` | `:DuplicateConfig` |
| enter_list | `Class Display` | Enters into the Class list | `<Esc>` | `:EnterList` | 
| close_property | `Property Editor` | Exits the property editor without saving | `Q` | `:CloseProperty` |
| save_property | `Property Editor` | Validates and saves the edited property | `<C-e>` | `:SaveProperty` |
| select_field | `Property Editor` | Selects the highlighted field | `<CR>` | `:SelectField` |
| next_keypoint | `Property Editor` | Displays the next keypoint | `>` | `:NextKeypoint` |
| prev_keypoint | `Property Editor` | Displays the previous keypoint | `<` | `:PrevKeypoint` |
| search_enter_list | `Search Bar` | Enters into the Class list | `<CR>` | `:EnterList` |

