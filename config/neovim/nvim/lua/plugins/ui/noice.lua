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
		cmdline = {
			enabled = true,
			view = "cmdline", -- bottom style
			format = {
				search_down = { kind = "search", pattern = "^/", icon = " /", lang = "regex" },
				search_up = { kind = "search", pattern = "^%?", icon = " ?", lang = "regex" },
				filter = { pattern = "^:%s*!", icon = " !", lang = "bash" },
				lua = { pattern = "^:%s*lua%s+", icon = " lua", lang = "lua" },
				help = { pattern = "^:%s*he?l?p?%s+", icon = " ?" },
			},
		},
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
