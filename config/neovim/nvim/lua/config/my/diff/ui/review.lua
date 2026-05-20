local M = {}

local ns = vim.api.nvim_create_namespace("diff_review_popup")

---@class ReviewPopupOpts
---@field title string|nil
---@field on_reply fun(comment_id: string|integer, close: fun())|nil
---@field on_edit fun(comment_id: string|integer, close: fun())|nil
---@field on_delete fun(comment_id: string|integer, close: fun())|nil
---@field on_resolve fun(comment_id: string|integer, close: fun())|nil

---@param comments table[]  atlas-shaped PullsComment[] with inline + inline_hunk attached
---@param opts ReviewPopupOpts|nil
function M.open(comments, opts)
	opts = opts or {}
	local renderer = require("atlas.pulls.ui.panel.pr.tabs.review.renderer")

	local width = math.min(120, vim.o.columns - 4)
	local height = math.min(40, vim.o.lines - 6)

	local pulls_state = require("atlas.pulls.state")
	local review_state = require("atlas.pulls.ui.panel.pr.tabs.review.state")

	local saved_user = pulls_state.current_user
	local saved_expanded = review_state.expanded_threads
	if comments and comments[1] and comments[1].author then
		pulls_state.current_user = comments[1].author
	end
	review_state.expanded_threads = setmetatable({}, { __index = function() return true end })

	local ok, lines, spans, line_map = pcall(renderer.render, nil, width, comments or {})

	pulls_state.current_user = saved_user
	review_state.expanded_threads = saved_expanded
	if not ok then
		error(lines)
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

	local win = vim.api.nvim_open_win(buf, true, {
		relative = "editor",
		row = math.floor((vim.o.lines - height) / 2),
		col = math.floor((vim.o.columns - width) / 2),
		width = width,
		height = height,
		style = "minimal",
		border = "rounded",
		title = opts.title or " Pending review ",
		title_pos = "center",
		footer = " r: reply  e: edit  d: delete  R: resolve  q: close ",
		footer_pos = "center",
	})
	vim.wo[win].scrollbind = false
	vim.wo[win].cursorbind = false
	vim.wo[win].diff = false

	local function close()
		if vim.api.nvim_win_is_valid(win) then
			vim.api.nvim_win_close(win, true)
		end
	end

	---@return string|integer|nil
	local function comment_id_at_cursor()
		local lnum = vim.api.nvim_win_get_cursor(0)[1]
		for i = lnum, 1, -1 do
			local entry = line_map and line_map[i]
			local c = entry and (entry.comment or (entry.item and entry.item.meta and entry.item.meta.comment))
			if c and c.id then
				return c.id
			end
		end
	end

	local km = { buffer = buf, nowait = true, silent = true }
	vim.keymap.set("n", "q", close, km)
	vim.keymap.set("n", "<Esc>", close, km)

	local function dispatch(cb)
		return function()
			local id = comment_id_at_cursor()
			if not id then
				vim.notify("[PR comments] No comment at cursor", vim.log.levels.WARN)
				return
			end
			cb(id, close)
		end
	end

	if opts.on_reply then
		vim.keymap.set("n", "r", dispatch(opts.on_reply), km)
	end
	if opts.on_edit then
		vim.keymap.set("n", "e", dispatch(opts.on_edit), km)
	end
	if opts.on_delete then
		vim.keymap.set("n", "d", dispatch(opts.on_delete), km)
	end
	if opts.on_resolve then
		vim.keymap.set("n", "R", dispatch(opts.on_resolve), km)
	end
end

return M
