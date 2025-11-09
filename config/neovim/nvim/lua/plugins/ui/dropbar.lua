return {
	"Bekaboo/dropbar.nvim",
	config = function()
		local sources = require("dropbar.sources")
		-- Configuration goes here
		require("dropbar").setup({
			bar = {
				-- show only file/folder path
				sources = function(_, _)
					return { sources.path }
				end,
				truncate = true, -- optional: truncate long paths

				padding = {
					left = 1,
					right = 1,
				},
			},
		})
	end,
}
