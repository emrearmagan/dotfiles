return {
	"nvim-telescope/telescope.nvim",
	dependencies = { "nvim-lua/plenary.nvim" },
	cmd = "Telescope",
	config = function()
		local actions = require("telescope.actions")

		require("telescope").setup({
			defaults = {
				layout_config = {
					prompt_position = "bottom",
				},
				sorting_strategy = "ascending",
				winblend = 10, -- slight transparency (optional)
				border = true,
				mappings = {
					i = {
						["<C-j>"] = actions.move_selection_next, -- move down
						["<C-k>"] = actions.move_selection_previous, -- move up
						["<C-q>"] = actions.smart_send_to_qflist + actions.open_qflist,
					},
					n = {
						["<C-j>"] = actions.move_selection_next,
						["<C-k>"] = actions.move_selection_previous,
					},
				},
			},
		})
	end,
}
