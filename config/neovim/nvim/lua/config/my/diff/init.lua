if not vim.g.use_codediff then
	return
end

local keymaps = require("config.my.diff.keymaps")

---@class DiffState
---@field provider DiffCommentsProvider|nil
---@field pr DiffCommentsPR|nil
---@field comments DiffComment[]
---@field session_key string|nil
---@field loading boolean
local state = {
	provider = nil,
	pr = nil,
	comments = {},
	session_key = nil,
	loading = false,
}

---@type DiffCommentsProvider[]
local providers = {
	require("config.my.diff.provider.github"),
	require("config.my.diff.provider.bitbucket"),
}

local comment_icon = ""
local pending_icon = ""
local resolved_icon = "󰄳"

local thread_popup = require("config.my.diff.ui.thread")
local input_popup = require("config.my.diff.ui.input")

---@param opts { prompt: string, text: string|nil, on_submit: fun(body: string) }
local function prompt_body(opts)
	input_popup.open({
		title = " " .. opts.prompt:gsub(":%s*$", "") .. " ",
		text = opts.text,
		on_submit = opts.on_submit,
		on_empty = function()
			vim.notify("[PR comments] Empty, cancelled", vim.log.levels.WARN)
		end,
	})
end

local ns = vim.api.nvim_create_namespace("diff_pr_comments")

local function notify(level, msg)
	vim.notify("[PR comments] " .. tostring(msg), level)
end

--------------------------------------------------------------------------------
-- helpers
--------------------------------------------------------------------------------

---@param tabpage integer|nil
---@return DiffCommentsSession|nil
local function current_session(tabpage)
	local ok, lifecycle = pcall(require, "codediff.ui.lifecycle")
	if not ok then
		return nil
	end
	return lifecycle.get_session(tabpage or vim.api.nvim_get_current_tabpage())
end

---@param session DiffCommentsSession|nil
---@param provider_name string|nil
---@return string|nil
local function session_key(session, provider_name)
	if not session then
		return nil
	end
	local rev = tostring(session.modified_revision or "")
	if rev == "" or rev == "WORKING" or rev == "STAGED" then
		return nil
	end
	local root = tostring(session.git_root or "")
	if root == "" then
		return nil
	end
	return table.concat({ provider_name or "", root, rev }, ":")
end

---@param session DiffCommentsSession|nil
---@return DiffCommentsProvider|nil
local function provider_for(session)
	if not session then
		return nil
	end
	for _, p in ipairs(providers) do
		if p.can_handle(session) then
			return p
		end
	end
end

---@param tabpage integer|nil
---@return string|nil file_path, DiffCommentsSession|nil session
local function session_file_path(tabpage)
	local session = current_session(tabpage)
	if not session then
		return nil
	end
	local file_path = (session.original_path ~= "" and session.original_path)
		or (session.modified_path ~= "" and session.modified_path)
	if not file_path then
		return nil, session
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

--------------------------------------------------------------------------------
-- Rendering
--------------------------------------------------------------------------------

---@param bufnr integer
---@param file_path string
---@param side "LEFT"|"RIGHT"
local function render(bufnr, file_path, side)
	if not vim.api.nvim_buf_is_valid(bufnr) then
		return
	end
	vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)

	local pending_lines, normal_lines, resolved_lines = {}, {}, {}
	for _, c in ipairs(state.comments) do
		if
			c.state ~= "OUTDATED"
			and not c.parent_id
			and c.context
			and c.context.file_path == file_path
			and c.context.side == side
		then
			local line = c.context.end_line
			if c.state == "PENDING" then
				pending_lines[line] = true
			elseif c.state == "RESOLVED" then
				resolved_lines[line] = true
			else
				normal_lines[line] = true
			end
		end
	end

	local has_any = next(normal_lines) ~= nil or next(pending_lines) ~= nil or next(resolved_lines) ~= nil
	for _, win in ipairs(vim.fn.win_findbuf(bufnr)) do
		if vim.api.nvim_win_is_valid(win) then
			vim.wo[win].signcolumn = has_any and "yes:1" or "auto"
		end
	end

	local line_count = vim.api.nvim_buf_line_count(bufnr)
	for line in pairs(resolved_lines) do
		if line >= 1 and line <= line_count and not normal_lines[line] and not pending_lines[line] then
			vim.api.nvim_buf_set_extmark(bufnr, ns, line - 1, 0, {
				sign_text = resolved_icon,
				sign_hl_group = "DiagnosticOk",
				priority = 999,
			})
		end
	end
	for line in pairs(normal_lines) do
		if line >= 1 and line <= line_count then
			vim.api.nvim_buf_set_extmark(bufnr, ns, line - 1, 0, {
				sign_text = comment_icon,
				sign_hl_group = "DiagnosticInfo",
				priority = 1000,
			})
		end
	end
	for line in pairs(pending_lines) do
		if line >= 1 and line <= line_count then
			vim.api.nvim_buf_set_extmark(bufnr, ns, line - 1, 0, {
				sign_text = pending_icon,
				sign_hl_group = "DiagnosticWarn",
				priority = 1001,
			})
		end
	end
