return {
	"aznhe21/actions-preview.nvim",
	event = { "BufReadPost", "LspAttach" },
	dependencies = { "folke/snacks.nvim" },
	config = function()
		require("actions-preview").setup({
			-- priority list of external command to highlight diff
			-- disabled by defalt, must be set by yourself
			highlight_command = {
				require("actions-preview.highlight").diff_highlight(),
				require("actions-preview.highlight").diff_so_fancy(),
			},

			backend = { "snacks" },
			snacks = {
				layout = {
					preset = "vertical",
					layout = { width = 0.6, height = 0.7 },
				},
			},
		})
	end,
}
