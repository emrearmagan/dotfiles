return {
	"brenoprata10/nvim-highlight-colors",
	event = { "BufReadPre", "BufNewFile" },
	config = function()
		require("nvim-highlight-colors").setup({
			render = "background", -- options: 'background', 'foreground', 'first_column'
			enable_named_colors = true,
			enable_tailwind = true,
		})
	end,
}
