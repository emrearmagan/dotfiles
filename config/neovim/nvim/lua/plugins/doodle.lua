return {
	"apdot/doodle",
	dependencies = {
		"kkharji/sqlite.lua",
		"nvim-lua/plenary.nvim",
		"nvim-telescope/telescope.nvim",
	},
	config = function()
		require("doodle").setup({
			--         settings = {
			--             -- This is the only required setting for sync to work.
			--             -- Set it to the absolute path of your private notes repository.
			--             git_repo = "path/to/your/initialized/git/repository",
			--             sync = true,
			--         }
		})
	end,
}
