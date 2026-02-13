return {
	{
		"nvim-treesitter/nvim-treesitter",
		event = { "BufReadPost", "BufNewFile" },
		build = ":TSUpdate",

		-- Treesitter setup options
		opts = {
			-- Install only these language parsers
			ensure_installed = {
				"go", -- Go
				"swift", -- Swift - Custom below, since its not supported
				"bash", -- Shell scripting
				"yaml", -- YAML files
				"json", -- JSON files
				"lua", -- Lua (for Neovim config)
				"php",
				"http", -- HTTP requests (for rest.nvim)
			},

			-- Don't install parsers synchronously (use async)
			sync_install = false,

			-- Automatically install missing parsers when opening a buffer
			auto_install = true,

			highlight = {
				-- Enable Treesitter-based syntax highlighting
				enable = true,

				-- Don't run traditional `:syntax` highlighting alongside Treesitter
				additional_vim_regex_highlighting = false,
			},
		},

		-- Setup Treesitter using the opts defined above
		config = function(_, opts)
			require("nvim-treesitter.config").setup(opts)

			vim.g.php_noindent = 1 -- ← disable Vim's built-in PHP indent (GetPhpIndent)
			-- Simple, predictable PHP indentation (no legacy script)
			vim.api.nvim_create_autocmd("FileType", {
				pattern = "php",
				callback = function()
					vim.bo.indentexpr = "" -- kill GetPhpIndent()
					vim.bo.cindent = true
					vim.bo.smartindent = true -- basic indent like other langs
					vim.bo.autoindent = true
				end,
			})
		end,
	},

	{
		"nvim-treesitter/nvim-treesitter-textobjects",
		dependencies = { "nvim-treesitter/nvim-treesitter" },
		event = { "BufReadPost", "BufNewFile" },
		config = function()
			require("nvim-treesitter.config").setup({
				textobjects = {
					select = {
						enable = true,
						lookahead = true,
						keymaps = {
							["af"] = "@function.outer",
							["if"] = "@function.inner",
							["ac"] = "@class.outer",
							["ic"] = "@class.inner",
						},
					},
					move = {
						enable = true,
						set_jumps = true,
						goto_next_start = {
							["]]"] = "@function.outer",
						},
						goto_next_end = {
							["]["] = "@function.outer",
						},
						goto_previous_start = {
							["[["] = "@function.outer",
						},
						goto_previous_end = {
							["[]"] = "@function.outer",
						},
					},
				},
			})
		end,
	},
}
