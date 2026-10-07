return {
	{
		"zbirenbaum/copilot.lua",

		-- Load only when it’s actually needed ─ either when you start typing or
		-- if you manually run :Copilot / :Copilot auth.
		cmd = "Copilot",
		event = "InsertEnter",

		-- Optional: if you want to force an auth prompt after first install
		-- build = ":Copilot auth",

		opts = {
			-- ╭──────────────── Panel ─────────────────╮
			panel = {
				enabled = true,
				auto_refresh = true,
				layout = { position = "right", ratio = 0.35 },
			},

			-- ╭────────────── Suggestions ─────────────╮
			suggestion = {
				enabled = true,
				auto_trigger = true, -- show as you type
				debounce = 75,
				keymap = {
					accept = "<C-y>", -- accept entire suggestion
					-- next = "<C-]>", -- cycle forward
					-- prev = "<C-[>", -- cycle backward
					dismiss = "<C-/>", -- clear ghost text
				},
			},

			-- ╭────────────── File-type filter ─────────╮
			filetypes = {
				markdown = true, -- enable in MD notes
				yaml = false, -- disable in YAML by choice
				["*"] = true, -- everything else on
			},
		},
	},
}
