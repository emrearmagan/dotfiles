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

		vim.api.nvim_create_autocmd("FileType", {
			pattern = { "dbui", "sql", "dbout" },
			callback = function()
				vim.keymap.set("n", "<leader>S", "<Plug>(DBUI_ExecuteQuery)", {
					buffer = true,
					desc = "DBExecuteQuery",
				})

				vim.keymap.set("n", "<leader>E", "<Plug>(DBUI_EditBindParameters)", {
					buffer = true,
					desc = "DBEditParameters",
				})

				vim.keymap.set("n", "<leader>W", "<Plug>(DBUI_SaveQuery)", {
					buffer = true,
					desc = "DBSaveQuery",
				})

				vim.keymap.set("v", "<leader>S", "<Plug>(DBUI_ExecuteQuery)", {
					buffer = true,
					desc = "DBExecuteSelection",
				})

				-- close DBUI tab
				vim.keymap.set("n", "<leader>Q", "<cmd>tabclose<CR>", {
					buffer = true,
					desc = "Close DBUI tab",
				})
			end,
		})

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
