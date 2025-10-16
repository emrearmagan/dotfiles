return {
	"nvimtools/none-ls.nvim",
	event = { "BufReadPre", "BufNewFile" },
	dependencies = {
		"jay-babu/mason-null-ls.nvim",
	},
	config = function()
		local null_ls = require("null-ls")
		-- vim.lsp.config('null-ls')
		--
		local augroup = vim.api.nvim_create_augroup("LspFormatting", {})
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
			},
			automatic_installation = true,
		})

		vim.fn.sign_define("DiagnosticSignError", { text = "✖", texthl = "DiagnosticSignError" })
		vim.fn.sign_define("DiagnosticSignWarn", { text = "▲", texthl = "DiagnosticSignWarn" })

		vim.diagnostic.config({
			virtual_text = {
				--severity = vim.diagnostic.severity.ERROR, -- Only show errors inline
				severity = {
					min = vim.diagnostic.severity.INFO, -- show INFO and ERROR
					max = vim.diagnostic.severity.ERROR,
				},
				source = "always", -- Always show source (e.g., gopls)
				prefix = "●", -- Prefix symbol for the error
				spacing = 4, -- Space between text and code
				current_line = false, -- Show all, expect on the cursor line
			},
			signs = true, -- Show signs in the gutter (E, W, etc.)
			underline = true, -- Underline the problematic code
			update_in_insert = false, -- Don’t update diagnostics in insert mode
			severity_sort = true, -- Sort diagnostics by severity

			float = {
				border = "rounded", -- Rounded border
				source = "always", -- Always show diagnostic source (e.g., gopls)
			},
		})

		null_ls.setup({
			name = "null_ls",
			-- format on save
			on_attach = function(client, bufnr)
				if client.supports_method("textDocument/formatting") then
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
				null_ls.builtins.formatting.swiftformat,
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
