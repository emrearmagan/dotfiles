return {
  -- Mason UI for managing LSPs
  {
    "mason-org/mason.nvim",
    config = function()
      require("mason").setup({
        ui = {
          icons = {
            package_installed = "✓",
            package_pending = "➜",
            package_uninstalled = "✗"
          }
        }
      })
    end
  },
  -- Bridge: Mason <-> LSPConfig
  {
    "mason-org/mason-lspconfig.nvim",
    config = function()
      require("mason-lspconfig").setup {
        ensure_installed = {
          "lua_ls",    -- Lua
          "gopls",     -- Go
          "dockerls",  -- Docker
          "yamlls",    -- YAML
          "ansiblels", -- Ansible
          "bashls",    -- Bash

          -- sourcekit (Swift) is macOS native, not installable via Mason
          -- Make sure to have Xcode installed or CLI Tools: xcode-select --install
        },
        automatic_enable = false
      }
    end
  },

  -- Built-in LSP Support for setting up LSP servers
  {
    "neovim/nvim-lspconfig",
    config = function()
      local lspconfig = require("lspconfig")

      vim.api.nvim_create_autocmd('LspAttach', {
        desc = 'LSP Actions',
        callback = function(args)
          local wk = require("which-key")
          wk.add({
            { "K",  vim.lsp.buf.hover,          desc = "LSP hover info",            mode = "n", buffer = args.buf },
            { "gd", vim.lsp.buf.definition,     desc = "LSP go to definition",      mode = "n", buffer = args.buf },
            { "gD", vim.lsp.buf.declaration,    desc = "LSP go to declaration",     mode = "n", buffer = args.buf },
            { "gi", vim.lsp.buf.implementation, desc = "LSP go to implementation",  mode = "n", buffer = args.buf },
            { "gr", vim.lsp.buf.references,     desc = "LSP list references",       mode = "n", buffer = args.buf },
            { "gs", vim.lsp.buf.signature_help, desc = "LSP signature help",        mode = "n", buffer = args.buf },
            { "gn", vim.lsp.buf.rename,         desc = "LSP rename",                mode = "n", buffer = args.buf },
            { "[g", vim.diagnostic.goto_prev,   desc = "Go to previous diagnostic", mode = "n", buffer = args.buf },
            { "g]", vim.diagnostic.goto_next,   desc = "Go to next diagnostic",     mode = "n", buffer = args.buf },
          })
        end,
      })
      -- Lua Language Server
      lspconfig.lua_ls.setup({})

      -- Go Language Server
      lspconfig.gopls.setup({
        filetypes = { "go", "gomod" },
      })

      -- Swift Language Server
      lspconfig.sourcekit.setup({
        filetypes = { "swift", "objc", "objective-c", "objective-cpp" },
      })

      -- Docker Language Server
      lspconfig.dockerls.setup({})

      -- YAML Language Server
      lspconfig.yamlls.setup({
        settings = {
          yaml = {
            schemas = {
              ["https://json.schemastore.org/ansible-stable-2.9.json"] = "*/playbook.yml",
              ["https://json.schemastore.org/github-workflow.json"] = ".github/workflows/*",
            },
          },
        },
      })

      -- Ansible Language Server
      lspconfig.ansiblels.setup({
        settings = {
          ansible = {
            ansibleLint = {
              enabled = true,
            },
          },
        },
      })

      -- Bash Language Server
      lspconfig.bashls.setup({})
    end,
  },

  -- nvim-cmp for autocompletion
  {
    "hrsh7th/nvim-cmp",
    dependencies = {
      "hrsh7th/cmp-nvim-lsp", -- Connects nvim-cmp with LSP
      "hrsh7th/cmp-buffer",   -- Autocomplete from open buffers
      "hrsh7th/cmp-path",     -- Autocomplete file paths
      "hrsh7th/cmp-vsnip",    -- Integrates with snippet engine
      "hrsh7th/vim-vsnip",    -- Snippet engine
    },
    config = function()
      local cmp = require("cmp")
      cmp.setup({
        snippet = {
          expand = function(args)
            vim.fn["vsnip#anonymous"](args.body)
          end,
        },
        mapping = cmp.mapping.preset.insert({
          ["<C-Space>"] = cmp.mapping.complete(),
          ["<CR>"] = cmp.mapping.confirm({ select = true }),
        }),
        sources = {
          { name = "nvim_lsp" },
          { name = "buffer" },
          { name = "path" },
        },
      })
    end,
  },
}
