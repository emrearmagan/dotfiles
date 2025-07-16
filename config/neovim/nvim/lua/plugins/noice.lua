-- lazy.nvim
return {
  "folke/noice.nvim",
  event = "VeryLazy",
  dependencies = {
    "MunifTanjim/nui.nvim",
    "rcarriga/nvim-notify", -- optional, used for notifications
  },
  config = function()
    require("noice").setup({
      presets = {
        bottom_search = true,         -- classic bottom command line for search
        command_palette = true,       -- position cmdline and popupmenu together
        long_message_to_split = true, -- long messages go to split
        inc_rename = false,           -- disable inc-rename support
        lsp_doc_border = false,       -- no border for hover/signature
      },
    })
  end,
}
