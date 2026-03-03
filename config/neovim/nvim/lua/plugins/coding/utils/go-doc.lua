return {
	"fredrikaverpil/godoc.nvim",
	version = "*",
	dependencies = {
		{
			"nvim-treesitter/nvim-treesitter",
			branch = "main",
			build = ":TSUpdate godoc go",
			config = function()
				require("nvim-treesitter.parsers").godoc = {
					install_info = {
						url = "https://github.com/fredrikaverpil/tree-sitter-godoc",
						files = { "src/parser.c" },
						branch = "main",
					},
					filetype = "godoc",
				}

				vim.treesitter.language.register("godoc", "godoc")
			end,
		},
		"nvim-telescope/telescope.nvim",
	},
	build = "go install github.com/lotusirous/gostdsym/stdsym@latest",
	cmd = { "GoDoc" },
	opts = {
		picker = {
			type = "telescope",
		},
		adapters = {
			{
				name = "go",
				opts = {
					get_syntax_info = function()
						return {
							filetype = "godoc",
							language = "godoc",
						}
					end,
				},
			},
		},
	},
	config = function(_, opts)
		require("godoc").setup(opts)

		vim.api.nvim_create_autocmd("FileType", {
			pattern = "godoc",
			callback = function(ev)
				pcall(vim.treesitter.start, ev.buf, "godoc")
			end,
		})
	end,
}
