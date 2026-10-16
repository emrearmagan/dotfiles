local actions = {
	{
		label = " GitHub",
		run = function()
			vim.cmd("Atlas pulls github")
		end,
	},
	{
		label = " GitLab",
		run = function()
			vim.cmd("Atlas pulls gitlab")
		end,
	},
	{
		label = "󰌃 JIRA",
		run = function()
			vim.cmd("Atlas issues jira")
		end,
	},
	{
		label = " GitHub Issues",
		run = function()
			vim.cmd("Atlas issues github")
		end,
	},
	{
		label = " GitLab Issues",
		run = function()
			vim.cmd("Atlas issues gitlab")
		end,
	},
	{
		label = " Docker",
		run = function()
			vim.cmd("Dockyard")
		end,
	},
	{
		label = "󰆼 Database",
		run = function()
			vim.cmd("DBUIFull")
		end,
	},
	{
		label = " Config",
		run = function()
			require("snacks").dashboard.pick("files", { cwd = vim.fn.stdpath("config") })
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
		snacks = {
			format = function(item)
				return { { item.label } }
			end,
		},
	}, function(choice)
		if not choice then
			return
		end

		choice.run()
	end)
end, {})
