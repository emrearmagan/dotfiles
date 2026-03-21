return {
	"m4xshen/hardtime.nvim",
	lazy = false,
	dependencies = { "MunifTanjim/nui.nvim" },
	opts = {
		restriction_mode = "hint",
		disable_mouse = false,
		hint = true,
		restricted_keys = {
			-- Exclude these keys from warnings
			["h"] = false,
			["j"] = false,
			["k"] = false,
			["l"] = false,
		},
	},
}
