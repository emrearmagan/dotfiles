return {
	"christoomey/vim-tmux-navigator",
	cmd = {
		"TmuxNavigateLeft",
		"TmuxNavigateDown",
		"TmuxNavigateUp",
		"TmuxNavigateRight",
		"TmuxNavigatePrevious",
		"TmuxNavigatorProcessList",
	},
	keys = {
		{
			"<C-h>",
			function()
				vim.cmd("TmuxNavigateLeft")
			end,
			mode = { "n", "i", "t" },
		},
		{
			"<C-j>",
			function()
				vim.cmd("TmuxNavigateDown")
			end,
			mode = { "n", "i", "t" },
		},
		{
			"<C-k>",
			function()
				vim.cmd("TmuxNavigateUp")
			end,
			mode = { "n", "i", "t" },
		},
		{
			"<C-l>",
			function()
				vim.cmd("TmuxNavigateRight")
			end,
			mode = { "n", "i", "t" },
		},
		{
			"<C-\\>",
			function()
				vim.cmd("TmuxNavigatePrevious")
			end,
			mode = { "n", "i", "t" },
		},
	},
}
