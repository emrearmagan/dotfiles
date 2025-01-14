return {
  {
    "nvim-telescope/telescope.nvim",
    tag = "0.1.8", -- Stable release tag
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      local telescope = require("telescope")
      local actions = require("telescope.actions")

      telescope.setup({
        defaults = {
          mappings = {
            i = {
              ["<C-j>"] = actions.move_selection_next, -- Move to next item
              ["<C-k>"] = actions.move_selection_previous, -- Move to previous item
              ["<esc>"] = actions.close, -- Close telescope
            },
          },
        },
        pickers = {
          find_files = {
            theme = "dropdown", -- Set dropdown theme for `find_files`
          },
        },
        extensions = {
          -- Extensions can be added here
        },
      })

      -- Load any extensions if needed
      -- telescope.load_extension('fzf')
    end,
  },
}
