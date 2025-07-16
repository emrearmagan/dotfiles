local wk = require("which-key")
local conform = require("conform")

-------------------- Keybindings ------------------------

wk.add({  
  { "<leader>?", "<cmd>WhichKey<cr>", desc = "Show all keybindings", mode = "n" },

  -- ----- File -----
  { "<leader>f", group = "File" },
  { "<leader>ff", "<cmd>Telescope find_files<cr>", desc = "Find File", mode = "n" },

  -- ----- Tree -----
  { "<leader>n", group = "Tree" },
  { "<leader>ne", ":Neotree toggle<CR>", desc = "Toggle Tree" },
  { "<leader>ng", "<cmd>LazyGit<cr>", desc = "LazyGit" },

  -- ----- Search (FzfLua) -----
  { "<leader>f", group = "Search" },
  { "<leader>ff", "<cmd>FzfLua files<CR>", desc = "Find files" },
  { "<leader>fg", "<cmd>FzfLua live_grep<CR>", desc = "Live grep" },
  { "<leader>fb", "<cmd>FzfLua buffer<CR>", desc = "Find buffer" },
  { "<leader>ft", "<cmd>FzfLua help_tag<CR>", desc = "Find help tags" },
  { "<leader>fo", ':!open %:h<CR>', desc = "Open in Finder" },

  -- ----- Formatting -----
  { "<leader>i", group = "Format" },
  { "<leader>ii", function()
      require("conform").format({ async = true, lsp_fallback = true })
    end, desc = "Format Buffer" },

  -- ----- Tabs & Split -----
  { "<leader>t", group = "Tabs & Splits" },
  { "<leader>tt", "<cmd>tabnew<cr>", desc = "New Tab", mode = "n" },
  { "<leader>tv", "<cmd>vsplit<cr>", desc = "Vertical Split", mode = "n" },
  { "<leader>th", "<cmd>split<cr>", desc = "Horizontal Split", mode = "n" },

  -- ----- Custom -----
})
