return {
	{
		"nvim-neotest/neotest",
		dependencies = {
			"nvim-neotest/nvim-nio",
			"nvim-lua/plenary.nvim",
			"antoinemadec/FixCursorHold.nvim",
			"nvim-treesitter/nvim-treesitter",
			"stevearc/overseer.nvim",
			{
				"fredrikaverpil/neotest-golang",
				version = "*", -- Optional, but recommended; track releases
				build = function()
					vim.system({ "go", "install", "gotest.tools/gotestsum@latest" }):wait() -- Optional, but recommended
				end,
			},
		},
		config = function()
			-- Ensure Go bin is in PATH for Neovim (for gotestsum)
			vim.env.PATH = vim.env.PATH .. ":" .. vim.fn.expand("~") .. "/go/bin"

			local config = {
				runner = "gotestsum", -- Optional, but recommended. Could also just use 'gotest' here and get rid of the PATH
			}
			require("neotest").setup({
				adapters = {
					require("neotest-golang")(config),
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
