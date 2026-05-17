-- Persistence across nvim restarts: cursor position, folds, quickfix list.

local function augroup(name)
	return vim.api.nvim_create_augroup("user_" .. name, { clear = true })
end

-- Go to last loc when opening a buffer.
vim.api.nvim_create_autocmd("BufReadPost", {
	group = augroup("last_location"),
	callback = function(event)
		local exclude = { "gitcommit" }
		if vim.tbl_contains(exclude, vim.bo[event.buf].filetype) then
			return
		end

		local mark = vim.api.nvim_buf_get_mark(event.buf, '"')
		local lcount = vim.api.nvim_buf_line_count(event.buf)
		if mark[1] > 0 and mark[1] <= lcount then
			pcall(vim.api.nvim_win_set_cursor, 0, mark)
		end
	end,
})

-- Remember folds (and cursor) per file across sessions.
vim.opt.viewoptions = { "folds", "cursor", "curdir" }

local fold_group = augroup("remember_folds")
vim.api.nvim_create_autocmd("BufWinLeave", {
	group = fold_group,
	pattern = "?*",
	callback = function()
		if vim.bo.buftype == "" and vim.bo.filetype ~= "" then
			vim.cmd("silent! mkview 1")
		end
	end,
})
vim.api.nvim_create_autocmd("BufWinEnter", {
	group = fold_group,
	pattern = "?*",
	callback = function()
		if vim.bo.buftype == "" and vim.bo.filetype ~= "" then
			vim.cmd("silent! loadview 1")
		end
	end,
})

-- Remember the quickfix list per project across sessions.
local qf_dir = vim.fn.stdpath("state") .. "/quickfix"
vim.fn.mkdir(qf_dir, "p")

local function qf_path()
	local cwd = vim.fn.getcwd():gsub("[/\\:]", "%%")
	return qf_dir .. "/" .. cwd .. ".json"
end

local qf_group = augroup("remember_qflist")
vim.api.nvim_create_autocmd("VimLeavePre", {
	group = qf_group,
	callback = function()
		local items = vim.fn.getqflist()
		if #items > 0 then
			vim.fn.writefile({ vim.json.encode(items) }, qf_path())
		else
			pcall(os.remove, qf_path())
		end
	end,
})
vim.api.nvim_create_autocmd("VimEnter", {
	group = qf_group,
	callback = function()
		local path = qf_path()
		if vim.fn.filereadable(path) ~= 1 then
			return
		end
		local ok, items = pcall(vim.json.decode, table.concat(vim.fn.readfile(path), "\n"))
		if ok and type(items) == "table" then
			vim.fn.setqflist(items)
		end
	end,
})
