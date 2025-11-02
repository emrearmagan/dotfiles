return {
	{
		"folke/trouble.nvim",
		event = "LspAttach",
		opts = {
			use_diagnostic_signs = true,
			auto_preview = true,
			modes = {
				diagnostics = {
					auto_open = false,
					auto_close = true,
					win = { position = "right" },
					filter = { buf = 0 },
				},
			},
		},
		config = function(_, opts)
			require("trouble").setup(opts)
		end,
	},
}
