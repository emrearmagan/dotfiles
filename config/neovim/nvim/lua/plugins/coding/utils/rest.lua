return {
	"rest-nvim/rest.nvim",
	ft = "http",
	rocks = false, -- Disable luarocks installation
	dependencies = {
		"nvim-lua/plenary.nvim",
		"nvim-treesitter/nvim-treesitter",
		opts = function(_, opts)
			opts.ensure_installed = opts.ensure_installed or {}
			table.insert(opts.ensure_installed, "http")
		end,
	},
	config = function()
		require("rest-nvim").setup({
			request = {
				skip_ssl_verification = false,
				hooks = {
					encode_url = false,
				},
			},
			response = {
				hooks = {
					decode_url = true,
					format = true, -- pretty-print JSON / XML
				},
			},
			ui = {
				winbar = true,
				keybinds = {
					prev = "H",
					next = "L",
				},
			},
			cookies = {
				enable = true,
			},
			env = {
				enable = true,
				pattern = ".*%.env.*",
			},
		})
	end,
}
