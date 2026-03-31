return {
	{
		"nvim-neotest/neotest",
		dependencies = {
			"nvim-neotest/nvim-nio",
			"nvim-lua/plenary.nvim",
			"antoinemadec/FixCursorHold.nvim",
			"nvim-treesitter/nvim-treesitter",
			"stevearc/overseer.nvim",

			-- Go
			{
				"fredrikaverpil/neotest-golang",
				version = "*", -- Optional, but recommended; track releases
				build = function()
					vim.system({ "go", "install", "gotest.tools/gotestsum@latest" }):wait() -- Optional, but recommended
				end,
			},
			"nvim-neotest/neotest-jest",

			-- Swift
			"mmllr/neotest-swift-testing",

			-- Lua. Make sure to call: luarocks install busted or brew install busted
			"MisanthropicBit/neotest-busted",
		},
		lazy = true,
		config = function()
			-- Ensure Go bin is in PATH for Neovim (for gotestsum)
			vim.env.PATH = vim.env.PATH .. ":" .. vim.fn.expand("~") .. "/go/bin"

			require("neotest").setup({
				adapters = {
					-- Go
					require("neotest-golang")({
						runner = "gotestsum",
					}),

					-- Swift
					require("neotest-swift-testing")({}),

					-- Lua (Busted)
					require("neotest-busted")({
						busted_command = "busted",
						no_nvim = true,
					}),
				},

				summary = {
					mappings = {
						expand = { "l", "<Right>" },
						expand_all = { "L" },
						collapse = { "h", "<Left>" },
						collapse_all = { "H" },
					},
				},

				consumers = {
					overseer = require("neotest.consumers.overseer"),
				},
			})
		end,
	},
}
