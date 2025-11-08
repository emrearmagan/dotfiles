local wk = require("which-key")
local gitsigns = require("gitsigns")
local xcodebuild = require("xcodebuild.integrations.dap")
local snacks = require("snacks")
local neotest = require("neotest")
local doodle = require("doodle")
local builtin = require("telescope.builtin")

-------------------- Keybindings ------------------------
wk.add({
	-- ╭────────────────────────────────────────────────────╮
	-- │                     Common                        │
	-- ╰────────────────────────────────────────────────────╯
	{ "J", "mzJ`z", desc = "Join lines (cursor stays)", mode = "n" },
	{ "Y", "y$", desc = "Yank to end of line", mode = "n" },

	-- Disable plain <Space> in normal mode so it doesn't move the cursor when used as <leader>
	-- (prevents accidental motion if <Space> is pressed alone)
	{ " ", "<Nop>", desc = "Leader key noop", mode = "n" },

	{ "<C-d>", "<C-d>zz", desc = "Half-page down & center", mode = "n" },
	{ "<C-u>", "<C-u>zz", desc = "Half-page up & center", mode = "n" },

	{ "n", "nzzzv", desc = "Next search result (centered)", mode = "n" },
	{ "N", "Nzzzv", desc = "Previous search result (centered)", mode = "n" },

	-- Currently overlapping with debugger mappings. But might add them later
	-- { "<leader>d", '"_d', desc = "Delete without yank", mode = "n" },
	-- { "<leader>d", '"_d', desc = "Delete without yank", mode = "v" },

	{ "J", ":m '>+1<CR>gv=gv", desc = "Move selection down", mode = "v" },
	{ "K", ":m '<-2<CR>gv=gv", desc = "Move selection up", mode = "v" },

	{
		"<leader>/",
		function()
			require("snacks.picker").grep_word()
		end,
		desc = "Search word under cursor",
	},

	-- ╭────────────────────────────────────────────────────╮
	-- │                      Tree                          │
	-- ╰────────────────────────────────────────────────────╯
	{ "<leader>n", ":Neotree toggle<CR>", desc = "Toggle Tree" },

	-- ╭────────────────────────────────────────────────────╮
	-- │                  Search (FzfLua)                   │
	-- ╰────────────────────────────────────────────────────╯
	{ "<leader>f", group = "Search" },
	{
		"<leader>ff",
		function()
			snacks.picker.files()
		end,
		desc = "Find files",
	},
	{
		"<leader>fg",
		function()
			snacks.picker.grep()
		end,
		desc = "Live grep",
	},
	{
		"<leader>f/",
		function()
			require("snacks.picker").grep_buffers()
		end,
		desc = "Search word under cursor",
	},
	{
		"<leader>fb",
		function()
			snacks.picker.buffers()
		end,
		desc = "Find buffer",
	},
	{
		"<leader>fm",
		function()
			snacks.picker.marks()
		end,
		desc = "Marks",
	},
	{
		"<leader>fy",
		function()
			snacks.picker.registers()
		end,
		desc = "Registers / Yank history",
	},
	{
		"<leader>fm",
		function()
			snacks.picker.marks()
		end,
		desc = "Marks",
	},

	{
		"<leader>fd",
		function()
			require("fzf-lua").files({
				prompt = "Change Dir❯ ",
				cwd_prompt = true,
				cmd = "find . -type d -not -path '*/\\.git/*'",
				actions = {
					["default"] = function(selected)
						local raw = selected[1]
						local path = raw:gsub("^[^%w./~]+", ""):gsub("%s+$", "")
						path = vim.fn.fnamemodify(path, ":p")
						vim.cmd("cd " .. vim.fn.fnameescape(path))
						print("Changed cwd to " .. path)
						vim.cmd("Neotree reveal")
					end,
				},
			})
		end,
		desc = "Find directory",
	},
	{ "<leader>fo", ":!open %:h<CR>", desc = "Open in Finder" },

	-- ╭────────────────────────────────────────────────────╮
	-- │               Tabs / Splits / Buffers              │
	-- ╰────────────────────────────────────────────────────╯
	{ "<C-n>", "<cmd>BufferLineCycleNext<CR>", desc = "Next Buffer", mode = "n" },
	{ "<C-p>", "<cmd>BufferLineCyclePrev<CR>", desc = "Previous Buffer", mode = "n" },
	{ "<Tab>", "<cmd>BufferLineCycleNext<CR>", desc = "Next Buffer", mode = "n" },
	{ "<S-Tab>", "<cmd>BufferLineCyclePrev<CR>", desc = "Previous Buffer", mode = "n" },
	{ "<C-x>", "<cmd>bdelete<CR>", desc = "Close current buffer", mode = "n" },

	-- ╭────────────────────────────────────────────────────╮
	-- │                 Quick / File Actions               │
	-- ╰────────────────────────────────────────────────────╯
	{ "<leader>q", group = "Quick / File" },
	{ "<leader>qq", ":bd<CR>", desc = "Close buffer", mode = "n" },
	{ "<leader>qa", ":BufferLineCloseOthers<CR>", desc = "Close all except current", mode = "n" },
	{ "<leader>qs", ":w<CR>", desc = "Save file", mode = "n" },
	{ "<leader>qS", ":wa<CR>", desc = "Save all files", mode = "n" },
	{ "<leader>qx", ":x<CR>", desc = "Save & close file", mode = "n" },
	{ "<leader>qQ", ":q!<CR>", desc = "Quit without saving", mode = "n" },
	{ "<leader>qW", ":wq<CR>", desc = "Save and quit", mode = "n" },
	{ "<leader>qA", ":wqa<CR>", desc = "Save all & quit", mode = "n" },
	{
		"<leader>qM",
		function()
			vim.cmd("delmarks!")
			vim.cmd("delm! | delm A-Z0-9")

			vim.notify("All marks deleted", vim.log.levels.INFO)
		end,
		desc = "Delete All Marks",
	},

	-- ╭────────────────────────────────────────────────────╮
	-- │                   LSP / Code Tools                 │
	-- ╰────────────────────────────────────────────────────╯
	{ "<leader>c", group = "Code / LSP" },

	-- Core LSP Actions
	{ "<leader>ca", vim.lsp.buf.code_action, desc = "Code Action", mode = { "n", "v" } },
	{ "<leader>cr", vim.lsp.buf.rename, desc = "Rename Symbol" },
	{
		"<leader>cf",
		function()
			vim.lsp.buf.format({ async = true })
		end,
		desc = "Format File",
		mode = { "n", "v" },
	},

	-- Diagnostics
	{
		"<leader>cd",
		function()
			require("snacks.picker").diagnostics_buffer()
		end,
		desc = "Buffer Diagnostics (Snacks)",
	},
	{
		"<leader>cD",
		function()
			require("snacks.picker").diagnostics()
		end,
		desc = "Workspace Diagnostics (Snacks)",
	},

	{ "<leader>cx", "<cmd>Trouble diagnostics toggle<cr>", desc = "Diagnostics (Trouble)" },
	{ "<leader>cX", "<cmd>Trouble diagnostics toggle filter.buf=0<cr>", desc = "Buffer Diagnostics (Trouble)" },

	-- Symbols / References
	{ "<leader>cs", "<cmd>Trouble symbols toggle focus=false<cr>", desc = "Document Symbols (Trouble)" },
	{ "<leader>cS", "<cmd>Telescope lsp_dynamic_workspace_symbols<CR>", desc = "Workspace Symbols" },
	{
		"<leader>cl",
		"<cmd>Trouble lsp toggle focus=false win.position=right<cr>",
		desc = "LSP Definitions / References (Trouble)",
	},
	-- Navigation
	-- { "gD", "<cmd>FzfLua lsp_declarations<cr>", desc = "Go to Declaration" },
	-- { "gd", "<cmd>FzfLua lsp_definitions<cr>", desc = "Go to Definition" },
	-- { "gi", "<cmd>FzfLua lsp_implementations<cr>", desc = "Go to Implementation" },
	-- { "gr", "<cmd>Telescope lsp_references<cr>", desc = "Find References" },
	{
		"gd",
		function()
			require("snacks.picker").lsp_definitions()
		end,
		desc = "Go to Definition (Snacks)",
	},
	{
		"gD",
		function()
			require("snacks.picker").lsp_declarations()
		end,
		desc = "Go to Declaration (Snacks)",
	},
	{
		"gi",
		function()
			require("snacks.picker").lsp_implementations()
		end,
		desc = "Go to Implementation (Snacks)",
	},
	{
		"gr",
		function()
			snacks.picker.lsp_references()
		end,
		desc = "Find References (Snacks)",
	},
	{
		"gs",
		function()
			require("snacks.picker").lsp_symbols()
		end,
		desc = "Outline (Snacks Symbols)",
		mode = "n",
	},

	-- Hover & Signature
	{ "K", vim.lsp.buf.hover, desc = "Hover Documentation" },
	{ "<C-k>", vim.lsp.buf.signature_help, desc = "Signature Help", mode = "i" },

	-- Diagnostic Movement
	{ "[d", vim.diagnostic.goto_prev, desc = "Previous Diagnostic" },
	{ "]d", vim.diagnostic.goto_next, desc = "Next Diagnostic" },

	-- ╭────────────────────────────────────────────────────╮
	-- │                     Code Tests (neotest)           │
	-- ╰────────────────────────────────────────────────────╯
	{ "<leader>t", icon = "", group = "Tests" },

	{
		"<leader>tt",
		function()
			neotest.run.run()
			vim.schedule(neotest.summary.open)
		end,
		desc = "Run nearest test",
		mode = "n",
	},

	{
		"<leader>tf",
		function()
			neotest.run.run(vim.fn.expand("%"))
			vim.schedule(neotest.summary.open)
		end,
		desc = "Run tests in file",
		mode = "n",
	},

	{
		"<leader>ta",
		function()
			neotest.run.run({ suite = true })
			vim.schedule(neotest.summary.open)
		end,
		desc = "Run all tests",
		mode = "n",
	},

	{
		"<leader>tr",
		function()
			neotest.run.run_last()
			vim.schedule(neotest.summary.open)
		end,
		desc = "Re-run last test",
		mode = "n",
	},

	{
		"<leader>td",
		function()
			neotest.run.run({ strategy = "dap" })
		end,
		desc = "Debug nearest test",
		mode = "n",
	},
	{
		"<leader>ts",
		function()
			neotest.summary.toggle()
		end,
		desc = "Toggle test summary",
		mode = "n",
	},
	{
		"<leader>to",
		function()
			neotest.output.open({ enter = true })
		end,
		desc = "Show test output",
		mode = "n",
	},
	{
		"<leader>tO",
		function()
			neotest.output_panel.toggle()
		end,
		desc = "Toggle output panel",
		mode = "n",
	},

	-- ╭────────────────────────────────────────────────────╮
	-- │                       Xcode                         │
	-- ╰────────────────────────────────────────────────────╯

	{ "<leader>x", group = "Swift / Xcode" },
	{ "<leader>xX", "<cmd>XcodebuildPicker<cr>", desc = "Show Xcodebuild Actions", mode = "n" },
	{ "<leader>xf", "<cmd>XcodebuildProjectManager<cr>", desc = "Show Project Manager Actions", mode = "n" },

	-- Build / Run
	{ "<leader>xb", "<cmd>XcodebuildBuild<cr>", desc = "Build Project", mode = "n" },
	{ "<leader>xB", "<cmd>XcodebuildBuildForTesting<cr>", desc = "Build For Testing", mode = "n" },
	{ "<leader>xr", "<cmd>XcodebuildBuildRun<cr>", desc = "Build & Run Project", mode = "n" },

	-- Logs & Coverage
	{ "<leader>xl", "<cmd>XcodebuildToggleLogs<cr>", desc = "Toggle Xcodebuild Logs", mode = "n" },
	{ "<leader>xc", "<cmd>XcodebuildToggleCodeCoverage<cr>", desc = "Toggle Code Coverage", mode = "n" },
	{ "<leader>xC", "<cmd>XcodebuildShowCodeCoverageReport<cr>", desc = "Show Code Coverage Report", mode = "n" },

	-- Test Explorer & Snapshots & Tests
	{ "<leader>xt", group = "Tests" },
	{ "<leader>xtt", "<cmd>XcodebuildTest<cr>", desc = "Run Tests", mode = "n" },
	{ "<leader>xts", "<cmd>XcodebuildTestSelected<cr>", desc = "Run Selected Tests", mode = "v" },
	{ "<leader>xtT", "<cmd>XcodebuildTestClass<cr>", desc = "Run This Test Class", mode = "n" },

	{ "<leader>xte", "<cmd>XcodebuildTestExplorerToggle<cr>", desc = "Toggle Test Explorer", mode = "n" },
	{ "<leader>xts", "<cmd>XcodebuildFailingSnapshots<cr>", desc = "Show Failing Snapshots", mode = "n" },

	-- Device / Test Plan
	{ "<leader>xD", "<cmd>XcodebuildSelectDevice<cr>", desc = "Select Device", mode = "n" },
	{ "<leader>xP", "<cmd>XcodebuildSelectTestPlan<cr>", desc = "Select Test Plan", mode = "n" },

	-- Quickfix & Actions
	{ "<leader>xx", "<cmd>XcodebuildQuickfixLine<cr>", desc = "Quickfix Line", mode = "n" },
	{ "<leader>xa", "<cmd>XcodebuildCodeActions<cr>", desc = "Show Code Actions", mode = "n" },

	{ "<leader>xd", group = "Debugger" },
	{ "<leader>xdd", xcodebuild.build_and_debug, desc = "Build & Debug", mode = "n" },
	{ "<leader>xdr", xcodebuild.debug_without_build, desc = "Debug Without Building", mode = "n" },
	{ "<leader>xdt", xcodebuild.debug_tests, desc = "Debug Tests", mode = "n" },
	{ "<leader>xdT", xcodebuild.debug_class_tests, desc = "Debug Class Tests", mode = "n" },
	{ "<leader>xdb", xcodebuild.toggle_breakpoint, desc = "Toggle Breakpoint", mode = "n" },
	{ "<leader>xdB", xcodebuild.toggle_message_breakpoint, desc = "Toggle Message Breakpoint", mode = "n" },
	{
		"<leader>xdx",
		function()
			xcodebuild.terminate_session()
			require("dap").listeners.after["event_terminated"]["me"]()
		end,
		desc = "Terminate Debugger",
		mode = "n",
	},

	-- ╭────────────────────────────────────────────────────╮
	-- │                     Debugger                       │
	-- ╰────────────────────────────────────────────────────╯
	-- See nvim.dap.lua
	{ "<leader>d", group = "Debugger" },

	-- ╭────────────────────────────────────────────────────╮
	-- │                       Git                          │
	-- ╰────────────────────────────────────────────────────╯
	{ "<leader>g", group = "Git" },
	{
		"<leader>gG",
		function()
			snacks.gitbrowse()
		end,
		desc = "Git Browse",
		mode = { "n", "v" },
	},
	{
		"<leader>gg",
		function()
			snacks.lazygit()
		end,
		desc = "Git Browse",
		mode = { "n", "v" },
	},
	{
		"<leader>gr",
		function()
			snacks.picker.git_branches()
		end,
		desc = "Git Branches",
	},
	{
		"<leader>gl",
		function()
			snacks.picker.git_log()
		end,
		desc = "Git Log",
	},
	{
		"<leader>gL",
		function()
			snacks.picker.git_log_line()
		end,
		desc = "Git Log Line",
	},
	{
		"<leader>gs",
		function()
			snacks.picker.git_status()
		end,
		desc = "Git Status",
	},
	{
		"<leader>gS",
		function()
			snacks.picker.git_stash()
		end,
		desc = "Git Stash",
	},
	{
		"<leader>gd",
		function()
			snacks.picker.git_diff()
		end,
		desc = "Git Diff (Hunks)",
	},
	{
		"<leader>gf",
		function()
			snacks.picker.git_log_file()
		end,
		desc = "Git Log File",
	},
	{
		"<leader>gt",
		function()
			gitsigns.toggle_current_line_blame()
		end,
		desc = "Toggle Line Blame",
	},
	{
		"<leader>gb",
		function()
			gitsigns.blame_line({ full = true })
		end,
		desc = "Git Blame Line",
	},
	{
		"<leader>gB",
		function()
			vim.cmd("Gitsigns blame")
			vim.cmd("wincmd p")
		end,
		desc = "Git Blame (panel, refocus)",
	},

	-- ╭────────────────────────────────────────────────────╮
	-- │                        AI                          │
	-- ╰────────────────────────────────────────────────────╯
	{ "<leader>a", group = "AI" },

	-- ╭────────────────────────────────────────────────────╮
	-- │                     Snacks / Utils                 │
	-- ╰────────────────────────────────────────────────────╯
	{ "<leader>.", icon = "", group = "Snacks / Utils" },
	{
		"<leader>.q",
		function()
			require("snacks.picker").qflist()
		end,
		desc = "Quickfix List (Snacks)",
		mode = "n",
	},

	{
		"<leader>.d",
		function()
			snacks.dim()
		end,
		desc = "Dim",
	},
	{
		"<leader>.a",
		function()
			snacks.picker.autocmds()
		end,
		desc = "Autocmds",
	},
	{
		"<leader>.C",
		function()
			snacks.picker.command_history()
		end,
		desc = "Command History",
	},
	{
		"<leader>.c",
		function()
			snacks.picker.commands()
		end,
		desc = "Commands",
	},
	{
		"<leader>.h",
		function()
			snacks.picker.help()
		end,
		desc = "Help Pages",
	},

	{
		"<leader>.i",
		function()
			snacks.picker.icons()
		end,
		desc = "Icons",
	},
	{
		"<leader>.M",
		function()
			snacks.picker.man()
		end,
		desc = "Man Pages",
	},

	{
		"<leader>.u",
		function()
			snacks.picker.undo()
		end,
		desc = "Undo History",
	},

	{
		"<leader>.d",
		function()
			doodle:toggle_finder()
		end,
		desc = "Doodle Finder",
	},
	{
		"<leader>.dl",
		function()
			doodle:toggle_links()
		end,
		desc = "Doodle Links",
	},

	{
		"<leader>..",
		function()
			snacks.scratch()
		end,
		desc = "Toggle Scratch Buffer",
	},
	{
		"<leader>.b",
		function()
			snacks.scratch.select()
		end,
		desc = "Select Scratch Buffer",
	},
})
