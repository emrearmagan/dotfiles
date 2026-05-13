local actions = {
	{
		label = "󰌃 JIRA",
		command = "AtlasIssues jira",
	},
	{
		label = " Bitbucket",
		command = "AtlasPulls bitbucket",
	},
	{
		label = " GitHub",
		command = "AtlasPulls Github",
	},
	{
		label = " GitHub Issues",
		command = "AtlasIssues Github",
	},
	{
		label = " GitLab",
		command = "AtlasPulls Gitlab",
	},
	{
		label = " GitLab Issues",
		command = "AtlasIssues GitLab",
	},

	{
		label = " Docker",
		command = "Dockyard",
	},
	{
		label = "󰆼 Database",
		command = "DBUIFull",
	},
	{
		label = "󰠮  Notes",
		run = function()
			require("snacks").picker.files({
				cwd = vim.g.obsidian_vault,
				cmd = "rg",
				args = { "--files", "-g", "*.md" },
			})
		end,
	},
	{
		label = "󰄬  Todo",
		run = function()
			if vim.fn.executable("tb") ~= 1 then
				vim.notify("taskbook (tb) is not installed or not in PATH", vim.log.levels.ERROR)
				return
			end

			vim.cmd("tabnew")
			local buf = vim.api.nvim_get_current_buf()
			vim.bo[buf].buflisted = false
			vim.bo[buf].bufhidden = "wipe"
			vim.fn.jobstart({ "tb" }, {
				term = true,
				on_exit = function()
					vim.schedule(function()
						for _, win in ipairs(vim.fn.win_findbuf(buf)) do
							pcall(vim.api.nvim_win_close, win, true)
						end
						if vim.api.nvim_buf_is_valid(buf) then
							pcall(vim.api.nvim_buf_delete, buf, { force = true })
						end
					end)
				end,
			})
			vim.cmd("startinsert")
		end,
	},
}

vim.api.nvim_create_user_command("Workflow", function()
	local choices = vim.tbl_filter(function(action)
		return action.enabled == nil or action.enabled()
	end, actions)

	vim.ui.select(choices, {
		prompt = "Workflow",
		format_item = function(item)
			return item.label
		end,
	}, function(choice)
		if not choice then
			return
		end

		if choice.run then
			choice.run()
			return
		end

		vim.cmd(choice.command)
	end)
end, {})
