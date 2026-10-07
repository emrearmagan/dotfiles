return {
	"leoluz/nvim-dap-go",
	ft = "go", -- Only load for Go files
	dependencies = { "mfussenegger/nvim-dap" },
	config = function()
		require("dap-go").setup({})
	end,
}
