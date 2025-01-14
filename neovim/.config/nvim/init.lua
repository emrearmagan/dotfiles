require("config.lazy")

vim.opt.number = true
vim.opt.relativenumber = true

vim.opt.guicursor = "n-v-c:ver25,i:ver25,r-cr:ver25"

-------------------- Keybindings ------------------------

--- to open Neotree press space + e
vim.keymap.set("n", "<leader>e", ":Neotree toggle<CR>", { silent = true })

--- Telescope key maps
local builtin = require('telescope.builtin')
vim.keymap.set('n', '<leader>ff', builtin.find_files, { desc = 'Telescope find files' })
vim.keymap.set('n', '<leader>fg', builtin.live_grep, { desc = 'Telescope live grep' })
vim.keymap.set('n', '<leader>fb', builtin.buffers, { desc = 'Telescope buffers' })
vim.keymap.set('n', '<leader>fh', builtin.help_tags, { desc = 'Telescope help tags' })
