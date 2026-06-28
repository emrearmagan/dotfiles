local M = {}

function M.run_in_popup(cmd)
	vim.system({ "tmux-popup", "-d" }, {}, function()
		vim.system({ "tmux", "-L", "popup", "send-keys", "-t", "popup", cmd, "C-m" })
		vim.system({
			"tmux",
			"display-popup",
			"-w",
			"80%",
			"-h",
			"80%",
			"-T",
			"Shell",
			"-E",
			"tmux-popup",
		})
	end)
end

vim.api.nvim_create_user_command("Popup", function(opts)
	M.run_in_popup(opts.args)
end, {
	nargs = "+",
	complete = "shellcmd",
})

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

function M.default_origin_branch(cwd)
	local symbolic_ref = vim.fn.systemlist({
		"git",
		"-C",
		cwd,
		"symbolic-ref",
		"refs/remotes/origin/HEAD",
	})

	if vim.v.shell_error == 0 and symbolic_ref[1] then
		local branch = symbolic_ref[1]:match("refs/remotes/origin/(.+)$")
		if branch and branch ~= "" then
			return branch
		end
	end

	local remote_head = vim.fn.systemlist({
		"git",
		"-C",
		cwd,
		"ls-remote",
		"--symref",
		"origin",
		"HEAD",
	})

	if vim.v.shell_error == 0 then
		for _, line in ipairs(remote_head) do
			local branch = line:match("^ref:%s+refs/heads/(%S+)%s+HEAD$")
			if branch and branch ~= "" then
				return branch
			end
		end
	end
end

function M.select_origin_branch(cwd, current_branch, on_select)
	local branches, err = M.get_origin_branches(cwd)
	if not branches then
		vim.notify(err or "helper: some error occured", vim.log.levels.ERROR)
		return
	end

	local default_branch = M.default_origin_branch(cwd)
	local choices = {}
	local seen = {}

	if default_branch and default_branch ~= current_branch then
		table.insert(choices, default_branch)
		seen[default_branch] = true
	end

	for _, branch in ipairs(branches) do
		if branch ~= current_branch and not seen[branch] then
			table.insert(choices, branch)
			seen[branch] = true
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
