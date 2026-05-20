-- Uses atlas.nvim's Bitbucket API: https://github.com/emrearmagan/atlas.nvim

---@class BitbucketProvider : DiffCommentsProvider
local M = {
	name = "bitbucket",
	allow_out_of_diff_comments = true,
}

--------------------------------------------------------------------------------
-- Shared helpers
--------------------------------------------------------------------------------

---@param value any
---@return string
local function trim(value)
	if type(value) ~= "string" then
		return ""
	end
	return vim.trim(value)
end

---@param root string
---@return string|nil workspace
---@return string|nil repo
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
	return path:match("^([^/]+)/(.+)$")
end

---@param comment table  raw bitbucket comment payload
---@return DiffComment
local function comment_to_diff_comment(comment)
	local inline = comment.inline or {}
	local end_line = tonumber(inline.to) or tonumber(inline["from"])
	local side = tonumber(inline.to) and "RIGHT" or "LEFT"
	local content = comment.content or {}
	local body = comment.content_raw or content.raw or ""
	local author = comment.author or comment.user or {}
	local parent = comment.parent or {}

	local context
	if inline.path and end_line then
		context = {
			file_path = inline.path,
			start_line = end_line,
			end_line = end_line,
			side = side,
		}
	end

	local state
	if comment.pending == true or tostring(comment.state or ""):upper() == "PENDING" then
		state = "PENDING"
	elseif tostring(comment.state or ""):upper() == "RESOLVED" then
		state = "RESOLVED"
	elseif comment.deleted == true then
		state = "DELETED"
	end

	return {
		id = comment.id,
		parent_id = comment.parent_id or parent.id,
		author = (author.nickname or author.display_name or author.name) and {
			name = author.display_name or author.name,
			username = author.nickname or author.username,
		} or nil,
		body = body,
		context = context,
		state = state,
		created_at = comment.created_on,
		updated_at = comment.updated_on,
		url = comment.links and comment.links.html and comment.links.html.href or nil,
		_raw = { comment = comment },
	}
end

---@param task table  raw bitbucket task payload
---@return DiffComment
local function task_to_diff_comment(task)
	local creator = task.creator or {}
	return {
		id = task.id,
		parent_id = task.comment and task.comment.id or nil,
		author = (creator.display_name or creator.nickname) and {
			name = creator.display_name,
			username = creator.nickname or creator.username,
		} or nil,
		body = task.content_raw or (task.content and task.content.raw) or "",
		state = tostring(task.state or ""):upper() == "RESOLVED" and "RESOLVED" or nil,
		is_task = true,
		created_at = task.created_on,
		updated_at = task.updated_on,
		url = task.links and task.links.html and task.links.html.href or nil,
		_raw = { task = task, task_url = task.links and task.links.self and task.links.self.href },
	}
end

--------------------------------------------------------------------------------
-- Provider interface
--------------------------------------------------------------------------------

---@param session DiffCommentsSession
---@return boolean
function M.can_handle(session)
	return session ~= nil and parse_origin(session.git_root) ~= nil
end

