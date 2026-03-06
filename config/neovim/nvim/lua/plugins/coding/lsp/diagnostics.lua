return {
	{
		"rachartier/tiny-inline-diagnostic.nvim",
		event = "VeryLazy",
		priority = 1000,
		config = function()
			-- Disable default inline virtual text and configure signs
			vim.diagnostic.config({
				virtual_text = false,
				signs = {
					text = {
						[vim.diagnostic.severity.ERROR] = "✖",
						[vim.diagnostic.severity.WARN] = "▲",
						[vim.diagnostic.severity.INFO] = "●",
						[vim.diagnostic.severity.HINT] = "",
					},
				},
			})

			require("tiny-inline-diagnostic").setup({
				-- Available: "modern", "classic", "minimal", "powerline", "ghost", "simple", "nonerdfont", "amongus"
				preset = "minimal", -- simple and clean inline style
				transparent_bg = true, -- remove background
				transparent_cursorline = true, -- no tint on cursorline
				hi = {
					error = "DiagnosticError",
					warn = "DiagnosticWarn",
					info = "DiagnosticInfo",
					hint = "DiagnosticHint",
					arrow = "NonText",
					background = "NONE",
					mixing_color = "NONE",
				},
				signs = {
					left = "", -- vertical bar to the left of diagnostic text
					right = "", -- same on the right side
					arrow = " ", -- icon before the diagnostic text (Nerd Font arrow)
					up_arrow = " ", -- for multiline diagnostics pointing upward
					vertical = "", -- used for multiline continuation
					vertical_end = "", -- used for end of multiline diagnostic block
					diag = "●", -- small red dot
				},

				blend = { factor = 0.0 }, -- no blending at all

				options = {
					-- Display the source of diagnostics (e.g., "lua_ls", "pyright")
					show_source = {
						enabled = true, -- Enable showing source names
						if_many = true, -- Only show source if multiple sources exist for the same diagnostic
					},

					use_icons_from_diagnostic = true,
					throttle = 20,
					softwrap = 30,
					add_messages = {
						messages = true,
						display_count = false,
						show_multiple_glyphs = true,
					},
					multilines = {
						enabled = true,
						always_show = true, -- always show diagnostics inline
					},
				},
			})
		end,
	},
}
