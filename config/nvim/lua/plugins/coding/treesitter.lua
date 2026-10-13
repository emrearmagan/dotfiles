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
				"diff",
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

			vim.api.nvim_create_autocmd("FileType", {
				pattern = "*",
				callback = function(ev)
					local buf = ev.buf

					-- Skip special buffers (dashboard, snacks, etc.)
					if vim.bo[buf].buftype ~= "" then
						return
					end

					local ft = ev.match
					local lang = vim.treesitter.language.get_lang(ft) or ft
					local parser = require("nvim-treesitter.parsers")[lang]
					if not parser or parser.tier == 4 then
						return
					end

					-- Installation is asynchronous and a no-op for installed parsers.
					ts.install(lang):await(vim.schedule_wrap(function(err, installed)
						if err then
							vim.notify(tostring(err), vim.log.levels.ERROR)
							return
						end
						if
							not installed
							or not vim.api.nvim_buf_is_loaded(buf)
							or vim.bo[buf].buftype ~= ""
							or vim.bo[buf].filetype ~= ft
						then
							return
						end

						if not pcall(vim.treesitter.start, buf, lang) then
							return
						end
						vim.bo[buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
						for _, win in ipairs(vim.fn.win_findbuf(buf)) do
							vim.wo[win].foldmethod = "expr"
							vim.wo[win].foldexpr = "v:lua.vim.treesitter.foldexpr()"
						end
					end))
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
