-- Thanks to this amazing guy: https://github.com/fredrikaverpil/dotfiles/blob/main/nvim-fredrik/plugin/github_comments.lua
if not vim.g.use_codediff then
	return
end

local comments_ui = require("config.my.diff.comments")

local ns = vim.api.nvim_create_namespace("pr_comments")

local cached_comments = {}
local cached_pending_review_ids = {}
local cached_diff_files = {}
local cached_pr_number = nil
local cached_pr_node_id = nil
local cached_pending_review_node_id = nil
local cached_pending_review_node_ids = {}

local function notify(level, msg)
	vim.notify("[GitHub comments] " .. tostring(msg), level)
end

local function shell(cmd)
	return { "bash", "-c", cmd }
end

local function trim(value)
	if type(value) ~= "string" then
		return ""
	end
	return vim.trim(value)
end

-- --------------------------------------------------------------------------
-- Sign column: show comment indicators
-- --------------------------------------------------------------------------

---@return integer?
local function resolve_line(comment, side)
	if side == "LEFT" then
		local original = comment.original_line
		if original and original ~= vim.NIL then
			return original
		end
	end

	local line = comment.line
	if line and line ~= vim.NIL then
		return line
	end

	local fallback = side == "LEFT" and comment.line or comment.original_line
	if fallback and fallback ~= vim.NIL then
		return fallback
	end
end

---@param comments table[]
---@param file_path string
---@return table<string, integer>
local function count_threads(comments, file_path)
	local counts = {}
	for _, comment in ipairs(comments) do
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

---@param pending_review_ids table<integer, boolean>
local function place_signs(bufnr, file_path, side, comments, pending_review_ids)
	if not vim.api.nvim_buf_is_valid(bufnr) then
		return
	end

	for _, win in ipairs(vim.fn.win_findbuf(bufnr)) do
		if vim.api.nvim_win_is_valid(win) then
			vim.wo[win].signcolumn = "yes:1"
		end
	end

	vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)

	local threads = count_threads(comments, file_path)
	local line_count = vim.api.nvim_buf_line_count(bufnr)
	local line_has_published = {}
	local line_has_pending = {}

	for _, comment in ipairs(comments) do
		if comment.path == file_path and not comment.in_reply_to_id then
			local comment_side = comment.side or "RIGHT"
			if comment_side == side then
				local line = resolve_line(comment, comment_side)
				if line then
					local review_id = comment.pull_request_review_id
					if review_id and pending_review_ids[review_id] then
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
				local icon = line_has_published[line] and "" or ""
				vim.api.nvim_buf_set_extmark(bufnr, ns, line - 1, 0, {
					sign_text = icon,
					sign_hl_group = "DiagnosticInfo",
					priority = 1000,
				})
			end
		end
	end
end

