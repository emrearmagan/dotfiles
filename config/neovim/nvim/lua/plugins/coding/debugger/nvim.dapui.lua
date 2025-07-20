return {
	"rcarriga/nvim-dap-ui",
	dependencies = {
		"mfussenegger/nvim-dap",
		"nvim-neotest/nvim-nio",
	},
	lazy = true,
	config = function()
		local dap, dapui = require("dap"), require("dapui")
		-- Set fallback layout mode
		_G.run_mode = false

		local full_layouts = {
			{
				elements = {
					{ id = "stacks", size = 0.25 },
					{ id = "scopes", size = 0.25 },
					{ id = "breakpoints", size = 0.25 },
					{ id = "watches", size = 0.25 },
				},
				position = "left",
				size = 40,
			},
			{
				elements = {
					{ id = "repl", size = 0.6 },
					{ id = "console", size = 0.4 },
				},
				position = "bottom",
				size = 10,
			},
		}

		-- Console-only layout
		local console_layout = {
			{
				elements = {
					{ id = "repl", size = 0.6 },
					{ id = "console", size = 0.4 },
				},
				position = "bottom",
				size = 10,
			},
		}

		local default_config = {
			controls = {
				element = "repl",
				enabled = true,
				icons = {
					disconnect = "",
					run_last = "",
					terminate = "⏹︎",
					pause = "⏸︎",
					play = "",
					step_into = "󰆹",
					step_out = "󰆸",
					step_over = "",
					step_back = "",
				},
			},
			floating = {
				border = "single",
				mappings = { close = { "q", "<Esc>" } },
			},
			icons = {
				collapsed = "",
				expanded = "",
				current_frame = "",
			},
			layouts = full_layouts,
		}

		dapui.setup(default_config)

		local group = vim.api.nvim_create_augroup("dapui_config", { clear = true })

		-- 🪄 Hide `~` lines in DAP UI buffers for cleaner look
		vim.api.nvim_create_autocmd("BufWinEnter", {
			group = group,
			pattern = "DAP*",
			callback = function()
				vim.wo.fillchars = "eob: "
			end,
		})
		vim.api.nvim_create_autocmd("BufWinEnter", {
			group = group,
			pattern = "\\[dap\\-repl\\]",
			callback = function()
				vim.wo.fillchars = "eob: "
			end,
		})

		-- 📦 Automatically open DAP UI on session start
		dap.listeners.after.event_initialized["dapui_config"] = function()
			if _G.run_mode then
				-- Always reset back to the old layout and enable all breakpoints. See nvim.dap.lua for changed layout
				for _, bp in ipairs(dap.list_breakpoints() or {}) do
					bp.enabled = false
				end

				dapui.setup({ default_config, layouts = console_layout })
			else
				for _, bp in ipairs(dap.list_breakpoints() or {}) do
					bp.enabled = false
				end

				dapui.setup(default_config) --  Restore full layout
			end

			dapui.open()
		end
		dap.listeners.before.event_terminated["dapui_config"] = function()
			dapui.close()
		end
		dap.listeners.before.event_exited["dapui_config"] = function()
			dapui.close()
		end
	end,
}