---@param session DiffCommentsSession
---@param on_done fun(pr: DiffCommentsPR|nil, err: string|nil)
function M.find_pr(session, on_done)
	local workspace, repo = parse_origin(session.git_root)
	if not workspace or not repo then
		on_done(nil, "Not a Bitbucket repo")
		return
	end

	local sha = tostring(session.modified_revision or "")
	if sha == "" or sha == "WORKING" or sha == "STAGED" then
		on_done(nil, "No revision in session")
		return
	end

	local service = require("atlas.pulls.providers.bitbucket.api.service")
	local normalizer = require("atlas.pulls.providers.bitbucket.api.pr_normalizer")
	local endpoint = ("/repositories/%s/%s/pullrequests?state=OPEN&pagelen=50"):format(workspace, repo)
	service.request("GET", endpoint, nil, nil, function(result, err)
		if err then
			on_done(nil, err)
			return
		end
		for _, raw in ipairs(normalizer.pullrequests(result, workspace, repo) or {}) do
			local head = (raw.source or {}).commit_hash or ""
			if head ~= "" and (head:sub(1, #sha) == sha or sha:sub(1, #head) == head) then
				on_done({
					number = tostring(raw.id),
					workspace = workspace,
					repo = repo,
					url = raw.link and raw.link.html or "",
					_raw = raw,
				})
				return
			end
		end
		on_done(nil, "No Bitbucket PR found")
	end)
end

---@param pr DiffCommentsPR
---@param on_done fun(comments: DiffComment[], err: string|nil)
function M.fetch_comments(pr, on_done)
	local service = require("atlas.pulls.providers.bitbucket.api.service")
	local comments_api = require("atlas.pulls.providers.bitbucket.api.comments")

	local raw = pr._raw or {}
	local comments_url = tostring((raw.links or {}).comments or "")
	if comments_url == "" then
		on_done({}, "Failed to load comments: no comments URL")
		return
	end

	local comments_result, tasks_result
	local first_err

	local function finish()
		if comments_result == nil or tasks_result == nil then
			return
		end
		if first_err then
			on_done({}, first_err)
			return
		end
		local merged = {}
		for _, c in ipairs(comments_result) do
			table.insert(merged, comment_to_diff_comment(c))
		end
		for _, t in ipairs(tasks_result) do
			table.insert(merged, task_to_diff_comment(t))
		end
		on_done(merged)
	end

	local sep = comments_url:find("?") and "&" or "?"
	local url = ("%s%spagelen=100"):format(comments_url, sep)
	service.request("GET", url, nil, nil, function(result, err)
		if err then
			first_err = first_err or err
			comments_result = {}
		else
			comments_result = (result or {}).values or {}
		end
		finish()
	end)

	comments_api.fetch_tasks(pr.workspace, pr.repo, pr.number, { force_refresh = true }, function(tasks, err)
		if err then
			first_err = first_err or err
			tasks_result = {}
		else
			tasks_result = tasks or {}
		end
		finish()
	end)
end

---@param pr DiffCommentsPR
---@param comment DiffComment
---@param on_done fun(created: DiffComment|nil, err: string|nil)
function M.add_comment(pr, comment, on_done)
	local body = comment and comment.body or ""
	if body == "" then
		on_done(nil, "Empty comment body")
		return
	end

	local comments_api = require("atlas.pulls.providers.bitbucket.api.comments")
	local service = require("atlas.pulls.providers.bitbucket.api.service")

	if comment.is_task then
		local parent_id = comment.parent and comment.parent.id or nil
		comments_api.create_task(pr.workspace, pr.repo, pr.number, body, { comment_id = parent_id }, function(task, err)
			if err then
				on_done(nil, "Failed to create task: " .. tostring(err))
				return
			end
			on_done(task and task_to_diff_comment(task) or nil)
		end)
		return
	end

	local parent = comment.parent
	if parent then
		local is_pending = comment.state == "PENDING" or parent.state == "PENDING"
		if is_pending then
			local comments_url = tostring(((pr._raw or {}).links or {}).comments or "")
			if comments_url == "" then
				on_done(nil, "Missing comments URL")
				return
			end
			local payload = vim.json.encode({
				content = { raw = body },
				parent = { id = tonumber(parent.id) or parent.id },
				pending = true,
			})
			service.request("POST", comments_url, nil, payload, function(result, err)
				if err then
					on_done(nil, "Failed to post pending reply: " .. tostring(err))
					return
				end
				on_done(result and comment_to_diff_comment(result) or nil)
			end)
			return
		end
		comments_api.reply_comment(pr._raw, parent.id, body, nil, function(created, err)
			if err then
				on_done(nil, "Failed to post reply: " .. tostring(err))
				return
			end
			on_done(created and comment_to_diff_comment(created) or nil)
		end)
		return
	end

	local inline
	if comment.context then
		local ctx = comment.context
		if ctx.side == "LEFT" then
			inline = { path = ctx.file_path, ["from"] = ctx.end_line }
		else
			inline = { path = ctx.file_path, to = ctx.end_line }
		end
	end

	if comment.state == "PENDING" then
		local comments_url = tostring(((pr._raw or {}).links or {}).comments or "")
		if comments_url == "" then
			on_done(nil, "Missing comments URL")
			return
		end
		local payload = vim.json.encode({
			content = { raw = body },
			inline = inline,
			pending = true,
		})
		service.request("POST", comments_url, nil, payload, function(result, err)
			if err then
				on_done(nil, "Failed to post pending comment: " .. tostring(err))
				return
			end
			on_done(result and comment_to_diff_comment(result) or nil)
		end)
		return
	end

	comments_api.add_comment(pr._raw, body, { inline = inline }, function(created, err)
		if err then
			on_done(nil, "Failed to post comment: " .. tostring(err))
			return
		end
		on_done(created and comment_to_diff_comment(created) or nil)
	end)
end

---@param pr DiffCommentsPR
---@param on_done fun(comments: table[]|nil, err: string|nil)
function M.fetch_review_comments(pr, on_done)
	local atlas_bb = require("atlas.pulls.providers.bitbucket")
	atlas_bb.fetch_comments(pr._raw, { force_refresh = true }, function(comments, err)
		if err then
			on_done(nil, err)
			return
		end
		local out = {}
		for _, c in ipairs(comments or {}) do
			if tostring(c.state or ""):upper() == "PENDING" then
				table.insert(out, c)
			end
		end
		on_done(out)
	end)
end

---@param pr DiffCommentsPR
---@param comment DiffComment
---@param on_done fun(updated: DiffComment|nil, err: string|nil)
function M.edit_comment(pr, comment, on_done)
	if not comment or not comment.id then
		on_done(nil, "No comment selected")
		return
	end

	local body = comment.body or ""

	if comment.is_task then
		local task_url = comment._raw and comment._raw.task_url
		if not task_url then
			on_done(nil, "Missing task URL")
			return
		end
		local comments_api = require("atlas.pulls.providers.bitbucket.api.comments")
		comments_api.update_task(task_url, { content_raw = body }, function(task, err)
			if err then
				on_done(nil, "Failed to edit task: " .. tostring(err))
				return
			end
			on_done(task and task_to_diff_comment(task) or nil)
		end)
		return
	end

	local comments_api = require("atlas.pulls.providers.bitbucket.api.comments")
	comments_api.edit_comment(pr._raw, comment.id, body, nil, function(updated, err)
		if err then
			on_done(nil, "Failed to edit comment: " .. tostring(err))
			return
		end
		on_done(updated and comment_to_diff_comment(updated) or nil)
	end)
end

---@param pr DiffCommentsPR
---@param comment DiffComment
---@param on_done fun(ok: boolean|nil, err: string|nil)
function M.delete_comment(pr, comment, on_done)
	if not comment or not comment.id then
		on_done(nil, "No comment selected")
		return
	end

	if comment.is_task then
		local task_url = comment._raw and comment._raw.task_url
		if not task_url then
			on_done(nil, "Missing task URL")
			return
		end
		local comments_api = require("atlas.pulls.providers.bitbucket.api.comments")
		comments_api.delete_task(task_url, function(_, err)
			if err then
				on_done(nil, "Failed to delete task: " .. tostring(err))
				return
			end
			on_done(true)
		end)
		return
	end

	local comments_api = require("atlas.pulls.providers.bitbucket.api.comments")
	comments_api.delete_comment(pr._raw, comment.id, function(ok, err)
		if not ok then
			on_done(nil, "Failed to delete comment: " .. tostring(err or ""))
			return
		end
		on_done(true)
	end)
end

---@param pr DiffCommentsPR
---@param root DiffComment
---@param on_done fun(ok: boolean|nil, err: string|nil)
function M.resolve_thread(pr, root, on_done)
	if not root.is_task then
		on_done(nil, "Bitbucket only supports resolving tasks")
		return
	end
	local task_url = root._raw and root._raw.task_url
	if not task_url then
		on_done(nil, "Missing task URL")
		return
	end
	local comments_api = require("atlas.pulls.providers.bitbucket.api.comments")
	comments_api.update_task(task_url, { state = "RESOLVED" }, function(_, err)
		if err then
			on_done(nil, "Failed to resolve task: " .. tostring(err))
			return
		end
		on_done(true)
	end)
end

---@param pr DiffCommentsPR
---@param root DiffComment
---@param on_done fun(ok: boolean|nil, err: string|nil)
function M.unresolve_thread(pr, root, on_done)
	if not root.is_task then
		on_done(nil, "Bitbucket only supports resolving tasks")
		return
	end
	local task_url = root._raw and root._raw.task_url
	if not task_url then
		on_done(nil, "Missing task URL")
		return
	end
	local comments_api = require("atlas.pulls.providers.bitbucket.api.comments")
	comments_api.update_task(task_url, { state = "UNRESOLVED" }, function(_, err)
		if err then
			on_done(nil, "Failed to unresolve task: " .. tostring(err))
			return
		end
		on_done(true)
	end)
end

---@param pr DiffCommentsPR
---@param event "APPROVE"|"REQUEST_CHANGES"|"COMMENT"
---@param body string
---@param on_done fun(ok: boolean|nil, err: string|nil)
function M.submit_review(pr, event, body, on_done)
	local links = (pr._raw or {}).links or {}
	local action_url, action
	if event == "APPROVE" then
		action_url, action = tostring(links.approve or ""), "approve"
	elseif event == "REQUEST_CHANGES" then
		action_url, action = tostring(links.request_changes or ""), "request_changes"
	else
		on_done(nil, "Unsupported Bitbucket review event: " .. tostring(event))
		return
	end
	if action_url == "" then
		on_done(nil, "No " .. action .. " URL available")
		return
	end

	local function submit_action()
		local pullrequests = require("atlas.pulls.providers.bitbucket.api.pullrequests")
		local fn = action == "approve" and pullrequests.approve or pullrequests.request_changes
		fn(action_url, function(_, err)
			if err then
				on_done(nil, action .. " failed: " .. tostring(err))
				return
			end
			on_done(true)
		end)
	end

	if body == "" then
		submit_action()
		return
	end

	local comments_api = require("atlas.pulls.providers.bitbucket.api.comments")
	comments_api.add_comment(pr._raw, body, nil, function(_, err)
		if err then
			on_done(nil, "Failed to post review comment: " .. tostring(err))
			return
		end
		submit_action()
	end)
end

---@param pr DiffCommentsPR
---@return string|nil
function M.pr_url(pr)
	return pr and pr.url ~= "" and pr.url or nil
end

return M
