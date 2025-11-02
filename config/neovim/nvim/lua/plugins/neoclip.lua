return {
	"AckslD/nvim-neoclip.lua",
	dependencies = {
		{ "nvim-telescope/telescope.nvim" },
		{ "kkharji/sqlite.lua", module = "sqlite" }, -- optional but recommended for persistence
	},
	event = "VeryLazy",
	config = function()
		require("neoclip").setup({
			history = 1000, -- how many yanks to remember
			enable_persistent_history = true, -- saves history between sessions
			continuous_sync = true, -- auto sync with system clipboard
			preview = true, -- show preview window
			keys = {
				telescope = {
					i = {
						select = "<cr>",
						paste = "<c-p>",
						replay = "<c-q>", -- replay a macro
						delete = "<c-d>",
					},
					n = {
						select = "<cr>",
						paste = "p",
						replay = "q",
						delete = "d",
					},
				},
			},
		})

		-- Load Telescope extension
		require("telescope").load_extension("neoclip")
	end,
}
