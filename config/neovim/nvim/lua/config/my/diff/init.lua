if not vim.g.use_codediff then
	return
end

local comments_ui = require("config.my.diff.comments")

local providers = {
	require("config.my.diff.bitbucket-comments"),
	require("config.my.diff.github-comments"),
}

local ns = vim.api.nvim_create_namespace("diff_pr_comments")
local state = {
	provider = nil,
	pr = nil,
	comments = {},
	diff_files = {},
	session_key = nil,
	loading_key = nil,
	placed_sign_keys = {},
}

local function notify(level, msg)
	vim.notify("[PR comments] " .. tostring(msg), level)
end

local function current_session(tabpage)
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

local function session_key(session, provider_name)
	if not session_has_revision(session) then
		return nil
	end
	local root = tostring(session.git_root or "")
	local revision = tostring(session.modified_revision or "")
	if root == "" then
		return nil
	end
	return table.concat({ provider_name or "", root, revision }, ":")
end

local function provider_for(tabpage)
	local session = current_session(tabpage)
	if not session then
		return nil, nil
	end
	for _, mod in ipairs(providers) do
		if mod.can_handle and mod.can_handle(session) then
			return mod, session
		end
	end
	return nil, session
end

local function tabpage_from_event(event)
	return event and event.data and event.data.tabpage or vim.api.nvim_get_current_tabpage()
end

