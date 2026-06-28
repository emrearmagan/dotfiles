local box = require("atlas.ui.components.box")
local comments_ui = require("config.my.diff.ui.comments")
local icons = require("config.my.diff.ui.icons")

local M = {}

local ns = vim.api.nvim_create_namespace("diff_review_notes")

--------------------------------------------------------------------------------
-- Helpers
--------------------------------------------------------------------------------

---@param bufnr integer
---@return integer
local function box_width(bufnr)
	local width = vim.o.columns
	for _, win in ipairs(vim.fn.win_findbuf(bufnr)) do
		if vim.api.nvim_win_is_valid(win) then
			width = vim.api.nvim_win_get_width(win)
			break
		end
	end
	return math.max(36, math.min(100, width - 4))
end

---@param a string|nil
---@param b string|nil
---@return boolean
local function same_sha(a, b)
	a = tostring(a or "")
	b = tostring(b or "")
	if a == "" or b == "" or b == "WORKING" or b == "STAGED" then
		return true
	end
	return a:sub(1, #b) == b or b:sub(1, #a) == a
end

---@param severity string|nil
---@return string|nil
local function severity_hl(severity)
	severity = tostring(severity or ""):lower()
	if severity == "important" or severity == "high" or severity == "critical" then
		return "DiagnosticError"
	end
	if severity == "medium" or severity == "warn" or severity == "warning" then
		return "DiagnosticWarn"
	end
	if severity == "low" or severity == "info" then
		return "DiagnosticInfo"
	end
end

---@param note table
---@return string
local function note_created_at(note)
	return tostring(note.created_at or note.created_on or note.createdAt or note.updated_at or note.updated_on or "")
end

---@param lines string[]
---@param spans table[]
---@return table[]
local function to_virt_lines(lines, spans)
	local by_line = {}
	for _, span in ipairs(spans or {}) do
		if span.start_col and span.end_col and span.hl_group then
			local line = span.line + 1
			by_line[line] = by_line[line] or {}
			table.insert(by_line[line], span)
		end
	end

	local virt_lines = {}
	for i, line in ipairs(lines) do
		local chunks = {}
		local col = 0
		local line_spans = by_line[i] or {}
		table.sort(line_spans, function(a, b)
			return a.start_col < b.start_col
		end)

		for _, span in ipairs(line_spans) do
			if span.start_col > col then
				table.insert(chunks, { line:sub(col + 1, span.start_col), "NormalFloat" })
			end
			table.insert(chunks, { line:sub(span.start_col + 1, span.end_col), span.hl_group })
			col = span.end_col
		end

		if col < #line then
			table.insert(chunks, { line:sub(col + 1), "NormalFloat" })
		end
		virt_lines[i] = chunks
	end
	return virt_lines
end

--------------------------------------------------------------------------------
-- Store
--------------------------------------------------------------------------------

---@param session DiffCommentsSession
---@return string|nil
function M.path(session)
	local root = session and session.git_root
	if type(root) ~= "string" or root == "" then
		return nil
	end
	local result = vim.system({ "branch-notes", "path" }, { text = true, cwd = root }):wait()
	if not result or result.code ~= 0 then
		return nil
	end
	return vim.trim(result.stdout or "")
end

---@param session DiffCommentsSession
---@return table[]
function M.load(session)
	local root = session and session.git_root
	if type(root) ~= "string" or root == "" then
		return {}
	end

	local result = vim.system({ "branch-notes", "list", "--json" }, { text = true, cwd = root }):wait()
	if not result or result.code ~= 0 then
		return {}
	end

	local ok, decoded = pcall(vim.json.decode, result.stdout or "")
	if not ok or type(decoded) ~= "table" then
		vim.notify_once("[branch notes] Failed to parse branch-notes output", vim.log.levels.WARN)
		return {}
	end
	return decoded
end

---@param session DiffCommentsSession
---@param file_path string
---@return integer[]
function M.note_lines(session, file_path)
	local seen, lines = {}, {}
	for _, note in ipairs(M.load(session)) do
		local line = tonumber(note.line)
		if note.file_path == file_path and line and line > 0 and not seen[line] then
			seen[line] = true
			table.insert(lines, line)
		end
	end
	table.sort(lines)
	return lines
end

---@param session DiffCommentsSession
---@return table<string, integer>
function M.counts_by_file(session)
	local by_file = {}
	for _, note in ipairs(M.load(session)) do
		local file_path = note.file_path
		if type(file_path) == "string" and file_path ~= "" then
			by_file[file_path] = (by_file[file_path] or 0) + 1
		end
	end
	return by_file
end

--------------------------------------------------------------------------------
-- Rendering
--------------------------------------------------------------------------------

---@param note table
---@param outdated boolean
---@return table
local function note_comment(note, outdated)
	local severity = tostring(note.severity or "")

	return {
		id = note.id,
		parent_id = note.parent_id,
		icon = icons.note,
		icon_hl = "DiagnosticInfo",
		author_name = note.title and note.title ~= "" and note.title or "Note",
		additional = severity ~= "" and "· " .. severity or nil,
		additional_hl = severity_hl(severity),
		created_at = note_created_at(note),
		right_text = outdated and "outdated" or "",
		right_text_hl = outdated and "DiagnosticWarn" or nil,
		body = note.body,
	}
end

---@param notes table[]
---@param width integer
---@param border_hl string
---@return table[]
local function note_box(notes, width, border_hl)
	local lines, spans = comments_ui.render(notes, {
		width = math.max(20, width - 4),
		footer_items = {},
	})
	local rendered = box.render({ { lines = lines, spans = spans } }, {
		width = width,
		padding_x = 0,
		border_hl = border_hl,
	})
	return to_virt_lines(rendered.lines, rendered.highlights)
end

---@param bufnr integer
function M.clear(bufnr)
	if vim.api.nvim_buf_is_valid(bufnr) then
		vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)
	end
end

---@param bufnr integer
---@param file_path string
---@param side "LEFT"|"RIGHT"
---@param session DiffCommentsSession
function M.render(bufnr, file_path, side, session)
	M.clear(bufnr)
	if side ~= "RIGHT" or not vim.api.nvim_buf_is_valid(bufnr) then
		return
	end

	local width = box_width(bufnr)
	local line_count = vim.api.nvim_buf_line_count(bufnr)
	local grouped = {}
	for _, note in ipairs(M.load(session)) do
		local line = tonumber(note.line)
		if note.file_path == file_path and line then
			line = math.max(1, math.min(line, line_count))
			local outdated = not same_sha(note.head_sha, session.modified_revision)
			grouped[line] = grouped[line] or { notes = {}, border_hl = "FloatBorder" }
			if outdated then
				grouped[line].border_hl = "DiagnosticWarn"
			end
			table.insert(grouped[line].notes, note_comment(note, outdated))
		end
	end

	for line, group in pairs(grouped) do
		vim.api.nvim_buf_set_extmark(bufnr, ns, line - 1, 0, {
			virt_lines = note_box(group.notes, width, group.border_hl),
			virt_lines_above = false,
			virt_lines_leftcol = true,
			priority = 1200,
		})
	end
end

return M
