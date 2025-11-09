return {
	"folke/noice.nvim",
	event = "VeryLazy",
	dependencies = {
		"MunifTanjim/nui.nvim",
		"hrsh7th/nvim-cmp", -- optional but enables full completion
		"hrsh7th/cmp-cmdline", -- cmdline completions
	},

	config = function()
		local cmp = require("cmp")
		-- Command-line completion for ":"
		cmp.setup.cmdline(":", {
			mapping = cmp.mapping.preset.cmdline(),
			sources = cmp.config.sources({
				{ name = "path" }, -- completes file paths like :edit ./src/
			}, {
				{ name = "cmdline" }, -- completes Vim commands
			}),
		})

		-- Search completion for "/" and "?"
		cmp.setup.cmdline({ "/", "?" }, {
			mapping = cmp.mapping.preset.cmdline(),
			sources = {
				{ name = "buffer" }, -- search from buffer text
			},
		})

		require("noice").setup({
			cmdline = {
				enabled = true,
				view = "cmdline_popup",
				format = {
					-- Normal command (e.g. :w, :q)
					cmdline = { pattern = "^:", icon = "", lang = "vim", conceal = false },
					search_down = { kind = "search", pattern = "^/", icon = "", lang = "regex" },
					search_up = { kind = "search", pattern = "^%?", icon = "", lang = "regex" },
					filter = { pattern = "^:%s*!%s*", icon = "", lang = "bash" },
					lua = { pattern = "^:%s*lua%s+", icon = "", lang = "lua" },
				},
			},
			messages = { enabled = true },
			lsp = {
				progress = { enabled = true, view = "mini" },
				message = { enabled = true },
			},

			-- notifcations are handled in snacks.nvim
			notify = { enabled = false },
			-- popupmenu = { enabled = false },

			popupmenu = {
				enabled = true, -- enable completion popup in cmdline
				backend = "cmp", -- use nvim-cmp as completion source
			},
			presets = {
				bottom_search = true, -- classic bottom command line for search
				command_palette = true, -- position cmdline and popupmenu together
				long_message_to_split = true, -- long messages go to split
				inc_rename = false, -- disable inc-rename support
				lsp_doc_border = false, -- no border for hover/signature
			},

			views = {
				mini = {
					position = {
						row = -2, -- move slightly up (negative = from bottom)
					},
				},
			},
		})
	end,
}
