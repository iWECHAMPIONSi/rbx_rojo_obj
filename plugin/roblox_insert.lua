if vim.g.loaded_roblox_insert == 1 then
	return
end

vim.g.loaded_roblox_insert = 1

vim.api.nvim_create_user_command("RbxCreate", function(opts)
	if #opts.fargs ~= 2 and #opts.fargs ~= 3 then
		vim.notify("Usage: RbxCreate <name> <class> <dir?>", vim.log.levels.ERROR)
		return
	end
	if opts.fargs[3] then
		opts.fargs[3] = vim.fn.fnamemodify(opts.fargs[3], ":p")
	end

	require("roblox_insert.commands").create_file(opts.fargs[1], opts.fargs[2], opts.fargs[3])
end, {
	nargs = "+",
	desc = "Create a Roblox Object in the current buffer's directory or a directory specified starting from neovim's working directory",
})

vim.api.nvim_create_user_command("RbxBrowser", function()
	require("roblox_insert.commands").open_browser()
end, {
	desc = "Opend a browser similar to roblox's",
})
