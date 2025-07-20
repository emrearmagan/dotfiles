return {
	"nvim-lualine/lualine.nvim", -- Lualine statusline plugin
	dependencies = {
		"nvim-tree/nvim-web-devicons",
		"dokwork/lualine-ex", -- Custom LSP component
	},
	config = function()
		local lualine = require("lualine")

		-- Custom function to display xcodebuild device info
		local function xcodebuild_device()
			if vim.g.xcodebuild_platform == "macOS" then
				return " macOS" -- Mac icon
			end

			if vim.g.xcodebuild_os then
				-- iPhone + OS name
				return " " .. vim.g.xcodebuild_device_name .. " (" .. vim.g.xcodebuild_os .. ")"
			end

			-- fallback: just device name
			return " " .. vim.g.xcodebuild_device_name
		end

		---------------------------------------------------------------------
		-- project() → repo‐root folder name, or CWD tail when not in a repo
		---------------------------------------------------------------------
		local function project()
			-- directory of current buffer
			local buf_dir = vim.fn.expand("%:p:h")

			-- try to detect the git root
			local git_root =
				vim.fn.systemlist("git -C " .. vim.fn.fnameescape(buf_dir) .. " rev-parse --show-toplevel")[1]

			-- fall back to current dir if not a git repo
			local dir = (git_root ~= "" and git_root) or buf_dir
			return "  " .. vim.fn.fnamemodify(dir, ":t")
		end

		lualine.setup({
			options = {
				globalstatus = true, -- Single global statusline (not per window)
				theme = "auto", -- Auto-detect colorscheme
				symbols = { -- Icon/symbol overrides
					alternate_file = "#", -- Alt file marker
					directory = "", -- Directory icon
					readonly = "", -- Readonly file icon
					unnamed = "[No Name]", -- Label for unnamed files
					newfile = "[New]", -- Label for new buffers
				},
				disabled_buftypes = { "quickfix", "prompt" }, -- Disable lualine for these types
				component_separators = "", -- No vertical separators
				section_separators = { left = "", right = "" }, -- Curved section separators
			},
			sections = {
				lualine_a = {
					{
						"filetype",
						icon_only = true,
						colored = true,
						--color = { bg = "#313244" },
						--separator = { left = "", right = "" },
						padding = { left = 1, right = 0 },
					},
					{
						"filename",
						file_status = true, -- Displays file status (readonly status, modified status)
						newfile_status = true, -- Display new file status (new file means no write after created)
						path = 0, -- 0: Just the filename
						-- 1: Relative path
						-- 2: Absolute path
						-- 3: Absolute path, with tilde as the home directory
						-- 4: Filename and parent dir, with tilde as the home directory

						shorting_target = 40, -- Shortens path to leave 40 spaces in the window
						-- for other components. (terrible name, any suggestions?)
						symbols = {
							modified = "󰷥", -- Text to show when the file is modified.
							readonly = "", -- Text to show when the file is non-modifiable or readonly.
							unnamed = " - No Name", -- Text to show for unnamed buffers.
							newfile = " - New File",
						},
						padding = { left = 0, right = 1 },
					},
				},

				lualine_b = {
					{
						"mode",
						fmt = function(str)
							return str:sub(1, 1)
						end,
					},
				},

				lualine_c = {
					{ "diagnostics" }, -- Show LSP diagnostics (errors/warnings)
				},

				lualine_x = {
					{ "ex.lsp.single", color = { fg = "#89b4fa" } }, -- Active LSP

					-- Custom Xcode build status (requires `vim.g.xcodebuild_last_status`)
					{ "' ' .. vim.g.xcodebuild_last_status", color = { fg = "#a6e3a1" } },
					-- Optional test plan info (currently commented)
					{ "'󰙨 ' .. vim.g.xcodebuild_test_plan", color = { fg = "#a6e3a1", bg = "#161622" } },
					-- Custom device info from earlier function
					{ xcodebuild_device, color = { fg = "#f9e2af", bg = "#161622" } },
				},
				lualine_y = {
					{ project, color = { fg = "#91d7e3" } }, -- ← new line
					{ "branch" }, -- Show current git branch
					{
						"diff",
						-- color = { fg = colors.mauve },
						colored = true, -- Displays a colored diff status if set to true
						diff_color = { -- match your palette
							added = { fg = "#a6da95" }, -- green
							modified = { fg = "#e0af68" }, -- yellow/peach
							removed = { fg = "#f7768e" }, -- red
						},
						symbols = { added = "+", modified = "~", removed = "-" }, -- Changes the symbols used by the diff.
					},
				},
				lualine_z = {
					{ "location" }, -- Show line & column number
				},
			},
			inactive_sections = {
				lualine_a = {}, -- Disable for inactive windows
				lualine_b = {},
				lualine_c = { "filename" }, -- Only show filename
				lualine_x = {},
				lualine_y = {},
				lualine_z = {},
			},
			extensions = {
				"nvim-dap-ui", -- Debugger UI
				"quickfix", -- Quickfix list
				"trouble", -- Diagnostics viewer
				"nvim-tree", -- File explorer
				"lazy", -- Plugin manager
				"mason", -- LSP/DAP/tool installer
			},
		})
	end,
}
