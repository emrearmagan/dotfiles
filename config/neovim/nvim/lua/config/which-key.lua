local wk = require("which-key")
local snacks = require("snacks")
local helper = require("config.helper")

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

	-- Disable command-line window (q:) as its annoying
	{
		"q:",
		"<nop>",
		desc = "Disable command-line window",
		mode = "n",
		hidden = true, -- hides it from which-key popup
	},

	{ "<C-d>", "<C-d>zz", desc = "Half-page down & center", mode = "n" },
	{ "<C-u>", "<C-u>zz", desc = "Half-page up & center", mode = "n" },

	{ "n", "nzzzv", desc = "Next search result (centered)", mode = "n" },
	{ "N", "Nzzzv", desc = "Previous search result (centered)", mode = "n" },

	-- Currently overlapping with debugger mappings. But might add them later
	-- { "<leader>d", '"_d', desc = "Delete without yank", mode = "n" },
	-- { "<leader>d", '"_d', desc = "Delete without yank", mode = "v" },

	{ "J", ":m '>+1<CR>gv=gv", desc = "Move selection down", mode = "v" },
	{ "K", ":m '<-2<CR>gv=gv", desc = "Move selection up", mode = "v" },

	-- Override Neovim's default LSP keymaps with Snacks equivalents
	{
		"gra",
		function()
			vim.lsp.buf.code_action()
		end,
		desc = "Code Actions",
		mode = { "n", "v" },
	},
	{
		"gri",
		function()
			require("snacks.picker").lsp_implementations()
		end,
		desc = "Go to Implementation (Snacks)",
	},
	{
		"grn",
		function()
			vim.lsp.buf.rename()
		end,
		desc = "Rename Symbol",
	},
	{
		"grr",
		function()
			require("snacks.picker").lsp_references()
		end,
		desc = "Find References (Snacks)",
	},
	{
		"grt",
		function()
			require("snacks.picker").lsp_type_definitions()
		end,
		desc = "Go to Type Definition (Snacks)",
	},

	{
		"gs",
		function()
			require("snacks.picker").lsp_symbols()
		end,
		desc = "Outline (Snacks Symbols)",
	},
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
		"gy",
		function()
			require("snacks.picker").lsp_type_definitions()
		end,
		desc = "Go to Type Definition (Snacks)",
	},

	-- Hover & Signature
	{ "K", vim.lsp.buf.hover, desc = "Hover Documentation" },
	{ "<C-k>", vim.lsp.buf.signature_help, desc = "Signature Help", mode = { "i", "n" } },

	-- Diagnostic Movement
	{ "[d", vim.diagnostic.goto_prev, desc = "Previous Diagnostic" },
	{ "]d", vim.diagnostic.goto_next, desc = "Next Diagnostic" },

	-- Words Navigation (Snacks)
	{
		"[w",
		function()
			require("snacks.words").jump(-1)
		end,
		desc = "Previous Reference",
	},
	{
		"]w",
		function()
			require("snacks.words").jump(1)
		end,
		desc = "Next Reference",
	},

	-- Quickfix Navigation
	{ "[q", ":cprev<CR>", desc = "Previous quickfix" },
	{ "]q", ":cnext<CR>", desc = "Next quickfix" },

	-- ╭────────────────────────────────────────────────────╮
	-- │                      Tree                          │
	-- ╰────────────────────────────────────────────────────╯
	{
		"<leader> ",
		function()
			local mini_files = require("mini.files")
			local is_open = false

			for _, win_id in ipairs(vim.api.nvim_list_wins()) do
				local buf_id = vim.api.nvim_win_get_buf(win_id)
				if vim.bo[buf_id].filetype == "minifiles" then
					is_open = true
					break
				end
			end

			if is_open then
				mini_files.close()
				return
			end

			--- Open the current file's directory if a file is open, otherwise open the current working directory
			local cwd = vim.fs.normalize(vim.uv.cwd())
			local file = vim.api.nvim_buf_get_name(0)
			local dir = file ~= "" and vim.fn.fnamemodify(file, ":p:h") or cwd
			mini_files.open(vim.fs.normalize(dir), false)
		end,
		desc = "Toggle Files",
	},
	{ "<leader>.", "<cmd>Neotree toggle reveal<CR>", desc = "Toggle Neotree" },

	-- ╭────────────────────────────────────────────────────╮
	-- │                  Search (FzfLua)                   │
	-- ╰────────────────────────────────────────────────────╯
	{ "<leader>f", group = "Search" },
	{
		"<leader>ff",
		function()
			snacks.picker.files({ hidden = true, no_ignore = false })
		end,
		desc = "Find files",
	},
	{
		"<leader>fg",
		function()
			snacks.picker.grep({ hidden = true, no_ignore = false })
		end,
		desc = "Lazygit",
	},
	{
		"<leader>f/",
		function()
			require("snacks.picker").grep_word()
		end,
		desc = "Search word under cursor",
	},
	{
		"<leader>fm",
		function()
			snacks.picker.marks()
		end,
		desc = "Marks",
	},
	{
		"<leader>fh",
		function()
			snacks.picker.help()
		end,
		desc = "Search help",
	},

	{
		"<leader>ft",
		function()
			vim.cmd("TodoTelescope")
		end,
		desc = "Find todos",
	},

	{
		"<leader>fq",
		function()
			require("snacks.picker").qflist()
		end,
		desc = "Quickfix List (Snacks)",
	},

	{ "<leader>fo", ":!open %:h<CR>", desc = "Open in Finder" },
	{ "<leader>fs", "<cmd>Telescope lsp_document_symbols<cr>", desc = "Document Symbols" },
	{ "<leader>fS", "<cmd>Telescope lsp_dynamic_workspace_symbols<CR>", desc = "Workspace Symbols" },

	-- ╭────────────────────────────────────────────────────╮
	-- │               Tabs / Splits / Buffers              │
	-- ╰────────────────────────────────────────────────────╯
	{ "<C-n>", "<cmd>BufferLineCycleNext<CR>", desc = "Next Buffer", mode = "n" },
	{ "<C-p>", "<cmd>BufferLineCyclePrev<CR>", desc = "Previous Buffer", mode = "n" },
	{ "<Tab>", "<cmd>BufferLineCycleNext<CR>", desc = "Next Buffer", mode = "n" },
	{ "<S-Tab>", "<cmd>BufferLineCyclePrev<CR>", desc = "Previous Buffer", mode = "n" },
	{
		"<C-x>",
		function()
			local bufnr = vim.api.nvim_get_current_buf()
			local listed = vim.fn.getbufinfo({ buflisted = 1 })
			if #listed > 1 then
				vim.cmd("bnext | bdelete " .. bufnr)
			else
				vim.cmd("enew | bdelete " .. bufnr)
			end
		end,
		desc = "Close current buffer",
	},
	-- { "<C-x>", "<cmd>bdelete<CR>", desc = "Close current buffer", mode = "n" },

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
			-- Delete all marks in current buffer
			vim.cmd("delmarks!")
			-- Delete all global marks (A-Z) and numbered marks (0-9)
			vim.cmd("delm A-Z0-9")
			-- Also clear jumplist to remove ` marks
			vim.cmd("clearjumps")

			vim.notify("All marks and jumps deleted", vim.log.levels.INFO)
		end,
		desc = "Delete All Marks",
	},

	-- ╭────────────────────────────────────────────────────╮
	-- │                   LSP / Code Tools                 │
	-- ╰────────────────────────────────────────────────────╯
	{ "<leader>c", group = "Code / LSP" },

	-- Core LSP Actions
	-- { "<leader>ca", vim.lsp.buf.code_action, desc = "Code Action", mode = { "n", "v" } },
	{
		"<leader>ca",
		function()
			require("actions-preview").code_actions()
		end,
		desc = "Code Action",
		mode = { "n", "v" },
	},
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
		"<leader>cD",
		function()
			require("snacks.picker").diagnostics_buffer()
		end,
		desc = "Buffer Diagnostics (Snacks)",
	},
	{
		"<leader>cd",
		function()
			require("snacks.picker").diagnostics()
		end,
		desc = "Workspace Diagnostics (Snacks)",
	},

	{ "<leader>cx", "<cmd>Trouble diagnostics toggle focus=false win.id=dock<cr>", desc = "Diagnostics (Trouble)" },
	{
		"<leader>cX",
		"<cmd>Trouble diagnostics toggle focus=false filter.buf=0 win.id=dock<cr>",
		desc = "Buffer Diagnostics (Trouble)",
	},

	-- Symbols / References
	{ "<leader>cs", "<cmd>Trouble symbols toggle focus=false win.id=dock<cr>", desc = "Document Symbols (Trouble)" },
	{ "<leader>cS", "<cmd>Telescope lsp_dynamic_workspace_symbols<CR>", desc = "Workspace Symbols" },
	{ "<leader>cl", "<cmd>Trouble lsp_bottom toggle<cr>", desc = "LSP References (Trouble)" },

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

	-- ╭────────────────────────────────────────────────────╮
	-- │                     Code Tests (neotest)           │
	-- ╰────────────────────────────────────────────────────╯
	{ "<leader>t", icon = "", group = "Tests" },

	{
		"<leader>tt",
		function()
			local neotest = require("neotest")
			neotest.run.run()
			vim.schedule(neotest.summary.open)
		end,
		desc = "Run nearest test",
		mode = "n",
	},

	{
		"<leader>tf",
		function()
			local neotest = require("neotest")
			neotest.run.run(vim.fn.expand("%"))
			vim.schedule(neotest.summary.open)
		end,
		desc = "Run tests in file",
		mode = "n",
	},

	{
		"<leader>ta",
		function()
			local neotest = require("neotest")
			neotest.run.run({ suite = true })
			vim.schedule(neotest.summary.open)
		end,
		desc = "Run all tests",
		mode = "n",
	},

	{
		"<leader>tr",
		function()
			local neotest = require("neotest")
			neotest.run.run_last()
			vim.schedule(neotest.summary.open)
		end,
		desc = "Re-run last test",
		mode = "n",
	},

	{
		"<leader>td",
		function()
			local neotest = require("neotest")
			neotest.run.run({ strategy = "dap" })
		end,
		desc = "Debug nearest test",
		mode = "n",
	},
	{
		"<leader>ts",
		function()
			local neotest = require("neotest")
			neotest.summary.toggle()
		end,
		desc = "Toggle test summary",
		mode = "n",
	},
	{
		"<leader>to",
		function()
			local neotest = require("neotest")
			neotest.output.open({ enter = true })
		end,
		desc = "Show test output",
		mode = "n",
	},
	{
		"<leader>tO",
		function()
			local neotest = require("neotest")
			neotest.output_panel.toggle()
		end,
		desc = "Toggle output panel",
		mode = "n",
	},

	-- ───── Overseer (task runner) ─────
	{
		"<leader>ro",
		"<cmd>OverseerToggle<CR>",
		desc = "Toggle Overseer task list",
		mode = "n",
	},
	{
		"<leader>rr",
		"<cmd>OverseerRun<CR>",
		desc = "Run task (Overseer)",
		mode = "n",
	},
	{
		"<leader>rR",
		"<cmd>OverseerRestartLast<CR>",
		desc = "Restart last task (Overseer)",
		mode = "n",
	},

	-- ───── HTTP Client (rest.nvim) ─────
	{ "<leader>rh", icon = "", group = "HTTP" },

	{
		"<leader>rhr",
		function()
			require("kulala").run()
		end,
		desc = "Run HTTP request",
	},
	{
		"<leader>rhR",
		function()
			require("kulala").replay()
		end,
		desc = "Rerun last HTTP request",
	},
	{
		"<leader>rhe",
		function()
			require("kulala").set_selected_env()
		end,
		desc = "Select .env for rest.nvim",
	},

	-- ╭────────────────────────────────────────────────────╮
	-- │                       Xcode                        │
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
	{
		"<leader>xdd",
		function()
			local xcodebuild = require("xcodebuild.integrations.dap")
			xcodebuild.build_and_debug()
		end,
		desc = "Build & Debug",
		mode = "n",
	},
	{
		"<leader>xdr",
		function()
			local xcodebuild = require("xcodebuild.integrations.dap")
			xcodebuild.debug_without_build()
		end,
		desc = "Debug Without Building",
		mode = "n",
	},
	{
		"<leader>xdt",
		function()
			local xcodebuild = require("xcodebuild.integrations.dap")
			xcodebuild.debug_tests()
		end,
		desc = "Debug Tests",
		mode = "n",
	},
	{
		"<leader>xdT",
		function()
			local xcodebuild = require("xcodebuild.integrations.dap")
			xcodebuild.debug_class_tests()
		end,
		desc = "Debug Class Tests",
		mode = "n",
	},
	{
		"<leader>xdb",
		function()
			local xcodebuild = require("xcodebuild.integrations.dap")
			xcodebuild.toggle_breakpoint()
		end,
		desc = "Toggle Breakpoint",
		mode = "n",
	},
	{
		"<leader>xdB",
		function()
			local xcodebuild = require("xcodebuild.integrations.dap")
			xcodebuild.toggle_message_breakpoint()
		end,
		desc = "Toggle Message Breakpoint",
		mode = "n",
	},
	{
		"<leader>xdx",
		function()
			local xcodebuild = require("xcodebuild.integrations.dap")
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
	},
	{
		"<leader>gg",
		function()
			snacks.lazygit()
		end,
		desc = "Git Browse",
	},
	{
		"<leader>gl",
		function()
			snacks.picker.git_log()
		end,
		desc = "Git Log",
	},
	{
		"<leader>gs",
		function()
			--- Tab is by default mapped to stage/unstage in git_status picker, but we want it to also move selection so we add that here
			snacks.picker.git_status({
				win = {
					input = {
						keys = {
							["<Tab>"] = { "select_and_next", mode = { "n", "i" } },
							["<S-Tab>"] = { "select_and_prev", mode = { "n", "i" } },
							["<C-s>"] = { "git_stage", mode = { "n", "i" } },
						},
					},
					list = {
						keys = {
							["<Tab>"] = { "select_and_next", mode = { "n", "x" } },
							["<S-Tab>"] = { "select_and_prev", mode = { "n", "x" } },
							["<C-s>"] = "git_stage",
						},
					},
				},
			})
		end,
		desc = "Git Status",
	},
	{
		"<leader>gd",
		function()
			snacks.picker.git_diff()
		end,
		desc = "Git Diff (Hunks)",
	},
	{
		"<leader>gt",
		function()
			local gitsigns = require("gitsigns")
			gitsigns.toggle_current_line_blame()
		end,
		desc = "Toggle Line Blame",
	},
	{
		"<leader>gb",
		function()
			local gitsigns = require("gitsigns")
			gitsigns.blame_line({ full = true })
		end,
		desc = "Git Blame Line",
	},
	{
		"<leader>gp",
		function()
			local gitsigns = require("gitsigns")
			gitsigns.preview_hunk()
		end,
		desc = "Preview Hunk",
	},
	{
		"<leader>gr",
		function()
			local gitsigns = require("gitsigns")
			gitsigns.reset_hunk()
		end,
		desc = "Reset Hunk",
	},
	{
		"[h",
		function()
			local gitsigns = require("gitsigns")
			gitsigns.nav_hunk("prev")
		end,
		desc = "Git Previous Hunk",
	},
	{
		"]h",
		function()
			local gitsigns = require("gitsigns")
			gitsigns.nav_hunk("next")
		end,
		desc = "Git Next Hunk",
	},
	{
		"<leader>gB",
		function()
			vim.cmd("Gitsigns blame")
			vim.cmd("wincmd p")
		end,
		desc = "Git Blame (panel, refocus)",
	},

	-- Diffview / CodeDiff
	{ "<leader>gD", group = "Diff" },
	{
		"<leader>gDD",
		"<cmd>DiffviewOpen<cr>",
		desc = "Open Diffview",
	},
	{
		"<leader>gDC",
		"<cmd>DiffviewClose<cr>",
		desc = "Close Diffview",
	},
	{
		"<leader>gDc",
		"<cmd>CodeDiff<cr>",
		desc = "Open CodeDiff",
	},
	{
		"<leader>gH",
		"<cmd>DiffviewFileHistory<cr>",
		desc = "File History",
	},
	{
		"<leader>goo",
		function()
			local cwd = vim.fn.getcwd()

			local current_branch = vim.trim(vim.fn.system({ "git", "-C", cwd, "rev-parse", "--abbrev-ref", "HEAD" }))
			if vim.v.shell_error ~= 0 or current_branch == "" then
				vim.notify("Git branch detection failed in current directory", vim.log.levels.WARN)
				return
			end

			if current_branch == "HEAD" then
				vim.notify("Detached HEAD: switch to a branch first", vim.log.levels.WARN)
				return
			end

			helper.select_origin_branch(cwd, current_branch, function(selection)
				local range = "origin/" .. selection .. "...HEAD"
				vim.cmd("DiffviewOpen " .. range)
			end)
		end,
		desc = "Diff vs origin branch (pick)",
	},
	{
		"<leader>goc",
		function()
			local cwd = vim.fn.getcwd()

			local current_branch = vim.trim(vim.fn.system({ "git", "-C", cwd, "rev-parse", "--abbrev-ref", "HEAD" }))
			if vim.v.shell_error ~= 0 or current_branch == "" then
				vim.notify("Git branch detection failed in current directory", vim.log.levels.WARN)
				return
			end

			if current_branch == "HEAD" then
				vim.notify("Detached HEAD: switch to a branch first", vim.log.levels.WARN)
				return
			end

			helper.select_origin_branch(cwd, current_branch, function(selection)
				local range = "origin/" .. selection .. "...HEAD"
				vim.cmd("CodeDiff " .. range)
			end)
		end,
		desc = "CodeDiff vs origin branch (pick)",
	},
	{
		"<leader>gh",
		function()
			snacks.picker.git_files({ untracked = true })
		end,
		desc = "Git Files",
	},
	{
		"<leader>gH",
		"<cmd>DiffviewFileHistory %<cr>",
		desc = "Current File History",
	},

	-- ╭────────────────────────────────────────────────────╮
	-- │                     Notes                          │
	-- ╰────────────────────────────────────────────────────╯
	{ "<leader>n", group = "Notes" },

	{ "<leader>nw", "<cmd>Obsidian workspace<CR>", desc = "Switch workspace" },
	{ "<leader>nn", "<cmd>Obsidian new<CR>", desc = "New note" },
	{ "<leader>nt", "<cmd>Obsidian tags<CR>", desc = "Tags" },
	{ "<leader>no", "<cmd>Obsidian open<CR>", desc = "Open in Obsidian app" },
	{ "<leader>nl", "<cmd>Obsidian dailies<CR>", desc = "Daily list" },
	{
		"<leader>nf",
		function()
			snacks.picker.files({
				cwd = vim.g.obsidian_vault,
				cmd = "rg",
				args = { "--files", "-g", "*.md" },
			})
		end,
		desc = "Find note",
	},

	{
		"<leader>ng",
		function()
			snacks.picker.grep({
				cwd = vim.g.obsidian_vault,
				cmd = "rg",
				args = { "-g", "*.md" },
			})
		end,
		desc = "Search notes",
	},

	-- ╭────────────────────────────────────────────────────╮
	-- │                     Snacks / Utils                 │
	-- ╰────────────────────────────────────────────────────╯
	{ "<leader>s", icon = "", group = "Snacks / Utils" },

	{
		"<leader>sd",
		function()
			if snacks.dim.enabled then
				snacks.dim.disable()
			else
				snacks.dim.enable()
			end
		end,
		desc = "Dim",
	},
	{
		"<leader>sz",
		function()
			snacks.zen()
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
		"<leader>sC",
		function()
			snacks.picker.command_history()
		end,
		desc = "Command History",
	},
	{
		"<leader>sc",
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
		"<leader>st",
		function()
			snacks.terminal.toggle()
		end,
		desc = "Floating Terminal",
	},

	{
		"<leader>s.",
		function()
			local default

			local base = { "markdown", "lua", "sql", "bash", "json" }
			local choices = { default }
			for _, ft in ipairs(base) do
				if ft ~= default then
					table.insert(choices, ft)
				end
			end

			vim.ui.select(choices, {
				prompt = "Scratch filetype:",
				format_item = function(item)
					if item == default then
						return item .. " (default)"
					end
					return item
				end,
			}, function(choice)
				if choice then
					snacks.scratch({ ft = choice })
				end
			end)
		end,
		desc = "Toggle Scratch Buffer",
	},

	{
		"<leader>sS",
		function()
			snacks.scratch.select()
		end,
		desc = "Select Scratch Buffer",
	},
})
