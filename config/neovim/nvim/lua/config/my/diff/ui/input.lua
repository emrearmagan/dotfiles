local M = {}

---@class InputPopupOpts
---@field title string|nil
---@field width integer|nil
---@field height integer|nil
---@field text string|nil      pre-filled body
---@field on_submit fun(body: string)
---@field on_empty fun()|nil

---@param opts InputPopupOpts
function M.open(opts)
	local buf = vim.api.nvim_create_buf(false, true)
	vim.bo[buf].filetype = "markdown"
	vim.bo[buf].bufhidden = "wipe"
	vim.b[buf].completion = false

	if opts.text and opts.text ~= "" then
		vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(opts.text, "\n", { plain = true }))
	end

	local width = math.min(opts.width or 80, vim.o.columns - 4)
	local height = math.min(opts.height or 10, vim.o.lines - 6)
	local win = vim.api.nvim_open_win(buf, true, {
		relative = "editor",
		width = width,
		height = height,
		col = math.floor((vim.o.columns - width) / 2),
		row = math.floor((vim.o.lines - height) / 2),
		style = "minimal",
		border = "rounded",
		title = opts.title or " Comment ",
		title_pos = "center",
		footer = " <CR>/<C-s>: submit  q/<Esc>: cancel ",
		footer_pos = "center",
	})

	local function close()
		if vim.api.nvim_win_is_valid(win) then
			vim.api.nvim_win_close(win, true)
		end
	end

	local function submit()
		local body = vim.fn.trim(table.concat(vim.api.nvim_buf_get_lines(buf, 0, -1, false), "\n"))
		close()
		if body == "" then
			if opts.on_empty then
				opts.on_empty()
			end
			return
		end
		opts.on_submit(body)
	end

	local km = { buffer = buf, silent = true }
	vim.keymap.set("n", "q", close, km)
	vim.keymap.set("n", "<Esc>", close, km)
	vim.keymap.set("n", "<CR>", submit, km)
	vim.keymap.set("n", "<C-s>", submit, km)
	vim.keymap.set("i", "<C-CR>", submit, km)
	vim.keymap.set("i", "<C-s>", submit, km)

end

return M
