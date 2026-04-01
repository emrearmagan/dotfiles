return {
	"zerochae/dbab.nvim",
	dependencies = {
		"MunifTanjim/nui.nvim",
		"nvim-lua/plenary.nvim", -- Optional: for async execution
	},
	-- For blink.cmp, the source is included in this plugin (blink_dbab)
	config = function()
		require("dbab").setup({
			connections = {
				{ name = "shnt", url = "postgres://admin:password@localhost:5432/shtn" },
			},
			layout = "wide",
		})
	end,
}
