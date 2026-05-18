return {
	"Bekaboo/dropbar.nvim",
	event = "BufReadPre",
	config = function()
		local sources = require("dropbar.sources")
		require("dropbar").setup({
			bar = {
				-- show only file/folder path
				sources = function(_, _)
					return { sources.path }
				end,
				truncate = true,

				padding = {
					left = 1,
					right = 1,
				},
			},
		})
	end,
}
