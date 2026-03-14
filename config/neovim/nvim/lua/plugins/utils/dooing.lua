return {
	"atiladefreitas/dooing",
	config = function()
		require("dooing").setup({
			pretty_print_json = true, -- Pretty-print JSON output (requires jq or python)
		})
	end,
}
