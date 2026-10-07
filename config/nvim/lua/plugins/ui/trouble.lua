return {
	"folke/trouble.nvim",
	event = "LspAttach",
	opts = {
		use_diagnostic_signs = true,
		auto_preview = true,
		modes = {
			-- buffer-only diagnostics
			diagnostics_buffer = {
				desc = "Buffer Diagnostics",
				mode = "diagnostics",
				filter = { buf = 0 }, -- restrict to current buffer
				win = { position = "right", size = 0.2 },
				auto_open = false,
				auto_close = false,
				groups = {
					{ "filename", format = "{file_icon} {basename:Title} {count}" },
				},
			},
			-- workspace-wide diagnostics (no filter)
			diagnostics = {
				desc = "Workspace Diagnostics",
				mode = "diagnostics", -- reuse built-in diagnostics source
				filter = {}, -- no buf filter = workspace-level
				win = { position = "right", size = 0.2 },
				auto_open = false,
				auto_close = true,
				groups = {
					{ "filename", format = "{file_icon} {basename:Title} {count}" },
				},
			},
			symbols = {
				desc = "Document Symbols",
				mode = "lsp_document_symbols",
				auto_open = false,
				auto_close = true,
				format = "{kind_icon} {symbol.name}",
				win = {
					position = "right",
					size = 0.2,
				},
				groups = {
					{ "kind", format = "{kind_icon} {kind} ({count})" },
				},
			},

			lsp_bottom = {
				desc = "LSP References",
				mode = "lsp",
				win = {
					position = "bottom",
					size = 15,
				},
				groups = {
					{ "filename", format = "{file_icon} {basename:Title} {count}" },
				},
			},
		},

		icons = {
			indent = {
				last = "╰╴", -- rounded
			},
		},
	},
	config = function(_, opts)
		local trouble = require("trouble")
		trouble.setup(opts)

		vim.api.nvim_create_autocmd("QuitPre", {
			group = vim.api.nvim_create_augroup("trouble_close_last", { clear = true }),
			callback = function()
				local current = vim.api.nvim_get_current_win()
				local windows = vim.tbl_filter(function(win)
					return vim.api.nvim_win_get_config(win).relative == ""
				end, vim.api.nvim_tabpage_list_wins(0))
				if #windows ~= 2 or vim.bo[vim.api.nvim_win_get_buf(current)].filetype == "trouble" then
					return
				end
				local other = windows[1] == current and windows[2] or windows[1]
				if vim.bo[vim.api.nvim_win_get_buf(other)].filetype == "trouble" then
					vim.api.nvim_win_close(other, true)
				end
			end,
		})
	end,
}
