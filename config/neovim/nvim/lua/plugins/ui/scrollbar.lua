return {
	"petertriho/nvim-scrollbar",
	event = "BufReadPost", -- load when a buffer is opened
	dependencies = {
		-- "kevinhwang91/nvim-hlslens", -- optional: integrates with search highlighting
		"lewis6991/gitsigns.nvim",
	},
	config = function()
		local scrollbar = require("scrollbar")
		local handlers = require("scrollbar.handlers")

		scrollbar.setup({
			show = true,
			handle = {
				text = " ", -- minimal handle
				color = "#4B5563", -- grayish Catppuccin-like tone
				hide_if_all_visible = true,
			},
			marks = {
				Search = { color = "#FBBF24" },
				Error = { color = "#EF4444" },
				Warn = { color = "#F59E0B" },
				Info = { color = "#3B82F6" },
				Hint = { color = "#10B981" },
				Misc = { color = "#8B5CF6" },
			},
			excluded_buftypes = { "terminal", "nofile" },
			excluded_filetypes = { "prompt", "TelescopePrompt", "noice" },
		})

		require("scrollbar.handlers.gitsigns").setup()
		require("scrollbar.handlers.diagnostic").setup()
	end,
}
