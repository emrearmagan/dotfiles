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
				automatic_enable = true,
				automatic_installation = true,
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
			vim.lsp.config("lua_ls", {
				filetypes = { "lua" },
				capabilities = capabilities,
			})

			-- Go
			vim.lsp.config("gopls", {
				filetypes = { "go", "gomod", "gowork", "gotmpl" },
				capabilities = capabilities,
				settings = {
					gopls = {
						completeUnimported = true,
						usePlaceholders = true,
						analyses = {
							unusedparams = true,
						},
					},
				},
			})

			-- Swift (macOS native)
			vim.lsp.config("sourcekit", {
				cmd = { vim.trim(vim.fn.system("xcrun -f sourcekit-lsp")) },
				filetypes = { "swift", "objc", "objective-c", "objective-cpp" },
				capabilities = capabilities,
				on_init = function(client)
					client.offset_encoding = "utf-8"
				end,
			})

			-- Docker
			vim.lsp.config("dockerls", {
				filetypes = { "dockerfile" },
				capabilities = capabilities,
			})

			-- YAML
			vim.lsp.config("yamlls", {
				filetypes = { "yaml", "yml", "j2" },
				capabilities = capabilities,
				settings = {
					yaml = {
						schemas = {
							["https://json.schemastore.org/ansible-stable-2.9.json"] = "*/playbook.yml",
							["https://json.schemastore.org/github-workflow.json"] = ".github/workflows/*",
						},
					},
				},
			})

			-- Ansible
			vim.lsp.config("ansiblels", {
				filetypes = { "yaml", "yml", "ansible" },
				capabilities = capabilities,
				settings = {
					ansible = {
						ansibleLint = { enabled = true },
					},
				},
			})

			-- Bash / Shell
			vim.lsp.config("bashls", {
				filetypes = { "sh", "bash", "zsh" },
				capabilities = capabilities,
			})

			-- ── Enable all LSPs ───────────────────────────────────────
			vim.lsp.enable({
				"sourcekit",
				"gopls",
			})
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
			"zbirenbaum/copilot-cmp", -- GitHub Copilot source for nvim-cmp
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
