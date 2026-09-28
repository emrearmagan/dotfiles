return {
	"catppuccin/nvim",
	lazy = false,
	name = "catppuccin",
	priority = 1000,

	config = function()
		require("catppuccin").setup({
			flavour = "mocha", -- or "latte", "frappe", "macchiato"
			transparent_background = true,
			auto_integrations = true, -- automatically load integrations
			integrations = {
				notify = true, -- pull in Notify* highlight groups
				gitsigns = true,
				telescope = true,
				mini = {
					enabled = true,
				},
				neotree = true,
				flash = true,
				cmp = true,
				dap = true,
				dap_ui = true,
				lsp_trouble = true,
				dadbod_ui = true,
				snacks = {
					enabled = true,
				},
			},
			styles = {
				functions = { "bold" },
				keywords = { "bold" },
				types = { "bold" },
			},
			dim_inactive = {
				enabled = false, -- dims the background color of inactive window
				shade = "light",
				percentage = 0.9, -- percentage of the shade to apply to the inactive window
			},
			custom_highlights = function(colors)
				local searchActive = { bg = colors.red, fg = "#181825" }
				local searchInactive = { bg = colors.peach, fg = "#000000" }
				local syntaxAccent = {
					func = "#6cb6ff",
					keyword = "#c792ea",
					type = "#ffcb6b",
				}

				return {
					CursorLineNr = { fg = colors.flamingo },

					-- Keep Catppuccin's syntax palette, strengthening only three accents.
					Function = { fg = syntaxAccent.func, bold = true },
					Keyword = { fg = syntaxAccent.keyword, bold = true },
					Type = { fg = syntaxAccent.type, bold = true },

					["@function"] = { link = "Function" },
					["@function.call"] = { link = "Function" },
					["@function.builtin"] = { link = "Function" },
					["@function.method"] = { link = "Function" },
					["@function.method.call"] = { link = "Function" },
					["@keyword"] = { link = "Keyword" },
					["@keyword.function"] = { link = "Keyword" },
					["@keyword.operator"] = { link = "Keyword" },
					["@keyword.return"] = { link = "Keyword" },
					["@type"] = { link = "Type" },
					["@type.builtin"] = { link = "Type" },
					["@constructor"] = { link = "Type" },
					["@lsp.type.function"] = { link = "Function" },
					["@lsp.type.method"] = { link = "Function" },
					["@lsp.type.keyword"] = { link = "Keyword" },
					["@lsp.type.type"] = { link = "Type" },
					["@lsp.type.class"] = { link = "Type" },

					DiffAdd = { bg = "#0e4429" },
					DiffDelete = { bg = "#4c1f2b" },
					DiffChange = { bg = "#1f3152" },
					DiffText = { bg = "#2f4f78" },
					Search = searchInactive,
					IncSearch = searchActive,
					EndOfBuffer = { fg = colors.flamingo },
					NormalNC = {
						bg = "#171722",
					},
					WinSeparator = {
						fg = colors.surface0,
						bg = "NONE",
					},
					NormalFloat = {
						bg = colors.mantle,
					},
					FloatBorder = {
						fg = colors.overlay0,
						bg = colors.mantle,
					},

					-- Completion menus
					Pmenu = {
						bg = colors.mantle,
						fg = colors.text,
					},

					PmenuSel = {
						bg = colors.surface0,
						fg = colors.text,
						bold = false,
					},

					PmenuBorder = {
						fg = colors.surface0,
						bg = colors.mantle,
					},

					PmenuSbar = {
						bg = colors.mantle,
					},

					PmenuThumb = {
						bg = colors.surface1,
					},

					-- Solid background for completion popup (overrides transparent_background)
					-- Pmenu = { bg = colors.mantle, fg = colors.text },
					-- PmenuSel = { bg = colors.surface0, fg = colors.text, bold = true },
					-- PmenuBorder = { fg = colors.surface1 },
					-- NormalFloat = { bg = colors.mantle, fg = colors.text },
					-- FloatBorder = { bg = colors.mantle, fg = colors.surface1 },
				}
			end,
		})
		vim.cmd.colorscheme("catppuccin")
	end,
}
