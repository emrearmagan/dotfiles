return {
	"kylechui/nvim-surround",
	version = "^3.0.0", -- Use for stability; omit to use `main` branch for the latest features
	event = "VeryLazy",
	config = function()
		require("nvim-surround").setup({
			-- Configuration here, or leave empty to use defaults

			-- Default keymaps:
			-- Normal mode:
			--   ys<motion><char>   → add surround
			--   yss<char>          → add surround around current line
			--   ds<char>           → delete surround
			--   cs<from><to>       → change surround
			--
			-- Visual mode:
			--   S<char>            → add surround around selection
			--   gS<char>           → add surround around visual line
			--
			-- Insert mode:
			--   <C-g>s<char>       → add surround to previous text
			--   <C-g>S<char>       → add surround on new line
		})
	end,
}
