return {
	{
		"rachartier/tiny-inline-diagnostic.nvim",
		event = "VeryLazy",
		priority = 1000,
		config = function()
			-- Disable default inline virtual text and configure signs
			vim.diagnostic.config({
				virtual_text = false,
				signs = {
					text = {
						[vim.diagnostic.severity.ERROR] = "✖",
						[vim.diagnostic.severity.WARN] = "▲",
						[vim.diagnostic.severity.INFO] = "●",
						[vim.diagnostic.severity.HINT] = "",
					},
				},
			})

			require("tiny-inline-diagnostic").setup({
				-- Available: "modern", "classic", "minimal", "powerline", "ghost", "simple", "nonerdfont", "amongus"
				preset = "minimal", -- simple and clean inline style
				transparent_bg = true, -- remove background
				transparent_cursorline = true, -- no tint on cursorline

				hi = {
					error = "DiagnosticError",
					warn = "DiagnosticWarn",
					info = "DiagnosticInfo",
					hint = "DiagnosticHint",
					arrow = "NonText",
					background = "NONE",
					mixing_color = "NONE",
				},
				signs = {
					left = "", -- vertical bar to the left of diagnostic text
					right = "", -- same on the right side
					arrow = " ", -- icon before the diagnostic text (Nerd Font arrow)
					up_arrow = " ", -- for multiline diagnostics pointing upward
					vertical = "", -- used for multiline continuation
					vertical_end = "", -- used for end of multiline diagnostic block
					diag = "●", -- small red dot
				},

				blend = { factor = 0.0 }, -- no blending at all

				options = {
					use_icons_from_diagnostic = false,
					throttle = 20,
					softwrap = 30,
					add_messages = {
						messages = true,
						display_count = false,
						show_multiple_glyphs = true,
					},
					multilines = {
						enabled = true,
						always_show = true, -- always show diagnostics inline
					},
				},
			})
		end,
	},

	-- Old configuration (commented out). Using tiny-inline-diagnostic.nvim instead.
	-- {
	-- 	"neovim/nvim-lspconfig",
	-- 	event = "VeryLazy",
	-- 	config = function()
	-- 		-- Define diagnostic signs
	-- 		vim.fn.sign_define("DiagnosticSignError", { text = "✖", texthl = "DiagnosticSignError" })
	-- 		vim.fn.sign_define("DiagnosticSignWarn", { text = "▲", texthl = "DiagnosticSignWarn" })
	-- 		vim.fn.sign_define("DiagnosticSignInfo", { text = "●", texthl = "DiagnosticSignInfo" })
	-- 		vim.fn.sign_define("DiagnosticSignHint", { text = "●", texthl = "DiagnosticSignHint" })
	--
	--
	-- Configure diagnostics display
	-- vim.diagnostic.config({
	-- 	virtual_text = {
	-- 		severity = {
	-- 			min = vim.diagnostic.severity.INFO,
	-- 			max = vim.diagnostic.severity.ERROR,
	-- 		},
	-- 		source = "always",
	-- 		prefix = "●",
	-- 		spacing = 4,
	-- 		current_line = false,
	-- 	},
	-- 	signs = true,
	-- 	underline = true,
	-- 	update_in_insert = false,
	-- 	severity_sort = true,
	--
	-- 	float = {
	-- 		border = "rounded",
	-- 		source = "always",
	-- 		focusable = true,
	-- 		header = "",
	-- 		severity_sort = true,
	-- 		prefix = "● ",
	-- 		max_width = math.floor(vim.o.columns * 0.7),
	-- 		max_height = math.floor(vim.o.lines * 0.3),
	-- 	},
	-- })
	--
	-- -- Show diagnostics in floating window when hovering
	-- vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
	-- 	callback = function()
	-- 		local opts = {
	-- 			focusable = false,
	-- 			close_events = { "BufLeave", "CursorMoved", "InsertEnter", "FocusLost" },
	-- 			scope = "cursor",
	-- 		}
	-- 		local diagnostics = vim.diagnostic.get(0, { lnum = vim.api.nvim_win_get_cursor(0)[1] - 1 })
	-- 		if diagnostics and #diagnostics > 0 then
	-- 			vim.diagnostic.open_float(nil, opts)
	-- 		end
	-- 	end,
	-- 	desc = "Show diagnostics in floating window on CursorHold",
	-- })
	-- 	end,
	-- },
}
