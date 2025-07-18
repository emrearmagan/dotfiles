local wk = require("which-key")

-------------------- Keybindings ------------------------

wk.add({
  -- ----- File -----
  { "<leader>f",  group = "File" },
  { "<leader>ff", "<cmd>Telescope find_files<cr>", desc = "Find File",     mode = "n" },

  -- ----- Tree -----
  { "<leader>n",  group = "Tree" },
  { "<leader>N",  ":Neotree toggle<CR>",           desc = "Toggle Tree" },
  { "<leader>ne", ":Neotree toggle<CR>",           desc = "Toggle Tree" },
  { "<leader>ng", "<cmd>LazyGit<cr>",              desc = "LazyGit" },

  -- ----- Search (FzfLua) -----
  { "<leader>f",  group = "Search" },
  { "<leader>ff", "<cmd>FzfLua files<CR>",         desc = "Find files" },
  { "<leader>fg", "<cmd>FzfLua live_grep<CR>",     desc = "Live grep" },
  { "<leader>fb", "<cmd>FzfLua buffers<CR>",       desc = "Find buffer" },
  { "<leader>ft", "<cmd>FzfLua help_tags<CR>",     desc = "Find help tags" },
  {
    "<leader>fd",
    function()
      require("fzf-lua").files({
        prompt = "Change Dir❯ ",
        cwd_prompt = true,
        cmd = "find . -type d -not -path '*/\\.git/*'",
        actions = {
          ["default"] = function(selected)
            local raw = selected[1]
            -- Remove any icons or extra characters (e.g., “ ./config/iterm” → “./config/iterm”)
            local path = raw:gsub("^[^%w./~]+", ""):gsub("%s+$", "") -- strip leading icons and trailing spaces
            path = vim.fn.fnamemodify(path, ":p")                    -- expand to full path

            vim.cmd("cd " .. vim.fn.fnameescape(path))
            print("Changed cwd to " .. path)
            vim.cmd("Neotree reveal")
          end
        }
      })
    end,
    desc = "Find directory"
  },

  { "<leader>fo", ':!open %:h<CR>',           desc = "Open in Finder" },

  -- ----- Tabs & Split -----
  { "<leader>t",  group = "Tabs & Splits" },
  { "<leader>tt", "<cmd>tabnew<cr>",          desc = "New Tab",                    mode = "n" },
  { "<leader>tv", "<cmd>vsplit<cr>",          desc = "Vertical Split",             mode = "n" },
  { "<leader>th", "<cmd>split<cr>",           desc = "Horizontal Split",           mode = "n" },

  -- ----- Quick / File -----
  { "<leader>q",  group = "Quick / File" },
  { "<leader>qq", ":bd!<CR>",                 desc = "Close buffer (force)",       mode = "n" },
  { "<leader>qs", ":w<CR>",                   desc = "Save file",                  mode = "n" },
  { "<leader>qS", ":wa<CR>",                  desc = "Save all files",             mode = "n" },
  { "<leader>qx", ":x<CR>",                   desc = "Save & close file",          mode = "n" },
  { "<leader>qQ", ":q!<CR>",                  desc = "Quit without saving",        mode = "n" },
  { "<leader>qW", ":wq<CR>",                  desc = "Save and quit",              mode = "n" },
  { "<leader>qA", ":wqa<CR>",                 desc = "Save all & quit",            mode = "n" },

  -- ----- Coding -----
  -- ----- (LSP) -----
  { "<leader>c",  group = "Code" },
  { "<leader>cK", vim.lsp.buf.hover,          desc = "Hover Info (LSP)",           mode = "n" },
  { "<leader>cd", vim.lsp.buf.definition,     desc = "Go to Definition (LSP)",     mode = "n" },
  { "<leader>cD", vim.lsp.buf.declaration,    desc = "Go to Declaration (LSP)",    mode = "n" },
  { "<leader>ci", vim.lsp.buf.implementation, desc = "Go to Implementation (LSP)", mode = "n" },
  { "<leader>cr", vim.lsp.buf.references,     desc = "List References (LSP)",      mode = "n" },
  { "<leader>cn", vim.lsp.buf.rename,         desc = "Rename Symbol (LSP)",        mode = "n" },
  { "<leader>cs", vim.lsp.buf.signature_help, desc = "Signature Help (LSP)",       mode = "n" },
  { "<leader>cf", vim.lsp.buf.format,         desc = "Format File (LSP)",          mode = "n" },
  { "<leader>cp", vim.diagnostic.goto_prev,   desc = "Prev diagnostic",            mode = "n" },
  { "<leader>cn", vim.diagnostic.goto_next,   desc = "Next diagnostic",            mode = "n" },

  -- Default Keybindings already defined in avantage. Just renaming the group so we have an Icon
  { "<leader>a",  group = "AI" },

  -- ----- LazyGit -----
  { "<leader>lg", "<cmd>LazyGit<cr>",         desc = "LazyGit" },
})
