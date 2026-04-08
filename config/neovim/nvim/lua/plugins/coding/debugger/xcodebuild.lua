-- Reuse this handle to update or finish Fidget progress UI
local progress_handle

return {
	{
		"wojciech-kulik/xcodebuild.nvim",
		dependencies = {
			{
				--- Only used for xcodebuild progress and notifications, not for LSP progress (handled by noice.nvim)
				"j-hui/fidget.nvim",
				opts = {
					progress = {
						poll_rate = false,
						ignore_done_already = true,
						ignore_empty_message = true,
						lsp = {
							progress_ringbuf_size = 0,
							log_handler = false,
						},
					},
					notification = {
						override_vim_notify = false,
						window = {
							normal_hl = "Normal",
							winblend = 100,
							border = "none",
							border_hl = "",
							zindex = 45,
							max_width = 0,
							max_height = 0,
							x_padding = 0,
							y_padding = 1,
							align = "bottom",
							relative = "editor",
						},
					},
				},
			},
			"folke/snacks.nvim", -- Used for pickers (e.g. quickfix list)
			"MunifTanjim/nui.nvim", -- UI framework for floating windows
			"nvim-treesitter/nvim-treesitter", -- (optional) for Quick tests support (required Swift parser)
		},
		lazy = true,
		config = function()
			require("xcodebuild").setup({
				-- Disable the default progress bar (we use fidget instead)
				show_build_progress_bar = false,
				commands = {
					focus_simulator_on_app_launch = false,
				},
				logs = {

					auto_open_on_success_tests = false,
					auto_open_on_failed_tests = false,
					auto_open_on_success_build = false,
					auto_open_on_failed_build = false,
					auto_focus = false,
					auto_close_on_app_launch = true,
					only_summary = true,

					-- Show notifications using fidget
					notify = function(message, severity)
						local fidget = require("fidget")

						if progress_handle then
							progress_handle.message = message
							if not message:find("Loading") then
								progress_handle:finish()
								progress_handle = nil
								if vim.trim(message) ~= "" then
									fidget.notify(message, severity)
								end
							end
						else
							fidget.notify(message, severity)
						end
					end,

					-- Update or start a fidget progress indicator
					notify_progress = function(message)
						local progress = require("fidget.progress")

						if progress_handle then
							progress_handle.title = ""
							progress_handle.message = message
						else
							progress_handle = progress.handle.create({
								message = message,
								lsp_client = { name = "xcodebuild.nvim" },
							})
						end
					end,
				},

				-- Enable code coverage support (show % coverage in UI)
				code_coverage = {
					enabled = true,
				},
			})
		end,
	},
}
