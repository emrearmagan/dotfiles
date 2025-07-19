return {
  {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-tree/nvim-web-devicons",
      "MunifTanjim/nui.nvim",
    },
    config = function()
      require("neo-tree").setup({
        hijack_netrw = true, -- Replace default netrw with Neo-tree

        event_handlers = {
          {
            event = "file_open_requested",
            handler = function()
              require("neo-tree.command").execute({ action = "close" })
            end,
          },
        },

        filesystem = {
          follow_current_file = {
            enabled = true,
          },
          close_if_last_window = true, -- Close Neo-tree if it's the last open window

          filtered_items = {
            visible = false,                      -- Hide hidden files
            show_hidden_count = true,             -- Display count of hidden files
            hide_dotfiles = true,                 -- Hide dotfiles by default
            hide_gitignore = false,               -- Show files ignored by .gitignore
          },
          hijack_netrw_behavior = "open_default", -- Automatically open Neo-tree for directories
          use_libuv_file_watcher = true,          -- Enable automatic tree refresh
        },

        window = {
          mappings = {
            ["l"] = "open",               -- Open file or directory
            ["<2-LeftMouse>"] = "open",   -- Open with double-click
            ["<cr>"] = "open",            -- Open file or folder with Enter
            ["<esc>"] = "cancel",         -- Close preview or Neo-tree window
            ["h"] = "close_node",         -- Collapse folder
            ["<Tab>"] = "toggle_preview", -- Toggle preview window
            ["<space>"] = false,
            ["f"] = function()
              require("fzf-lua").files()
            end,
            ["/"] = "fuzzy_finder",
            ["P"] = function(state)
              local node = state.tree:get_node()
              require("neo-tree.ui.renderer").focus_node(state, node:get_parent_id())
            end
          },
        },
      })

      -- Automatically open Neo-tree for directories or when nvim is launched without arguments
      -- vim.api.nvim_create_autocmd("VimEnter", {
      --   callback = function(data)
      --     local no_args = vim.fn.argc() == 0
      --     local directory = vim.fn.isdirectory(data.file) == 1
      --     if no_args or directory then
      --       require("neo-tree.command").execute({ source = "filesystem", position = "left", toggle = true })
      --       if directory then
      --         vim.cmd.cd(data.file)
      --       end
      --     end
      --   end,
      -- })
    end,
  },
}
