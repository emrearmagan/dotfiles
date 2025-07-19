return {
  {
    "rcarriga/nvim-notify",
    config = function()
      require("notify").setup({
        -- Customize `nvim-notify` options here
        stages = "fade_in_slide_out",  -- Animation style
        timeout = 3000,                -- Time (ms) notifications remain visible
        background_colour = "#000000", -- Background color
        max_width = 50,
        max_height = 100,
      })

      -- Replace the default `vim.notify` function with `nvim-notify`
      vim.notify = require("notify")
    end,
    lazy = true,        -- Load the plugin lazily
    event = "VeryLazy", -- Load when Neovim enters an idle state
  },
}
