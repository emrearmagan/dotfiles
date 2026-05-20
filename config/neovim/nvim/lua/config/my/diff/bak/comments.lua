local M = {}

local ns = vim.api.nvim_create_namespace("diff_comments_popup")
local palette = {
	"#91d7e3",
	"#7dc4e4",
	"#8bd5ca",
	"#eed49f",
	"#f5a97f",
	"#f5bde6",
	"#c6a0f6",
	"#8aadf4",
	"#b7bdf8",
	"#f0c6c6",
	"#f4dbd6",
}

local function hash_string(text)
	local hash = 0
	for i = 1, #text do
		hash = (hash * 31 + string.byte(text, i)) % 2147483647
	end
	return hash
end

local function author_hl(author)
	if type(author) ~= "string" or author == "" then
		return "DiffCommentsMuted"
	end

	local idx = (hash_string(author:lower()) % #palette) + 1
	return ("DiffCommentsAuthor%02d"):format(idx)
end

local function setup_highlights()
	local comment = vim.api.nvim_get_hl(0, { name = "Comment", link = false })
	vim.api.nvim_set_hl(0, "DiffCommentsMuted", {
		fg = comment.fg,
		bg = comment.bg,
		italic = false,
	})
	vim.api.nvim_set_hl(0, "DiffCommentsPending", { fg = "#f5a97f", bold = true })
	for idx, color in ipairs(palette) do
		vim.api.nvim_set_hl(0, ("DiffCommentsAuthor%02d"):format(idx), { fg = color, bold = true })
	end
end

local function close_win(win)
	if vim.api.nvim_win_is_valid(win) then
		vim.api.nvim_win_close(win, true)
	end
end

local function utc_epoch(value)
	if type(value) ~= "string" then
		return nil
	end

	local year, month, day, hour, min, sec = value:match("^(%d+)%-(%d+)%-(%d+)T(%d+):(%d+):(%d+)Z$")
	if not year then
		return nil
	end

	local local_epoch = os.time({
		year = tonumber(year),
		month = tonumber(month),
		day = tonumber(day),
		hour = tonumber(hour),
		min = tonumber(min),
		sec = tonumber(sec),
	})
	local utc_offset = os.difftime(os.time(os.date("*t", local_epoch)), os.time(os.date("!*t", local_epoch)))
	return local_epoch + utc_offset
end

local function relative_time(value)
	local epoch = utc_epoch(value)
	if not epoch then
		return value or ""
	end

	local diff = math.max(0, os.time() - epoch)
	if diff < 60 then
		return "just now"
	end
	if diff < 3600 then
		local minutes = math.floor(diff / 60)
		return ("%d minute%s ago"):format(minutes, minutes == 1 and "" or "s")
	end
	if diff < 86400 then
		local hours = math.floor(diff / 3600)
		return ("%d hour%s ago"):format(hours, hours == 1 and "" or "s")
	end
	if diff < 604800 then
		local days = math.floor(diff / 86400)
		return ("%d day%s ago"):format(days, days == 1 and "" or "s")
	end

	return os.date("%Y-%m-%d", epoch)
end

function M.input(opts)
	opts = opts or {}

	local buf = vim.api.nvim_create_buf(false, true)
	vim.bo[buf].filetype = "markdown"
	vim.bo[buf].bufhidden = "wipe"
	vim.b[buf].completion = false

	local width = math.min(opts.width or 80, vim.o.columns - 4)
	local height = math.min(opts.height or 15, vim.o.lines - 6)
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
	})

	local function close()
		close_win(win)
	end

	local function submit()
		local body = vim.fn.trim(table.concat(vim.api.nvim_buf_get_lines(buf, 0, -1, false), "\n"))
		if body == "" then
			if opts.on_empty then
				opts.on_empty()
			end
			close()
			return
		end

		close()
		if opts.on_submit then
			opts.on_submit(body)
		end
	end

	local keymap_opts = { buffer = buf, silent = true }
	vim.keymap.set("n", "q", close, vim.tbl_extend("force", keymap_opts, { desc = "Cancel comment" }))
	vim.keymap.set("n", "<Esc>", close, vim.tbl_extend("force", keymap_opts, { desc = "Cancel comment" }))
	vim.keymap.set("n", "<CR>", submit, vim.tbl_extend("force", keymap_opts, { desc = "Submit comment" }))
	vim.keymap.set("n", "<C-CR>", submit, vim.tbl_extend("force", keymap_opts, { desc = "Submit comment" }))
	vim.keymap.set("n", "<C-s>", submit, vim.tbl_extend("force", keymap_opts, { desc = "Submit comment" }))
	vim.keymap.set("i", "<CR>", submit, vim.tbl_extend("force", keymap_opts, { desc = "Submit comment" }))
	vim.keymap.set("i", "<C-s>", submit, vim.tbl_extend("force", keymap_opts, { desc = "Submit comment" }))

	vim.cmd("startinsert")
