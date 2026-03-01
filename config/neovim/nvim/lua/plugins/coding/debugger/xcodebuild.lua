-- Reuse this handle to update or finish Fidget progress UI
local progress_handle

return {
	{
		"wojciech-kulik/xcodebuild.nvim",
		dependencies = {
			-- "j-hui/fidget.nvim", -- guarantee load order. Also installed, see figet.lua
			"nvim-telescope/telescope.nvim", -- Used for pickers (e.g. quickfix list)
			"MunifTanjim/nui.nvim", -- UI framework for floating windows
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
