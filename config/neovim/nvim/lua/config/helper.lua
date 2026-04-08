local M = {}

function M.get_origin_branches(cwd)
	local remote_refs = vim.fn.systemlist({
		"git",
		"-C",
		cwd,
		"for-each-ref",
		"--format=%(refname:short)",
		"refs/remotes/origin",
	})

	if vim.v.shell_error ~= 0 then
		return nil, "Failed to list origin branches"
	end

	local branches = {}
	for _, ref in ipairs(remote_refs) do
		if ref ~= "origin/HEAD" then
			local short = ref:gsub("^origin/", "")
			if short ~= "" then
				table.insert(branches, short)
			end
		end
	end

	table.sort(branches)
	return branches
end

function M.select_origin_branch(cwd, current_branch, on_select)
	local branches, err = M.get_origin_branches(cwd)
	if not branches then
		vim.notify(err, vim.log.levels.ERROR)
		return
	end

	local choices = {}
	for _, branch in ipairs(branches) do
		if branch ~= current_branch then
			table.insert(choices, branch)
		end
	end

	if #choices == 0 then
		vim.notify("No origin branches available to compare", vim.log.levels.WARN)
		return
	end

	vim.ui.select(choices, {
		prompt = "Select a branch",
		format_item = function(item)
			return "origin/" .. item
		end,
	}, function(selection)
		if selection and on_select then
			on_select(selection)
		end
	end)
end

return M
