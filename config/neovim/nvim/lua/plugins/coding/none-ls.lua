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

				"swiftformat", -- Swift
				"swiftlint",
				"prettier", -- YAML (also JSON, etc.)
				"shfmt", -- Bash

				"php-cs-fixer",

				"stylua", --- Lua
			},
			automatic_installation = true,
		})

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

				null_ls.builtins.formatting.phpcsfixer.with({
					command = "php-cs-fixer", -- uses Homebrew binary
					env = { PHP_CS_FIXER_IGNORE_ENV = "1" }, -- allow PHP 8.4+
				}),

				-- Linter --
				null_ls.builtins.diagnostics.swiftlint,
				null_ls.builtins.diagnostics.phpstan.with({
					command = function()
						local cwd = vim.fn.getcwd()
						local current = cwd
						-- Search up the directory tree for vendor/bin/phpstan
						for _ = 1, 10 do -- Max 10 levels up
							local vendor_path = current .. "/vendor/bin/phpstan"
							if vim.fn.filereadable(vendor_path) == 1 then
								return vendor_path
							end
							local parent = vim.fn.fnamemodify(current, ":h")
							if parent == current then
								break
							end -- Reached root
							current = parent
						end
						return "phpstan"
					end,
					extra_args = { "analyse", "--error-format", "raw" },
					to_stdin = false,
					diagnostics_format = "[phpstan] #{m}",
				}),
			},
		})
	end,
}
