-- Persistence across nvim restarts: cursor position, folds, quickfix list.

local function augroup(name)
	return vim.api.nvim_create_augroup("user_" .. name, { clear = true })
end

-- Go to last loc when opening a buffer.
vim.api.nvim_create_autocmd("BufReadPost", {
	group = augroup("last_location"),
	callback = function(event)
		local bo = vim.bo[event.buf]
		if bo.buftype ~= "" then
			return
		end
		local exclude = { "gitcommit", "snacks_dashboard", "dashboard", "alpha", "starter" }
		if vim.tbl_contains(exclude, bo.filetype) then
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
		if #items == 0 then
			pcall(os.remove, qf_path())
			return
		end
		local serializable = {}
		for _, it in ipairs(items) do
			table.insert(serializable, {
				filename = it.bufnr > 0 and vim.api.nvim_buf_get_name(it.bufnr) or nil,
				lnum = it.lnum,
				end_lnum = it.end_lnum,
				col = it.col,
				end_col = it.end_col,
				text = it.text,
				type = it.type,
				valid = it.valid,
			})
		end
		vim.fn.writefile({ vim.json.encode(serializable) }, qf_path())
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
		if not ok or type(items) ~= "table" then
			return
		end
		for _, it in ipairs(items) do
			if it.filename and it.filename ~= "" then
				it.bufnr = vim.fn.bufadd(it.filename)
				it.filename = nil
			end
		end
		vim.fn.setqflist(items)
	end,
})
