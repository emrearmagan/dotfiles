return {
	"folke/snacks.nvim",
	event = "VimEnter",
	lazy = false,
	priority = 1000,
	opts = {
		bigfile = { enabled = true },
		explorer = { enabled = false },
		zen = {
			toggles = {
				dim = true,
				git_signs = false,
				mini_diff_signs = false,
			},

			center = true,

			show = {
				statusline = true,
				tabline = false,
			},

			win = {
				style = "zen",
				width = 0.9,
				height = 0,
			},
		},
		image = {
			enabled = true,
			resolve = function(path, src)
				local api = require("obsidian.api")
				if api.path_is_note(path) then
					return api.resolve_attachment_path(src)
				end
			end,
		},
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
		picker = {
			sources = {
				files = {
					cmd = "rg",
					hidden = true,
					no_ignore = false,
					preview = "file", -- show file contents
				},
				grep = {
					cmd = "rg --vimgrep",
					hidden = true,
					no_ignore = false,
					live = true,
					preview = "file", -- open matching line
				},
				git_files = {
					cmd = "git ls-files --exclude-standard --cached --others",
					preview = "diff", -- show git diff using delta if available
				},
			},

			formatters = {
				file = {
					filename_first = true, -- display filename before the file path
				},
			},
		},
		quickfile = { enabled = true },
		scope = { enabled = true },
		scroll = {
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
		terminal = {
			enabled = true,
			win = {
				position = "float",
				backdrop = 60,
				height = 0.9,
				width = 0.9,
				border = "rounded",
				title_pos = "center",
				footer_pos = "center",
			},
		},
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
		scratch = {
			win = {
				keys = {
					delete = {
						"D",
						function(self)
							local file = vim.api.nvim_buf_get_name(self.buf)

							vim.ui.select({ "Yes", "No" }, {
								prompt = "Delete scratch?",
							}, function(choice)
								if choice == "Yes" then
									-- First close the scratch buffer and then delete to avoid recration (because of autowrite = file)
									self:close()

									if file ~= "" then
										vim.fn.delete(file)
									end

									vim.schedule(function()
										require("snacks").scratch.select()
									end)
								end
							end)
						end,
						desc = "Delete Scratch",
						mode = "n",
					},
				},
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
					require("snacks").picker[type](opts or {})
				end,
				keys = {
					{ icon = " ", key = "f", desc = "Find File", action = ":lua Snacks.dashboard.pick('files')" },
					{
						icon = " ",
						key = "g",
						desc = "Find Text",
						action = ":lua Snacks.dashboard.pick('grep')",
					},
					{
						icon = " ",
						key = "d",
						desc = "Database",
						action = ":DBUIFull",
					},
					{
						icon = " ",
						key = "n",
						desc = "Notes",
						action = function()
							require("snacks").picker.files({
								cwd = vim.g.obsidian_vault,
								cmd = "rg",
								args = { "--files", "-g", "*.md" },
							})
						end,
					},
					{
						icon = " ",
						key = "t",
						desc = "Todo",
						action = function()
							-- see: https://github.com/taskbook-sh/taskbook
							-- install with: curl --proto '=https' --tlsv1.2 -sSf https://taskbook.sh/install| sh
							if vim.fn.executable("tb") ~= 1 then
								vim.notify("taskbook (tb) is not installed or not in PATH", vim.log.levels.ERROR)
								return
							end

							vim.cmd("tabnew")
							local buf = vim.api.nvim_get_current_buf()
							vim.bo[buf].buflisted = false
							vim.bo[buf].bufhidden = "wipe"
							vim.fn.termopen("tb", {
								on_exit = function()
									vim.schedule(function()
										for _, win in ipairs(vim.fn.win_findbuf(buf)) do
											pcall(vim.api.nvim_win_close, win, true)
										end
										if vim.api.nvim_buf_is_valid(buf) then
											pcall(vim.api.nvim_buf_delete, buf, { force = true })
										end
									end)
								end,
							})
							vim.cmd("startinsert")
						end,
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
						gap = 1, -- adds space below
					},

					-- ─────────────────────────────
					--  Dev
					-- ─────────────────────────────

					function()
						return {
							{
								icon = "󰌃",
								key = "J",
								desc = "JIRA",
								action = ":AtlasJira",
							},

							{
								icon = " ",
								key = "B",
								desc = "Bitbucket",
								action = ":AtlasBitbucket",
							},

							{
								icon = " ",
								key = "G",
								desc = "Github",
								action = ":AtlasGithub",
							},

							{
								icon = "",
								key = "D",
								desc = "Docker",
								action = ":Dockyard",
							},

							{
								gap = 1, -- adds space below
							},
						}
					end,

					-- ─────────────────────────────
					--  GIT SECTION
					-- ─────────────────────────────

					function()
						local in_git = Snacks.git.get_root() ~= nil

						return {
							{
								section = "terminal",
								padding = 1,
								indent = 2,
								ttl = 0,
								icon = " ",
								title = "Git Status",
								cmd = "git --no-pager diff --stat=40 -B -M -C",
								key = "S",
								action = function()
									require("snacks").picker.git_status()
								end,
								height = 5,
								enabled = in_git,
							},
						}
					end,
				},

				{ section = "startup" },
			},
		},
	},
}
