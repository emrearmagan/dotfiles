local wk = require("which-key")
local conform = require("conform")

-------------------- Keybindings ------------------------

wk.add({
  -- ----- File -----
  { "<leader>f",  group = "File" },
  { "<leader>ff", "<cmd>Telescope find_files<cr>", desc = "Find File",     mode = "n" },

  -- ----- Tree -----
  { "<leader>n",  group = "Tree" },
  { "<leader>ne", ":Neotree toggle<CR>",           desc = "Toggle Tree" },
  { "<leader>ng", "<cmd>LazyGit<cr>",              desc = "LazyGit" },

  -- ----- Search (FzfLua) -----
  { "<leader>f",  group = "Search" },
  { "<leader>ff", "<cmd>FzfLua files<CR>",         desc = "Find files" },
  { "<leader>fg", "<cmd>FzfLua live_grep<CR>",     desc = "Live grep" },
  { "<leader>fb", "<cmd>FzfLua buffers<CR>",       desc = "Find buffer" },
  { "<leader>ft", "<cmd>FzfLua help_tags<CR>",     desc = "Find help tags" },

  { "<leader>fo", ':!open %:h<CR>',                desc = "Open in Finder" },

  -- ----- Formatting -----
  { "<leader>i",  group = "Format" },
  {
    "<leader>ii",
    function()
      require("conform").format({ async = true, lsp_fallback = true })
    end,
    desc = "Format Buffer"
  },

  -- ----- Tabs & Split -----
  { "<leader>t",  group = "Tabs & Splits" },
  { "<leader>tt", "<cmd>tabnew<cr>",      desc = "New Tab",              mode = "n" },
  { "<leader>tv", "<cmd>vsplit<cr>",      desc = "Vertical Split",       mode = "n" },
  { "<leader>th", "<cmd>split<cr>",       desc = "Horizontal Split",     mode = "n" },

  -- ----- Quick / File -----
  { "<leader>q",  group = "Quick / File" },
  { "<leader>qq", ":bd!<CR>",             desc = "Close buffer (force)", mode = "n" },
  { "<leader>qs", ":w<CR>",               desc = "Save file",            mode = "n" },
  { "<leader>qS", ":wa<CR>",              desc = "Save all files",       mode = "n" },
  { "<leader>qx", ":x<CR>",               desc = "Save & close file",    mode = "n" },
  { "<leader>qQ", ":q!<CR>",              desc = "Quit without saving",  mode = "n" },
  { "<leader>qW", ":wq<CR>",              desc = "Save and quit",        mode = "n" },
  { "<leader>qA", ":wqa<CR>",             desc = "Save all & quit",      mode = "n" },
  -- ----- Custom -----

})
