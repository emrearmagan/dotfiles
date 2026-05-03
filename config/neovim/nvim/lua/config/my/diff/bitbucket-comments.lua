if not vim.g.use_codediff then
	return {}
end

local comments_ui = require("config.my.diff.comments")

local M = {}
local ns = vim.api.nvim_create_namespace("bitbucket_pr_comments")

local cached_comments = {}
local cached_diff_files = {}
local cached_pr = nil
local cached_session_key = nil
local loading_session_key = nil
local placed_sign_keys = {}

local function notify(level, msg)
	vim.notify("[Bitbucket comments] " .. tostring(msg), level)
end

local function trim(value)
	if type(value) ~= "string" then
		return ""
	end
	return vim.trim(value)
end

local function current_codediff_session(tabpage)
	local ok, lifecycle = pcall(require, "codediff.ui.lifecycle")
	if not ok then
		return nil
	end

	return lifecycle.get_session(tabpage or vim.api.nvim_get_current_tabpage())
end

local function session_has_revision(session)
	if not session then
		return false
	end

	local revision = tostring(session.modified_revision or "")
	return revision ~= "" and revision ~= "WORKING" and revision ~= "STAGED"
end

local function session_cache_key(session)
	if not session then
		return nil
	end

	local root = tostring(session.git_root or "")
	local revision = tostring(session.modified_revision or "")
	if root == "" or revision == "" or revision == "WORKING" or revision == "STAGED" then
		return nil
	end

	return root .. ":" .. revision
end

local function parse_origin(root)
	if type(root) ~= "string" or root == "" then
		return nil
	end

	local result = vim.system({ "git", "-C", root, "remote", "get-url", "origin" }, { text = true }):wait()
	if not result or result.code ~= 0 then
		return nil
	end

	local url = trim(result.stdout)
	if not url:find("bitbucket", 1, false) then
		return nil
	end

	local path = url:match("^[%w_-]+@[^:]+:(.+)$")
		or url:match("^https?://[^/]+/(.+)$")
		or url:match("^[%w]+://[^/]+/(.+)$")
	if not path then
		return nil
	end

	path = path:gsub("%.git$", "")
	local workspace, repo = path:match("^([^/]+)/(.+)$")
	if not workspace or not repo then
		return nil
	end

	return workspace, repo
end

function M.can_handle()
	local session = current_codediff_session()
	return session ~= nil and parse_origin(session.git_root) ~= nil
end

