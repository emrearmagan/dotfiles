local comments_ui = require("config.my.diff.ui.comments")

local M = {}

local ns = vim.api.nvim_create_namespace("diff_thread_popup")

--------------------------------------------------------------------------------
-- API
--------------------------------------------------------------------------------

---@class ThreadPopupOpts
---@field title string|nil
---@field width integer|nil
---@field show_location boolean|nil
---@field empty_message string|nil
---@field on_reply fun(comment: DiffComment, close: fun())|nil
---@field on_edit fun(comment: DiffComment, close: fun())|nil
---@field on_delete fun(comment: DiffComment, close: fun())|nil
---@field on_resolve fun(comment: DiffComment, close: fun())|nil

---@param comments DiffComment[] root + replies, or multiple root threads
---@param opts ThreadPopupOpts|nil
function M.open(comments, opts)
	opts = opts or {}
	local root = comments[1]
	if not root and not opts.empty_message then
		return
	end

	local max_width = math.max(20, vim.o.columns - 4)
	local width = math.min(opts.width or 84, max_width)
	local lines, spans, line_map = comments_ui.render(comments, {
		width = width,
		show_location = opts.show_location,
	})
	if #lines == 0 and opts.empty_message then
		lines = { opts.empty_message }
		spans = {}
		line_map = {}
	end

	---@return DiffComment
	local function comment_at_cursor()
		local lnum = vim.api.nvim_win_get_cursor(0)[1]
		for i = lnum, 1, -1 do
			local comment = comments_ui.comment_from_entry(line_map and line_map[i])
			if comment then
				return comment
			end
		end
		return root
	end

	local buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
	for _, h in ipairs(spans or {}) do
		vim.api.nvim_buf_set_extmark(buf, ns, h.line, h.start_col, {
			end_col = h.end_col,
			hl_group = h.hl_group,
		})
	end
	vim.bo[buf].modifiable = false
	vim.bo[buf].bufhidden = "wipe"
	vim.bo[buf].buftype = "nofile"

	local height = math.max(1, math.min(#lines, vim.o.lines - 6))
	local win = vim.api.nvim_open_win(buf, true, {
		relative = "editor",
		row = math.floor((vim.o.lines - height) / 2),
		col = math.floor((vim.o.columns - width) / 2),
		width = width,
		height = height,
		style = "minimal",
		border = "rounded",
		title = opts.title or " Thread ",
		title_pos = "center",
		footer = " r: reply  e: edit  d: delete  R: resolve  q: close ",
		footer_pos = "center",
	})

	local function close()
		if vim.api.nvim_win_is_valid(win) then
			vim.api.nvim_win_close(win, true)
		end
	end

	local km = { buffer = buf, nowait = true, silent = true }
	vim.keymap.set("n", "q", close, km)
	vim.keymap.set("n", "<Esc>", close, km)
	if opts.on_reply then
		vim.keymap.set("n", "r", function()
			opts.on_reply(comment_at_cursor(), close)
		end, km)
	end
	if opts.on_edit then
		vim.keymap.set("n", "e", function()
			opts.on_edit(comment_at_cursor(), close)
		end, km)
	end
	if opts.on_delete then
		vim.keymap.set("n", "d", function()
			opts.on_delete(comment_at_cursor(), close)
		end, km)
	end
	if opts.on_resolve then
		vim.keymap.set("n", "R", function()
			opts.on_resolve(comment_at_cursor(), close)
		end, km)
	end
end

return M
