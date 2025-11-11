return {
	"stevearc/overseer.nvim",
	branch = "master",
	opts = {},
	config = function()
		require("overseer").setup({
			-- Automatically detect build systems like Makefile, npm, composer, etc.
			templates = { "builtin" },

			-- Default strategy: open task output in a toggleable terminal
			strategy = "terminal",

			-- Task list window configuration
			task_list = {
				direction = "bottom", -- "bottom", "left", or "right"
				max_height = { 15, 0.25 }, -- max of 15 lines OR 25% of window height
				min_height = 8, -- at least 8 lines tall
				default_detail = 1,
			},
		})
	end,
}
