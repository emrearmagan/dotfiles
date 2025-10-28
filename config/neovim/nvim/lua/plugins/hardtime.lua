return {
	"m4xshen/hardtime.nvim",
	-- dependencies = { "MunifTanjim/nui.nvim", "nvim-lua/plenary.nvim" },
	event = "VeryLazy",
	opts = {
		disabled_filetypes = { "qf", "netrw", "NvimTree", "lazy", "mason" },
		max_count = 3, -- how many repeats before blocking
		restriction_mode = "hint", -- "block" | "hint"
		hint = true,
		disable_mouse = false,
	},
}
