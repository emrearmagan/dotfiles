return {
	"nvim-lualine/lualine.nvim", -- Lualine statusline plugin
	dependencies = { "nvim-tree/nvim-web-devicons" },
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

		local function lsp_name()
			local clients = vim.lsp.get_active_clients()
			if #clients > 0 then
				return " " .. clients[1].name
			else
				return " No LSP"
			end
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
					-- or simply use: { "mode" }, -- this will display the full name of the mode
					{
						function()
							local mode_map = {
								["NORMAL"] = "N",
								["INSERT"] = "I",
								["VISUAL"] = "V",
								["V-LINE"] = "VL",
								["V-BLOCK"] = "VB",
								["REPLACE"] = "R",
								["COMMAND"] = "C",
								["SELECT"] = "S",
								["S-LINE"] = "SL",
								["S-BLOCK"] = "SB",
								["EX"] = "E",
								["TERMINAL"] = "T",
							}
							local mode = vim.fn.mode(true):upper()
							return mode_map[vim.api.nvim_get_mode().mode:upper()] or mode:sub(1, 1)
						end,
					},
				},
				lualine_b = {
					{
						function()
							local icon = "" -- Gopher icon (or any Nerd Font icon you want)
							local filename = vim.fn.expand("%:t") -- current file name
							return icon .. " " .. filename
						end,
					},
				},
				lualine_c = {
					{ "diagnostics" }, -- Show LSP diagnostics (errors/warnings)
				},

				lualine_x = {
					{ lsp_name, color = { fg = "#89b4fa" } }, -- Active LSP

					-- Custom Xcode build status (requires `vim.g.xcodebuild_last_status`)
					{ "' ' .. vim.g.xcodebuild_last_status", color = { fg = "#a6e3a1" } },
					-- Optional test plan info (currently commented)
					{ "'󰙨 ' .. vim.g.xcodebuild_test_plan", color = { fg = "#a6e3a1", bg = "#161622" } },
					-- Custom device info from earlier function
					{ xcodebuild_device, color = { fg = "#f9e2af", bg = "#161622" } },
				},
				lualine_y = {
					{ "branch" }, -- Show current git branch
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
