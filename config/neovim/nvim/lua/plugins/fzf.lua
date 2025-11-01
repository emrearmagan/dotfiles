return {
	"ibhagwan/fzf-lua",
	dependencies = { "nvim-tree/nvim-web-devicons" }, -- optional, for file icons
	config = function()
		require("fzf-lua").setup({
			winopts = {
				height = 0.85, -- Window height (percentage)
				width = 0.80, -- Window width (percentage)
				preview = {
					vertical = "down:45%", -- Split preview vertically
					horizontal = "right:60%",
				},
			},
			files = {
				prompt = "Files❯ ",
				-- Use ripgrep to list project files while:
				-- - including hidden files (like .env)
				-- - excluding common clutter (e.g. .git, node_modules, .DS_Store)
				cmd = "rg --files --no-ignore --hidden --follow --glob '!.git/*' --glob '!node_modules/*' --glob '!.DS_Store' --glob '!vendor/**' --glob '!tmp/**'",
				previewer = "bat", -- Use `bat` as a previewer
				git_icons = true,
				follow = true,
			},
			git = {
				prompt = "GitFiles❯ ",
				cmd = "git ls-files --exclude-standard --cached --others",
				previewer = "git diff", -- Git diff preview
			},
			grep = {
				prompt = "Grep❯ ",
				input_prompt = "Grep For❯ ",
				previwer = "bat",
				rg_glob = true, -- Enable glob parsing
				glob_flag = "--iglob", -- Use case-insensitive globs
				glob_separator = "%s%-%-", -- Separator pattern
				cmd = "rg --vimgrep --hidden --glob '!.git/**' --glob '!node_modules/**' --glob '!vendor/**' --glob '!tmp/**'", -- Exclude dirs
				silent = true,
			},
		})
	end,
}
