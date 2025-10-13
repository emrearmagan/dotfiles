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
						package_uninstalled = "✗",
					},
				},
			})
		end,
	},
	-- Bridge: Mason <-> LSPConfig
	{
		"mason-org/mason-lspconfig.nvim",
		config = function()
			require("mason-lspconfig").setup({
				ensure_installed = {
					"lua_ls", -- Lua
					"gopls", -- Go
					"dockerls", -- Docker
					"yamlls", -- YAML
					"ansiblels", -- Ansible
					"bashls", -- Bash

					-- sourcekit (Swift) is macOS native, not installable via Mason
					-- Make sure to have Xcode installed or CLI Tools: xcode-select --install
				},
				automatic_enable = false,
			})
		end,
	},

	-- Built-in LSP Support for setting up LSP servers
	{
		"neovim/nvim-lspconfig",
		config = function()
			vim.diagnostic.config({
				virtual_text = true,
				float = {
					border = "rounded",
					source = "always",
					focusable = false,
				},
			})

			local capabilities = vim.lsp.protocol.make_client_capabilities()

			-- Lua Language Server
			vim.lsp.config("lua_ls", {})

			-- Go Language Server
			vim.lsp.config("gopls", {
				filetypes = { "go", "gomod" },
			})

			-- Swift Language Server
			vim.lsp.config("sourcekit", {
				capabilities = {
					workspace = {
						didChangeWatchedFiles = {
							dynamicRegistration = true,
						},
					},
				},
				filetypes = { "swift", "objc", "objective-c", "objective-cpp" },
			})

			-- Docker Language Server
			vim.lsp.config("dockerls", {})

			-- YAML Language Server
			vim.lsp.config("yamlls", {
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
			vim.lsp.config("ansiblels", {
				settings = {
					ansible = {
						ansibleLint = {
							enabled = true,
						},
					},
				},
			})

			-- Bash Language Server
			vim.lsp.config("bashls", {})
		end,
	},

	-- nvim-cmp for autocompletion
	{
		"hrsh7th/nvim-cmp",
		event = "InsertEnter",
		dependencies = {
			"hrsh7th/cmp-nvim-lsp", -- Connects nvim-cmp with LSP
			"hrsh7th/cmp-buffer", -- Autocomplete from open buffers
			"hrsh7th/cmp-path", -- Autocomplete file paths
			"L3MON4D3/LuaSnip", -- snippet engine
			"saadparwaiz1/cmp_luasnip", -- for autocompletion
			"rafamadriz/friendly-snippets", -- useful snippets
			"onsails/lspkind.nvim", -- vs-code like pictograms
		},
		config = function()
			local cmp = require("cmp")
			local luasnip = require("luasnip")
			local lspkind = require("lspkind")

			-- loads vscode style snippets from installed plugins (e.g. friendly-snippets)
			require("luasnip.loaders.from_vscode").lazy_load()

			cmp.setup({
				completion = {
					completeopt = "menu,menuone,preview",
				},
				snippet = { -- configure how nvim-cmp interacts with snippet engine
					expand = function(args)
						-- vim.fn["vsnip#anonymous"](args.body)
						luasnip.lsp_expand(args.body)
					end,
				},

				mapping = cmp.mapping.preset.insert({
					["<C-Space>"] = cmp.mapping.complete(),
					["<CR>"] = cmp.mapping.confirm({ select = true }),
				}),
				-- sources for autocompletion
				sources = cmp.config.sources({
					{ name = "nvim_lsp" },
					{ name = "luasnip" }, -- snippets
					{ name = "buffer" }, -- text within current buffer
					{ name = "path" }, -- file system paths
				}),
				-- configure lspkind for vs-code like pictograms in completion menu
				formatting = {
					format = lspkind.cmp_format({
						maxwidth = 50,
						ellipsis_char = "...",
					}),
				},
			})
		end,
	},
}
