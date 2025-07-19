return {
  "akinsho/bufferline.nvim",
  version = "*",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  event = "VeryLazy",
  config = function()
    require("bufferline").setup({
      options = {
        mode = "buffers",
        numbers = "none",
        diagnostics = "nvim_lsp",
        show_close_icon = false,
        show_buffer_close_icons = false,
        separator_style = "slant",
        always_show_bufferline = true,
        offsets = {
          {
            filetype = "neo-tree",
            text = "File Explorer",
            highlight = "Directory",
            text_align = "left",
          }
        },
      },
    })

    -- optional styling
    vim.opt.termguicolors = true
  end
}
