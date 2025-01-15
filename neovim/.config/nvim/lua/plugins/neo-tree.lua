return {
  {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-tree/nvim-web-devicons", -- optional, for file icons
      "MunifTanjim/nui.nvim",
    },
    config = function()
      require("neo-tree").setup({
        filesystem = {
          follow_current_file = true,
	  filtered_items = {
	      visible = true,
	      show_hidden_count = true,
	      hide_dotfiles = true,
	      hide_gitignore = false
	  },
          hijack_netrw = true,
          use_libuv_file_watcher = true,
        },
	window = {
	  mappings = {
	    ["l"] = "open",
	    ["<2-LeftMouse>"] = "open",
	    ["<cr>"] = "open",           -- Open file or folder with Enter
	    ["<esc>"] = "cancel",         -- Close preview or floating neo-tree window
      	    ["P"] = "toggle_preview", -- Read `# Preview Mode` for more information
            ["h"] = "close_node", -- Collapse folder with h
            ["<Tab>"] = "toggle_preview", -- Toggle file preview
          },
	},
      })
    end,
  },
}