local function get_session_file_path(tabpage)
	tabpage = tabpage or vim.api.nvim_get_current_tabpage()
	local session = current_codediff_session(tabpage)
	if not session then
		return nil
	end

	local file_path = (session.original_path ~= "" and session.original_path)
		or (session.modified_path ~= "" and session.modified_path)
	if not file_path then
		return nil
	end

	local git_root = tostring(session.git_root or "")
	if git_root ~= "" then
		local prefix = git_root .. "/"
		if file_path:sub(1, #prefix) == prefix then
			file_path = file_path:sub(#prefix + 1)
		end
	end

	return file_path, session
end

local function resolve_line(comment, side)
	if side == "LEFT" then
		return comment.original_line
	end
	return comment.line
end

local function count_threads(comments, file_path)
	local counts = {}
	for _, comment in ipairs(comments or {}) do
		if comment.path == file_path and not comment.in_reply_to_id then
			local side = comment.side or "RIGHT"
			local line = resolve_line(comment, side)
			if line then
				local key = ("%d:%s"):format(line, side)
				counts[key] = (counts[key] or 0) + 1
			end
		end
	end
	return counts
end

local function place_signs(bufnr, file_path, side, comments)
	if not vim.api.nvim_buf_is_valid(bufnr) then
		return
	end

	for _, win in ipairs(vim.fn.win_findbuf(bufnr)) do
		if vim.api.nvim_win_is_valid(win) then
			vim.wo[win].signcolumn = "yes:1"
		end
	end

	local sign_key = table.concat({
		tostring(bufnr),
		file_path,
		side,
		tostring(#(comments or {})),
	}, ":")
	local existing_signs = vim.api.nvim_buf_get_extmarks(bufnr, ns, 0, -1, {})
	if placed_sign_keys[bufnr] == sign_key and #existing_signs > 0 then
		return
	end
	placed_sign_keys[bufnr] = sign_key

	vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)

	local threads = count_threads(comments, file_path)
	local line_count = vim.api.nvim_buf_line_count(bufnr)
	local line_has_published = {}
	local line_has_pending = {}

	for _, comment in ipairs(comments or {}) do
		if comment.path == file_path and not comment.in_reply_to_id then
			local comment_side = comment.side or "RIGHT"
			if comment_side == side then
				local line = resolve_line(comment, comment_side)
				if line then
					if comment.pending then
						line_has_pending[line] = true
					else
						line_has_published[line] = true
					end
				end
			end
		end
	end

	for key in pairs(threads) do
		local line_str, comment_side = key:match("^(%d+):(.+)$")
		if comment_side == side then
			local line = tonumber(line_str)
			if line and line >= 1 and line <= line_count then
				vim.api.nvim_buf_set_extmark(bufnr, ns, line - 1, 0, {
					sign_text = line_has_published[line] and "" or "",
					sign_hl_group = "DiagnosticInfo",
					priority = 1000,
				})
			end
		end
	end
end

local function show_signs_for_session(comments, tabpage)
	local file_path, session = get_session_file_path(tabpage)
	if not file_path or not session then
		return
	end

	place_signs(session.original_bufnr, file_path, "LEFT", comments)
	place_signs(session.modified_bufnr, file_path, "RIGHT", comments)
end

local function hunk_range(header, side)
	local left_start, left_count, right_start, right_count = header:match("@@ %-(%d+),?(%d*) %+(%d+),?(%d*) @@")
	if side == "LEFT" then
		return tonumber(left_start), tonumber(left_count) or 1
	end
	return tonumber(right_start), tonumber(right_count) or 1
end

local function lines_in_diff(file_path, start_line, end_line, side)
	local file = cached_diff_files[file_path]
	if not file then
		return false
	end

	for _, hunk in ipairs(file.hunks or {}) do
		local start, count = hunk_range(hunk.header or "", side)
		if start then
			local finish = start + count - 1
			if start_line >= start and end_line <= finish then
				return true
			end
		end
	end

	return false
end

local function iso_for_popup(value)
	if type(value) ~= "string" then
		return nil
	end

	return value:gsub("%.%d+", ""):gsub("%+00:00$", "Z")
end

local function normalize_comment(comment)
	local inline = comment.inline or {}
	local line = tonumber(inline.to)
	local original_line = tonumber(inline["from"])
	local side = line and "RIGHT" or "LEFT"
	local author = comment.author or comment.user or {}
	local content = comment.content or {}
	local parent = comment.parent or {}
	local user = author.nickname ~= "" and author.nickname or author.name or author.display_name

	return {
		id = comment.id,
		path = inline.path,
		body = comment.content_raw or content.raw or "",
		line = line,
		original_line = original_line,
		side = side,
		in_reply_to_id = comment.parent_id or parent.id,
		user = user,
		created_at = iso_for_popup(comment.created_on),
		pending = comment.pending == true or tostring(comment.state or ""):upper() == "PENDING",
	}
end

local function normalize_comments(comments)
	local normalized = {}
	local by_id = {}

	for _, comment in ipairs(comments or {}) do
		local item = normalize_comment(comment)
		if item.path and (item.line or item.original_line) then
			table.insert(normalized, item)
			by_id[item.id] = item
		end
	end

	for _, comment in ipairs(comments or {}) do
		local item = normalize_comment(comment)
		if item.in_reply_to_id and not item.path then
			local parent = by_id[item.in_reply_to_id]
			if parent then
				item.path = parent.path
				item.line = parent.line
				item.original_line = parent.original_line
				item.side = parent.side
				table.insert(normalized, item)
			end
		end
	end

	return normalized
end

local function merge_comments(...)
	local comments = {}
	local seen = {}
	for _, list in ipairs({ ... }) do
		for _, comment in ipairs(list or {}) do
			if comment.path and (comment.line or comment.original_line) then
				local key = tostring(comment.id or "")
				if key == "" then
					key = table.concat(
						{ comment.path or "", comment.side or "", tostring(comment.line or ""), comment.body or "" },
						":"
					)
				end
				if not seen[key] then
					seen[key] = true
					table.insert(comments, comment)
				end
			end
		end
	end
	return comments
end

local function hash_matches(left, right)
	left = tostring(left or "")
	right = tostring(right or "")
	return left ~= "" and right ~= "" and (left:sub(1, #right) == right or right:sub(1, #left) == left)
end

local function fetch_open_prs(workspace, repo, callback)
	local service = require("atlas.pulls.providers.bitbucket.api.service")
	local pr_normalizer = require("atlas.pulls.providers.bitbucket.api.pr_normalizer")
	local endpoint = ("/repositories/%s/%s/pullrequests?state=OPEN&pagelen=50"):format(workspace, repo)
	service.request("GET", endpoint, nil, nil, function(result, err)
		if err then
			callback(nil, err)
			return
		end
		callback(pr_normalizer.pullrequests(result, workspace, repo), nil)
	end)
end

local function pr_from_codediff_revision(tabpage, callback)
	local session = current_codediff_session(tabpage)
	if not session or not session.git_root then
		callback(nil)
		return
	end

	local workspace, repo = parse_origin(session.git_root)
	if not workspace or not repo then
		callback(nil)
		return
	end

	local sha = tostring(session.modified_revision or "")
	fetch_open_prs(workspace, repo, function(prs, err)
		if err then
			callback(nil, err)
			return
		end

		for _, pr in ipairs(prs or {}) do
			if hash_matches((pr.source or {}).commit_hash, sha) then
				callback(pr)
				return
			end
		end

		callback(nil)
	end)
end

local function wait_for_codediff_pr(tabpage, attempt, callback)
	attempt = attempt or 1
	pr_from_codediff_revision(tabpage, function(pr, err)
		if pr or err then
			callback(pr, err)
			return
		end

		if attempt >= 12 then
			callback(nil)
			return
		end

		vim.defer_fn(function()
			wait_for_codediff_pr(tabpage, attempt + 1, callback)
		end, 100)
	end)
end

local function fetch_pr_data(callback, tabpage, on_done)
	local function done()
		if on_done then
			on_done()
		end
	end

	wait_for_codediff_pr(tabpage, 1, function(pr, err)
		if err then
			notify(vim.log.levels.WARN, "Failed to find Bitbucket PR: " .. err)
			done()
			return
		end
		if not pr then
			notify(vim.log.levels.WARN, "No Bitbucket PR found")
			done()
			return
		end

		cached_pr = pr
		cached_comments = {}
		cached_diff_files = {}
		placed_sign_keys = {}
		notify(vim.log.levels.INFO, "Loading PR comments...")

		local provider = require("atlas.pulls.providers.bitbucket")
		provider.fetch_diff(pr, { force_refresh = true }, function(files)
			local by_path = {}
			for _, file in ipairs(files or {}) do
				by_path[file.path] = file
				if file.old_path then
					by_path[file.old_path] = file
				end
			end
			cached_diff_files = by_path
		end)

		local raw = pr._raw or {}
		local comments_url = tostring((raw.links or {}).comments or "")
		if comments_url == "" then
			notify(vim.log.levels.WARN, "Failed to load comments: no comments URL")
			done()
			return
		end

		local sep = comments_url:find("?") and "&" or "?"
		local comments_api_url = string.format("%s%spagelen=100", comments_url, sep)
		local service = require("atlas.pulls.providers.bitbucket.api.service")
		service.request("GET", comments_api_url, nil, nil, function(result, comments_err)
			if comments_err then
				notify(vim.log.levels.WARN, "Failed to load comments: " .. comments_err)
				done()
				return
			end

			cached_comments = merge_comments(normalize_comments((result or {}).values or {}))
			callback(cached_comments)
			notify(vim.log.levels.INFO, ("Loaded %d PR comments"):format(#cached_comments))
			done()
		end)
	end)
end

local function refresh(tabpage, opts)
	opts = opts or {}
	local target_tabpage = tabpage or vim.api.nvim_get_current_tabpage()
	local session = current_codediff_session(target_tabpage)
	local key = session_cache_key(session)

	if opts.force ~= true and key and cached_session_key == key and cached_pr then
		show_signs_for_session(cached_comments, target_tabpage)
		return
	end

	if key and loading_session_key == key then
		return
	end

	loading_session_key = key
	fetch_pr_data(
		function(comments)
			cached_session_key = key
			show_signs_for_session(comments, target_tabpage)
		end,
		target_tabpage,
		function()
			if loading_session_key == key then
				loading_session_key = nil
			end
		end
	)
end

local function show_cached(tabpage)
	local target_tabpage = tabpage or vim.api.nvim_get_current_tabpage()
	local session = current_codediff_session(target_tabpage)
	if not session or not parse_origin(session.git_root) then
		return
	end
	if cached_comments and #cached_comments > 0 then
		show_signs_for_session(cached_comments, target_tabpage)
	end
end

local function get_thread_at_cursor()
	local cursor_line = vim.fn.line(".")
	local file_path, session = get_session_file_path()
	if not file_path or not session then
		return nil, {}, nil, nil, nil
	end

	local current_buf = vim.api.nvim_get_current_buf()
	local side = current_buf == session.original_bufnr and "LEFT"
		or current_buf == session.modified_bufnr and "RIGHT"
		or nil
	if not side then
		return nil, {}, nil, nil, nil
	end

	local root = nil
	for _, comment in ipairs(cached_comments) do
		if comment.path == file_path and not comment.in_reply_to_id then
			local comment_side = comment.side or "RIGHT"
			if comment_side == side and resolve_line(comment, comment_side) == cursor_line then
				root = comment
				break
			end
		end
	end

	if not root then
		return nil, {}, file_path, side, cursor_line
	end

	local replies = {}
	for _, comment in ipairs(cached_comments) do
		if comment.in_reply_to_id == root.id then
			table.insert(replies, comment)
		end
	end
	table.sort(replies, function(a, b)
		return tostring(a.id) < tostring(b.id)
	end)

	return root, replies, file_path, side, cursor_line
end

local function get_current_line_diff_context()
	local file_path, session = get_session_file_path()
	if not file_path or not session then
		notify(vim.log.levels.WARN, "Not in a CodeDiff session")
		return nil
	end

	local current_buf = vim.api.nvim_get_current_buf()
	local side = current_buf == session.original_bufnr and "LEFT"
		or current_buf == session.modified_bufnr and "RIGHT"
		or nil
	if not side then
		notify(vim.log.levels.WARN, "Cursor is not in a diff buffer")
		return nil
	end

	local line = vim.fn.line(".")
	return file_path, line, line, side
end

local function get_visual_diff_context()
	local start_line = vim.fn.line("v")
	local end_line = vim.fn.line(".")
	if start_line > end_line then
		start_line, end_line = end_line, start_line
	end
	vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "x", false)

	local file_path, _, _, side = get_current_line_diff_context()
	if not file_path then
		return nil
	end
	return file_path, start_line, end_line, side
end

local function inline_for(file_path, start_line, end_line, side)
	if side == "LEFT" then
		return {
			path = file_path,
			["from"] = end_line,
			start_from = start_line ~= end_line and start_line or nil,
		}
	end

	return {
		path = file_path,
		to = end_line,
		start_to = start_line ~= end_line and start_line or nil,
	}
end

local function open_comment_popup(title, file_path, start_line, end_line, side, on_submit)
	comments_ui.input({
		title = (" %s: %s:%d-%d (%s) "):format(title, file_path, start_line, end_line, side),
		on_empty = function()
			notify(vim.log.levels.WARN, "Empty comment, cancelled")
		end,
		on_submit = on_submit,
	})
end

local function post_pending_comment(body, inline, callback)
	local raw = cached_pr and cached_pr._raw or {}
	local comments_url = tostring((raw.links or {}).comments or "")
	if comments_url == "" then
		callback(nil, "No comments URL available")
		return
	end

	local service = require("atlas.pulls.providers.bitbucket.api.service")
	local payload = vim.json.encode({
		content = { raw = body },
		inline = inline,
		pending = true,
	})
	service.request("POST", comments_url, nil, payload, callback)
end

local function add_comment(context, pending)
	if not cached_pr then
		notify(vim.log.levels.ERROR, "No PR data cached. Open CodeDiff for a Bitbucket PR first.")
		return
	end

	local file_path, start_line, end_line, side = context()
	if not file_path then
		return
	end
	if not lines_in_diff(file_path, start_line, end_line, side) then
		notify(vim.log.levels.WARN, "Selected lines are outside the diff")
		return
	end

	local title = pending and "Pending Bitbucket comment" or "Bitbucket comment"
	open_comment_popup(title, file_path, start_line, end_line, side, function(body)
		local inline = inline_for(file_path, start_line, end_line, side)
		local function on_done(_, err)
			if err then
				notify(vim.log.levels.ERROR, "Failed to post comment: " .. err)
				return
			end
			notify(vim.log.levels.INFO, pending and "Pending comment added" or "Comment posted")
			refresh(nil, { force = true })
		end

		if pending then
			post_pending_comment(body, inline, on_done)
			return
		end

		local comments_api = require("atlas.pulls.providers.bitbucket.api.comments")
		comments_api.add_comment(cached_pr, body, {
			inline = inline,
		}, on_done)
	end)
end

local function post_reply(root_comment, body)
	if not cached_pr then
		notify(vim.log.levels.ERROR, "No PR data cached. Open CodeDiff for a Bitbucket PR first.")
		return
	end

	local function post_pending_reply()
		local raw = cached_pr._raw or {}
		local comments_url = tostring((raw.links or {}).comments or "")
		if comments_url == "" then
			notify(vim.log.levels.ERROR, "Failed to post pending reply: no comments URL")
			return
		end

		local service = require("atlas.pulls.providers.bitbucket.api.service")
		local payload = vim.json.encode({
			content = { raw = body },
			parent = { id = tonumber(root_comment.id) or root_comment.id },
			pending = true,
		})
		service.request("POST", comments_url, nil, payload, function(_, pending_err)
			if pending_err then
				notify(vim.log.levels.ERROR, "Failed to post pending reply: " .. pending_err)
				return
			end
			notify(vim.log.levels.INFO, "Reply posted")
			refresh(nil, { force = true })
		end)
	end

	if root_comment.pending then
		post_pending_reply()
		return
	end

	local comments_api = require("atlas.pulls.providers.bitbucket.api.comments")
	local function on_done(_, err)
		if err then
			if tostring(err):find("NONPENDING_COMMENT_ON_PENDING_COMMENT", 1, true) then
				post_pending_reply()
				return
			end

			notify(vim.log.levels.ERROR, "Failed to post reply: " .. err)
			return
		end
		notify(vim.log.levels.INFO, "Reply posted")
		refresh(nil, { force = true })
	end

	comments_api.reply_comment(cached_pr, root_comment.id, body, on_done)
end

local function delete_comment(comment)
	if not cached_pr then
		notify(vim.log.levels.ERROR, "No PR data cached. Open CodeDiff for a Bitbucket PR first.")
		return
	end
	if not comment or not comment.id then
		notify(vim.log.levels.ERROR, "No comment selected")
		return
	end

	local comments_api = require("atlas.pulls.providers.bitbucket.api.comments")
	comments_api.delete_comment(cached_pr, comment.id, function(ok, err)
		if not ok then
			notify(vim.log.levels.ERROR, "Failed to delete comment: " .. tostring(err or ""))
			return
		end

		local remaining = {}
		for _, item in ipairs(cached_comments) do
			if item.id ~= comment.id and item.in_reply_to_id ~= comment.id then
				table.insert(remaining, item)
			end
		end
		cached_comments = remaining
		placed_sign_keys = {}
		show_signs_for_session(cached_comments)
		notify(vim.log.levels.INFO, comment.in_reply_to_id and "Reply deleted" or "Thread deleted")
	end)
end

local function view_thread()
	local root, replies, file_path, side, cursor_line = get_thread_at_cursor()
	if not root then
		notify(vim.log.levels.WARN, "No PR thread at cursor")
		return
	end

	local thread_comments = { root }
	vim.list_extend(thread_comments, replies)
	comments_ui.open(thread_comments, {
		title = (" Thread: %s:%d (%s) "):format(file_path, cursor_line, side),
		on_reply = function(comment, close)
			if not comment then
				notify(vim.log.levels.WARN, "Move cursor onto a comment first")
				return
			end
			close()
			open_comment_popup("Reply", file_path, cursor_line, cursor_line, side, function(body)
				post_reply(root, body)
			end)
		end,
		on_delete = function(comment, close)
			if not comment then
				notify(vim.log.levels.WARN, "Move cursor onto a comment first")
				return
			end
			close()
			delete_comment(comment)
		end,
	})
end

local group = vim.api.nvim_create_augroup("bitbucket_pr_comment_signs", { clear = true })

vim.api.nvim_create_autocmd("User", {
	group = group,
	pattern = "CodeDiffVirtualFileLoaded",
	callback = function(event)
		local tabpage = event.data and event.data.tabpage or vim.api.nvim_get_current_tabpage()
		show_cached(tabpage)
	end,
})

vim.api.nvim_create_autocmd("User", {
	group = group,
	pattern = "CodeDiffFileSelect",
	callback = function(event)
		local tabpage = event.data and event.data.tabpage or vim.api.nvim_get_current_tabpage()
		local session = current_codediff_session(tabpage)
		if session_has_revision(session) and parse_origin(session.git_root) then
			refresh(tabpage)
		end
		vim.defer_fn(function()
			show_cached(tabpage)
		end, 100)
	end,
})

vim.api.nvim_create_autocmd("WinEnter", {
	group = group,
	callback = function()
		if cached_comments and #cached_comments > 0 then
			vim.schedule(function()
				show_cached(vim.api.nvim_get_current_tabpage())
			end)
		end
	end,
})

function M.add_comment_visual()
	add_comment(get_visual_diff_context, true)
end

function M.add_comment_line()
	add_comment(get_current_line_diff_context, true)
end

function M.add_pending_comment_visual()
	add_comment(get_visual_diff_context, true)
end

function M.add_pending_comment_line()
	add_comment(get_current_line_diff_context, true)
end

function M.add_instant_comment_visual()
	add_comment(get_visual_diff_context, false)
end

function M.add_instant_comment_line()
	add_comment(get_current_line_diff_context, false)
end

function M.view_thread()
	view_thread()
end

function M.open_pr()
	local url = cached_pr and cached_pr.link and cached_pr.link.html or nil
	if not url or url == "" then
		notify(vim.log.levels.WARN, "No PR URL cached")
		return
	end
	vim.ui.open(url)
end

return M
