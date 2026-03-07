return {
	-- if this ever fails: ~/.local/share/nvim/lazy/markdown-preview.nvim/app/install.sh
	-- or:
	-- cd ~/.local/share/nvim/lazy/markdown-preview.nvim/app
	-- npm install
	{
		"iamcco/markdown-preview.nvim",
		cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
		build = "cd app && npm install && git restore .",
		init = function()
			vim.g.mkdp_filetypes = { "markdown" }
		end,
		ft = { "markdown" },
	},

	{
		"MeanderingProgrammer/render-markdown.nvim",
		dependencies = {
			"nvim-treesitter/nvim-treesitter",
			"nvim-tree/nvim-web-devicons",
		}, -- if you prefer nvim-web-devicons
		---@module 'render-markdown'
		---@type render.md.UserConfig
		opts = {
			render_modes = { "n", "i", "c", "t" },

			code = {
				enabled = true,
				border = "thin",
				style = "full",
			},

			link = {
				enabled = true,
				image = "󰥶 ",
				hyperlink = "󰌹 ",
			},
			anti_conceal = {
				enabled = true,
				disabled_modes = { "n", "c", "t" }, -- only active in insert mode
				above = 1,
				below = 1,
			},
		},
	},
}
