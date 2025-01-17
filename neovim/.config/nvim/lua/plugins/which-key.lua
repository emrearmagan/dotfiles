return {
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    config = function()
      require("plugins.which-key") -- Load the configuration file
    end,
  },
}
