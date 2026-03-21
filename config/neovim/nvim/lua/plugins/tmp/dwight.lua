return {
	"otaleghani/dwight.nvim",
	dependencies = {
		"nvim-lua/plenary.nvim",
		"nvim-treesitter/nvim-treesitter",
	},
	config = function()
		local function set_dwight_highlights()
			local hl = vim.api.nvim_set_hl
			hl(0, "DwightProcessing", { fg = "#ffffff", bold = true, italic = true })
		end

		require("dwight").setup({
			-- Which CLI agent runs agentic tasks.
			-- "claude_code" (default) | "codex" | "gemini" | "opencode"
			backend = "opencode",
			model = "opencode/minimax-m2.5-free",
			agentic_opts = {
				cli_timeout = 120,
				claude_code_timeout = false,
			},
		})

		set_dwight_highlights()
		vim.api.nvim_create_autocmd("ColorScheme", {
			callback = set_dwight_highlights,
		})
	end,
}
