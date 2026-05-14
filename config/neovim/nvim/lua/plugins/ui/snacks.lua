local function set_dashboard_highlights()
	for _, group in ipairs({
		"SnacksDashboardDesc",
		"SnacksDashboardIcon",
		"SnacksDashboardSpecial",
	}) do
		vim.api.nvim_set_hl(0, group, { link = "Normal" })
	end

	local comment = vim.api.nvim_get_hl(0, { name = "Comment", link = false })
	local muted = {
		fg = comment.fg,
		italic = false,
		bold = false,
	}
	vim.api.nvim_set_hl(0, "SnacksDashboardHeader", muted)
	vim.api.nvim_set_hl(0, "SnacksDashboardFooter", muted)
	vim.api.nvim_set_hl(0, "SnacksDashboardKey", muted)
end

return {
	"folke/snacks.nvim",
	event = "VimEnter",
	lazy = false,
	priority = 1000,
	config = function(_, opts)
		require("snacks").setup(opts)
		set_dashboard_highlights()

		vim.api.nvim_create_autocmd("ColorScheme", {
			group = vim.api.nvim_create_augroup("user_snacks_dashboard_highlights", { clear = true }),
			callback = set_dashboard_highlights,
		})
	end,
	opts = {
		bigfile = {
			-- consider: https://github.com/fredrikaverpil/dotfiles/blob/main/nvim-fredrik/plugin/bigfile.lua
			enabled = true,
			notify = true,
			size = 1024 * 1024,
			line_length = 500,
			setup = function(ctx)
				if vim.fn.exists(":NoMatchParen") ~= 0 then
					vim.cmd("NoMatchParen")
				end

				vim.b[ctx.buf].completion = false
				vim.b[ctx.buf].minianimate_disable = true
				vim.b[ctx.buf].minihipatterns_disable = true
				vim.bo[ctx.buf].swapfile = false
				vim.bo[ctx.buf].undofile = false

				Snacks.util.wo(0, {
					foldmethod = "manual",
					statuscolumn = "",
					conceallevel = 0,
				})

				if vim.tbl_contains({ "json", "yaml", "xml" }, ctx.ft) then
					vim.schedule(function()
						if vim.api.nvim_buf_is_valid(ctx.buf) then
							vim.bo[ctx.buf].syntax = ctx.ft
						end
					end)
				else
					pcall(vim.treesitter.stop, ctx.buf)
					vim.cmd("syntax clear")
				end
			end,
		},
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
		notify = { enabled = false },
		picker = {
			matcher = { smartcase = false },
			sources = {
				git_status = {
					preview = function(ctx)
						Snacks.picker.preview.cmd({
							"git",
							"--no-pager",
							"diff",
							"--no-ext-diff",
							"HEAD",
							"--",
							ctx.item.file,
						}, ctx, { ft = "diff" })
					end,
				},
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
					preview = "file",
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
			filekey = {
				cwd = true,
				branch = false,
				count = false,
			},
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
			row = nil,
			col = nil,
			pane_gap = 4,
			autokeys = "1234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ",

			preset = {
				pick = function(type, opts)
					require("snacks").picker[type](opts or {})
				end,
				keys = {
					{ icon = " ", key = "f", desc = "Find File", action = ":lua Snacks.dashboard.pick('files')" },
					{
						icon = " ",
						key = "g",
						desc = "Find Text",
						action = ":lua Snacks.dashboard.pick('grep')",
					},
					{
						icon = " ",
						key = "r",
						desc = "Recent Files",
						action = ":lua Snacks.dashboard.pick('oldfiles')",
					},
					{
						icon = " ",
						key = "R",
						desc = "Recent Projects",
						action = ":lua Snacks.dashboard.pick('projects')",
					},
					{
						icon = " ",
						key = "w",
						desc = "Workflow",
						action = ":Workflow",
					},
					{
						icon = " ",
						key = "s",
						desc = "Git Status",
						action = ":lua Snacks.picker.git_status()",
					},
					{
						icon = " ",
						key = "n",
						desc = "Notes",
						action = ":lua Snacks.picker.files({ cwd = vim.g.obsidian_vault, cmd = 'rg', args = { '--files', '-g', '*.md' } })",
					},
					{ icon = " ", key = "S", desc = "Restore Session", section = "session" },
					{ icon = " ", key = "q", desc = "Quit", action = ":qa" },
				},
				header = [[
 .          .
 ';;,.        ::'
 ,:::;,,        :ccc,
,::c::,,,,.     :cccc,
,cccc:;;;;;.    cllll,
,cccc;.;;;;;,   cllll;
:cccc; .;;;;;;. coooo;
;llll;   ,:::::'loooo;
;llll:    ':::::loooo:
:oooo:     .::::llodd:
.;ooo:       ;cclooo:.
.;oc        'coo;.
 .'         .,.]],
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
				{ section = "header" },
				{
					section = "keys",
					gap = 1,
					padding = 1,
				},
				{ section = "startup" },
			},
		},
	},
}
