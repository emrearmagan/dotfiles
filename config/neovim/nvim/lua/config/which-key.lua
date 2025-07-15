local wk = require("which-key")
local conform = require("conform")

-------------------- Keybindings ------------------------

wk.add({
  -- ----- Show all Keybinding -----
  { "<leader>?", group = "<cmd>WhichKey<cr>"m desc = "Show Keymap Cheatsheet" mode = "n" },
  
  -- ----- File -----
  { "<leader>f", group = "File" },
  { "<leader>ff", "<cmd>Telescope find_files<cr>", desc = "Find File", mode = "n" },

  -- ----- Tree -----
  { "<leader>n", group = "Tree" },
  { "<leader>ne", ":Neotree toggle<CR>", desc = "Toggle Tree" },

  -- ----- Search (FzfLua) -----
  { "<leader>f", group = "Search" },
  { "<leader>ff", "<cmd>FzfLua files<CR>", desc = "Find files" },
  { "<leader>fg", "<cmd>FzfLua live_grep<CR>", desc = "Live grep" },
  { "<leader>fb", "<cmd>FzfLua buffer<CR>", desc = "Find buffer" },
  { "<leader>ft", "<cmd>FzfLua help_tag<CR>", desc = "Find help tags" },

  -- ----- Formatting -----
  { "<leader>i", group = "Format" },
  { "<leader>ii", function()
      require("conform").format({ async = true, lsp_fallback = true })
    end, desc = "Format Buffer" },

  -- ----- Buffers -----
  { "<leader>b", group = "Buffers", expand = function()
      return require("which-key.extras").expand.buf()
    end
  },

  -- ----- Windows -----
  { "<leader>w", proxy = "<c-w>", group = "Windows" },

  -- ----- Quit/Write -----
  {
    mode = { "n", "v" }, -- Apply to NORMAL and VISUAL mode
    { "<leader>q", "<cmd>q<cr>", desc = "Quit" },
    { "<leader>w", "<cmd>w<cr>", desc = "Write" },
  },

  -- ----- Custom -----
  { "<leader>o", ':!open %:h<CR>', desc = "Open in Finder" },
})