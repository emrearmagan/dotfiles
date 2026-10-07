return {
	"nvimtools/none-ls.nvim",
	event = "LspAttach", --- load when lsp attaches to buffer. This way we make sure lsp is running before null-ls and it also looks nicer in lualine
	dependencies = {
		"jay-babu/mason-null-ls.nvim",
	},
	config = function()
		local null_ls = require("null-ls")
		local augroup = vim.api.nvim_create_augroup("LspFormatting", {})

		local function executable(name)
			return vim.fn.executable(name) == 1
		end

		local function add_source(sources, command, source)
			if executable(command) then
				sources[#sources + 1] = source
			end
		end

		require("mason-null-ls").setup({
			ensure_installed = {
				"gofmt", -- Go (should come with go installed - no available in mason)
				"goimports", -- Also GO
				"golangci-lint",

				"swiftformat", -- Swift
				"swiftlint",
				"prettier", -- YAML (also JSON, etc.)
				"shfmt", -- Bash

				"stylua", --- Lua
				"selene", --- Lua linter
			},
			automatic_installation = true,
		})

		local sources = {}
		local selene = null_ls.builtins.diagnostics.selene
		--- Formatter
		add_source(sources, "gofmt", null_ls.builtins.formatting.gofmt)
		add_source(sources, "goimports", null_ls.builtins.formatting.goimports)
		add_source(sources, "swiftformat", null_ls.builtins.formatting.swiftformat)
		add_source(sources, "prettier", null_ls.builtins.formatting.prettier)
		add_source(sources, "stylua", null_ls.builtins.formatting.stylua)
		add_source(sources, "shfmt", null_ls.builtins.formatting.shfmt)

		--- Linter
		add_source(sources, "swiftlint", null_ls.builtins.diagnostics.swiftlint)
		add_source(sources, "golangci-lint", null_ls.builtins.diagnostics.golangci_lint)
		add_source(
			sources,
			"selene",
			selene.with({
				on_output = function(params, done)
					params.output = params.output or ""
					return selene._opts.on_output(params, done)
				end,
			})
		)

		null_ls.setup({
			-- format on save
			on_attach = function(client, bufnr)
				if client:supports_method("textDocument/formatting") then
					vim.api.nvim_clear_autocmds({ group = augroup, buffer = bufnr })
					vim.api.nvim_create_autocmd("BufWritePre", {
						group = augroup,
						buffer = bufnr,
						callback = function()
							vim.lsp.buf.format({
								bufnr = bufnr,
								async = false,
								filter = function(c)
									return c.name == "null-ls" or c.name == "none-ls"
								end,
							})
						end,
					})
				end
			end,

			sources = sources,
		})
	end,
}
