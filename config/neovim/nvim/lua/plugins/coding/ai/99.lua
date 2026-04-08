return {
	{
		"ThePrimeagen/99",
		event = "VeryLazy",
		dependencies = {
			"hrsh7th/nvim-cmp",
		},
		keys = {
			{
				"<leader>99",
				function()
					require("99").vibe({})
				end,
				desc = "99 Vibe",
			},
			{
				"<leader>9f",
				function()
					require("99").search({})
				end,
				desc = "99 Search",
			},
			{
				"<leader>9o",
				function()
					require("99").open()
				end,
				desc = "99 Open",
			},
			{
				"<leader>9c",
				function()
					require("99").clear_previous_requests()
				end,
				desc = "99 Clear Requests",
			},
			{
				"<leader>9x",
				function()
					require("99").stop_all_requests()
				end,
				desc = "99 Stop Requests",
				mode = { "n", "v" },
			},
			{
				"<leader>9l",
				function()
					require("99").view_logs()
				end,
				desc = "99 Logs",
			},
			{
				"<leader>9v",
				function()
					require("99").visual({})
				end,
				desc = "99 Visual",
				mode = { "v", "x" },
			},
		},
		config = function()
			local _99 = require("99")
			local cwd = vim.uv.cwd()
			local basename = vim.fs.basename(cwd)

			vim.fn.setenv("OPENCODE_PERMISSION", '{"edit": "allow"}')
			_99.setup({
				provider = _99.Providers.OpenCodeProvider,
				model = "opencode/minimax-m2.5-free",
				tmp_dir = vim.fn.stdpath("cache") .. "/99",
				logger = {
					level = _99.DEBUG,
					path = "/tmp/" .. basename .. ".99.debug",
					print_on_error = true,
				},
				completion = {
					custom_rules = {
						"scratch/custom_rules/",
					},
					files = {},
					source = "cmp",
				},
				md_files = {
					"AGENT.md",
				},
			})
		end,
	},
}
