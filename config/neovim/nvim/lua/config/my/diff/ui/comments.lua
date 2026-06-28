local threadsv2 = require("atlas.ui.components.threadsv2")
local icons = require("config.my.diff.ui.icons")

local M = {}

local DEFAULT_FOOTER_ITEMS = { "reply (r)", "edit (e)", "delete (d)", "resolve (R)" }

--------------------------------------------------------------------------------
-- Helpers
--------------------------------------------------------------------------------

---@param values string[]
---@param sep string
---@return string
local function join_nonempty(values, sep)
	local out = {}
	for _, value in ipairs(values) do
		if type(value) == "string" and value ~= "" then
			table.insert(out, value)
		end
	end
	return table.concat(out, sep)
end

---@param value any
---@return string|nil
local function as_key(value)
	if value == nil then
		return nil
	end
	local key = tostring(value)
	return key ~= "" and key or nil
end

---@param comment table
---@return string|nil
local function comment_id(comment)
	return as_key(comment.id or comment.databaseId or comment.node_id)
end

---@param comment table
---@return string|nil
local function parent_id(comment)
	local parent = comment.parent or comment.replyTo or comment.reply_to
	return as_key(
		comment.parent_id or comment.parentId or (type(parent) == "table" and (parent.id or parent.databaseId) or nil)
	)
end

---@param author table|nil
---@return string
local function author_name(author)
	if type(author) ~= "table" then
		return "Unknown"
	end
	return author.nickname
		or author.username
		or author.login
		or author.name
		or author.display_name
		or author.displayName
		or "Unknown"
end

---@param text string
---@return string
local function clean_text(text)
	for _, codepoint in ipairs({ 0x200B, 0x200C, 0x200D, 0xFEFF }) do
		text = text:gsub(vim.fn.nr2char(codepoint), "")
	end
	return text:gsub("[ \t\r\n]+$", "")
end

---@param comment table
---@return string
local function comment_body(comment)
	local content = comment.content
	return clean_text(
		tostring(
			comment.body
				or comment.content_raw
				or (type(content) == "table" and (content.raw or content.text or content.html) or nil)
				or comment.text
				or ""
		)
	)
end

---@param comment table
---@return string
local function created_at(comment)
	return tostring(
		comment.created_at or comment.created_on or comment.createdAt or comment.updated_at or comment.updated_on or ""
	)
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

---@param comment table
---@return string|nil
local function location(comment)
	local context = comment.context
	local inline = comment.inline
	local file_path = type(context) == "table" and context.file_path or nil
	local line = type(context) == "table" and (context.end_line or context.start_line) or nil
	local side = type(context) == "table" and context.side or nil

	if (file_path == nil or line == nil) and type(inline) == "table" then
		file_path = file_path or inline.path
		line = line or inline.to or inline.from
		side = side or (inline.to ~= nil and "RIGHT" or inline.from ~= nil and "LEFT" or nil)
	end
	file_path = file_path or comment.path
	line = line or comment.line

	if type(file_path) ~= "string" or file_path == "" or line == nil then
		return nil
	end

	local suffix = side == "LEFT" and " old" or side == "RIGHT" and " new" or ""
	return ("%s:%s%s"):format(file_path, tostring(line), suffix)
end

---@param comment table
---@return string|nil text, string|nil hl
local function state_marker(comment)
	local state = tostring(comment.state or ""):upper()
	if state == "DELETED" or comment.deleted == true then
		return "deleted", "DiagnosticError"
	end
	if state == "RESOLVED" then
		return icons.status_resolved .. " resolved", "DiagnosticOk"
	end
	if state == "OUTDATED" then
		return "outdated", "DiagnosticWarn"
	end
	if state == "PENDING" or comment.pending == true then
		return icons.status_pending .. " pending", "DiagnosticWarn"
	end
	if comment.is_task == true then
		return "task", "DiagnosticInfo"
	end
	return nil, nil
end

