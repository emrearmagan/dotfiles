-- lazy.nvim
return {
	"folke/noice.nvim",
	event = "VeryLazy",
	dependencies = {
		"MunifTanjim/nui.nvim",
	},
	config = function()
		require("noice").setup({
			cmdline = {
				enabled = true,
				view = "cmdline_popup",
				format = {
					cmdline = {
						pattern = "^:",
						icon = "",
						lang = "vim",
						conceal = false, -- keep ":" visible
					},
				},
			},
			notify = {
				enabled = false,
			},
			presets = {
				bottom_search = true, -- classic bottom command line for search
				command_palette = true, -- position cmdline and popupmenu together
				long_message_to_split = true, -- long messages go to split
				inc_rename = false, -- disable inc-rename support
				lsp_doc_border = false, -- no border for hover/signature
			},
		})
	end,
}
