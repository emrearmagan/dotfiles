local helper = require("config.helper")

local function command()
	if vim.g.use_codediff then
		return "CodeDiff"
	end

	return "DiffviewOpen"
end

vim.api.nvim_create_user_command("GitOriginDiff", function()
	local open_cmd = command()

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
		vim.api.nvim_cmd({
			cmd = open_cmd,
			args = { "origin/" .. selection .. "...HEAD" },
		}, {})
	end)
end, {})
