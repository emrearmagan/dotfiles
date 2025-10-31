local M = {}

function M.insert_header()
	local filename = vim.fn.expand("%:t")
	local author = "emrearmagan"

	-- try to detect project name from git or folder
	local handle = io.popen("basename `git rev-parse --show-toplevel 2>/dev/null`")
	local project = handle and handle:read("*l")
	if handle then
		handle:close()
	end
	project = project or vim.fn.fnamemodify(vim.fn.getcwd(), ":t")

	local date = os.date("%d.%m.%y")
	local header = string.format(
		[[/*
%s
Created at %s by %s
Copyright © %s. All rights reserved.
*/
]],
		filename,
		date,
		author,
		project
	)

	-- only insert if file is empty
	local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
	if #lines == 1 and lines[1] == "" then
		vim.api.nvim_buf_set_lines(0, 0, 0, false, vim.split(header, "\n"))
	else
		vim.api.nvim_buf_set_lines(0, 0, 0, false, vim.split(header .. "\n", "\n"))
	end
end

vim.api.nvim_create_user_command("AddHeader", M.insert_header, {})
return M
