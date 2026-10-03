return {
	-- if this ever fails: ~/.local/share/nvim/lazy/markdown-preview.nvim/app/install.sh
	-- or:
	-- cd ~/.local/share/nvim/lazy/markdown-preview.nvim/app
	-- npm install
	{
		"iamcco/markdown-preview.nvim",
		cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
		build = "cd app && npm install && git restore .",
		ft = { "help", "markdown" },
		init = function()
			vim.g.mkdp_filetypes = { "markdown" }
		end,
	},
	{
		"MeanderingProgrammer/render-markdown.nvim",
		ft = { "help", "markdown" },
		dependencies = {
			"nvim-treesitter/nvim-treesitter",
			"nvim-tree/nvim-web-devicons",
		},
		---@module 'render-markdown'
		---@type render.md.UserConfig
		opts = {
			render_modes = { "n", "i", "c", "t" },
			completions = { lsp = { enabled = true } },
			sign = { enabled = false },
			heading = {
				sign = false,
				icons = { "", "", "", "", "", "" },
				position = "inline",
				width = { "full", "full", "block", "block", "block", "block" },
				left_pad = { 2, 0, 0, 0, 0, 0 },
				right_pad = { 2, 0, 0, 0, 0, 0 },
				border = { true, true, false, false, false, false },
				border_virtual = true,
				above = " ",
				below = "─",
				backgrounds = {
					"RenderMarkdownH1Bg",
					"RenderMarkdownH2",
					"RenderMarkdownH3",
					"RenderMarkdownH4",
					"RenderMarkdownH5",
					"RenderMarkdownH6",
				},
			},
			code = {
				sign = false,
				style = "full",
				border = "thin",
				position = "right",
				language_icon = false,
				language_name = true,
				language_info = false,
				language_pad = 1,
				language_border = "█",
				background_inset = 0,
				left_pad = 2,
				right_pad = 0.9,
				above = " ",
				below = " ",
				inline_pad = 1,
				highlight = "CursorLine",
				highlight_info = "Comment",
				highlight_language = "Comment",
				highlight_border = "CursorLine",
				highlight_inline = "ColorColumn",
			},
			bullet = {
				icons = { "•", "◦", "▪", "▫" },
				right_pad = 1,
			},
			checkbox = {
				right_pad = 0,
				unchecked = { icon = "󰄱 " },
				checked = { icon = "󰄵 " },
			},
			quote = {
				icon = "▎",
			},
			dash = {
				icon = "─",
				width = "full",
			},
			pipe_table = {
				preset = "none",
				cell = "trimmed",
				padding = 1,
				border_enabled = true,
			},
			link = {
				enabled = true,
				image = "󰥶 ",
				hyperlink = "󰌹 ",
			},
			callout = {
				note = { rendered = "Note", quote_icon = "▎" },
				tip = { rendered = "Tip", quote_icon = "▎" },
				important = { rendered = "Important", quote_icon = "▎" },
				warning = { rendered = "Warning", quote_icon = "▎" },
				caution = { rendered = "Caution", quote_icon = "▎" },
			},
			anti_conceal = {
				enabled = true,
				disabled_modes = { "n", "c", "t" },
				above = 1,
				below = 1,
			},
		},
	},
}
