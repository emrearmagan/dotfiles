return {
	"folke/noice.nvim",
	event = "VeryLazy",
	dependencies = {
		"MunifTanjim/nui.nvim",
	},
	opts = {
		popupmenu = { enabled = false },
		notify = { enabled = true },
		messages = { enabled = true },
		cmdline = { enabled = true, view = "cmdline" }, -- bottom style
		lsp = {
			progress = { enabled = true, view = "mini" },
			message = { enabled = true },
			hover = { enabled = false },
			signature = { enabled = false },
		},
		views = {
			mini = {
				position = {
					row = -2,
				},
			},
		},
	},
}
