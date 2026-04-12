return {
	{
		"nvim-neo-tree/neo-tree.nvim",
		branch = "main",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"nvim-tree/nvim-web-devicons",
			"MunifTanjim/nui.nvim",
		},
		config = function()
			require("neo-tree").setup({
				hijack_netrw = true, -- Replace default netrw with Neo-tree

				close_if_last_window = true, -- Close Neo-tree if it's the last open window
				enable_git_status = true,
				enable_diagnostics = true,
				filesystem = {
					follow_current_file = {
						enabled = true,
					},
					close_on_open = true,
					filtered_items = {
						visible = false, -- Hide hidden files
						show_hidden_count = true, -- Display count of hidden files
						hide_dotfiles = true, -- Hide dotfiles by default
						hide_gitignore = false, -- Show files ignored by .gitignore
						never_show = { ".DS_Store" },
					},
					hijack_netrw_behavior = "open_default", -- Automatically open Neo-tree for directories
					use_libuv_file_watcher = true, -- Enable automatic tree refresh
				},

				window = {
					mappings = {
						["l"] = "open", -- Open file or directory
						["<2-LeftMouse>"] = "open", -- Open with double-click
						["<cr>"] = function(state)
							local node = state.tree:get_node()
							require("neo-tree.sources.filesystem.commands").open(state)
							require("neo-tree.command").execute({ action = "close" })
						end,
						["<esc>"] = "cancel", -- Close preview or Neo-tree window
						["h"] = "close_node", -- Collapse folder
						["<Tab>"] = "toggle_preview", -- Toggle preview window
						["<space>"] = false,
						["f"] = function()
							require("fzf-lua").files()
						end,
						["/"] = "fuzzy_finder",
						["P"] = function(state)
							local node = state.tree:get_node()
							require("neo-tree.ui.renderer").focus_node(state, node:get_parent_id())
						end,
					},
				},
			})

			vim.api.nvim_create_autocmd("WinLeave", {
				callback = function()
					if vim.bo.filetype ~= "neo-tree" then
						return
					end

					vim.schedule(function()
						pcall(function()
							require("neo-tree.command").execute({ action = "close" })
						end)
					end)
				end,
			})
		end,
	},
}
