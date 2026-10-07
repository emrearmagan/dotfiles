local M = {}

local group = vim.api.nvim_create_augroup("user_buffer_list", { clear = true })
local state

local function location_list(win)
	return vim.fn.getloclist(win, {
		context = 0,
		idx = 0,
		items = 0,
		quickfixtextfunc = 0,
		title = 0,
	})
end

local function restore_location_list(win, list)
	local what = {
		idx = list.idx,
		items = list.items or {},
		title = list.title or "",
	}
	if list.context ~= nil then
		what.context = list.context
	end
	if list.quickfixtextfunc and list.quickfixtextfunc ~= "" then
		what.quickfixtextfunc = list.quickfixtextfunc
	end
	vim.fn.setloclist(win, {}, "r", what)
end

local function current_item(current)
	if not vim.api.nvim_win_is_valid(current.list_win) then
		return
	end
	local row = vim.api.nvim_win_get_cursor(current.list_win)[1]
	return vim.fn.getloclist(current.origin_win, { items = 0 }).items[row]
end

local function show_item(current, item)
	if not item or item.bufnr <= 0 or not vim.api.nvim_buf_is_valid(item.bufnr) then
		return false
	end
	if not vim.api.nvim_win_is_valid(current.origin_win) then
		return false
	end

	local ok = pcall(vim.api.nvim_win_set_buf, current.origin_win, item.bufnr)
	if not ok then
		return false
	end

	local line_count = vim.api.nvim_buf_line_count(item.bufnr)
	local line = math.max(1, math.min(item.lnum, line_count))
	local col = math.max(0, item.col - 1)
	pcall(vim.api.nvim_win_set_cursor, current.origin_win, { line, col })
	return true
end

local function close(restore_buffer)
	local current = state
	if not current then
		return
	end
	state = nil
	vim.api.nvim_clear_autocmds({ group = group })

	if vim.api.nvim_win_is_valid(current.list_win) then
		pcall(vim.api.nvim_win_close, current.list_win, true)
	end
	if vim.api.nvim_buf_is_valid(current.list_buf) then
		pcall(vim.api.nvim_buf_delete, current.list_buf, { force = true })
	end
	if not vim.api.nvim_win_is_valid(current.origin_win) then
		return
	end

	if restore_buffer and vim.api.nvim_buf_is_valid(current.original_buf) then
		pcall(vim.api.nvim_win_set_buf, current.origin_win, current.original_buf)
		vim.api.nvim_win_call(current.origin_win, function()
			vim.fn.winrestview(current.original_view)
		end)
	end

	restore_location_list(current.origin_win, current.previous_list)
	pcall(vim.api.nvim_set_current_win, current.origin_win)
end

local function listed_buffers(origin_buf)
	local buffers = vim.fn.getbufinfo({ buflisted = 1 })
	table.sort(buffers, function(a, b)
		local a_current = a.bufnr == origin_buf
		local b_current = b.bufnr == origin_buf
		if a_current ~= b_current then
			return a_current
		end
		if a.lastused ~= b.lastused then
			return a.lastused > b.lastused
		end
		return a.bufnr < b.bufnr
	end)
	return buffers
end

function M.open()
	if state then
		close(true)
		return
	end

	local origin_win = vim.api.nvim_get_current_win()
	local original_buf = vim.api.nvim_get_current_buf()
	local buffers = listed_buffers(original_buf)
	if #buffers == 0 then
		vim.notify("No listed buffers", vim.log.levels.INFO)
		return
	end

	local items = {}
	for _, buffer in ipairs(buffers) do
		local marker = {}
		if buffer.bufnr == original_buf then
			table.insert(marker, "[current]")
		end
		if buffer.changed == 1 then
			table.insert(marker, "[modified]")
		end

		local pos
		if buffer.bufnr == original_buf then
			pos = vim.api.nvim_win_get_cursor(origin_win)
		else
			local ok, mark = pcall(vim.api.nvim_buf_get_mark, buffer.bufnr, '"')
			pos = ok and mark or { buffer.lnum, 0 }
		end
		table.insert(items, {
			bufnr = buffer.bufnr,
			lnum = pos[1] > 0 and pos[1] or math.max(buffer.lnum, 1),
			col = pos[2] + 1,
			text = table.concat(marker, " "),
		})
	end

	local previous_list = location_list(origin_win)
	local original_view = vim.api.nvim_win_call(origin_win, function()
		return vim.fn.winsaveview()
	end)
	vim.fn.setloclist(origin_win, {}, "r", {
		idx = 1,
		items = items,
		title = "Buffers",
	})
	vim.cmd("botright lopen")

	local list = vim.fn.getloclist(origin_win, { qfbufnr = 0, winid = 0 })
	if list.winid == 0 then
		restore_location_list(origin_win, previous_list)
		return
	end

	state = {
		list_buf = list.qfbufnr,
		list_win = list.winid,
		origin_win = origin_win,
		original_buf = original_buf,
		original_view = original_view,
		previous_list = previous_list,
	}
	vim.b[list.qfbufnr].buffer_list = true
	vim.api.nvim_win_set_cursor(list.winid, { 1, 0 })

	vim.api.nvim_create_autocmd("CursorMoved", {
		group = group,
		buffer = list.qfbufnr,
		callback = function()
			if state then
				show_item(state, current_item(state))
			end
		end,
	})
	vim.api.nvim_create_autocmd("WinClosed", {
		group = group,
		pattern = tostring(list.winid),
		once = true,
		callback = function()
			vim.schedule(function()
				close(true)
			end)
		end,
	})

	-- The shared qf FileType autocmd schedules its q mapping, so install ours afterward.
	vim.schedule(function()
		if not state or state.list_buf ~= list.qfbufnr or not vim.api.nvim_buf_is_valid(list.qfbufnr) then
			return
		end
		local opts = { buffer = list.qfbufnr, silent = true }
		vim.keymap.set("n", "<CR>", function()
			local current = state
			if current and show_item(current, current_item(current)) then
				close(false)
			end
		end, vim.tbl_extend("force", opts, { desc = "Select buffer" }))
		vim.keymap.set("n", "q", function()
			close(true)
		end, vim.tbl_extend("force", opts, { desc = "Cancel buffer list" }))
		vim.keymap.set("n", "<Esc>", function()
			close(true)
		end, vim.tbl_extend("force", opts, { desc = "Cancel buffer list" }))
		vim.keymap.set("n", "dd", "<Nop>", opts)
		vim.keymap.set("x", "d", "<Nop>", opts)
	end)
end

function M.toggle()
	M.open()
end

return M
