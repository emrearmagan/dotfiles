return {
	"akinsho/bufferline.nvim",
	version = "*",
	dependencies = { "nvim-tree/nvim-web-devicons", "catppuccin/nvim" },
	event = "VeryLazy",
	config = function()
		local bufferline = require("bufferline")
		local mocha = require("catppuccin.palettes").get_palette("mocha")
		local highlights = require("catppuccin.special.bufferline").get_theme({
			styles = { "bold" },
			custom = {
				all = {
					fill = { bg = "NONE" },
				},
				mocha = {
					buffer_selected = { fg = mocha.blue, bg = mocha.surface0 },
					duplicate_selected = { fg = mocha.blue, bg = mocha.surface0 },
					modified_selected = { fg = mocha.peach, bg = mocha.surface0 },
					tab_selected = { fg = mocha.blue, bg = mocha.surface0 },
				},
			},
		})

		bufferline.setup({
			options = {
				mode = "buffers",
				style_preset = bufferline.style_preset.minimal,
				sort_by = "insert_at_end",
				diagnostics = false,
				indicator = { style = "none" },
				separator_style = { "", "" },
				show_close_icon = false,
				show_buffer_close_icons = false,
				show_tab_indicators = true,
				always_show_bufferline = false,
				color_icons = true,
				tab_size = 0,
				max_name_length = 120,
			},
			highlights = highlights,
		})
	end,
}
