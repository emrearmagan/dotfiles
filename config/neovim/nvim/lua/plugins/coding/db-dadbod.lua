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
	end,
}
