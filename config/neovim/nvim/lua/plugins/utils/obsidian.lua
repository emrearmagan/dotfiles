local M = {}
M.vault_path = vim.fn.expand("~/Library/Mobile Documents/iCloud~md~obsidian/Documents")
M.personal = M.vault_path .. "/emrearmagan"
M.tmp = M.vault_path .. "/tmp"

vim.g.obsidian_vault = M.vault_path

return {
	"obsidian-nvim/obsidian.nvim",
	version = "*",
	ft = "markdown",
	cmd = { "Obsidian" },
	enabled = function()
		-- only enable on macOS for now, and if vault_path exists
		return vim.fn.has("mac") == 1 and vim.fn.isdirectory(M.vault_path) == 1
	end,
	dependencies = {
		"folke/snacks.nvim",
	},
	opts = {
		legacy_commands = false,
		workspaces = {
			{ name = "personal", path = M.personal },
			{ name = "tmp", path = M.tmp },
		},
		note_id_func = function(title)
			return require("obsidian.builtin").title_id(title)
		end,
		daily_notes = {
			enabled = true,
			folder = "daily",
			date_format = "YYYY-MM-DD",
		},
		attachments = {
			folder = "./assets/", -- same folder as current file
		},
		templates = {
			folder = "templates",
		},

		completion = {
			nvim_cmp = true,
			blink = false,
			-- Trigger completion at 2 chars.
			min_chars = 2,
		},

		footer = {
			enabled = true,
			format = "󰈙 {{backlinks}} backlinks  󰏗 {{properties}} properties  󰎛 {{words}} words  󰉉 {{chars}} chars",
			hl_group = "Comment",
			separator = string.rep("─", 80),
		},
		frontmatter = {
			enabled = true,
			sort = false,
			func = function(note)
				local frontmatter = note.frontmatter(note)

				frontmatter.id = note.id

				if frontmatter.created == nil then
					frontmatter.created = os.date("%Y-%m-%d")
				end

				if frontmatter.tags == nil then
					frontmatter.tags = {}
				end

				return frontmatter
			end,
		},

		ui = {
			-- INFO: Might conflict with render-markdown.nvim disable if any issues arise
			enable = true, -- disables the obsidian renderer
			ignore_conceal_warn = true,
		},
	},
}
