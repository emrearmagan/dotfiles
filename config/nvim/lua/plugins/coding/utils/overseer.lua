return {
	"stevearc/overseer.nvim",
	branch = "master",
	cmd = { "OverseerOpen", "OverseerClose", "OverseerToggle", "OverseerRun", "OverseerShell", "OverseerTaskAction" },
	config = function()
		local overseer = require("overseer")

		vim.api.nvim_create_autocmd("VimLeavePre", {
			callback = function()
				for _, task in ipairs(overseer.list_tasks({ status = "RUNNING" })) do
					task:stop()
				end
			end,
		})

		overseer.setup({
			-- Task list window configuration
			task_list = {
				direction = "bottom", -- "bottom", "left", or "right"
				max_height = { 15, 0.25 }, -- max of 15 lines OR 25% of window height
				min_height = 8, -- at least 8 lines tall
			},
		})
	end,
}
