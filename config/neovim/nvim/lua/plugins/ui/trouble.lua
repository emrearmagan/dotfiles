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
				win = {
					position = "right",
					size = 0.3,
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
	end,
}
