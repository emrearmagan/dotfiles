require("config.lazy")

-- Basic Options
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.tabstop = 2       -- Number of spaces a tab counts for
vim.opt.softtabstop = 2   -- Number of spaces per Tab when editing
vim.opt.shiftwidth = 2    -- Number of spaces for indentation
vim.opt.expandtab = true  -- Convert tabs to spaces

-------------------- Keybindings ------------------------

local wk = require("which-key")
local conform = require("conform")

wk.add({
    ---- Neotree
    { "<leader>n", group = "Tree" },
    { "<leader>ne", ":Neotree toggle<CR>", desc = "Toggle Tree" },

    ---- Fzf
    { "<leader>f", group = "Search"},
    { "<leader>ff", "<cmd>FzfLua files<CR>", desc = "Find files" },
    { "<leader>fg", "<cmd>FzfLua live_grep<CR>", desc = "Live grep" },
    { "<leader>fb", "<cmd>FzfLua buffer<CR>", desc = "Find buffer" },
    { "<leader>ft", "<cmd>FzfLua help_tag<CR>", desc = "Find help tags"},

    ---- Formatting
    { "<leader>i", group = "Format"},
    { "<leader>ii", function() require("conform").format({ async = true, lsp_fallback = true }) end, desc = "Format Buffer" },

    ---- Custom
    { "<leader>o", ':!open %:h<CR>', desc = "Open in Finder" },
})
