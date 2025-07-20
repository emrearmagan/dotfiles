return {
	"catppuccin/nvim",
	lazy = false,
	name = "catppuccin",
	priority = 1000,

	config = function()
		require("catppuccin").setup({
			flavour = "mocha", -- or "latte", "frappe", "macchiato"
			transparent_background = false,
			integrations = {
				notify = true, -- pull in Notify* highlight groups
			},
			dim_inactive = {
				enabled = false, -- dims the background color of inactive window
				shade = "light",
				percentage = 0.9, -- percentage of the shade to apply to the inactive window
			},
			custom_highlights = function(colors)
				local searchActive = { bg = colors.red, fg = "#181825" }
				local searchInactive = { bg = colors.peach, fg = "#000000" }

				return {
					CursorLineNr = { fg = colors.flamingo },
					Search = searchInactive,
					IncSearch = searchActive,
					EndOfBuffer = { fg = colors.flamingo },
					WinSeparator = { fg = colors.surface0, bg = colors.surface0 },
				}
			end,
		})
		vim.cmd.colorscheme("catppuccin")
	end,
}
