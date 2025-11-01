local wk = require("which-key")
local gitsigns = require("gitsigns")
local xcodebuild = require("xcodebuild.integrations.dap")
local snacks = require("snacks")

-------------------- Keybindings ------------------------
wk.add({
	-- ╭────────────────────────────────────────────────────╮
	-- │                      Tree                          │
	-- ╰────────────────────────────────────────────────────╯
	{ "<leader>n", ":Neotree toggle<CR>", desc = "Toggle Tree" },

	-- ╭────────────────────────────────────────────────────╮
	-- │                  Search (FzfLua)                   │
	-- ╰────────────────────────────────────────────────────╯
	{ "<leader>f", group = "Search" },
	{ "<leader>ff", "<cmd>FzfLua files<CR>", desc = "Find files" },
	{ "<leader>fg", "<cmd>FzfLua live_grep<CR>", desc = "Live grep" },
	{ "<leader>fb", "<cmd>FzfLua buffers<CR>", desc = "Find buffer" },
	{ "<leader>ft", "<cmd>FzfLua help_tags<CR>", desc = "Find help tags" },
	{ "<leader>fy", "<cmd>Telescope neoclip<CR>", desc = "Find from yank history (Telescope)" },
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

	-- ╭────────────────────────────────────────────────────╮
	-- │                      Coding                        │
	-- ╰────────────────────────────────────────────────────╯
	{ "<leader>c", group = "Code" },
	{ "<leader>cK", vim.lsp.buf.hover, desc = "Hover Info (LSP)", mode = "n" },
	{ "<leader>ca", vim.lsp.buf.code_action, desc = "Code actions", mode = "n" },
	{
		"<leader>cx",
		function()
			vim.lsp.buf.code_action({ apply = true })
		end,
		desc = "Quickfix (auto-apply)",
		mode = "n",
	},
	{ "<leader>cD", vim.lsp.buf.declaration, desc = "Go to Declaration (LSP)", mode = "n" },
	{ "<leader>ci", vim.lsp.buf.implementation, desc = "Go to Implementation (LSP)", mode = "n" },
	{ "<leader>cd", vim.lsp.buf.definition, desc = "Go to Definition (LSP)", mode = "n" },
	{ "<leader>cI", require("telescope.builtin").lsp_implementations, desc = "Go to Implementation", mode = "n" },
	{ "<leader>cr", vim.lsp.buf.references, desc = "List References (LSP)", mode = "n" },
	{ "<leader>cn", vim.lsp.buf.rename, desc = "Rename Symbol (LSP)", mode = "n" },
	{ "<leader>cs", vim.lsp.buf.signature_help, desc = "Signature Help (LSP)", mode = "n" },
	{ "<leader>cf", vim.lsp.buf.format, desc = "Format File (LSP)", mode = "n" },
	{ "<leader>cp", vim.diagnostic.goto_prev, desc = "Prev diagnostic", mode = "n" },
	{ "<leader>cn", vim.diagnostic.goto_next, desc = "Next diagnostic", mode = "n" },
	{
		"<leader>cs",
		function()
			snacks.picker.lsp_symbols()
		end,
		desc = "LSP Symbols",
	},
	{
		"<leader>cS",
		function()
			snacks.picker.lsp_workspace_symbols()
		end,
		desc = "LSP Workspace Symbols",
	},

	{
		"<leader>cm",
		"<cmd>Trouble symbols toggle focus=false<cr>",
		desc = "Minimap",
	},
	{
		"<leader>cl",
		"<cmd>Trouble lsp toggle focus=false win.position=right<cr>",
		desc = "LSP Definitions / references / ... (Trouble)",
	},
	{
		"<leader>cx",
		function()
			snacks.picker.diagnostics()
		end,
		desc = "Diagnostics",
	},
	{
		"<leader>cX",
		function()
			snacks.picker.diagnostics_buffer()
		end,
		desc = "Buffer Diagnostics",
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
	{ "<leader>xq", "<cmd>Telescope quickfix<cr>", desc = "Show QuickFix List", mode = "n" },
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
	{ "<leader>gl", "<cmd>LazyGit<cr>", desc = "Open LazyGit" },
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
	-- │                     AI Tools                       │
	-- ╰────────────────────────────────────────────────────╯
	{ "<leader>a", group = "AI" },

	-- ╭────────────────────────────────────────────────────╮
	-- │                     snacks                         │
	-- ╰────────────────────────────────────────────────────╯
	{ "<leader>s", group = "Snacks" },
	{
		"<leader>sd",
		function()
			snacks.dim()
		end,
		desc = "Dim",
	},
	{
		"<leader>sa",
		function()
			snacks.picker.autocmds()
		end,
		desc = "Autocmds",
	},
	{
		"<leader>sc",
		function()
			snacks.picker.command_history()
		end,
		desc = "Command History",
	},
	{
		"<leader>sC",
		function()
			snacks.picker.commands()
		end,
		desc = "Commands",
	},
	{
		"<leader>sh",
		function()
			snacks.picker.help()
		end,
		desc = "Help Pages",
	},

	{
		"<leader>si",
		function()
			snacks.picker.icons()
		end,
		desc = "Icons",
	},

	{
		"<leader>sM",
		function()
			snacks.picker.man()
		end,
		desc = "Man Pages",
	},

	{
		"<leader>su",
		function()
			snacks.picker.undo()
		end,
		desc = "Undo History",
	},
	{
		"<leader>sG",
		function()
			snacks.gitbrowse()
		end,
		desc = "Git Browse",
		mode = { "n", "v" },
	},
	{
		"<leader>sg",
		function()
			snacks.lazygit()
		end,
		desc = "Git Browse",
		mode = { "n", "v" },
	},
	{
		"<leader>sm",
		function()
			snacks.picker.marks()
		end,
		desc = "Marks",
	},

	{
		"<leader>..",
		function()
			snacks.scratch()
		end,
		desc = "Toggle Scratch Buffer",
	},
	{
		"<leader>.s",
		function()
			snacks.scratch.select()
		end,
		desc = "Select Scratch Buffer",
	},

	{
		"<leader>Xd",
		function()
			snacks.picker.lsp_definitions()
		end,
		desc = "Goto Definition",
	},
	{
		"<leader>XD",
		function()
			snacks.picker.lsp_declarations()
		end,
		desc = "Goto Declaration",
	},
	{
		"<leader>Xr",
		function()
			snacks.picker.lsp_references()
		end,
		nowait = true,
		desc = "References",
	},
	{
		"<leader>XI",
		function()
			snacks.picker.lsp_implementations()
		end,
		desc = "Goto Implementation",
	},
	{
		"<leader>Xy",
		function()
			snacks.picker.lsp_type_definitions()
		end,
		desc = "Goto T[y]pe Definition",
	},
})
