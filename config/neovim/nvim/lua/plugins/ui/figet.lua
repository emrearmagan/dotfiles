return {
	"j-hui/fidget.nvim",
	-- event = "VeryLazy",
	--
	lazy = false,
	priority = 10000,
	config = function()
		require("fidget").setup({
			progress = {
				ignore_done_already = true, -- Ignore new tasks that are already complete
				ignore_empty_message = true, -- Ignore new tasks that don't contain a message
				-- Completely ignore all LSP clients (disables `$ /progress`)
				-- Currenlty all lsp progress is handled by noice.nvim. In the future i might wanna use fidget again,
				-- then i could use the display config below.
				ignore = { "null-ls" },

				-- display = {
				-- 	-- format_message = function(msg)
				-- 	-- 	local icon = msg.done and "✔" or "…" -- only change appearance here
				-- 	-- 	local pct = msg.percentage and string.format(" (%d%%)", msg.percentage) or ""
				-- 	-- 	local title = msg.title or msg.message or ""
				-- 	-- 	return string.format("%s %s%s", icon, title, pct)
				-- 	-- end,
				--
				-- 	-- everything below is valid documented config
				-- 	done_icon = "✔",
				-- 	done_style = "Constant",
				-- 	progress_icon = { "dots" },
				-- 	progress_style = "WarningMsg",
				-- 	group_style = "Title",
				-- 	icon_style = "Question",
				-- 	done_ttl = 2,
				-- 	progress_ttl = 10,
				-- 	skip_history = true,
				-- },

				lsp = {
					progress_ringbuf_size = 0,
					log_handler = false,
				},
			},

			notification = {
				override_vim_notify = false,
				window = {
					normal_hl = "String", -- Base highlight group in the notification window
					winblend = 0, -- Background color opacity in the notification window
					border = "rounded", -- Border around the notification window
					zindex = 45, -- Stacking priority of the notification window
					max_width = 0, -- Maximum width of the notification window
					max_height = 0, -- Maximum height of the notification window
					x_padding = 1, -- Padding from right edge of window boundary
					y_padding = 1, -- Padding from bottom edge of window boundary
					align = "bottom", -- How to align the notification window
					relative = "editor", -- What the notification window position is relative to
				},
			},
		})
	end,
}
