require("config.lazy")

vim.opt.number = true
vim.opt.relativenumber = true

vim.opt.guicursor = "n-v-c:ver25,i:ver25,r-cr:ver25"

-------------------- Keybindings ------------------------

--- to open Neotree press space + e
vim.keymap.set("n", "<leader>e", ":Neotree toggle<CR>", { silent = true })

--- Telescope key maps
local builtin = require('telescope.builtin')
vim.keymap.set('n', '<leader>tf', builtin.find_files, { desc = 'Telescope find files' })
vim.keymap.set('n', '<leader>tg', builtin.live_grep, { desc = 'Telescope live grep' })
vim.keymap.set('n', '<leader>tb', builtin.buffers, { desc = 'Telescope buffers' })
vim.keymap.set('n', '<leader>th', builtin.help_tags, { desc = 'Telescope help tags' })


    -- Keybindings for fzf-lua
vim.keymap.set("n", "<leader>ff", "<cmd>FzfLua files<CR>", { desc = "Find files" })
vim.keymap.set("n", "<leader>fg", "<cmd>FzfLua live_grep<CR>", { desc = "Live grep" })
vim.keymap.set("n", "<leader>fb", "<cmd>FzfLua buffers<CR>", { desc = "Find buffers" })
vim.keymap.set("n", "<leader>fh", "<cmd>FzfLua help_tags<CR>", { desc = "Find help tags" })
