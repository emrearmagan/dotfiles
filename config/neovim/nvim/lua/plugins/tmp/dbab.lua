return {
	"zerochae/dbab.nvim",
	lazy = true,
	cmd = { "Dbab", "DbabClose" },
	dependencies = {
		"MunifTanjim/nui.nvim",
		"nvim-lua/plenary.nvim",
	},
	config = function()
		require("dbab").setup({
			connections = {
				{ name = "shnt", url = "postgres://admin:password@localhost:5432/shtn" },
			},
			layout = "wide",
		})
	end,
}
