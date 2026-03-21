return {
	-- "emrearmagan/atlas.nvim",
	dir = "/Users/emrearmagan/development/nvim/sticky.nvim",
	-- lazy = true,
	config = function()
		require("sticky").setup({
			-- optional overrides:
			-- note_path = vim.fs.joinpath(vim.fn.stdpath("state"), "sticky-note.md"),
			-- width = 0.28,
			-- height = 0.35,
			-- col_offset = 2,
			-- row_offset = 1,
			-- border = "rounded",
			-- auto_open = true,
		})
	end,
}
