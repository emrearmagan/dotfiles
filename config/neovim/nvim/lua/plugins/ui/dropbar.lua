return {
	"Bekaboo/dropbar.nvim",
	config = function()
		-- Configuration goes here
		require("dropbar").setup({
			bar = {
				padding = {
					left = 1,
					right = 1,
				},
			},
		})
	end,
}
