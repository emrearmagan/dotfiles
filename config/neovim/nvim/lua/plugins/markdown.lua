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
}
