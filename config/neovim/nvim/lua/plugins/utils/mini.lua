return {
	-- Smarter text objects (quotes, brackets, tags, etc.)
	-- Lets you use things like:
	--   ciq → change inside *any* quotes (' " `)
	--   cib → change inside brackets/parentheses
	--   cit → change inside HTML/XML tags
	-- Works automatically with which-key and operators (c/d/y)
	"echasnovski/mini.ai",
	version = "*",
	event = "VeryLazy",
	config = function()
		require("mini.ai").setup()
	end,
}
