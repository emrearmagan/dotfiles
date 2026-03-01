return {
	{
		"nvim-treesitter/nvim-treesitter",
		lazy = false,
		build = ":TSUpdate",
		config = function()
			local ts = require("nvim-treesitter")

			-- make sure to install the cli tool for installing parsers - brew install tree-sitter-cli
			local parsers = {
				"go",
				"swift",
				"bash",
				"yaml",
				"json",
				"lua",
				"php",
				"http",

				"comment",
				"css",
				"dockerfile",
				"git_config",
				"gitcommit",
				"gitignore",
				"html",
				"javascript",
				"json5",
				"make",
				"markdown",
				"markdown_inline",
				"python",
				"regex",
				"ssh_config",
				"sql",
				"toml",
				"typescript",
				"vim",
			}

			-- Install your parsers
			for _, parser in ipairs(parsers) do
				ts.install(parser)
			end

			-- Not every tree-sitter parser is the same as the file type detected
			-- So the patterns need to be registered more cleverly
			local patterns = {}
			for _, parser in ipairs(parsers) do
				local parser_patterns = vim.treesitter.language.get_filetypes(parser)
				for _, pp in pairs(parser_patterns) do
					table.insert(patterns, pp)
				end
			end

			vim.api.nvim_create_autocmd("FileType", {
				pattern = patterns,
				callback = function(ev)
					local buf = ev.buf

					-- Skip special buffers (dashboard, telescope, snacks, etc.)
					if vim.bo[buf].buftype ~= "" then
						return
					end

					local ft = ev.match
					local lang = vim.treesitter.language.get_lang(ft) or ft

					local ok = pcall(vim.treesitter.start, buf, lang)
					if not ok then
						return
					end

					vim.wo.foldmethod = "expr"
					vim.wo.foldexpr = "v:lua.vim.treesitter.foldexpr()"
					vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
				end,
			})
		end,
	},

	{
		"nvim-treesitter/nvim-treesitter-textobjects",
		branch = "main",
		dependencies = { "nvim-treesitter/nvim-treesitter", branch = "main" },
		config = function()
			require("nvim-treesitter-textobjects").setup({
				select = {
					lookahead = true,
				},
				move = {
					set_jumps = true,
				},
			})

			-- Select
			local select = require("nvim-treesitter-textobjects.select")
			vim.keymap.set({ "x", "o" }, "af", function()
				select.select_textobject("@function.outer", "textobjects")
			end)
			vim.keymap.set({ "x", "o" }, "if", function()
				select.select_textobject("@function.inner", "textobjects")
			end)
			vim.keymap.set({ "x", "o" }, "ac", function()
				select.select_textobject("@class.outer", "textobjects")
			end)
			vim.keymap.set({ "x", "o" }, "ic", function()
				select.select_textobject("@class.inner", "textobjects")
			end)

			-- Move
			local move = require("nvim-treesitter-textobjects.move")
			vim.keymap.set({ "n", "x", "o" }, "]]", function()
				move.goto_next_start("@function.outer", "textobjects")
			end)
			vim.keymap.set({ "n", "x", "o" }, "][", function()
				move.goto_next_end("@function.outer", "textobjects")
			end)
			vim.keymap.set({ "n", "x", "o" }, "[[", function()
				move.goto_previous_start("@function.outer", "textobjects")
			end)
			vim.keymap.set({ "n", "x", "o" }, "[]", function()
				move.goto_previous_end("@function.outer", "textobjects")
			end)
		end,
	},
}
