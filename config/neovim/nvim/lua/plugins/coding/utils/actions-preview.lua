return {
	"aznhe21/actions-preview.nvim",
	event = { "BufReadPost", "LspAttach" },
	config = function()
		require("actions-preview").setup({
			-- priority list of external command to highlight diff
			-- disabled by defalt, must be set by yourself
			highlight_command = {
				require("actions-preview.highlight").diff_highlight(),
				require("actions-preview.highlight").diff_so_fancy(),
			},

			-- priority list of preferred backend
			backend = { "telescope" },

			-- options related to telescope.nvim
			telescope = vim.tbl_extend(
				"force",
				-- telescope theme: https://github.com/nvim-telescope/telescope.nvim#themes
				require("telescope.themes").get_dropdown(),
				-- a table for customizing content
				{
					-- a function to make a table containing the values to be displayed.
					-- fun(action: Action): { title: string, client_name: string|nil }
					make_value = nil,

					-- a function to make a function to be used in `display` of a entry.
					-- see also `:h telescope.make_entry` and `:h telescope.pickers.entry_display`.
					-- fun(values: { index: integer, action: Action, title: string, client_name: string }[]): function
					make_make_display = nil,
					layout_strategy = "vertical",
					layout_config = {
						width = 0.6,
						height = 0.7,
						prompt_position = "top",
						preview_cutoff = 20,
						preview_height = function(_, _, max_lines)
							return max_lines - 15
						end,
					},
				}
			),
		})
	end,
}
