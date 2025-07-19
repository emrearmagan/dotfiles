return {
	"akinsho/bufferline.nvim",
	version = "*",
	dependencies = { "nvim-tree/nvim-web-devicons" },
	event = "VeryLazy",
	config = function()
		require("bufferline").setup({
			options = {
				mode = "buffers", -- Show buffers (not tabs)
				numbers = "none", -- No numbering shown on buffers
				diagnostics = "nvim_lsp", -- Show LSP diagnostic indicators (errors/warnings)
				show_close_icon = false, -- Hide top-right global close icon
				show_buffer_close_icons = false, -- Hide close icon on each buffer tab
				separator_style = "slant", -- Use slanted separators between tabs ("slant", "thick", "thin")
				always_show_bufferline = false, -- Show bufferline even with only one buffer
				color_icons = true, -- Enable colorful devicons
				show_tab_indicators = true, -- Show tab indicator (thin underline for active tab)
				enforce_regular_tabs = true, -- Prevent bufferline from compressing tab names
				max_name_length = 25, -- Max length of a buffer name before truncation
				-- max_prefix_length = 15,         -- Max length of prefix used before truncated name
			},
			highlights = {
				buffer_selected = {
					fg = "#89b4fa", -- Foreground color for selected buffer
					bold = true, -- Bold text
					italic = false, -- No italic
				},
				indicator_selected = {
					fg = "#89b4fa", -- Color of the little underline arrow/indicator
					bold = true,
				},
			},
		})
	end,
}
