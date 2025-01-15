-- Install the plugins using Lazy.nvim
return {
  -- nvim-lspconfig for setting up LSP servers
  {
    "neovim/nvim-lspconfig",
    config = function()
      local lspconfig = require("lspconfig")

      -- Bash Language Server
      lspconfig.bashls.setup({})

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

      -- Go Language Server
      lspconfig.gopls.setup({})

      -- Swift Language Server
      lspconfig.sourcekit.setup({})
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

