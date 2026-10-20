# rbx_rojo_obj
This plugin is designed to make creating new objects and scripts as easy as possible

## How to Install
for Lazy just do
```lua
{
    'iWECHAMPIONSi/rbx_rojo_obj'
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

### How to assign keybinds

There are 2 methods:
```lua
keybinds = {
    export_class = {"<C-e>",},
}
```
The format is just `<action> = {<keybind1>, <keybind2> ...}`

The second method is usefull for grouping

```lua
custom_keybinds = {
    groups = {
        my_group = {
            keybind = "Q",
            actions = {
                "close_browser_window",
                "close_input",
                "close_dir_window",
                "close_property",
            },
        },
    },
    actions = {
        start_search = "/",
    },
}
```


Note that for this one, it's a single keybind and not a table of keybinds.
If you choose to assign keybinds to an action, the default keybindings will not be assigned to that action. It's reccomended to check and make sure that you aren't assigning keybinds that conflict.

I didn't implement keybind conflict checking, although at the end there will be a list of all actions and their assosiated buffer(s).

Buffers:
There are buffers to be aware of when using commands and keybindings.  
`Classes`  
`Class`  
`Search`  
`Directory Browser`  