local function session_file_path(tabpage)
	local session = current_session(tabpage)
	if not session then
		return nil
	end

	local file_path = (session.original_path ~= "" and session.original_path)
		or (session.modified_path ~= "" and session.modified_path)
	if not file_path then
		return nil
	end

	local root = tostring(session.git_root or "")
	if root ~= "" then
		local prefix = root .. "/"
		if file_path:sub(1, #prefix) == prefix then
			file_path = file_path:sub(#prefix + 1)
		end
	end

	return file_path, session
end

local function resolve_line(comment, side)
	if side == "LEFT" then
		return comment.original_line or comment.line
	end
	return comment.line or comment.original_line
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

	local pending_count = 0
	for _, comment in ipairs(comments or {}) do
		if comment.pending then
			pending_count = pending_count + 1
		end
	end

	local sign_key = table.concat({
		tostring(bufnr),
		file_path,
		side,
		tostring(#(comments or {})),
		tostring(pending_count),
	}, ":")
	local existing = vim.api.nvim_buf_get_extmarks(bufnr, ns, 0, -1, {})
	if state.placed_sign_keys[bufnr] == sign_key and #existing > 0 then
		return
	end
	state.placed_sign_keys[bufnr] = sign_key
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

local function show_cached(tabpage)
	local provider, active_session = provider_for(tabpage)
	if
		not provider
		or provider ~= state.provider
		or session_key(active_session, provider.name) ~= state.session_key
	then
		return
	end

	local file_path, session = session_file_path(tabpage)
	if not file_path or not session then
		return
	end
	place_signs(session.original_bufnr, file_path, "LEFT", state.comments)
	place_signs(session.modified_bufnr, file_path, "RIGHT", state.comments)
end

local function reset_for(provider, key)
	state.provider = provider
	state.pr = nil
	state.comments = {}
	state.diff_files = {}
	state.session_key = key
	state.placed_sign_keys = {}
end

local function refresh(tabpage, opts)
	opts = opts or {}
	local provider, session = provider_for(tabpage)
	if not provider or not session_has_revision(session) then
		return
	end

	local key = session_key(session, provider.name)
	if opts.force ~= true and key and state.session_key == key and state.pr then
		show_cached(tabpage)
		return
	end
	if key and state.loading_key == key then
		return
	end

	state.loading_key = key
	reset_for(provider, key)
	notify(vim.log.levels.INFO, "Loading PR comments...")

	provider.find_pr(session, function(pr, pr_err)
		if state.loading_key ~= key then
			return
		end
		if pr_err then
			state.loading_key = nil
			notify(vim.log.levels.WARN, pr_err)
			return
		end
		if not pr then
			state.loading_key = nil
			notify(vim.log.levels.WARN, "No PR found")
			return
		end

		state.pr = pr
		local loaded = {
			diff = false,
			comments = false,
		}

		local function finish()
			if not loaded.diff or not loaded.comments then
				return
			end
			state.loading_key = nil
			show_cached(tabpage)
			notify(vim.log.levels.INFO, ("Loaded %d PR comments"):format(#state.comments))
		end

		provider.fetch_diff_files(pr, function(files)
			if state.session_key == key then
				state.diff_files = files or {}
				loaded.diff = true
				finish()
			end
		end)

		provider.fetch_comments(pr, function(comments, comments_err)
			if comments_err then
				state.loading_key = nil
				state.pr = nil
				state.session_key = nil
				notify(vim.log.levels.WARN, comments_err)
				return
			end
			state.comments = comments or {}
			loaded.comments = true
			finish()
		end)
	end)
end

local function parse_hunks(file)
	if not file then
		return {}
	end
	if type(file.hunks) == "table" then
		local out = {}
		for _, hunk in ipairs(file.hunks) do
			local header = hunk.header or hunk
			local left_start, left_count, right_start, right_count =
				tostring(header):match("@@ %-(%d+),?(%d*) %+(%d+),?(%d*) @@")
			if left_start then
				table.insert(out, {
					left_start = tonumber(left_start),
					left_count = tonumber(left_count) or 1,
					right_start = tonumber(right_start),
					right_count = tonumber(right_count) or 1,
				})
			end
		end
		return out
	end

	local out = {}
	for left_start, left_count, right_start, right_count in
		tostring(file.patch or ""):gmatch("@@ %-(%d+),?(%d*) %+(%d+),?(%d*) @@")
	do
		table.insert(out, {
			left_start = tonumber(left_start),
			left_count = tonumber(left_count) or 1,
			right_start = tonumber(right_start),
			right_count = tonumber(right_count) or 1,
		})
	end
	return out
end

local function lines_in_diff(file_path, start_line, end_line, side)
	local file = state.diff_files[file_path]
	if not file then
		return false
	end

	for _, hunk in ipairs(parse_hunks(file)) do
		local hunk_start = side == "LEFT" and hunk.left_start or hunk.right_start
		local hunk_count = side == "LEFT" and hunk.left_count or hunk.right_count
		local hunk_end = hunk_start + hunk_count - 1
		if start_line >= hunk_start and end_line <= hunk_end then
			return true
		end
	end
	return false
end

local function current_context()
	local file_path, session = session_file_path()
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
	return {
		file_path = file_path,
		start_line = line,
		end_line = line,
		side = side,
	}
end

local function visual_context()
	local start_line = vim.fn.line("v")
	local end_line = vim.fn.line(".")
	if start_line > end_line then
		start_line, end_line = end_line, start_line
	end
	vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "x", false)

	local context = current_context()
	if not context then
		return nil
	end
	context.start_line = start_line
	context.end_line = end_line
	return context
end

local function get_thread_at_cursor()
	local context = current_context()
	if not context then
		return nil
	end

	local root
	for _, comment in ipairs(state.comments) do
		if comment.path == context.file_path and not comment.in_reply_to_id then
			local side = comment.side or "RIGHT"
			if side == context.side and resolve_line(comment, side) == context.start_line then
				root = comment
				break
			end
		end
	end
	if not root then
		return nil, {}, context
	end

	local replies = {}
	for _, comment in ipairs(state.comments) do
		if comment.in_reply_to_id == root.id then
			table.insert(replies, comment)
		end
	end
	table.sort(replies, function(a, b)
		return tostring(a.id) < tostring(b.id)
	end)

	return root, replies, context
end

local function ensure_ready()
	local provider = provider_for()
	if not provider or provider ~= state.provider or not state.pr then
		notify(vim.log.levels.WARN, "No PR data cached. Open CodeDiff for a PR first.")
		return nil
	end
	return provider
end

local function open_comment_popup(title, context, on_submit)
	comments_ui.input({
		title = (" %s: %s:%d-%d (%s) "):format(
			title,
			context.file_path,
			context.start_line,
			context.end_line,
			context.side
		),
		on_empty = function()
			notify(vim.log.levels.WARN, "Empty comment, cancelled")
		end,
		on_submit = on_submit,
	})
end

local function add_comment(context_fn, pending)
	local provider = ensure_ready()
	if not provider then
		return
	end

	local context = context_fn()
	if not context then
		return
	end
	if not lines_in_diff(context.file_path, context.start_line, context.end_line, context.side) then
		notify(vim.log.levels.WARN, "Selected lines are outside the diff")
		return
	end

	local title = pending and "Pending PR comment" or "PR comment"
	open_comment_popup(title, context, function(body)
		provider.add_comment(state.pr, context, body, { pending = pending }, function(_, err)
			if err then
				notify(vim.log.levels.ERROR, err)
				return
			end
			notify(vim.log.levels.INFO, pending and "Pending comment added" or "Comment posted")
			refresh(nil, { force = true })
		end)
	end)
end

local function view_thread()
	local provider = ensure_ready()
	if not provider then
		return
	end

	local root, replies, context = get_thread_at_cursor()
	if not root then
		notify(vim.log.levels.WARN, "No PR thread at cursor")
		return
	end

	local thread_comments = { root }
	vim.list_extend(thread_comments, replies)
	comments_ui.open(thread_comments, {
		title = (" Thread: %s:%d (%s) "):format(context.file_path, context.start_line, context.side),
		on_reply = function(_, close)
			close()
			open_comment_popup("Reply", context, function(body)
				provider.reply(state.pr, root, body, function(_, err)
					if err then
						notify(vim.log.levels.ERROR, err)
						return
					end
					notify(vim.log.levels.INFO, "Reply posted")
					refresh(nil, { force = true })
				end)
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
				provider.delete_comment(state.pr, selected, function(_, err)
					if err then
						notify(vim.log.levels.ERROR, err)
						return
					end
					close()
					notify(vim.log.levels.INFO, selected.in_reply_to_id and "Reply deleted" or "Thread deleted")
					refresh(nil, { force = true })
				end)
			end)
		end,
	})
end

vim.keymap.set("v", "<leader>gcc", function()
	add_comment(visual_context, true)
end, { desc = "Add pending PR comment" })

vim.keymap.set("n", "<leader>gcc", function()
	add_comment(current_context, true)
end, { desc = "Add pending PR comment" })

vim.keymap.set("v", "<leader>gcC", function()
	add_comment(visual_context, false)
end, { desc = "Add PR comment" })

vim.keymap.set("n", "<leader>gcC", function()
	add_comment(current_context, false)
end, { desc = "Add PR comment" })

vim.keymap.set("n", "<leader>gcv", view_thread, { desc = "View PR thread" })

vim.keymap.set("n", "gx", function()
	local provider = provider_for()
	if provider and provider == state.provider and state.pr and provider.pr_url then
		local url = provider.pr_url(state.pr)
		if url and url ~= "" then
			vim.ui.open(url)
			return
		end
	end
	vim.cmd.normal({ "gx", bang = true })
end, { desc = "Open PR" })

local group = vim.api.nvim_create_augroup("my_diff_comments", { clear = true })

vim.api.nvim_create_autocmd("User", {
	group = group,
	pattern = "CodeDiffVirtualFileLoaded",
	callback = function(event)
		show_cached(tabpage_from_event(event))
	end,
})

vim.api.nvim_create_autocmd("User", {
	group = group,
	pattern = "CodeDiffFileSelect",
	callback = function(event)
		local tabpage = tabpage_from_event(event)
		refresh(tabpage)
		vim.defer_fn(function()
			show_cached(tabpage)
		end, 100)
	end,
})

vim.api.nvim_create_autocmd("WinEnter", {
	group = group,
	callback = function()
		local tabpage = vim.api.nvim_get_current_tabpage()
		vim.schedule(function()
			show_cached(tabpage)
		end)
	end,
})
