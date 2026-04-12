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
				cmdline = { pattern = "^:", icon = ":", lang = "vim" },
				search_down = { kind = "search", pattern = "^/", icon = "/", lang = "regex" },
				search_up = { kind = "search", pattern = "^%?", icon = "?", lang = "regex" },
				filter = { pattern = "^:%s*!", icon = "!", lang = "bash" },
				lua = { pattern = "^:%s*lua%s+", icon = "lua", lang = "lua" },
				help = { pattern = "^:%s*he?l?p?%s+", icon = "help" },
				input = { view = "cmdline", icon = "" },
			},
		},
		presets = {
			bottom_search = true, -- use a classic bottom cmdline for search
			command_palette = true, -- position the cmdline and popupmenu together
			long_message_to_split = true, -- long messages will be sent to a split
		},
		lsp = {
			override = {
				["vim.lsp.util.convert_input_to_markdown_lines"] = true,
				["vim.lsp.util.stylize_markdown"] = true,
				["cmp.entry.get_documentation"] = true, -- requires hrsh7th/nvim-cmp
			},

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