---@return string? file_path
---@return table? session
local function get_session_file_path(tabpage)
	tabpage = tabpage or vim.api.nvim_get_current_tabpage()
	local ok, lifecycle = pcall(require, "codediff.ui.lifecycle")
	if not ok then
		return nil
	end

	local session = lifecycle.get_session(tabpage)
	if not session then
		return nil
	end

	local file_path = (session.original_path ~= "" and session.original_path)
		or (session.modified_path ~= "" and session.modified_path)
	if not file_path then
		return nil
	end

	local git_root = vim.fn.trim(vim.fn.system("git rev-parse --show-toplevel"))
	if git_root ~= "" then
		local prefix = git_root .. "/"
		if file_path:sub(1, #prefix) == prefix then
			file_path = file_path:sub(#prefix + 1)
		end
	end

	return file_path, session
end

---@param pending_review_ids table<integer, boolean>?
local function show_signs_for_session(comments, pending_review_ids, tabpage)
	local file_path, session = get_session_file_path(tabpage)
	if not file_path or not session then
		return
	end

	place_signs(session.original_bufnr, file_path, "LEFT", comments, pending_review_ids or {})
	place_signs(session.modified_bufnr, file_path, "RIGHT", comments, pending_review_ids or {})
end

local function parse_hunk_ranges(patch)
	if not patch then
		return {}
	end

	local hunks = {}
	for left_start, left_count, right_start, right_count in patch:gmatch("@@ %-(%d+),?(%d*) %+(%d+),?(%d*) @@") do
		table.insert(hunks, {
			left_start = tonumber(left_start),
			left_count = tonumber(left_count) or 1,
			right_start = tonumber(right_start),
			right_count = tonumber(right_count) or 1,
		})
	end
	return hunks
end

-- Pending review comments returned by GitHub's review-specific REST endpoint
-- have diff positions but no line/original_line fields. Convert that position
-- back into a file line so the sign can be placed.
local function line_from_diff_hunk(diff_hunk, position, side)
	if type(diff_hunk) ~= "string" or type(position) ~= "number" then
		return nil
	end

	local old_line
	local new_line
	local diff_position = 0

	for raw_line in diff_hunk:gmatch("[^\r\n]+") do
		local old_start, new_start = raw_line:match("^@@ %-(%d+),?%d* %+(%d+),?%d* @@")
		if old_start and new_start then
			old_line = tonumber(old_start)
			new_line = tonumber(new_start)
		elseif old_line and new_line then
			diff_position = diff_position + 1

			local prefix = raw_line:sub(1, 1)
			local mapped_line
			if prefix == "+" then
				mapped_line = side == "RIGHT" and new_line or nil
				new_line = new_line + 1
			elseif prefix == "-" then
				mapped_line = side == "LEFT" and old_line or nil
				old_line = old_line + 1
			elseif prefix == " " then
				mapped_line = side == "LEFT" and old_line or new_line
				old_line = old_line + 1
				new_line = new_line + 1
			end

			if diff_position == position then
				return mapped_line
			end
		end
	end
end

local function lines_in_diff(file_path, start_line, end_line, side)
	local file_entry = cached_diff_files[file_path]
	if not file_entry then
		return false
	end

	for _, hunk in ipairs(parse_hunk_ranges(file_entry.patch)) do
		local hunk_start = side == "LEFT" and hunk.left_start or hunk.right_start
		local hunk_count = side == "LEFT" and hunk.left_count or hunk.right_count
		local hunk_end = hunk_start + hunk_count - 1

		if start_line >= hunk_start and end_line <= hunk_end then
			return true
		end
	end

	return false
end

-- --------------------------------------------------------------------------
-- GitHub API helpers
-- --------------------------------------------------------------------------

---@param query string GraphQL query
---@param variables table? GraphQL variables
---@param callback fun(data: table)
---@param on_error fun(msg: string)?
local function graphql(query, variables, callback, on_error)
	local payload = vim.json.encode({ query = query, variables = variables or {} })
	local stdout_chunks = {}
	local stderr_chunks = {}

	local job_id = vim.fn.jobstart(shell("gh api graphql --input -"), {
		stdout_buffered = true,
		stderr_buffered = true,
		on_stdout = function(_, data)
			if data then
				table.insert(stdout_chunks, table.concat(data, "\n"))
			end
		end,
		on_stderr = function(_, data)
			if data then
				table.insert(stderr_chunks, table.concat(data, "\n"))
			end
		end,
		on_exit = function(_, exit_code)
			vim.schedule(function()
				local raw = table.concat(stdout_chunks, "")
				if exit_code ~= 0 or raw == "" then
					if on_error then
						on_error(table.concat(stderr_chunks, ""))
					end
					return
				end

				local ok, result = pcall(vim.json.decode, raw)
				if not ok then
					if on_error then
						on_error("Failed to decode GraphQL response")
					end
					return
				end

				if result.errors then
					if on_error then
						on_error(vim.json.encode(result.errors))
					end
					return
				end

				callback(result.data or {})
			end)
		end,
	})

	vim.fn.chansend(job_id, payload)
	vim.fn.chanclose(job_id, "stdin")
end

local function fetch_diff_files(pr_number)
	local stdout_chunks = {}
	local cmd = ("gh api repos/{owner}/{repo}/pulls/%s/files --paginate"):format(pr_number)

	vim.fn.jobstart(shell(cmd), {
		stdout_buffered = true,
		on_stdout = function(_, data)
			if data then
				table.insert(stdout_chunks, table.concat(data, "\n"))
			end
		end,
		on_exit = function(_, exit_code)
			vim.schedule(function()
				if exit_code ~= 0 then
					return
				end

				local raw = table.concat(stdout_chunks, "")
				local ok, files = pcall(vim.json.decode, raw)
				if not ok or type(files) ~= "table" then
					return
				end

				local by_path = {}
				for _, file in ipairs(files) do
					by_path[file.filename] = file
				end
				cached_diff_files = by_path
			end)
		end,
	})
end

local function fetch_review_comments(pr_number, callback)
	local stdout_chunks = {}
	local cmd = ("gh api repos/{owner}/{repo}/pulls/%s/comments --paginate"):format(pr_number)

	vim.fn.jobstart(shell(cmd), {
		stdout_buffered = true,
		on_stdout = function(_, data)
			if data then
				table.insert(stdout_chunks, table.concat(data, "\n"))
			end
		end,
		on_exit = function(_, exit_code)
			vim.schedule(function()
				if exit_code ~= 0 then
					callback({})
					return
				end

				local ok, items = pcall(vim.json.decode, table.concat(stdout_chunks, ""))
				if not ok or type(items) ~= "table" then
					callback({})
					return
				end

				local comments = {}
				for _, comment in ipairs(items) do
					local side = comment.side or "RIGHT"
					table.insert(comments, {
						id = comment.id,
						node_id = comment.node_id,
						path = comment.path,
						body = comment.body,
						line = comment.line or line_from_diff_hunk(comment.diff_hunk, comment.position, side),
						original_line = comment.original_line
							or line_from_diff_hunk(comment.diff_hunk, comment.original_position, side),
						side = side,
						pull_request_review_id = comment.pull_request_review_id,
						in_reply_to_id = comment.in_reply_to_id,
						user = comment.user and comment.user.login,
						created_at = comment.created_at,
					})
				end

				callback(comments)
			end)
		end,
	})
end

local function merge_comments(...)
	local comments = {}
	local seen = {}

	for _, list in ipairs({ ... }) do
		for _, comment in ipairs(list or {}) do
			local key = comment.id
				or table.concat({
					comment.path or "",
					comment.side or "",
					tostring(comment.line or ""),
					comment.body or "",
				}, ":")

			if not seen[key] then
				seen[key] = true
				table.insert(comments, comment)
			end
		end
	end

	return comments
end

local function fetch_review_comments_for_review(pr_number, review_id, callback)
	local stdout_chunks = {}
	local cmd = ("gh api repos/{owner}/{repo}/pulls/%s/reviews/%s/comments --paginate"):format(pr_number, review_id)

	vim.fn.jobstart(shell(cmd), {
		stdout_buffered = true,
		on_stdout = function(_, data)
			if data then
				table.insert(stdout_chunks, table.concat(data, "\n"))
			end
		end,
		on_exit = function(_, exit_code)
			vim.schedule(function()
				if exit_code ~= 0 then
					callback({})
					return
				end

				local ok, items = pcall(vim.json.decode, table.concat(stdout_chunks, ""))
				if not ok or type(items) ~= "table" then
					callback({})
					return
				end

				local comments = {}
				for _, comment in ipairs(items) do
					local side = comment.side or "RIGHT"
					table.insert(comments, {
						id = comment.id,
						node_id = comment.node_id,
						path = comment.path,
						body = comment.body,
						line = comment.line or line_from_diff_hunk(comment.diff_hunk, comment.position, side),
						original_line = comment.original_line
							or line_from_diff_hunk(comment.diff_hunk, comment.original_position, side),
						side = side,
						pull_request_review_id = comment.pull_request_review_id,
						in_reply_to_id = comment.in_reply_to_id,
						user = comment.user and comment.user.login,
						created_at = comment.created_at,
					})
				end

				callback(comments)
			end)
		end,
	})
end

local function fetch_pending_review_comments(pr_number, pending_review_ids, callback)
	local review_ids = vim.tbl_keys(pending_review_ids or {})

	if #review_ids == 0 then
		callback({})
		return
	end

	local remaining = #review_ids
	local all_comments = {}

	for _, review_id in ipairs(review_ids) do
		fetch_review_comments_for_review(pr_number, review_id, function(comments)
			all_comments = merge_comments(all_comments, comments)
			remaining = remaining - 1

			if remaining == 0 then
				callback(all_comments)
			end
		end)
	end
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

local function repo_slug_from_root(root, callback)
	vim.system({
		"gh",
		"repo",
		"view",
		"--json",
		"owner,name",
		"--jq",
		'.owner.login + "\\n" + .name',
	}, { text = true, cwd = root }, function(result)
		vim.schedule(function()
			if not result or result.code ~= 0 then
				callback(nil, nil)
				return
			end

			local repo_info = vim.split(trim(result.stdout), "\n", { plain = true, trimempty = true })
			callback(repo_info[1], repo_info[2])
		end)
	end)
end

local function pr_from_codediff_revision(tabpage, callback)
	local session = current_codediff_session(tabpage)
	if not session or not session.git_root then
		callback(nil, nil, nil)
		return
	end

	local sha = tostring(session.modified_revision or "")
	if sha == "" or sha == "WORKING" or sha == "STAGED" then
		callback(nil, nil, nil)
		return
	end

	repo_slug_from_root(session.git_root, function(owner, repo)
		if not owner or not repo then
			callback(nil, nil, nil)
			return
		end

		local slug = owner .. "/" .. repo
		vim.system({
			"gh",
			"api",
			"repos/" .. slug .. "/commits/" .. sha .. "/pulls",
			"-H",
			"Accept: application/vnd.github+json",
		}, { text = true, cwd = session.git_root }, function(result)
			vim.schedule(function()
				if not result or result.code ~= 0 then
					callback(nil, nil, nil)
					return
				end

				local ok, pulls = pcall(vim.json.decode, result.stdout or "")
				if not ok or type(pulls) ~= "table" or #pulls == 0 then
					callback(nil, nil, nil)
					return
				end

				local selected = pulls[1]
				for _, pr in ipairs(pulls) do
					if pr.state == "open" then
						selected = pr
						break
					end
				end

				local pr_number = tostring(selected.number or "")
				if pr_number == "" then
					callback(nil, nil, nil)
					return
				end

				callback(pr_number, owner, repo)
			end)
		end)
	end)
end

local function wait_for_codediff_pr(tabpage, attempt, callback)
	attempt = attempt or 1
	pr_from_codediff_revision(tabpage, function(pr_number, owner, repo)
		if pr_number then
			callback(pr_number, owner, repo)
			return
		end

		if attempt >= 12 then
			callback(nil, nil, nil)
			return
		end

		vim.defer_fn(function()
			wait_for_codediff_pr(tabpage, attempt + 1, callback)
		end, 100)
	end)
end

local function pr_from_current_branch(callback)
	vim.system({ "gh", "pr", "view", "--json", "number", "--jq", ".number" }, { text = true }, function(pr_result)
		vim.schedule(function()
			local pr_number = pr_result and pr_result.code == 0 and trim(pr_result.stdout) or ""
			if pr_number == "" then
				callback(nil)
				return
			end

			repo_slug_from_root(nil, function(owner, repo)
				callback(pr_number, owner, repo)
			end)
		end)
	end)
end

local function fetch_pr_data(callback, tabpage)
	local function add_visible_comments(comments)
		cached_comments = merge_comments(cached_comments, comments)
		callback(cached_comments, cached_pending_review_ids)
	end

	local query = [[
query($owner: String!, $repo: String!, $pr: Int!) {
  repository(owner: $owner, name: $repo) {
    pullRequest(number: $pr) {
      id
      reviews(first: 100) {
        nodes { id databaseId state }
      }
    }
  }
}
]]

	local function fetch_with_pr(pr_number, owner, repo)
		cached_pr_number = pr_number
		cached_comments = {}
		cached_pending_review_ids = {}
		cached_pending_review_node_id = nil
		cached_pending_review_node_ids = {}
		fetch_diff_files(pr_number)
		notify(vim.log.levels.INFO, "Loading PR comments...")

		local loaded = {
			review_comments = false,
			pending_comments = false,
			notified = false,
		}

		local function notify_loaded()
			if loaded.notified or not loaded.review_comments or not loaded.pending_comments then
				return
			end

			loaded.notified = true
			notify(vim.log.levels.INFO, ("Loaded %d PR comments"):format(#cached_comments))
		end

		fetch_review_comments(pr_number, function(comments)
			add_visible_comments(comments)
			loaded.review_comments = true
			notify_loaded()
		end)

		if not owner or not repo then
			notify(vim.log.levels.WARN, "Failed to detect GitHub repository")
			return
		end

		graphql(query, { owner = owner, repo = repo, pr = tonumber(pr_number) }, function(data)
			local pr = data.repository and data.repository.pullRequest
			if not pr then
				loaded.pending_comments = true
				notify_loaded()
				return
			end

			cached_pr_node_id = pr.id
			cached_pending_review_node_id = nil
			cached_pending_review_node_ids = {}

			local pending = {}
			for _, review in ipairs(pr.reviews and pr.reviews.nodes or {}) do
				if review.state == "PENDING" then
					pending[review.databaseId] = true
					cached_pending_review_node_id = review.id
					cached_pending_review_node_ids[review.databaseId] = review.id
				end
			end
			cached_pending_review_ids = pending

			fetch_pending_review_comments(pr_number, cached_pending_review_ids, function(pending_comments)
				add_visible_comments(pending_comments)
				loaded.pending_comments = true
				notify_loaded()
			end)
		end, function(err)
			notify(vim.log.levels.WARN, "Failed to fetch pending review ids: " .. err)
			loaded.pending_comments = true
			notify_loaded()
		end)
	end

	wait_for_codediff_pr(tabpage, 1, function(pr_number, owner, repo)
		if pr_number and owner and repo then
			fetch_with_pr(pr_number, owner, repo)
			return
		end

		pr_from_current_branch(function(branch_pr, branch_owner, branch_repo)
			if not branch_pr or not branch_owner or not branch_repo then
				notify(vim.log.levels.WARN, "No GitHub PR found")
				return
			end

			fetch_with_pr(branch_pr, branch_owner, branch_repo)
		end)
	end)
end

local function refresh(tabpage)
	local target_tabpage = tabpage or vim.api.nvim_get_current_tabpage()
	fetch_pr_data(function(comments, pending)
		show_signs_for_session(comments, pending, target_tabpage)
	end, target_tabpage)
end

local function show_cached(tabpage)
	local target_tabpage = tabpage or vim.api.nvim_get_current_tabpage()
	if cached_comments and #cached_comments > 0 then
		show_signs_for_session(cached_comments, cached_pending_review_ids, target_tabpage)
	end
end

-- --------------------------------------------------------------------------
-- Thread helpers
-- --------------------------------------------------------------------------

--- Returns the root comment and replies at the cursor position, plus context.
--- When multiple root comments exist on the same line, the first is used.
---@return table? root
---@return table[] replies
---@return string? file_path
---@return string? side
---@return integer? cursor_line
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
		return a.id < b.id
	end)

	return root, replies, file_path, side, cursor_line
end

-- --------------------------------------------------------------------------
-- Posting comments
-- --------------------------------------------------------------------------

---@return string? file_path
---@return integer? start_line
---@return integer? end_line
---@return string? side "LEFT"|"RIGHT"
local function get_visual_diff_context()
	local start_line = vim.fn.line("v")
	local end_line = vim.fn.line(".")
	if start_line > end_line then
		start_line, end_line = end_line, start_line
	end
	vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "x", false)

	local ok, lifecycle = pcall(require, "codediff.ui.lifecycle")
	if not ok then
		notify(vim.log.levels.WARN, "CodeDiff lifecycle is unavailable")
		return nil
	end

	local session = lifecycle.get_session(vim.api.nvim_get_current_tabpage())
	if not session then
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

	local file_path = (session.original_path ~= "" and session.original_path)
		or (session.modified_path ~= "" and session.modified_path)
	if not file_path then
		notify(vim.log.levels.WARN, "No file path in CodeDiff session")
		return nil
	end

	local git_root = vim.fn.trim(vim.fn.system("git rev-parse --show-toplevel"))
	if git_root ~= "" then
		local prefix = git_root .. "/"
		if file_path:sub(1, #prefix) == prefix then
			file_path = file_path:sub(#prefix + 1)
		end
	end

	return file_path, start_line, end_line, side
end

---@return string? file_path
---@return integer? start_line
---@return integer? end_line
---@return string? side "LEFT"|"RIGHT"
local function get_current_line_diff_context()
	local ok, lifecycle = pcall(require, "codediff.ui.lifecycle")
	if not ok then
		notify(vim.log.levels.WARN, "CodeDiff lifecycle is unavailable")
		return nil
	end

	local session = lifecycle.get_session(vim.api.nvim_get_current_tabpage())
	if not session then
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

	local file_path = (session.original_path ~= "" and session.original_path)
		or (session.modified_path ~= "" and session.modified_path)
	if not file_path then
		notify(vim.log.levels.WARN, "No file path in CodeDiff session")
		return nil
	end

	local git_root = vim.fn.trim(vim.fn.system("git rev-parse --show-toplevel"))
	if git_root ~= "" then
		local prefix = git_root .. "/"
		if file_path:sub(1, #prefix) == prefix then
			file_path = file_path:sub(#prefix + 1)
		end
	end

	local line = vim.fn.line(".")
	return file_path, line, line, side
end

local function open_comment_popup(title_prefix, file_path, start_line, end_line, side, on_submit)
	comments_ui.input({
		title = (" %s: %s:%d-%d (%s) "):format(title_prefix, file_path, start_line, end_line, side),
		on_empty = function()
			notify(vim.log.levels.WARN, "Empty comment, cancelled")
		end,
		on_submit = on_submit,
	})
end

local function thread_variables(file_path, start_line, end_line, side, body)
	local vars = {
		path = file_path,
		body = body,
		line = end_line,
		side = side,
	}
	if start_line ~= end_line then
		vars.startSide = side
		vars.startLine = start_line
	end
	return vars
end

local function post_review_comment(file_path, start_line, end_line, side, body)
	local variables = thread_variables(file_path, start_line, end_line, side, body)

	local thread_query = [[
mutation($pullRequestReviewId: ID!, $path: String!, $body: String!, $line: Int!, $side: DiffSide!, $startSide: DiffSide, $startLine: Int) {
  addPullRequestReviewThread(input: {
    pullRequestReviewId: $pullRequestReviewId
    path: $path
    body: $body
    line: $line
    side: $side
    startSide: $startSide
    startLine: $startLine
  }) {
    thread { id }
  }
}
]]

	local function add_thread(review_node_id, is_new_review)
		variables.pullRequestReviewId = review_node_id
		graphql(thread_query, variables, function()
			local msg = is_new_review and "Review started" or "Review comment added"
			notify(vim.log.levels.INFO, ("%s on %s:%d-%d"):format(msg, file_path, start_line, end_line))
			refresh()
		end, function(err)
			notify(vim.log.levels.ERROR, "Failed to add review thread: " .. err)
		end)
	end

	if cached_pending_review_node_id then
		add_thread(cached_pending_review_node_id, false)
		return
	end

	if not cached_pr_node_id then
		notify(vim.log.levels.ERROR, "No PR data cached. Open CodeDiff for a PR first.")
		return
	end

	local create_query = [[
mutation($pullRequestId: ID!) {
  addPullRequestReview(input: { pullRequestId: $pullRequestId }) {
    pullRequestReview { id }
  }
}
]]

	graphql(create_query, { pullRequestId = cached_pr_node_id }, function(data)
		local review_id = data.addPullRequestReview
			and data.addPullRequestReview.pullRequestReview
			and data.addPullRequestReview.pullRequestReview.id
		if not review_id then
			notify(vim.log.levels.ERROR, "Failed to create pending review")
			return
		end
		cached_pending_review_node_id = review_id
		add_thread(review_id, true)
	end, function(err)
		notify(vim.log.levels.ERROR, "Failed to create pending review: " .. err)
	end)
end

local function post_reply(root_comment, body)
	if not cached_pr_number then
		notify(vim.log.levels.ERROR, "No PR data cached. Open CodeDiff for a PR first.")
		return
	end

	if cached_pending_review_ids[root_comment.pull_request_review_id] then
		local review_node_id = cached_pending_review_node_ids[root_comment.pull_request_review_id]
			or cached_pending_review_node_id
		if not review_node_id or not root_comment.node_id then
			notify(vim.log.levels.ERROR, "Missing pending review node data. Refresh CodeDiff and try again.")
			return
		end

		local query = [[
mutation($pullRequestReviewId: ID!, $inReplyTo: ID!, $body: String!) {
  addPullRequestReviewComment(input: {
    pullRequestReviewId: $pullRequestReviewId
    inReplyTo: $inReplyTo
    body: $body
  }) {
    comment { id }
  }
}
]]

		graphql(query, {
			pullRequestReviewId = review_node_id,
			inReplyTo = root_comment.node_id,
			body = body,
		}, function()
			notify(vim.log.levels.INFO, "Reply added to pending review")
			refresh()
		end, function(err)
			notify(vim.log.levels.ERROR, "Failed to post pending reply: " .. err)
		end)
		return
	end

	local payload = vim.json.encode({ body = body })
	local stderr_chunks = {}
	local cmd = ("gh api repos/{owner}/{repo}/pulls/%s/comments/%s/replies --method POST --input -"):format(
		cached_pr_number,
		root_comment.id
	)

	local job_id = vim.fn.jobstart(shell(cmd), {
		stderr_buffered = true,
		on_stderr = function(_, data)
			if data then
				table.insert(stderr_chunks, table.concat(data, "\n"))
			end
		end,
		on_exit = function(_, exit_code)
			vim.schedule(function()
				if exit_code ~= 0 then
					notify(vim.log.levels.ERROR, "Failed to post reply: " .. table.concat(stderr_chunks, ""))
					return
				end
				notify(vim.log.levels.INFO, "Reply posted")
				refresh()
			end)
		end,
	})

	vim.fn.chansend(job_id, payload)
	vim.fn.chanclose(job_id, "stdin")
end

local function remove_cached_comment(comment_id)
	if not comment_id then
		return
	end

	local remaining = {}
	for _, comment in ipairs(cached_comments) do
		if comment.id ~= comment_id and comment.in_reply_to_id ~= comment_id then
			table.insert(remaining, comment)
		end
	end
	cached_comments = remaining
end

local function delete_comment(comment, on_done)
	if not comment or not comment.id then
		notify(vim.log.levels.ERROR, "No comment selected")
		return
	end

	local stderr_chunks = {}
	local cmd = ("gh api repos/{owner}/{repo}/pulls/comments/%s --method DELETE"):format(comment.id)

	vim.fn.jobstart(shell(cmd), {
		stderr_buffered = true,
		on_stderr = function(_, data)
			if data then
				table.insert(stderr_chunks, table.concat(data, "\n"))
			end
		end,
		on_exit = function(_, exit_code)
			vim.schedule(function()
				if exit_code ~= 0 then
					notify(vim.log.levels.ERROR, "Failed to delete comment: " .. table.concat(stderr_chunks, ""))
					return
				end

				remove_cached_comment(comment.id)
				notify(vim.log.levels.INFO, comment.in_reply_to_id and "Reply deleted" or "Thread deleted")
				if on_done then
					on_done()
				end
				refresh()
			end)
		end,
	})
end

local function open_thread_viewer(thread_comments, root_comment, file_path, side, cursor_line)
	comments_ui.open(thread_comments, {
		title = (" Thread: %s:%d (%s) "):format(file_path, cursor_line, side),
		on_reply = function(_, close)
			close()
			open_comment_popup("Reply", file_path, cursor_line, cursor_line, side, function(body)
				post_reply(root_comment, body)
			end)
		end,
		on_delete = function(selected, close)
			if not selected then
				notify(vim.log.levels.WARN, "Move cursor onto a comment first")
				return
			end

			local target = selected.in_reply_to_id and "reply" or "thread"
			vim.ui.input({ prompt = ("Delete %s? [y/N]: "):format(target) }, function(input)
				if type(input) ~= "string" or not input:match("^[yY]") then
					return
				end
				delete_comment(selected, close)
			end)
		end,
	})
end

local function pr_comment(context)
	local file_path, start_line, end_line, side = context()
	if not file_path then
		return
	end

	if not lines_in_diff(file_path, start_line, end_line, side) then
		notify(vim.log.levels.WARN, "Selected lines are outside the diff")
		return
	end

	local title = "Pending review comment"
	open_comment_popup(title, file_path, start_line, end_line, side, function(body)
		post_review_comment(file_path, start_line, end_line, side, body)
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
	open_thread_viewer(thread_comments, root, file_path, side, cursor_line)
end

-- --------------------------------------------------------------------------
-- Autocmds and keymaps
-- --------------------------------------------------------------------------

local group = vim.api.nvim_create_augroup("pr_comment_signs", { clear = true })

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

		if session_has_revision(session) then
			refresh(tabpage)
		end

		vim.defer_fn(function()
			show_cached(tabpage)
		end, 100)
	end,
})

vim.keymap.set("v", "<leader>gdc", function()
	pr_comment(get_visual_diff_context)
end, { desc = "Add pending PR comment" })

vim.keymap.set("n", "<leader>gdc", function()
	pr_comment(get_current_line_diff_context)
end, { desc = "Add pending PR comment" })

vim.keymap.set("n", "<leader>gdv", view_thread, { desc = "View PR thread" })
