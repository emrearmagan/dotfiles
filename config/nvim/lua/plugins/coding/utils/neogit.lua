return {
	"NeogitOrg/neogit",
	cmd = "Neogit",
	dependencies = {
		"esmuellert/codediff.nvim",
		"folke/snacks.nvim",
	},
	opts = {
		graph_style = "unicode",
		integrations = {
			codediff = true,
			telescope = false,
			snacks = true,
		},
		diff_viewer = "codediff",
	},
}
