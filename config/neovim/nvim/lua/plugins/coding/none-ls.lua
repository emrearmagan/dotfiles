return {
	"nvimtools/none-ls.nvim",
	event = "LspAttach", --- load when lsp attaches to buffer. This way we make sure lsp is running before null-ls and it also looks nicer in lualine
	dependencies = {
		"jay-babu/mason-null-ls.nvim",
	},
	config = function()
		local null_ls = require("null-ls")
		local augroup = vim.api.nvim_create_augroup("LspFormatting", {})

		require("mason-null-ls").setup({
			ensure_installed = {
				"gofmt", -- Go (should come with go installed - no available in mason)
				"goimports", -- Also GO
				"golangci-lint",

				"prettier", -- YAML (also JSON, etc.)
				"shfmt", -- Bash

				"stylua", --- Lua
			},
			automatic_installation = true,
		})

		null_ls.setup({
			name = "null_ls",
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
									return c.name == "null-ls"
								end,
							})
						end,
					})
				end
			end,

			sources = {
				-- Formatter
				null_ls.builtins.formatting.gofmt,
				null_ls.builtins.formatting.goimports,
				null_ls.builtins.formatting.prettier.with({
					filetypes = { "yaml", "yml" },
				}),
				null_ls.builtins.formatting.stylua,
				null_ls.builtins.formatting.shfmt,

				-- Linter --
				null_ls.builtins.diagnostics.golangci_lint,
				null_ls.builtins.diagnostics.swiftlint,
			},
		})
	end,
}
