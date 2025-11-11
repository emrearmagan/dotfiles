return {
	"rachartier/tiny-glimmer.nvim",
	event = "VeryLazy",
	config = function()
		require("tiny-glimmer").setup({
			enabled = true,
			disable_warnings = true,
			refresh_interval_ms = 8,

			overwrite = {
				auto_map = true,

				yank = {
					enabled = true,
					default_animation = "fade",
				},

				paste = {
					enabled = true,
					default_animation = "reverse_fade",
				},

				undo = {
					enabled = true,
					default_animation = {
						name = "fade",
						settings = {
							from_color = "DiffDelete",
							max_duration = 400,
							min_duration = 300,
						},
					},
					undo_mapping = "u",
				},

				redo = {
					enabled = true,
					default_animation = {
						name = "fade",
						settings = {
							from_color = "DiffAdd",
							max_duration = 400,
							min_duration = 300,
						},
					},
					redo_mapping = "<C-r>",
				},

				search = { enabled = false },
			},

			animations = {
				fade = {
					max_duration = 300,
					min_duration = 200,
					easing = "outQuad",
					from_color = "Visual",
					to_color = "Normal",
				},
				reverse_fade = {
					max_duration = 280,
					min_duration = 200,
					easing = "outBack",
					from_color = "Visual",
					to_color = "Normal",
				},
			},

			-- disable it in dashboard-like buffers
			hijack_ft_disabled = { "alpha", "snacks_dashboard" },
		})
	end,
}
