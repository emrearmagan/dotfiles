return {
	"kylechui/nvim-surround",
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
			--
			--
			--       Old text                    Command         New text
			--------------------------------------------------------------------------------
			-- surr*ound_words             ysiw)           (surround_words)
			-- surr*ound_words             ysiw(           ( surround_words )
			-- *make strings               ys$"            "make strings"
			-- [delete ar*ound me!]        ds]             delete around me!
			-- remove <b>HTML t*ags</b>    dst             remove HTML tags
			-- 'change quot*es'            cs'"            "change quotes"
			-- <b>or tag* types</b>        csth1<CR>       <h1>or tag types</h1>
			-- delete(functi*on calls)     dsf             function calls
		})
	end,
}
