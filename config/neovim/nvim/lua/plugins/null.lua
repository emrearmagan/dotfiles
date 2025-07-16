return {
  "nvimtools/none-ls.nvim",
  event = { "BufReadPre", "BufNewFile" },
  dependencies = {
    "jay-babu/mason-null-ls.nvim",
  },
  config = function()
    local null_ls = require("null-ls")
    require("mason-null-ls").setup({
      ensure_installed = {
        "gofmt",       -- Go (should come with go installed - no available in mason)
        "goimports",   -- Also GO
        "golangcli_lint",
        "swiftformat", -- Swift
        "prettier",    -- YAML (also JSON, etc.)
      },
      automatic_installation = true,
    })

    vim.api.nvim_create_autocmd('LspAttach', {
      desc = 'LSP Actions',
      callback = function(args)
        local wk = require("which-key")
        wk.add({
          -- Make sure they dont conflict with the lsp plugin.
          { "gf", vim.lsp.buf.format, desc = "Format", mode = "n", buffer = args.buf },
        })
      end,
    })

    null_ls.setup({
      sources = {
        -- Go formatting
        null_ls.builtins.formatting.gofmt,
        null_ls.builtins.formatting.goimports,

        -- Swift formatting (requires swiftformat installed)
        null_ls.builtins.formatting.swiftformat,

        -- YAML formatting (prettier is most common)
        null_ls.builtins.formatting.prettier.with({
          filetypes = { "yaml", "yml" },
        }),
      },
    })
  end,
}
