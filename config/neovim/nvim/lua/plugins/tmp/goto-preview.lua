return {
	"rmagatti/goto-preview",
	event = "BufEnter",
	config = function()
		local goto_preview = require("goto-preview")
		local preview_width = 120
		local preview_height = 15

		goto_preview.setup({
			width = preview_width,
			height = preview_height,
			post_open_hook = function(buf, win)
				vim.api.nvim_win_set_config(win, {
					relative = "editor",
					row = math.floor((vim.o.lines - preview_height) / 2),
					col = math.floor((vim.o.columns - preview_width) / 2),
					width = preview_width,
					height = preview_height,
				})

				vim.keymap.set("n", "q", goto_preview.close_all_win, {
					buffer = buf,
					silent = true,
					desc = "Close goto-preview",
				})
			end,
		}) -- necessary as per https://github.com/rmagatti/goto-preview/issues/88

		vim.keymap.set("n", "gpd", goto_preview.goto_preview_definition)
		vim.keymap.set("n", "gpt", goto_preview.goto_preview_type_definition)
		vim.keymap.set("n", "gpi", goto_preview.goto_preview_implementation)
		vim.keymap.set("n", "gpD", goto_preview.goto_preview_declaration)
		vim.keymap.set("n", "gP", goto_preview.close_all_win)
		vim.keymap.set("n", "gpr", goto_preview.goto_preview_references)
	end,
}
