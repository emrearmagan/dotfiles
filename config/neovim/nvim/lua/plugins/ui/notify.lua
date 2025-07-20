return {
	{
		"rcarriga/nvim-notify",
		lazy = true, -- Load the plugin lazily
		event = "VeryLazy", -- Load when Neovim enters an idle state

		config = function()
			require("notify").setup({
				-- Customize `nvim-notify` options here
				stages = "fade_in_slide_out", -- Animation style
				timeout = 3000, -- Time (ms) notifications remain visible
				background_colour = "#000000", -- Background color
				max_width = 50,
				max_height = 100,
			})

			vim.notify = require("notify")
		end,
	},
}
