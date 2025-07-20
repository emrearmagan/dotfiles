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
				-- background_colour = "#000000", -- Background color
				max_width = 50,
				max_height = 100,
			})

			--------------------------------------------------------------------------
			--  Custom highlight palette (matches your lualine colours)
			--------------------------------------------------------------------------

			local bg = "#1e1e2e" -- mantle
			local blue = "#89b4fa" -- INFO
			local peach = "#fab387" -- WARN
			local red = "#f38ba8" -- ERROR
			local mauve = "#cba6f7" -- DEBUG
			local green = "#a6e3a1" -- TRACE

			local palette = {
				INFO = blue,
				WARN = peach,
				ERROR = red,
				DEBUG = mauve,
				TRACE = green,
			}

			local hi = vim.api.nvim_set_hl
			hi(0, "NotifyBackground", { bg = bg })

			for level, colour in pairs(palette) do
				for _, part in ipairs({ "Border", "Icon", "Title" }) do
					hi(0, "Notify" .. level .. part, { fg = colour, bg = bg })
				end
			end

			vim.notify = require("notify")
		end,
	},
}
