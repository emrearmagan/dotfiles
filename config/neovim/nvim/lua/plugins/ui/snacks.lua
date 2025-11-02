return {
	"folke/snacks.nvim",
	event = "VimEnter",
	lazy = true,
	priority = 1000,
	opts = {
		bigfile = { enabled = true },
		explorer = { enabled = false },
		indent = { enabled = true },
		input = { enabled = false },
		notifier = {
			enabled = true,
			timeout = 3000,
			style = "compact", -- can also be "compact" or "default"
			border = "rounded", -- or "none"
			winblend = 10, -- transparency
		},
		notify = { enabled = true },
		picker = { enabled = true },
		quickfile = { enabled = true },
		scope = { enabled = true },
		scroll = {
			-- feels a bit laggy with my custom keybindings in options.lua, need to optimize later
			enabled = true,
			animate = {
				duration = { step = 10, total = 250 }, -- step: per-frame delay; total: total ms per scroll
				easing = "outQuad", -- smooth and natural easing
			},
			animate_repeat = {
				delay = 100, -- if you scroll again within 100ms, use faster animation
				duration = { step = 6, total = 120 },
				easing = "outQuad",
			},
			filter = function(buf)
				-- animate only “normal” buffers; skip terminals/pickers/etc.
				local bt = vim.bo[buf].buftype
				return vim.g.snacks_scroll ~= false
					and vim.b[buf].snacks_scroll ~= false
					and bt ~= "terminal"
					and bt ~= "nofile"
					and bt ~= "prompt"
			end,
		},
		statuscolumn = { enabled = true },
		words = { enabled = true },
		dim = {
			enabled = true,
			scope = {
				min_size = 4, -- minimum lines visible above/below the cursor
				max_size = 25, -- maximum lines to keep fully lit
				siblings = true, -- keep sibling blocks dimmed (for context awareness)
			},

			animate = {
				enabled = true,
				easing = "outQuad", -- smooth fade
				duration = {
					step = 16, -- ~60 FPS
					total = 250, -- total ms to fade
				},
			},

			highlight = {
				dim = "NormalNC", -- use NormalNC as dim base
				blend = 0.4, -- 0.0 = no dim, 1.0 = full dark
			},
		},
		styles = {
			notification = {
				-- wo = { wrap = true } -- Wrap notifications
			},
		},
		dashboard = {
			enabled = true,
			width = 60,
			row = nil,
			col = nil,
			pane_gap = 4,
			autokeys = "1234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ",

			preset = {
				pick = function(type, opts)
					require("fzf-lua")[type](opts or {})
				end,
				keys = {
					{ icon = " ", key = "f", desc = "Find File", action = ":lua Snacks.dashboard.pick('files')" },
					{
						icon = " ",
						key = "g",
						desc = "Find Text",
						action = ":lua Snacks.dashboard.pick('live_grep')",
					},
					{ icon = " ", key = "n", desc = "New File", action = ":ene | startinsert" },
					{
						icon = " ",
						key = "r",
						desc = "Recent Files",
						action = ":lua Snacks.dashboard.pick('oldfiles')",
					},
					{
						icon = "󰈙 ",
						key = "d",
						desc = "Doodle Notes",
						action = ":lua require('doodle'):toggle_finder()",
					},
					{
						icon = " ",
						key = "l",
						desc = "LeetCode",
						action = ":Leet", -- or :LeetCode browse
					},
					{
						icon = " ",
						key = "c",
						desc = "Config",
						action = ":lua Snacks.dashboard.pick('files', {cwd = vim.fn.stdpath('config')})",
					},
					{ icon = " ", key = "s", desc = "Restore Session", section = "session" },
					{
						icon = "󰒲 ",
						key = "L",
						desc = "Lazy",
						action = ":Lazy",
						enabled = package.loaded.lazy ~= nil,
					},
					{ icon = " ", key = "q", desc = "Quit", action = ":qa" },
				},
				header = [[
███╗   ██╗███████╗ ██████╗ ██╗   ██╗██╗███╗   ███╗
████╗  ██║██╔════╝██╔═══██╗██║   ██║██║████╗ ████║
██╔██╗ ██║█████╗  ██║   ██║██║   ██║██║██╔████╔██║
██║╚██╗██║██╔══╝  ██║   ██║╚██╗ ██╔╝██║██║╚██╔╝██║
██║ ╚████║███████╗╚██████╔╝ ╚████╔╝ ██║██║ ╚═╝ ██║
╚═╝  ╚═══╝╚══════╝ ╚═════╝   ╚═══╝  ╚═╝╚═╝     ╚═╝]],
			},

			formats = {
				icon = function(item)
					if item.file and (item.icon == "file" or item.icon == "directory") then
						return require("snacks.dashboard").icon(item.file, item.icon)
					end
					return { item.icon, width = 2, hl = "icon" }
				end,
				footer = { "%s", align = "center" },
				header = { "%s", align = "center" },
				file = function(item, ctx)
					local fname = vim.fn.fnamemodify(item.file, ":~")
					fname = ctx.width and #fname > ctx.width and vim.fn.pathshorten(fname) or fname
					if #fname > ctx.width then
						local dir = vim.fn.fnamemodify(fname, ":h")
						local file = vim.fn.fnamemodify(fname, ":t")
						if dir and file then
							file = file:sub(-(ctx.width - #dir - 2))
							fname = dir .. "/…" .. file
						end
					end
					local dir, file = fname:match("^(.*)/(.+)$")
					return dir and { { dir .. "/", hl = "dir" }, { file, hl = "file" } } or { { fname, hl = "file" } }
				end,
			},

			sections = {
				{
					pane = 1,
					{
						section = "header",
					},
					{
						section = "keys",
						gap = 1,
						padding = 1,
					},
				},

				{
					pane = 2,
					{
						icon = " ",
						title = "Recent Files",
						section = "recent_files",
						indent = 2,
						padding = 1,
					},
					{
						icon = " ",
						title = "Projects",
						section = "projects",
						indent = 2,
						padding = 1,
					},

					{
						icon = " ",
						desc = "Browse Repo",
						key = "b",
						action = function()
							Snacks.gitbrowse()
						end,
					},
					{
						title = "Open Issues",
						cmd = "gh issue list -L 3",
						key = "i",
						action = function()
							vim.fn.jobstart("gh issue list --web", { detach = true })
						end,
						icon = " ",
						height = 7,
					},
					{
						icon = " ",
						title = "Open PRs",
						cmd = "gh pr list -L 3",
						key = "P",
						action = function()
							vim.fn.jobstart("gh pr list --web", { detach = true })
						end,
						height = 7,
					},
					{
						icon = " ",
						title = "Git Status",
						section = "terminal",
						enabled = function()
							return require("snacks.git").get_root() ~= nil
						end,
						cmd = "git status --short --branch --renames",
						height = 5,
						padding = 1,
						ttl = 5 * 60,
						indent = 3,
					},
				},
				{
					section = "startup",
				},
			},
		},
	},
}
