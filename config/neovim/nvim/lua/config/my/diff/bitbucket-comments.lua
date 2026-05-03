-- Currently makes heavy use of atlas.nvim: https://github.com/emrearmagan/atlas.nvim
if not vim.g.use_codediff then
	return {}
end

local M = { name = "bitbucket" }

local function trim(value)
	if type(value) ~= "string" then
		return ""
	end
	return vim.trim(value)
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

function M.can_handle(session)
	return session ~= nil and parse_origin(session.git_root) ~= nil
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

local function pr_from_codediff_revision(session, callback)
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

local function wait_for_pr(session, attempt, callback)
	attempt = attempt or 1
	pr_from_codediff_revision(session, function(pr, err)
		if pr or err then
			callback(pr, err)
			return
		end
		if attempt >= 12 then
			callback(nil)
			return
		end
		vim.defer_fn(function()
			wait_for_pr(session, attempt + 1, callback)
		end, 100)
	end)
end

function M.find_pr(session, callback)
	wait_for_pr(session, 1, function(pr, err)
		if err then
			callback(nil, "Failed to find Bitbucket PR: " .. err)
			return
		end
		if not pr then
			callback(nil, "No Bitbucket PR found")
			return
		end
		callback(pr)
	end)
end

function M.fetch_diff_files(pr, callback)
	local provider = require("atlas.pulls.providers.bitbucket")
	provider.fetch_diff(pr, { force_refresh = true }, function(files)
		local by_path = {}
		for _, file in ipairs(files or {}) do
			by_path[file.path] = file
			if file.old_path then
				by_path[file.old_path] = file
			end
		end
		callback(by_path)
	end)
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

local function merge_comments(comments)
	local out = {}
	local seen = {}
	for _, comment in ipairs(comments or {}) do
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
				table.insert(out, comment)
			end
		end
	end
	return out
end

function M.fetch_comments(pr, callback)
	local raw = pr._raw or {}
	local comments_url = tostring((raw.links or {}).comments or "")
	if comments_url == "" then
		callback(nil, "Failed to load comments: no comments URL")
		return
	end

	local sep = comments_url:find("?") and "&" or "?"
	local url = ("%s%spagelen=100"):format(comments_url, sep)
	local service = require("atlas.pulls.providers.bitbucket.api.service")
	service.request("GET", url, nil, nil, function(result, err)
		if err then
			callback(nil, "Failed to load comments: " .. err)
			return
		end
		callback(merge_comments(normalize_comments((result or {}).values or {})))
	end)
end

local function inline_for(context)
	if context.side == "LEFT" then
		return {
			path = context.file_path,
			["from"] = context.end_line,
			start_from = context.start_line ~= context.end_line and context.start_line or nil,
		}
	end

	return {
		path = context.file_path,
		to = context.end_line,
		start_to = context.start_line ~= context.end_line and context.start_line or nil,
	}
end

local function post_pending_comment(pr, body, inline, callback)
	local raw = pr._raw or {}
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
	service.request("POST", comments_url, nil, payload, function(result, err)
		if err then
			callback(nil, "Failed to post comment: " .. err)
			return
		end
		callback(result)
	end)
end

function M.add_comment(pr, context, body, opts, callback)
	local inline = inline_for(context)
	if opts and opts.pending then
		post_pending_comment(pr, body, inline, callback)
		return
	end

	local comments_api = require("atlas.pulls.providers.bitbucket.api.comments")
	comments_api.add_comment(pr, body, { inline = inline }, function(comment, err)
		if err then
			callback(nil, "Failed to post comment: " .. err)
			return
		end
		callback(comment)
	end)
end

local function post_pending_reply(pr, root_comment, body, callback)
	local raw = pr._raw or {}
	local comments_url = tostring((raw.links or {}).comments or "")
	if comments_url == "" then
		callback(nil, "Failed to post pending reply: no comments URL")
		return
	end

	local service = require("atlas.pulls.providers.bitbucket.api.service")
	local payload = vim.json.encode({
		content = { raw = body },
		parent = { id = tonumber(root_comment.id) or root_comment.id },
		pending = true,
	})
	service.request("POST", comments_url, nil, payload, function(result, err)
		if err then
			callback(nil, "Failed to post pending reply: " .. err)
			return
		end
		callback(result)
	end)
end

function M.reply(pr, root_comment, body, callback)
	if root_comment.pending then
		post_pending_reply(pr, root_comment, body, callback)
		return
	end

	local comments_api = require("atlas.pulls.providers.bitbucket.api.comments")
	comments_api.reply_comment(pr, root_comment.id, body, function(comment, err)
		if err then
			if tostring(err):find("NONPENDING_COMMENT_ON_PENDING_COMMENT", 1, true) then
				post_pending_reply(pr, root_comment, body, callback)
				return
			end
			callback(nil, "Failed to post reply: " .. err)
			return
		end
		callback(comment)
	end)
end

function M.submit_review(pr, event, body, callback)
	local raw = pr and pr._raw or {}
	local links = raw.links or {}
	local action_url
	local action

	if event == "APPROVE" then
		action_url = tostring(links.approve or "")
		action = "approve"
	elseif event == "REQUEST_CHANGES" then
		action_url = tostring(links.request_changes or "")
		action = "request_changes"
	else
		callback(nil, "Unsupported Bitbucket review event: " .. tostring(event))
		return
	end

	if action_url == "" then
		callback(nil, action == "approve" and "No approve URL available" or "No request changes URL available")
		return
	end

	local function submit_action()
		local pullrequests = require("atlas.pulls.providers.bitbucket.api.pullrequests")
		local fn = action == "approve" and pullrequests.approve or pullrequests.request_changes
		fn(action_url, function(result, err)
			if err then
				callback(
					nil,
					(action == "approve" and "Approve failed: " or "Request changes failed: ") .. tostring(err)
				)
				return
			end
			callback(result or true)
		end)
	end

	local comments_api = require("atlas.pulls.providers.bitbucket.api.comments")
	comments_api.add_comment(pr, body, function(_, err)
		if err then
			callback(nil, "Failed to post review comment: " .. tostring(err))
			return
		end
		submit_action()
	end)
end

function M.delete_comment(pr, comment, callback)
	if not comment or not comment.id then
		callback(nil, "No comment selected")
		return
	end

	local comments_api = require("atlas.pulls.providers.bitbucket.api.comments")
	comments_api.delete_comment(pr, comment.id, function(ok, err)
		if not ok then
			callback(nil, "Failed to delete comment: " .. tostring(err or ""))
			return
		end
		callback(true)
	end)
end

function M.pr_url(pr)
	return pr and pr.link and pr.link.html or nil
end

return M