end

local function render_comment(lines, line_to_comment, spans, comment, width)
	local start = #lines + 1
	local author = comment.user or comment.author or "unknown"
	local author_text = "@" .. author
	local pending_text = comment.pending and " PENDING" or ""
	local left_text = author_text .. pending_text
	local right_text = comment.right_text or relative_time(comment.created_at)
	local header = left_text
	if right_text ~= "" then
		local left_width = vim.api.nvim_strwidth(left_text)
		local right_width = vim.api.nvim_strwidth(right_text)
		local gap = math.max(1, width - left_width - right_width)
		header = left_text .. string.rep(" ", gap) .. right_text
	end

	table.insert(lines, header)
	local header_line = #lines - 1
	table.insert(spans, {
		line = header_line,
		start_col = 0,
		end_col = #author_text,
		hl_group = author_hl(author),
	})
	if pending_text ~= "" then
		table.insert(spans, {
			line = header_line,
			start_col = #author_text + 1,
			end_col = #left_text,
			hl_group = "DiffCommentsPending",
		})
	end
	if right_text ~= "" then
		table.insert(spans, {
			line = header_line,
			start_col = #header - #right_text,
			end_col = #header,
			hl_group = "DiffCommentsMuted",
		})
	end

	for _, line in ipairs(vim.split(comment.body or comment.content or "", "\n")) do
		table.insert(lines, line)
	end
	table.insert(lines, " (r)  󰆴 (d)")
	table.insert(spans, {
		line = #lines - 1,
		start_col = 0,
		end_col = #lines[#lines],
		hl_group = "DiffCommentsMuted",
	})

	for line = start, #lines do
		line_to_comment[line] = comment
	end
end

function M.open(comments, opts)
	opts = opts or {}
	comments = comments or {}
	setup_highlights()

	local buf = vim.api.nvim_create_buf(false, true)
	vim.bo[buf].filetype = "markdown"
	vim.bo[buf].bufhidden = "wipe"

	local width = math.min(opts.width or 90, vim.o.columns - 4)
	local lines = {}
	local line_to_comment = {}
	local spans = {}
	for index, comment in ipairs(comments) do
		if index > 1 then
			table.insert(lines, string.rep("─", width))
			table.insert(spans, {
				line = #lines - 1,
				start_col = 0,
				end_col = #lines[#lines],
				hl_group = "DiffCommentsMuted",
			})
		end
		render_comment(lines, line_to_comment, spans, comment, width)
	end

	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
	vim.bo[buf].modifiable = false
	for _, item in ipairs(spans) do
		vim.api.nvim_buf_set_extmark(buf, ns, item.line, item.start_col, {
			end_col = item.end_col,
			hl_group = item.hl_group,
			priority = 200,
		})
	end

	local height = math.min(opts.height or 30, vim.o.lines - 6)
	local win = vim.api.nvim_open_win(buf, true, {
		relative = "editor",
		width = width,
		height = height,
		col = math.floor((vim.o.columns - width) / 2),
		row = math.floor((vim.o.lines - height) / 2),
		style = "minimal",
		border = "rounded",
		title = opts.title or " Comments ",
		title_pos = "center",
		footer = " r: reply  d: delete  q: close ",
		footer_pos = "center",
	})

	vim.wo[win].wrap = true
	vim.wo[win].linebreak = true

	local function close()
		close_win(win)
	end

	local function selected_comment()
		return line_to_comment[vim.fn.line(".")]
	end

	local keymap_opts = { buffer = buf, silent = true }
	vim.keymap.set("n", "q", close, vim.tbl_extend("force", keymap_opts, { desc = "Close comments" }))
	vim.keymap.set("n", "<Esc>", close, vim.tbl_extend("force", keymap_opts, { desc = "Close comments" }))
	vim.keymap.set("n", "r", function()
		local comment = selected_comment()
		if opts.on_reply then
			opts.on_reply(comment, close)
		end
	end, vim.tbl_extend("force", keymap_opts, { desc = "Reply to comment" }))
	vim.keymap.set("n", "d", function()
		local comment = selected_comment()
		if opts.on_delete then
			opts.on_delete(comment, close)
		end
	end, vim.tbl_extend("force", keymap_opts, { desc = "Delete comment" }))
end

return M