---@param comment table
---@param children AtlasThreadV2Item[]|nil
---@param opts table
---@return AtlasThreadV2Item
local function to_item(comment, children, opts)
	local marker, marker_hl = state_marker(comment)
	local body = comment_body(comment)
	local timestamp = relative_time(created_at(comment))
	local additional = comment.additional
	if additional and additional ~= "" and timestamp ~= "" and comment.show_timestamp ~= false then
		additional = additional .. " · " .. timestamp
	elseif not additional or additional == "" then
		additional = timestamp
	end
	if opts.show_location then
		additional = join_nonempty({ location(comment) or "", additional }, "  ·  ")
	end

	return {
		icon = comment.icon or (comment.is_task and icons.task or icons.user),
		author = comment.author_name or author_name(comment.author or comment.user or comment.creator),
		additional = additional,
		right_text = comment.right_text or marker or "",
		content = body ~= "" and body or "(empty)",
		footer_items = opts.footer_items or DEFAULT_FOOTER_ITEMS,
		children = children,
		line_map = { comment = comment, entity_kind = "comment" },
		meta = {
			comment = comment,
			additional_hl = comment.additional_hl,
			icon_hl = comment.icon_hl or marker_hl or "DiagnosticInfo",
			is_deleted = tostring(comment.state or ""):upper() == "DELETED" or comment.deleted == true,
			right_text_hl = comment.right_text_hl or marker_hl,
		},
	}
end

---@param comments table[]
---@param opts table
---@return AtlasThreadV2Item[]
local function build_items(comments, opts)
	local by_id = {}
	for _, comment in ipairs(comments or {}) do
		local id = comment_id(comment)
		if id then
			by_id[id] = comment
		end
	end

	local replies_by_parent = {}
	for _, comment in ipairs(comments or {}) do
		local pid = parent_id(comment)
		if pid and by_id[pid] then
			replies_by_parent[pid] = replies_by_parent[pid] or {}
			table.insert(replies_by_parent[pid], comment)
		end
	end

	local function build(comment)
		local children = {}
		for _, reply in ipairs(replies_by_parent[comment_id(comment)] or {}) do
			table.insert(children, build(reply))
		end
		return to_item(comment, children, opts)
	end

	local items = {}
	for _, comment in ipairs(comments or {}) do
		local pid = parent_id(comment)
		if not (pid and by_id[pid]) then
			table.insert(items, build(comment))
		end
	end
	return items
end

--------------------------------------------------------------------------------
-- API
--------------------------------------------------------------------------------

---@param comments table[]
---@param opts { width: integer, thread_padding_x: integer|nil, show_location: boolean|nil, footer_items: string[]|nil }|nil
---@return string[] lines, table[] spans, table<integer, table> line_map
function M.render(comments, opts)
	opts = opts or {}
	local width = math.max(20, opts.width or 80)
	local items = build_items(comments or {}, opts)
	if #items == 0 then
		return {}, {}, {}
	end

	return threadsv2.render(items, width, {
		padding_x = opts.thread_padding_x or 1,
		separator = "─",
		additional_hl = function(item)
			return item and item.meta and item.meta.additional_hl or "AtlasTextMuted"
		end,
		content_hl = function(item, row)
			local meta = item and item.meta or {}
			if meta.is_deleted then
				return { { start_col = 0, end_col = #row, hl_group = "AtlasTextMutedItalic" } }
			end
		end,
		icon_hl_fn = function(item)
			return item and item.meta and item.meta.icon_hl or "DiagnosticInfo"
		end,
		right_text_hl = function(item)
			return item and item.meta and item.meta.right_text_hl or "AtlasTextMuted"
		end,
	})
end

---@param entry table|nil
---@return table|nil
function M.comment_from_entry(entry)
	if type(entry) ~= "table" then
		return nil
	end
	return entry.comment or (entry.item and entry.item.meta and entry.item.meta.comment) or nil
end

return M
