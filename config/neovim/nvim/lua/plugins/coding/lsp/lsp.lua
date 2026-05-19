return {
	-- Mason UI for managing LSPs
	{
		"mason-org/mason.nvim",
		cmd = { "Mason", "MasonInstall", "MasonUninstall", "MasonUpdate", "MasonLog" },
		event = "BufReadPre",
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
		event = "BufReadPre",
		dependencies = { "mason-org/mason.nvim" },
		config = function()
			require("mason-lspconfig").setup({
				ensure_installed = {
					"lua_ls", -- Lua
					"gopls", -- Go
					"dockerls", -- Docker
					"yamlls", -- YAML
					"jsonls", -- JSON
					"ansiblels", -- Ansible
					"bashls", -- Bash

					"html", -- HTML
					"vtsls", -- TypeScript & JavaScript (alternative)
					"cssls", -- CSS (for LESS support)
					"marksman", -- Markdown

					"sqls", -- SQL language server

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
					source = true,
					focusable = true,
				},
			})

			-- local capabilities = vim.lsp.protocol.make_client_capabilities()
			local capabilities = require("cmp_nvim_lsp").default_capabilities()

			-- Lua Language Server
			vim.lsp.config("lua_ls", {
				filetypes = { "lua" },
				capabilities = capabilities,
				root_markers = {
					".luarc.json",
					".luarc.jsonc",
					".luacheckrc",
					"stylua.toml",
					"selene.toml",
					"selene.yml",
					".git",
				},
				settings = {
					Lua = {
						runtime = { version = "LuaJIT" },
						workspace = {
							checkThirdParty = false,
							maxPreload = 100000,
							preloadFileSize = 10000,
							library = {
								vim.env.VIMRUNTIME,
								"${3rd}/luv/library",
								"${3rd}/busted/library",
								"${3rd}/luassert/library",
							},
						},
						diagnostics = {
							globals = { "vim" },
						},
					},
				},
			})

			-- Go
			vim.lsp.config("gopls", {
				filetypes = { "go", "gomod", "gowork", "gotmpl" },
				capabilities = capabilities,
				settings = {
					gopls = {
						gofumpt = true,
						staticcheck = true,
						completeUnimported = true,
						usePlaceholders = true,
						analyses = {
							unusedparams = true,
							ST1000 = false, -- disables warning for package comments
						},
					},
				},
			})

			-- Swift (macOS native).
			-- TODO: still have to test. might not even work
			vim.api.nvim_create_autocmd("FileType", {
				pattern = { "swift", "objc", "objective-c", "objective-cpp" },
				once = true,
				callback = function()
					-- Point sourcekit-lsp at the build's index store so go-to-definition
					-- works for SPM/Xcode dependencies (otherwise external symbols can't be resolved).
					local function sourcekit_index_store()
						local cwd = vim.fn.getcwd()
						if vim.fn.filereadable(cwd .. "/Package.swift") == 1 then
							return cwd .. "/.build/debug/index/store"
						end

						local build_dir = vim.fn.systemlist(
							"xcodebuild -showBuildSettings 2>/dev/null | awk -F= '/ BUILD_DIR /{gsub(/^ +| +$/,\"\",$2); print $2}' | head -1"
						)[1]
						if build_dir and build_dir ~= "" then
							return build_dir:gsub("/Build/Products$", "/Index.noindex/DataStore")
						end
					end

					local cmd = { vim.trim(vim.fn.system("xcrun -f sourcekit-lsp")) }
					local index_store = sourcekit_index_store()
					if index_store then
						vim.list_extend(cmd, { "--index-store-path", index_store })
					end

					vim.lsp.config("sourcekit", {
						capabilities = capabilities,
						filetypes = { "swift", "objc", "objective-c", "objective-cpp" },
						on_init = function(client)
							client.offset_encoding = "utf-8"
						end,
						root_dir = require("lspconfig.util").root_pattern(
							"Package.swift",
							"*.xcworkspace",
							"*.xcodeproj",
							".git"
						),
						cmd = cmd,
					})
					vim.lsp.enable("sourcekit")
					vim.cmd("LspStart sourcekit")
				end,
			})

			-- YAML
			vim.lsp.config("yamlls", {
				filetypes = { "yaml", "j2" },
				capabilities = capabilities,
				settings = {
					yaml = {
						schemas = {
							["https://raw.githubusercontent.com/ansible/ansible-lint/main/src/ansiblelint/schemas/ansible.json#/$defs/playbook"] = "*/playbook.yml",
							["https://json.schemastore.org/github-workflow.json"] = ".github/workflows/*",
						},
					},
				},
			})

			-- JSON
			vim.lsp.config("jsonls", {
				filetypes = { "json", "jsonc" },
				capabilities = capabilities,
				settings = {
					json = {
						validate = { enable = true },
					},
				},
			})

			-- Ansible
			vim.lsp.config("ansiblels", {
				filetypes = { "yaml" },
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

			-- TypeScript / JavaScript
			vim.lsp.config("vtsls", {
				capabilities = capabilities,
				filetypes = { "typescript", "javascript", "typescriptreact", "javascriptreact" },
			})

			-- CSS / LESS
			vim.lsp.config("cssls", {
				filetypes = { "css", "scss", "less" },
			})
		end,
	},

	-- Neovim API type annotations and autocompletion for lua_ls
	-- When removing make sure to remove the lua_ls settings above
	{
		"folke/lazydev.nvim",
		ft = "lua",
		opts = {
			library = {
				{ path = "${3rd}/luv/library", words = { "vim%.uv" } },
				"lazy.nvim",
			},
		},
	},

	-- nvim-cmp for autocompletion
	{
		"hrsh7th/nvim-cmp",
		event = { "InsertEnter", "CmdlineEnter" },
		dependencies = {
			"hrsh7th/cmp-nvim-lsp", -- Connects nvim-cmp with LSP
			"hrsh7th/cmp-buffer", -- Autocomplete from open buffers
			"hrsh7th/cmp-path", -- Autocomplete file paths
			"hrsh7th/cmp-cmdline", -- Cmdline completion sources
			"L3MON4D3/LuaSnip", -- snippet engine
			"saadparwaiz1/cmp_luasnip", -- for autocompletion
			"rafamadriz/friendly-snippets", -- useful snippets
			"onsails/lspkind.nvim", -- vs-code like pictograms
			"kristijanhusak/vim-dadbod-completion", -- DB completion source for nvim-cmp
			"folke/lazydev.nvim", -- Neovim API completions
		},
		config = function()
			local cmp = require("cmp")
			local luasnip = require("luasnip")
			local ls_types = require("luasnip.util.types")
			local lspkind = require("lspkind")

			vim.api.nvim_set_hl(0, "LuasnipInsertNodeActive", { link = "Comment" })
			vim.api.nvim_set_hl(0, "LuasnipChoiceNodeActive", { link = "Comment" })
			luasnip.config.setup({
				ext_opts = {
					[ls_types.insertNode] = {
						active = { hl_group = "LuasnipInsertNodeActive" },
					},
					[ls_types.choiceNode] = {
						active = { hl_group = "LuasnipChoiceNodeActive" },
					},
				},
			})

			-- loads vscode style snippets from installed plugins (e.g. friendly-snippets)
			require("luasnip.loaders.from_vscode").lazy_load()

			cmp.register_source("filemention", require("config.my.filemention").new())

			cmp.setup({
				preselect = cmp.PreselectMode.None, -- do not preselect any item
				completion = {
					completeopt = "menu,menuone,preview,noselect",
				},
				snippet = { -- configure how nvim-cmp interacts with snippet engine
					expand = function(args)
						luasnip.lsp_expand(args.body)
					end,
				},

				mapping = cmp.mapping.preset.insert({
					["<C-Space>"] = cmp.mapping.complete(),
					["<CR>"] = cmp.mapping.confirm({ select = false }),
					["<C-j>"] = cmp.mapping.select_next_item(),
					["<C-k>"] = cmp.mapping.select_prev_item(),

					-- scroll completion docs
					["<C-f>"] = cmp.mapping.scroll_docs(4),
					["<C-b>"] = cmp.mapping.scroll_docs(-4),

					-- Snippet navigation with Tab / Shift-Tab
					["<Tab>"] = cmp.mapping(function(fallback)
						if luasnip.jumpable(1) and luasnip.locally_jumpable(1) then
							luasnip.jump(1)
						elseif cmp.visible() then
							cmp.select_next_item()
						else
							fallback()
						end
					end, { "i", "s" }),

					["<S-Tab>"] = cmp.mapping(function(fallback)
						if luasnip.jumpable(-1) then
							luasnip.jump(-1)
						elseif cmp.visible() then
							cmp.select_prev_item()
						else
							fallback()
						end
					end, { "i", "s" }),
				}),

				-- sources for autocompletion
				sources = cmp.config.sources({
					{ name = "lazydev", group_index = 0 }, -- doesnt seems to work always
					{ name = "nvim_lsp" },
					{ name = "luasnip" }, -- snippets
					-- INFO: Seems annoying at the moment, so disabled for now
					-- { name = "buffer" }, -- text within current buffer
					{ name = "vim-dadbod-completion" },
					{ name = "path" }, -- file system paths
					{ name = "filemention" }, -- @path/to/file in prose buffers
				}),

				-- configure lspkind for vs-code like pictograms in completion menu
				window = {
					completion = cmp.config.window.bordered({
						border = "rounded",
						winhighlight = "Normal:Pmenu,FloatBorder:PmenuBorder,CursorLine:PmenuSel,Search:None",
					}),
					documentation = cmp.config.window.bordered({
						border = "rounded",
						-- max_width = 60,
						-- max_height = 12,
						winhighlight = "Normal:Pmenu,FloatBorder:PmenuBorder,Search:None",
					}),
				},
				formatting = {
					format = lspkind.cmp_format({
						maxwidth = 50,
						ellipsis_char = "...",
					}),
				},
			})

			-- Cmdline completion for ":" commands and "/" search.
			cmp.setup.cmdline(":", {
				mapping = cmp.mapping.preset.cmdline(),
				sources = cmp.config.sources({
					{ name = "path" },
				}, {
					{ name = "cmdline" },
				}),
			})

			cmp.setup.cmdline({ "/", "?" }, {
				mapping = cmp.mapping.preset.cmdline(),
				sources = {
					{ name = "buffer" },
				},
			})
		end,
	},
}
