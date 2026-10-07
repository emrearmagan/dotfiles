return {
	{
		"rest-nvim/rest.nvim",
		ft = "http",
		cmd = "Rest",
		dependencies = {
			"nvim-treesitter/nvim-treesitter",
		},
		init = function()
			vim.api.nvim_create_autocmd("FileType", {
				pattern = "json",
				callback = function(event)
					vim.bo[event.buf].formatprg = "jq ."
				end,
			})
			vim.api.nvim_create_autocmd("FileType", {
				pattern = "http",
				callback = function(event)
					local cfg = { buffer = event.buf, silent = true }

					vim.keymap.set(
						{ "n", "v" },
						"<leader>R",
						"<cmd>Rest run<cr>",
						vim.tbl_extend("force", cfg, { desc = "Run request" })
					)
					vim.keymap.set(
						"n",
						"<leader>I",
						"<cmd>Rest open<cr>",
						vim.tbl_extend("force", cfg, { desc = "Open response" })
					)
					vim.keymap.set(
						"n",
						"<leader>L",
						"<cmd>Rest last<cr>",
						vim.tbl_extend("force", cfg, { desc = "Replay last request" })
					)
					vim.keymap.set(
						"n",
						"<leader>E",
						"<cmd>Rest env select<cr>",
						vim.tbl_extend("force", cfg, { desc = "Select env" })
					)
					vim.keymap.set(
						"n",
						"<leader>C",
						"<cmd>Rest curl yank<cr>",
						vim.tbl_extend("force", cfg, { desc = "Copy curl" })
					)
				end,
			})
		end,
	},
}
