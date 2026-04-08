return {
	"nvim-lualine/lualine.nvim", -- Lualine statusline plugin
	event = "BufRead",
	dependencies = {
		"nvim-tree/nvim-web-devicons",
		"dokwork/lualine-ex", -- Custom LSP component
		"mfussenegger/nvim-dap",
	},
	config = function()
		local lualine = require("lualine")
		local custom_theme = {
			normal = {
				a = { fg = "#89b4fa", bg = "NONE" },
				b = { fg = "#cdd6f4", bg = "NONE" },
				c = { fg = "#cdd6f4", bg = "NONE" },
			},
			insert = {
				a = { fg = "#a6e3a1", bg = "NONE" },
				b = { fg = "#cdd6f4", bg = "NONE" },
				c = { fg = "#cdd6f4", bg = "NONE" },
			},
			visual = {
				a = { fg = "#cba6f7", bg = "NONE" },
				b = { fg = "#cdd6f4", bg = "NONE" },
				c = { fg = "#cdd6f4", bg = "NONE" },
			},
			replace = {
				a = { fg = "#f38ba8", bg = "NONE" },
				b = { fg = "#cdd6f4", bg = "NONE" },
				c = { fg = "#cdd6f4", bg = "NONE" },
			},
			command = {
				a = { fg = "#f9e2af", bg = "NONE" },
				b = { fg = "#cdd6f4", bg = "NONE" },
				c = { fg = "#cdd6f4", bg = "NONE" },
			},
			inactive = {
				a = { fg = "#7f849c", bg = "NONE" },
				b = { fg = "#7f849c", bg = "NONE" },
				c = { fg = "#7f849c", bg = "NONE" },
			},
		}

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

		local function obsidian_workspace()
			local file = vim.fn.expand("%:p")
			local vault = vim.g.obsidian_vault

			if not file:find(vault, 1, true) then
				return ""
			end

			-- detect workspace folder
			local rel = file:sub(#vault + 2) -- remove vault prefix
			local ws = rel:match("([^/]+)/")

			if ws then
				return "󱞁 " .. ws
			end

			return "󱞁 vault"
		end

		lualine.setup({
			options = {
				globalstatus = true, -- Single global statusline (not per window)
				theme = custom_theme,
				symbols = { -- Icon/symbol overrides
					alternate_file = "#", -- Alt file marker
					directory = "", -- Directory icon
					readonly = "", -- Readonly file icon
					unnamed = "[No Name]", -- Label for unnamed files
					newfile = "[New]", -- Label for new buffers
				},
				disabled_buftypes = { "quickfix", "prompt" }, -- Disable lualine for these types
				component_separators = "",
				section_separators = "",
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
					{
						"diagnostics",

						sources = { "nvim_diagnostic", "nvim_lsp", "nvim_workspace_diagnostic" },
					}, -- Show LSP diagnostics (errors/warnings)
				},

				lualine_x = {
					{ "searchcount" },
					{ "selectioncount" },
					{ obsidian_workspace },
					{ "overseer" },
					{
						function()
							local reg = vim.fn.reg_recording()
							if reg ~= "" then
								return "󰑋"
							end
							return ""
						end,
						color = function()
							if vim.fn.reg_recording() ~= "" then
								return { fg = "#f38ba8" } -- recording color
							end
							return {}
						end,
					},

					{ "ex.lsp.single", color = { fg = "#89b4fa" } }, -- Active LSP
					{ "dap_status" },

					-- Custom Xcode build status (requires `vim.g.xcodebuild_last_status`)
					{ "' ' .. vim.g.xcodebuild_last_status", color = { fg = "#a6e3a1" } },
					-- Custom device info from earlier function
					{ xcodebuild_device, color = { fg = "#f9e2af" } },
				},
				lualine_y = {
					{
						"branch",
						icon = "",
						color = { fg = "#89b4fa", bg = "NONE" },
						padding = { left = 1 },
					},
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
					{
						"location",
						padding = { left = 1, right = 0 },
					}, -- Show line & column number
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
				"trouble",
				"avante",
				"fzf",
				"lazy",
				"neo-tree",
				"overseer",
			},
		})
	end,
}
