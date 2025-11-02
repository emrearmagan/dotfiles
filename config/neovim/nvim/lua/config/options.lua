vim.g.mapleader = " "
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

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

-- Auto-reload files when changed externally
vim.opt.autoread = true
vim.opt.updatetime = 1000 -- Reduce update time (default is 4000ms)
vim.api.nvim_create_autocmd({ "FocusGained", "TermClose", "TermLeave" }, {
	command = "checktime",
})

-- Also check on buffer enter and cursor hold
vim.api.nvim_create_autocmd({ "BufEnter", "CursorHold", "CursorHoldI", "FocusGained" }, {
	command = "if mode() != 'c' | checktime | endif",
	pattern = { "*" },
})
