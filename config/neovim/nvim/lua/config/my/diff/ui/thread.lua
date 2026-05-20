local threadsv2 = require("atlas.ui.components.threadsv2")

local M = {}

local ns = vim.api.nvim_create_namespace("diff_thread_popup")

local FOOTER_ITEMS = { " (r)", " (e)", "(d)" }

--------------------------------------------------------------------------------
-- Helpers
--------------------------------------------------------------------------------

---@param author {name: string|nil, username: string|nil}|nil
---@return string
local function author_name(author)
	if not author then
		return "Unknown"
	end
	return author.username or author.name or "Unknown"
end

---@param comment DiffComment
---@return string|nil badge, string|nil hl
local function state_marker(comment)
	if comment.state == "DELETED" then
		return " deleted", "DiagnosticError"
	end
	if comment.state == "RESOLVED" then
		return "✓ resolved", "DiagnosticOk"
	end
	if comment.state == "OUTDATED" then
		return " outdated", "DiagnosticWarn"
	end
	if comment.state == "PENDING" then
		return "● pending", "DiagnosticWarn"
	end
	if comment.is_task then
		return "⊙ task", "DiagnosticInfo"
	end
	return nil, nil
end

---@param iso string|nil
---@return string
local function relative_time(iso)
	if type(iso) ~= "string" or iso == "" then
		return ""
	end
	local y, mo, d, h, mi = iso:match("(%d+)-(%d+)-(%d+)T(%d+):(%d+)")
	if not y then
		return iso
	end
	local t = os.time({ year = y, month = mo, day = d, hour = h, min = mi, sec = 0 })
	local diff = os.difftime(os.time(), t)
	if diff < 60 then
		return "just now"
	end
	if diff < 3600 then
		return ("%dm"):format(diff / 60)
	end
	if diff < 86400 then
		return ("%dh"):format(diff / 3600)
	end
	return ("%dd"):format(diff / 86400)
end

---@param comment DiffComment
---@param children table[]|nil
---@return AtlasThreadV2Item
local function to_item(comment, children)
	local badge, badge_hl = state_marker(comment)
	return {
		icon = "",
		author = author_name(comment.author),
		additional = relative_time(comment.created_at),
		right_text = badge or "",
		content = comment.body ~= "" and comment.body or "(empty)",
		footer_items = FOOTER_ITEMS,
		children = children,
		meta = { comment = comment, right_text_hl = badge_hl },
	}
end

--- Build threadsv2 items from a flat thread list (root, replies, root2, ...).
---@param thread DiffComment[]
---@return AtlasThreadV2Item[]
local function build_items(thread)
	local replies_by_root = {}
	for _, c in ipairs(thread) do
		if c.parent_id then
			replies_by_root[c.parent_id] = replies_by_root[c.parent_id] or {}
			table.insert(replies_by_root[c.parent_id], c)
		end
	end

	local items = {}
	for _, c in ipairs(thread) do
		if not c.parent_id then
			local children = {}
			for _, r in ipairs(replies_by_root[c.id] or {}) do
				table.insert(children, to_item(r))
			end
			table.insert(items, to_item(c, children))
		end
	end
	return items
end

--------------------------------------------------------------------------------
-- API
--------------------------------------------------------------------------------

---@class ThreadPopupOpts
---@field title string|nil
---@field width integer|nil
---@field on_reply fun(comment: DiffComment, close: fun())|nil
---@field on_edit fun(comment: DiffComment, close: fun())|nil
---@field on_delete fun(comment: DiffComment, close: fun())|nil
---@field on_resolve fun(comment: DiffComment, close: fun())|nil

---@param thread DiffComment[]  root + replies, multiple threads allowed
---@param opts ThreadPopupOpts|nil
function M.open(thread, opts)
	opts = opts or {}
	local root = thread[1]
	if not root then
		return
	end

	local width = math.min(opts.width or 80, vim.o.columns - 4)

	local items = build_items(thread)
	local lines, spans, line_map = threadsv2.render(items, width, {
		padding_x = 2,
		separator = "─",
		icon_hl_fn = function()
			return "DiagnosticInfo"
		end,
		right_text_hl = function(item)
			return item.meta and item.meta.right_text_hl
		end,
	})

	---@return DiffComment
	local function comment_at_cursor()
		local lnum = vim.api.nvim_win_get_cursor(0)[1]
		for i = lnum, 1, -1 do
			local entry = line_map and line_map[i]
			local c = entry and entry.item and entry.item.meta and entry.item.meta.comment
			if c then
				return c
			end
		end
		return root
	end

	local buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
	for _, h in ipairs(spans) do
		vim.api.nvim_buf_set_extmark(buf, ns, h.line, h.start_col, {
			end_col = h.end_col,
			hl_group = h.hl_group,
		})
	end
	vim.bo[buf].modifiable = false
	vim.bo[buf].bufhidden = "wipe"

	local height = math.min(#lines, vim.o.lines - 6)
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