end

---@param tabpage integer|nil
local function show(tabpage)
	local file_path, session = session_file_path(tabpage)
	if not file_path or not session then
		return
	end
	render(session.original_bufnr, file_path, "LEFT")
	render(session.modified_bufnr, file_path, "RIGHT")
end

--------------------------------------------------------------------------------
-- Loading
--------------------------------------------------------------------------------

---@param tabpage integer|nil
---@param opts { force: boolean|nil }|nil
local function load(tabpage, opts)
	opts = opts or {}
	local session = current_session(tabpage)
	local provider = provider_for(session)
	if not provider or not session then
		return
	end
	local key = session_key(session, provider.name)
	if not key then
		return
	end
	if not opts.force and state.session_key == key then
		show(tabpage)
		return
	end
	if state.loading then
		return
	end

	state.loading = true
	state.provider = provider
	state.session_key = key
	if opts.force ~= true then
		state.pr = nil
		state.comments = {}
	end
	if not opts.silent then
		notify(vim.log.levels.INFO, "Loading PR comments...")
	end

	provider.find_pr(session, function(pr, err)
		if state.session_key ~= key then
			return
		end
		if not pr then
			state.loading = false
			notify(vim.log.levels.WARN, err or "No PR found")
			return
		end
		state.pr = pr
		provider.fetch_comments(pr, function(comments, cerr)
			state.loading = false
			if state.session_key ~= key then
				return
			end
			if cerr then
				notify(vim.log.levels.WARN, cerr)
				return
			end
			state.comments = comments or {}
			notify(vim.log.levels.INFO, ("Loaded %d PR comments"):format(#state.comments))
			show(tabpage)
		end)
	end)
end

--------------------------------------------------------------------------------
-- Actions
--------------------------------------------------------------------------------

---@return DiffCommentContext|nil, DiffCommentsSession|nil
local function cursor_context()
	local file_path, session = session_file_path()
	if not file_path or not session then
		return nil
	end
	local buf = vim.api.nvim_get_current_buf()
	local side = buf == session.original_bufnr and "LEFT" or buf == session.modified_bufnr and "RIGHT" or nil
	if not side then
		return nil
	end
	local line = vim.fn.line(".")
	return { file_path = file_path, start_line = line, end_line = line, side = side }, session
end

---@return DiffCommentContext|nil
local function visual_context()
	local s, e = vim.fn.line("v"), vim.fn.line(".")
	if s > e then
		s, e = e, s
	end
	vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "x", false)
	local ctx = cursor_context()
	if ctx then
		ctx.start_line = s
		ctx.end_line = e
	end
	return ctx
end

--- All comments on the line under the cursor, in display order:
--- root1, reply1.1, reply1.2, root2, reply2.1, ...
---@return DiffComment[] thread, DiffCommentContext|nil ctx
local function threads_at_cursor()
	local ctx = cursor_context()
	if not ctx then
		return {}, nil
	end
	local roots = {}
	for _, c in ipairs(state.comments) do
		if
			not c.parent_id
			and c.context
			and c.context.file_path == ctx.file_path
			and c.context.side == ctx.side
			and c.context.end_line == ctx.start_line
		then
			table.insert(roots, c)
		end
	end
	table.sort(roots, function(a, b)
		return tostring(a.created_at or a.id) < tostring(b.created_at or b.id)
	end)

	local out = {}
	for _, root in ipairs(roots) do
		table.insert(out, root)
		local replies = {}
		for _, c in ipairs(state.comments) do
			if c.parent_id == root.id then
				table.insert(replies, c)
			end
		end
		table.sort(replies, function(a, b)
			return tostring(a.created_at or a.id) < tostring(b.created_at or b.id)
		end)
		for _, r in ipairs(replies) do
			table.insert(out, r)
		end
	end
	return out, ctx
end

local function ensure_ready()
	if not state.provider or not state.pr then
		notify(vim.log.levels.WARN, "No PR loaded — open a CodeDiff session first")
		return false
	end
	return true
end

---@param ctx_fn fun(): DiffCommentContext|nil
---@param opts { pending: boolean, is_task: boolean|nil }
local function add_comment(ctx_fn, opts)
	if not ensure_ready() then
		return
	end
	local ctx = ctx_fn()
	if not ctx then
		return
	end
	local title = opts.is_task and "Task" or (opts.pending and "Pending comment" or "Comment")
	prompt_body({
		prompt = ("%s @ %s:%d (%s): "):format(title, ctx.file_path, ctx.start_line, ctx.side),
		on_submit = function(body)
			---@type DiffComment
			local comment = {
				body = body,
				context = ctx,
				state = opts.pending and "PENDING" or nil,
				is_task = opts.is_task,
			}
			state.provider.add_comment(state.pr, comment, function(created, err)
				if err then
					notify(vim.log.levels.ERROR, err)
					return
				end
				if created then
					table.insert(state.comments, created)
					show()
				end
				load(nil, { force = true, silent = true })
				notify(vim.log.levels.INFO, "Posted")
			end)
		end,
	})
end

--------------------------------------------------------------------------------
-- Keymaps
--------------------------------------------------------------------------------

---@type DiffActions
local actions = {
	add_comment = function(opts)
		add_comment(cursor_context, opts)
	end,

	add_comment_range = function(opts)
		add_comment(visual_context, opts)
	end,

	view_thread = function()
		if not ensure_ready() then
			return
		end
		local thread, ctx = threads_at_cursor()
		if #thread == 0 then
			notify(vim.log.levels.WARN, "No thread at cursor")
			return
		end
		local root = thread[1]
		thread_popup.open(thread, {
			title = (" %s:%d (%s) "):format(ctx.file_path, ctx.start_line, ctx.side),
			on_reply = function(parent, close)
				close()
				prompt_body({
					prompt = "Reply: ",
					on_submit = function(body)
						state.provider.add_comment(state.pr, { body = body, parent = parent }, function(created, err)
							if err then
								notify(vim.log.levels.ERROR, err)
								return
							end
							if created then
								table.insert(state.comments, created)
								show()
							end
							load(nil, { force = true, silent = true })
							notify(vim.log.levels.INFO, "Reply posted")
						end)
					end,
				})
			end,
			on_edit = function(comment, close)
				close()
				prompt_body({
					prompt = "Edit: ",
					text = comment.body,
					on_submit = function(body)
						local updated = vim.tbl_extend("force", comment, { body = body })
						state.provider.edit_comment(state.pr, updated, function(result, err)
							if err then
								notify(vim.log.levels.ERROR, err)
								return
							end
							if result then
								for i, c in ipairs(state.comments) do
									if c.id == result.id then
										state.comments[i] = result
										break
									end
								end
								show()
							else
								load(nil, { force = true, silent = true })
							end
							notify(vim.log.levels.INFO, "Comment updated")
						end)
					end,
				})
			end,
			on_delete = function(comment, close)
				vim.ui.input({ prompt = "Delete comment? [y/N]: " }, function(input)
					if not input or not input:match("^[yY]") then
						return
					end
					state.provider.delete_comment(state.pr, comment, function(_, err)
						if err then
							notify(vim.log.levels.ERROR, err)
							return
						end
						close()
						load(nil, { force = true, silent = true })
						notify(vim.log.levels.INFO, "Comment deleted")
					end)
				end)
			end,
			on_resolve = function(comment, close)
				local fn = comment.state == "RESOLVED" and state.provider.unresolve_thread
					or state.provider.resolve_thread
				if not fn then
					notify(vim.log.levels.WARN, "Not supported by provider")
					return
				end
				local verb = comment.state == "RESOLVED" and "Unresolve" or "Resolve"
				vim.ui.input({ prompt = verb .. " thread? [y/N]: " }, function(input)
					if not input or not input:match("^[yY]") then
						return
					end
					fn(state.pr, comment, function(_, err)
						if err then
							notify(vim.log.levels.ERROR, err)
							return
						end
						close()
						load(nil, { force = true, silent = true })
						notify(vim.log.levels.INFO, verb .. "d thread")
					end)
				end)
			end,
		})
	end,

	submit_review = function(event)
		if not ensure_ready() or not state.provider.submit_review then
			notify(vim.log.levels.WARN, "Submit review not supported")
			return
		end
		prompt_body({
			prompt = event .. " review: ",
			on_submit = function(body)
				state.provider.submit_review(state.pr, event, body, function(_, err)
					if err then
						notify(vim.log.levels.ERROR, err)
						return
					end
					notify(vim.log.levels.INFO, event .. " submitted")
					load(nil, { force = true, silent = true })
				end)
			end,
		})
	end,

	refresh = function()
		load(nil, { force = true })
	end,

	jump = function(direction)
		local file_path, session = session_file_path()
		if not file_path or not session then
			return
		end
		local buf = vim.api.nvim_get_current_buf()
		local side = buf == session.original_bufnr and "LEFT" or buf == session.modified_bufnr and "RIGHT" or nil
		if not side then
			return
		end
		local seen, lines = {}, {}
		for _, c in ipairs(state.comments) do
			if
				not c.parent_id
				and c.context
				and c.context.file_path == file_path
				and c.context.side == side
				and c.state ~= "OUTDATED"
			then
				local l = c.context.end_line
				if l and not seen[l] then
					seen[l] = true
					table.insert(lines, l)
				end
			end
		end
		if #lines == 0 then
			notify(vim.log.levels.INFO, "No comments in this file")
			return
		end
		table.sort(lines)
		local cur = vim.fn.line(".")
		local target
		if direction > 0 then
			for _, l in ipairs(lines) do
				if l > cur then
					target = l
					break
				end
			end
			target = target or lines[1]
		else
			for i = #lines, 1, -1 do
				if lines[i] < cur then
					target = lines[i]
					break
				end
			end
			target = target or lines[#lines]
		end
		vim.api.nvim_win_set_cursor(0, { target, 0 })
	end,

	open_pr_url = function()
		if state.provider and state.pr and state.provider.pr_url then
			local url = state.provider.pr_url(state.pr)
			if url and url ~= "" then
				vim.ui.open(url)
				return
			end
		end
		vim.cmd.normal({ "gx", bang = true })
	end,
}

--------------------------------------------------------------------------------
-- Autocmds
--------------------------------------------------------------------------------

local group = vim.api.nvim_create_augroup("my_diff_comments", { clear = true })

vim.api.nvim_create_autocmd("User", {
	group = group,
	pattern = "CodeDiffFileSelect",
	callback = function(event)
		local tabpage = event.data and event.data.tabpage or vim.api.nvim_get_current_tabpage()
		local session = current_session(tabpage)
		if session then
			keymaps.setup(session.original_bufnr, actions)
			keymaps.setup(session.modified_bufnr, actions)
		end
		load(tabpage)
	end,
})

vim.api.nvim_create_autocmd("User", {
	group = group,
	pattern = "CodeDiffVirtualFileLoaded",
	callback = function(event)
		show(event.data and event.data.tabpage)
	end,
})

vim.api.nvim_create_autocmd("WinEnter", {
	group = group,
	callback = function()
		vim.schedule(show)
	end,
})
