vim.g.mapleader = " "
vim.keymap.set("n", " ", "<Nop>", { silent = true, remap = false })
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv", { desc = "Move selection down" })
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv", { desc = "Move selection up" })

vim.keymap.set("n", "Y", "y$", { desc = "Yank to end-of-line" })
vim.keymap.set("n", "J", "mzJ`z", { desc = "Join lines (cursor stays)" })

vim.keymap.set("n", "<C-d>", "<C-d>zz", { desc = "Half-page down & center" })
vim.keymap.set("n", "<C-u>", "<C-u>zz", { desc = "Half-page up & center" })

vim.keymap.set("n", "n", "nzzzv", { desc = "Next search (centered)" })
vim.keymap.set("n", "N", "Nzzzv", { desc = "Prev search (centered)" })

vim.keymap.set("n", "<leader>d", '"_d', { desc = "Delete without yank" })
vim.keymap.set("v", "<leader>d", '"_d', { desc = "Delete without yank" })

-- Basic Options
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.tabstop = 2 -- Number of spaces a tab counts for
vim.opt.softtabstop = 2 -- Number of spaces per Tab when editing
vim.opt.shiftwidth = 2 -- Number of spaces for indentation
vim.opt.expandtab = true -- Convert tabs to spaces
vim.opt.scrolloff = 8 -- Lines to keep above and below the cursor
vim.opt.clipboard = "unnamedplus" -- Sync yank with clipboard

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
