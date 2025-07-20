-- DAP listener bindings (attach/remove keys on start/stop)
local function setup_listeners()
	local dap = require("dap")
	local areSet = false

	dap.listeners.after["event_initialized"]["me"] = function()
		if not areSet and not _G.run_mode then
			areSet = true
			vim.keymap.set("n", "<leader>dx", function()
				require("dap").terminate()
			end, { desc = "Terminate Debugger" })

			if not _G.run_mode then
				vim.keymap.set("n", "<leader>dc", dap.continue, { desc = "Continue" })
				vim.keymap.set("n", "<leader>dC", dap.run_to_cursor, { desc = "Run To Cursor" })
				vim.keymap.set("n", "<leader>ds", dap.step_over, { desc = "Step Over" })
				vim.keymap.set("n", "<leader>di", dap.step_into, { desc = "Step Into" })
				vim.keymap.set("n", "<leader>do", dap.step_out, { desc = "Step Out" })
				vim.keymap.set({ "n", "v" }, "<Leader>dh", require("dap.ui.widgets").hover, { desc = "Hover" })
				vim.keymap.set({ "n", "v" }, "<Leader>de", require("dapui").eval, { desc = "Eval" })
			end
		end
	end

	local function cleanup()
		if areSet then
			areSet = false
			vim.keymap.set("n", "<leader>dc", dap.continue, { desc = "Start Debugging" })

			vim.keymap.del("n", "<leader>dC")
			vim.keymap.del("n", "<leader>ds")
			vim.keymap.del("n", "<leader>di")
			vim.keymap.del("n", "<leader>do")
			vim.keymap.del("n", "<leader>dx")
			vim.keymap.del({ "n", "v" }, "<Leader>dh")
			vim.keymap.del({ "n", "v" }, "<Leader>de")
		end
	end

	dap.listeners.after["event_terminated"]["me"] = cleanup
	dap.listeners.after["event_exited"]["me"] = cleanup
	dap.listeners.before["disconnect"]["me"] = cleanup

	-- Auto terminate DAP on Vim exit otherwise the debugger will still be attached
	vim.api.nvim_create_autocmd("VimLeavePre", {
		callback = function()
			local dap = require("dap")
			if dap.session() then
				dap.terminate()
			end
		end,
	})
end

return {
	"mfussenegger/nvim-dap",
	dependencies = {
		"rcarriga/nvim-dap-ui", -- UI for debugging (scopes, breakpoints, etc.)
	},
	config = function()
		local dap = require("dap")

		setup_listeners()
		local dap_integration = require("xcodebuild.integrations.dap")
		local codelldbPath = os.getenv("HOME") .. "/.local/share/nvim/codelldb/extension/adapter/codelldb"
		dap_integration.setup(codelldbPath)

		local define = vim.fn.sign_define
		define("DapBreakpoint", { text = "", texthl = "DiagnosticError" })
		define("DapBreakpointRejected", { text = "", texthl = "DiagnosticError" })
		define("DapStopped", { text = "", texthl = "DiagnosticOk" })
		define("DapLogPoint", { text = "", texthl = "DiagnosticInfo" })

		-- Keybinding --
		vim.keymap.set("n", "<leader>dt", dap.toggle_breakpoint, { desc = "Toggle Breakpoint" })
		vim.keymap.set("n", "<leader>dc", function()
			local dap = require("dap")
			_G.run_mode = false -- full debug UI
			dap.continue()
		end, { desc = "Start Debugging" })

		vim.keymap.set("n", "<leader>dD", function()
			require("dap").clear_breakpoints()
			local fidget = require("fidget")
			fidget.notify("❌ All breakpoints cleared", vim.log.levels.INFO)
		end, { desc = "Clear All Breakpoints" })

		-- Run mode: Uses the console-only layout, disabled all breakpoints temporarily
		vim.keymap.set("n", "<leader>dr", function()
			local dap = require("dap")
			_G.run_mode = true

			-- Open UI + start debugging
			dap.continue()
		end, { desc = "Run" })
	end,
}
