return {
	"kristijanhusak/vim-dadbod-ui",
	dependencies = {
		{ "tpope/vim-dadbod", lazy = true },
		{ "kristijanhusak/vim-dadbod-completion", ft = { "sql", "mysql", "plsql" }, lazy = true },
	},
	cmd = {
		"DBUI",
		"DBUIToggle",
		"DBUIAddConnection",
		"DBUIFindBuffer",
	},
	init = function()
		vim.g.db_ui_use_nerd_fonts = 1

		vim.api.nvim_create_user_command("DBUIFull", function()
			require("lazy").load({ plugins = { "vim-dadbod-ui" } })
			vim.cmd("tabnew | DBUI")
		end, {})

		-- Custom keybindings for DBUI buffers
		vim.api.nvim_create_autocmd("FileType", {
			pattern = "dbui",
			callback = function()
				-- Use l/h like in NvimTree
				local opts = { buffer = true, silent = true }
				vim.keymap.set("n", "l", "<Plug>(DBUI_SelectLine)", opts) -- expand/open
				vim.keymap.set("n", "h", "<Plug>(DBUI_GoBack)", opts) -- collapse/go back
			end,
		})
	end,
}
