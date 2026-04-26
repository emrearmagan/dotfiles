vim.g.mapleader = " "
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

local deprecate = vim.deprecate
---@diagnostic disable-next-line: duplicate-set-field
vim.deprecate = function(...)
	local trace = debug.traceback("", 2)
	--- lualine-ex has a deprecation warning which works for now. Simply ignore it until lualine-ex is updated to remove the deprecation warning.
	if trace:find("lualine%-ex", 1, false) then
		return
	end
	return deprecate(...)
end

-- Basic Options
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.tabstop = 2 -- Number of spaces a tab counts for
vim.opt.softtabstop = 2 -- Number of spaces per Tab when editing
vim.opt.shiftwidth = 2 -- Number of spaces for indentation
vim.opt.expandtab = true -- Convert tabs to spaces
vim.opt.scrolloff = 8 -- Lines to keep above and below the cursor
vim.opt.clipboard = "unnamedplus" -- Sync yank with clipboard
vim.opt.fillchars = { eob = " " } -- Hide ~ on empty lines
vim.env.PATH = table.concat({
	"/opt/homebrew/bin",
	vim.fn.expand("~/.luarocks/bin"),
	vim.env.PATH,
}, ":")

-- Auto-reload files when changed externally
vim.opt.autoread = true
vim.opt.updatetime = 1000 -- Reduce update time (default is 4000ms)
vim.opt.cmdheight = 0
vim.opt.foldlevel = 99
vim.opt.foldlevelstart = 99
vim.opt.foldenable = true

-- Custom filetype mappings
vim.filetype.add({
	filename = {
		Brewfile = "ruby",
		[".http"] = "http",
		[".rest"] = "rest",
	},
	extension = {
		yml = "yaml",
		http = "http",
		rest = "rest",
	},
	pattern = {
		[".*%.yml"] = "yaml",
	},
})
