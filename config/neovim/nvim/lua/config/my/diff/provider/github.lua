-- Thanks to this amazing guy: https://github.com/fredrikaverpil/dotfiles/blob/main/nvim-fredrik/plugin/github_comments.lua

local git = require("config.my.diff.git")

---@class GithubPR : DiffCommentsPR
---@field pending_review_node_id string|nil  cached pending-review node id; draft comments must attach to a Pending Review (GitHub allows one per user/PR)

---@class GithubProvider : DiffCommentsProvider
local M = {
	name = "github",
}

local COMMENT_FIELDS = [[
id
databaseId
body
url
path
line
createdAt
updatedAt
author { login ... on User { name } }
replyTo { id databaseId }
pullRequestReview { id state }
]]

--------------------------------------------------------------------------------
-- Shared helpers
--------------------------------------------------------------------------------

---@param cmd string
---@return string[]
local function shell(cmd)
	return { "bash", "-c", cmd }
end

---@param value any
---@return string
local function trim(value)
	if type(value) ~= "string" then
		return ""
	end
	return vim.trim(value)
end

---@param query string
---@param variables table|nil
---@param callback fun(data: table)
---@param on_error fun(err: string)|nil
local function graphql(query, variables, callback, on_error)
	local payload = vim.json.encode({ query = query, variables = variables or {} })
	local stdout_chunks, stderr_chunks = {}, {}

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
				local ok, result = pcall(vim.json.decode, raw, { luanil = { object = true, array = true } })
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

---@param gh_comment table
---@param thread table|nil
---@return DiffComment
local function to_diff_comment(gh_comment, thread)
	local end_line = (thread and thread.line) or gh_comment.line
	local start_line = (thread and thread.startLine) or end_line
	local side = (thread and thread.diffSide) == "LEFT" and "LEFT" or "RIGHT"
	local path = (thread and thread.path) or gh_comment.path
	local context = (path and path ~= "" and end_line)
			and {
				file_path = path,
				start_line = start_line or end_line,
				end_line = end_line,
				side = side,
			}
		or nil

	local state
	local review = gh_comment.pullRequestReview
	if review and review.state == "PENDING" then
		state = "PENDING"
	elseif thread and thread.isResolved then
		state = "RESOLVED"
	elseif thread and thread.isOutdated then
		state = "OUTDATED"
	end

	return {
		id = gh_comment.databaseId,
		node_id = gh_comment.id,
		parent_id = gh_comment.replyTo and gh_comment.replyTo.databaseId or nil,
		thread_id = thread and thread.id,
		author = gh_comment.author and { name = gh_comment.author.name, username = gh_comment.author.login } or nil,
		body = gh_comment.body or "",
		context = context,
		state = state,
		created_at = gh_comment.createdAt,
		updated_at = gh_comment.updatedAt,
		url = gh_comment.url,
		_raw = { comment = gh_comment, thread = thread },
	}
end

---@param root DiffComment|nil
---@return string|integer|nil
local function thread_node_id(root)
	if not root then
		return nil
	end
	if root.thread_id then
		return root.thread_id
	end
	if root._raw and root._raw.thread and root._raw.thread.id then
		return root._raw.thread.id
	end
	return nil
end

--------------------------------------------------------------------------------
-- Provider interface
--------------------------------------------------------------------------------

---@param session DiffCommentsSession
---@return boolean
function M.can_handle(session)
	if not session or not session.git_root or session.git_root == "" then
		return false
	end
	local url = git.remote_url(session.git_root)
	return url and url:find("github", 1, false) ~= nil or false
end

---@param session DiffCommentsSession
---@param on_done fun(pr: DiffCommentsPR|nil, err: string|nil)
function M.find_pr(session, on_done)
	local sha = tostring(session.modified_revision or "")
	if sha == "" or sha == "WORKING" or sha == "STAGED" then
		on_done(nil, "No revision in session")
		return
	end

	vim.system(
		{ "gh", "repo", "view", "--json", "nameWithOwner", "--jq", ".nameWithOwner" },
		{ text = true, cwd = session.git_root },
		function(repo_result)
			vim.schedule(function()
				local slug = repo_result and repo_result.code == 0 and trim(repo_result.stdout) or ""
				local owner, repo = slug:match("^([^/]+)/(.+)$")
				if not owner then
					on_done(nil, "Could not resolve repo")
					return
				end

				vim.system({
					"gh",
					"api",
					("repos/%s/%s/commits/%s/pulls"):format(owner, repo, sha),
					"-H",
					"Accept: application/vnd.github+json",
				}, { text = true, cwd = session.git_root }, function(result)
					vim.schedule(function()
						local ok, pulls = false, nil
						if result and result.code == 0 then
							ok, pulls = pcall(
								vim.json.decode,
								result.stdout or "",
								{ luanil = { object = true, array = true } }
							)
						end
						if not ok or type(pulls) ~= "table" or #pulls == 0 then
							on_done(nil, "No GitHub PR found for commit " .. sha:sub(1, 7))
							return
						end

						local selected = pulls[1]
						for _, pr in ipairs(pulls) do
							if pr.state == "open" then
								selected = pr
								break
							end
						end
						on_done({
							number = tostring(selected.number),
							owner = owner,
							repo = repo,
							url = ("https://github.com/%s/%s/pull/%s"):format(owner, repo, selected.number),
						})
					end)
				end)
			end)
		end
	)
end

---@param pr GithubPR
---@param on_done fun(comments: DiffComment[], err: string|nil)
function M.fetch_comments(pr, on_done)
	local query = ([[
query($owner: String!, $repo: String!, $pr: Int!) {
  repository(owner: $owner, name: $repo) {
    pullRequest(number: $pr) {
      id
      reviews(first: 100) { nodes { id state } }
      reviewThreads(first: 100) {
        nodes {
          id isResolved isOutdated path line startLine diffSide
          comments(first: 100) { nodes { %s } }
        }
      }
      comments(first: 100) {
        nodes {
          id databaseId body url createdAt updatedAt
          author { login ... on User { name } }
        }
      }
    }
  }
}
]]):format(COMMENT_FIELDS)

	graphql(query, {
		owner = pr.owner,
		repo = pr.repo,
		pr = tonumber(pr.number),
	}, function(data)
		local gh_pr = data.repository and data.repository.pullRequest
		if not gh_pr then
			on_done({}, "No PR data")
			return
		end

		pr.node_id = gh_pr.id
		pr.pending_review_node_id = nil
		for _, review in ipairs(gh_pr.reviews and gh_pr.reviews.nodes or {}) do
			if review.state == "PENDING" then
				pr.pending_review_node_id = review.id
			end
		end

		local comments = {}
		for _, thread in ipairs(gh_pr.reviewThreads and gh_pr.reviewThreads.nodes or {}) do
			local nodes = thread.comments and thread.comments.nodes or {}
			for idx, gh_comment in ipairs(nodes) do
				local c = to_diff_comment(gh_comment, thread)
				if idx > 1 and not c.parent_id then
					c.parent_id = nodes[1].databaseId
				end
				table.insert(comments, c)
			end
		end
		for _, gh_comment in ipairs(gh_pr.comments and gh_pr.comments.nodes or {}) do
			table.insert(comments, to_diff_comment(gh_comment, nil))
		end

		on_done(comments)
	end, function(err)
		on_done({}, err)
	end)
end

---@param diff_hunk string|nil
---@return DiffHunk|nil
local function parse_diff_hunk(diff_hunk)
	if type(diff_hunk) ~= "string" or diff_hunk == "" then
		return nil
	end
	local ok, parser = pcall(require, "atlas.core.git.diff_parser")
	if not ok then
		return nil
	end
	local synthetic = "diff --git a/x b/x\n--- a/x\n+++ b/x\n" .. diff_hunk .. "\n"
	local pok, files = pcall(parser.parse, synthetic)
	if not pok or not files or #files == 0 or #files[1].hunks == 0 then
		return nil
	end
	return files[1].hunks[1]
end

---@param pr GithubPR
---@param on_done fun(comments: table[]|nil, err: string|nil)
function M.fetch_review_comments(pr, on_done)
	local query = [[
query($owner: String!, $repo: String!, $pr: Int!) {
  repository(owner: $owner, name: $repo) {
    pullRequest(number: $pr) {
      reviewThreads(first: 100) {
        nodes {
          id isResolved isOutdated path line startLine diffSide
          comments(first: 100) {
            nodes {
              id databaseId body url createdAt updatedAt
              path line
              diffHunk
              author { login ... on User { name } }
              replyTo { id databaseId }
              pullRequestReview { id state }
            }
          }
        }
      }
    }
  }
}
]]
	graphql(query, { owner = pr.owner, repo = pr.repo, pr = tonumber(pr.number) }, function(data)
		local gh_pr = data.repository and data.repository.pullRequest
		if not gh_pr then
			on_done({}, "No PR data")
			return
		end

		local out = {}
		for _, thread in ipairs(gh_pr.reviewThreads and gh_pr.reviewThreads.nodes or {}) do
			local nodes = thread.comments and thread.comments.nodes or {}
			for _, c in ipairs(nodes) do
				local rv = c.pullRequestReview
				if rv and rv.state == "PENDING" then
					local path = thread.path or c.path
					local line = thread.line or c.line
					local side = thread.diffSide == "LEFT" and "old" or "new"
					table.insert(out, {
						id = c.databaseId,
						parent_id = c.replyTo and c.replyTo.databaseId or nil,
						author = c.author and {
							name = c.author.name or c.author.login,
							nickname = c.author.login,
							id = c.author.login,
						} or nil,
						content_raw = c.body or "",
						created_on = c.createdAt or "",
						inline = path and line and {
							path = path,
							to = side == "new" and line or nil,
							from = side == "old" and line or nil,
						} or nil,
						inline_hunk = parse_diff_hunk(c.diffHunk),
						state = "PENDING",
						url = c.url,
						html_url = c.url,
					})
				end
			end
		end
		on_done(out)
	end, function(err)
		on_done(nil, err)
	end)
end

---@param pr GithubPR
---@param comment DiffComment
---@param on_done fun(created: DiffComment|nil, err: string|nil)
function M.add_comment(pr, comment, on_done)
	local body = comment and comment.body or ""
	if body == "" then
		on_done(nil, "Empty comment body")
		return
	end

	---@param callback fun(review_id: string|nil, err: string|nil)
	local function ensure_pending_review(callback)
		if pr.pending_review_node_id then
			callback(pr.pending_review_node_id)
			return
		end
		if not pr.node_id then
			callback(nil, "No GitHub PR node data cached")
			return
		end
		local query = [[
mutation($pullRequestId: ID!) {
  addPullRequestReview(input: { pullRequestId: $pullRequestId }) {
    pullRequestReview { id }
  }
}
]]
		graphql(query, { pullRequestId = pr.node_id }, function(data)
			local review_id = data.addPullRequestReview
				and data.addPullRequestReview.pullRequestReview
				and data.addPullRequestReview.pullRequestReview.id
			if not review_id then
				callback(nil, "Failed to create pending review")
				return
			end
			pr.pending_review_node_id = review_id
			callback(review_id)
		end, function(err)
			callback(nil, "Failed to create pending review: " .. err)
		end)
	end

	local parent = comment.parent
	local is_pending = comment.state == "PENDING"

	if parent then
		local parent_pending = parent.state == "PENDING"
		if is_pending or parent_pending or pr.pending_review_node_id then
			ensure_pending_review(function(review_id, err)
				if not review_id then
					on_done(nil, err)
					return
				end
				local parent_node_id = parent.node_id
					or (parent._raw and parent._raw.comment and parent._raw.comment.id)
				if not parent_node_id then
					on_done(nil, "Missing parent node id for reply")
					return
				end
				local reply_query = ([[
mutation($pullRequestReviewId: ID!, $inReplyTo: ID!, $body: String!) {
  addPullRequestReviewComment(input: {
    pullRequestReviewId: $pullRequestReviewId
    inReplyTo: $inReplyTo
    body: $body
  }) {
    comment { %s }
  }
}
]]):format(COMMENT_FIELDS)
				graphql(reply_query, {
					pullRequestReviewId = review_id,
					inReplyTo = parent_node_id,
					body = body,
				}, function(data)
					local gh_comment = data.addPullRequestReviewComment and data.addPullRequestReviewComment.comment
					on_done(gh_comment and to_diff_comment(gh_comment, parent._raw and parent._raw.thread) or nil)
				end, function(gerr)
					on_done(nil, "Failed to post pending reply: " .. gerr)
				end)
			end)
		else
			local parent_id = parent.id or (parent._raw and parent._raw.comment and parent._raw.comment.databaseId)
			if not parent_id then
				on_done(nil, "Missing parent id for reply")
				return
			end

			local payload = vim.json.encode({ body = body })
			local stderr_chunks = {}
			local cmd = ("gh api repos/%s/%s/pulls/%s/comments/%s/replies --method POST --input -"):format(
				pr.owner,
				pr.repo,
				pr.number,
				parent_id
			)
			local job_id = vim.fn.jobstart(shell(cmd), {
				stdout_buffered = true,
				stderr_buffered = true,
				on_stderr = function(_, data)
					if data then
						table.insert(stderr_chunks, table.concat(data, "\n"))
					end
				end,
				on_exit = function(_, exit_code)
					vim.schedule(function()
						if exit_code ~= 0 then
							on_done(nil, "Failed to post reply: " .. table.concat(stderr_chunks, ""))
							return
						end
						on_done({
							body = body,
							parent_id = parent.id,
							thread_id = parent.thread_id,
							context = parent.context,
							_raw = parent._raw,
						})
					end)
				end,
			})
			vim.fn.chansend(job_id, payload)
			vim.fn.chanclose(job_id, "stdin")
		end
		return
	end

	if comment.context then
		local ctx = comment.context
		local variables = {
			path = ctx.file_path,
			body = body,
			line = ctx.end_line,
			side = ctx.side,
		}
		if ctx.start_line and ctx.start_line ~= ctx.end_line then
			variables.startSide = ctx.side
			variables.startLine = ctx.start_line
		end
		if is_pending then
			ensure_pending_review(function(review_id, err)
				if not review_id then
					on_done(nil, err)
					return
				end
				variables.pullRequestReviewId = review_id
				local pending_query = ([[
mutation($pullRequestReviewId: ID!, $path: String!, $body: String!, $line: Int!, $side: DiffSide!, $startSide: DiffSide, $startLine: Int) {
  addPullRequestReviewThread(input: {
    pullRequestReviewId: $pullRequestReviewId
    path: $path body: $body line: $line side: $side
    startSide: $startSide startLine: $startLine
  }) {
    thread { id isResolved isOutdated path line startLine diffSide
      comments(first: 1) { nodes { %s } }
    }
  }
}
]]):format(COMMENT_FIELDS)
				graphql(pending_query, variables, function(data)
					local thread = data.addPullRequestReviewThread and data.addPullRequestReviewThread.thread
					local gh_comment = thread and thread.comments and thread.comments.nodes and thread.comments.nodes[1]
					on_done(gh_comment and to_diff_comment(gh_comment, thread) or nil)
				end, function(gerr)
					on_done(nil, "Failed to add review thread: " .. gerr)
				end)
			end)
		else
			if not pr.node_id then
				on_done(nil, "No GitHub PR node data cached")
				return
			end
			variables.pullRequestId = pr.node_id
			local instant_query = ([[
mutation($pullRequestId: ID!, $path: String!, $body: String!, $line: Int!, $side: DiffSide!, $startSide: DiffSide, $startLine: Int) {
  addPullRequestReviewThread(input: {
    pullRequestId: $pullRequestId
    path: $path body: $body line: $line side: $side
    startSide: $startSide startLine: $startLine
  }) {
    thread { id isResolved isOutdated path line startLine diffSide
      comments(first: 1) { nodes { %s } }
    }
  }
}
]]):format(COMMENT_FIELDS)
			graphql(instant_query, variables, function(data)
				local thread = data.addPullRequestReviewThread and data.addPullRequestReviewThread.thread
				local gh_comment = thread and thread.comments and thread.comments.nodes and thread.comments.nodes[1]
				on_done(gh_comment and to_diff_comment(gh_comment, thread) or nil)
			end, function(gerr)
				on_done(nil, "Failed to post comment: " .. gerr)
			end)
		end
		return
	end

	on_done(nil, "GitHub provider: top-level non-inline comments not supported")
end

---@param pr DiffCommentsPR
---@param comment DiffComment
---@param on_done fun(updated: DiffComment|nil, err: string|nil)
function M.edit_comment(pr, comment, on_done)
	if not comment or not comment.id then
		on_done(nil, "No comment selected")
		return
	end

	if comment.state == "PENDING" then
		local node_id = comment.node_id or (comment._raw and comment._raw.comment and comment._raw.comment.id)
		if not node_id then
			on_done(nil, "Missing comment node id")
			return
		end
		local query = [[
mutation($id: ID!, $body: String!) {
  updatePullRequestReviewComment(input: { pullRequestReviewCommentId: $id, body: $body }) {
    pullRequestReviewComment { id databaseId body createdAt updatedAt url }
  }
}
]]
		graphql(query, { id = node_id, body = comment.body or "" }, function(data)
			local updated = data.updatePullRequestReviewComment
				and data.updatePullRequestReviewComment.pullRequestReviewComment
			if not updated then
				on_done(nil, "Empty edit response")
				return
			end
			on_done(vim.tbl_extend("force", comment, {
				id = updated.databaseId,
				node_id = updated.id,
				body = updated.body,
				updated_at = updated.updatedAt,
				url = updated.url or comment.url,
			}))
		end, function(err)
			on_done(nil, "Failed to edit comment: " .. err)
		end)
		return
	end

	local endpoint = comment.context and ("repos/%s/%s/pulls/comments/%s"):format(pr.owner, pr.repo, comment.id)
		or ("repos/%s/%s/issues/comments/%s"):format(pr.owner, pr.repo, comment.id)

	local payload = vim.json.encode({ body = comment.body or "" })
	local stdout_chunks, stderr_chunks = {}, {}
	local job_id = vim.fn.jobstart(shell(("gh api %s --method PATCH --input -"):format(endpoint)), {
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
				if exit_code ~= 0 then
					on_done(nil, "Failed to edit comment: " .. table.concat(stderr_chunks, ""))
					return
				end
				local ok, result = pcall(
					vim.json.decode,
					table.concat(stdout_chunks, ""),
					{ luanil = { object = true, array = true } }
				)
				if not ok or type(result) ~= "table" then
					on_done(nil, "Failed to parse edit response")
					return
				end
				on_done({
					id = result.id,
					node_id = result.node_id,
					parent_id = comment.parent_id,
					thread_id = comment.thread_id,
					author = comment.author,
					body = result.body or comment.body,
					context = comment.context,
					state = comment.state,
					created_at = result.created_at or comment.created_at,
					updated_at = result.updated_at,
					url = result.html_url or comment.url,
					_raw = comment._raw,
				})
			end)
		end,
	})
	vim.fn.chansend(job_id, payload)
	vim.fn.chanclose(job_id, "stdin")
end

---@param pr DiffCommentsPR
---@param comment DiffComment
---@param on_done fun(ok: boolean|nil, err: string|nil)
function M.delete_comment(pr, comment, on_done)
	if not comment or not comment.id then
		on_done(nil, "No comment selected")
		return
	end
	local stderr_chunks = {}
	vim.fn.jobstart(
		shell(("gh api repos/%s/%s/pulls/comments/%s --method DELETE"):format(pr.owner, pr.repo, comment.id)),
		{
			stderr_buffered = true,
			on_stderr = function(_, data)
				if data then
					table.insert(stderr_chunks, table.concat(data, "\n"))
				end
			end,
			on_exit = function(_, exit_code)
				vim.schedule(function()
					if exit_code ~= 0 then
						on_done(nil, "Failed to delete comment: " .. table.concat(stderr_chunks, ""))
						return
					end
					on_done(true)
				end)
			end,
		}
	)
end

---@param pr DiffCommentsPR
---@param root DiffComment
---@param on_done fun(ok: boolean|nil, err: string|nil)
function M.resolve_thread(pr, root, on_done)
	local tid = thread_node_id(root)
	if not tid then
		on_done(nil, "No thread id on comment")
		return
	end
	local query = [[
mutation($threadId: ID!) {
  resolveReviewThread(input: { threadId: $threadId }) { thread { id isResolved } }
}
]]
	graphql(query, { threadId = tid }, function()
		on_done(true)
	end, function(err)
		on_done(nil, "Failed to resolve thread: " .. err)
	end)
end

---@param pr DiffCommentsPR
---@param root DiffComment
---@param on_done fun(ok: boolean|nil, err: string|nil)
function M.unresolve_thread(pr, root, on_done)
	local tid = thread_node_id(root)
	if not tid then
		on_done(nil, "No thread id on comment")
		return
	end
	local query = [[
mutation($threadId: ID!) {
  unresolveReviewThread(input: { threadId: $threadId }) { thread { id isResolved } }
}
]]
	graphql(query, { threadId = tid }, function()
		on_done(true)
	end, function(err)
		on_done(nil, "Failed to unresolve thread: " .. err)
	end)
end

---@param pr GithubPR
---@param event "APPROVE"|"REQUEST_CHANGES"|"COMMENT"
---@param body string
---@param on_done fun(ok: boolean|nil, err: string|nil)
function M.submit_review(pr, event, body, on_done)
	if not pr.node_id then
		on_done(nil, "No GitHub PR node data cached")
		return
	end

	if pr.pending_review_node_id then
		local submit_query = [[
mutation($pullRequestReviewId: ID!, $event: PullRequestReviewEvent!, $body: String!) {
  submitPullRequestReview(input: {
    pullRequestReviewId: $pullRequestReviewId event: $event body: $body
  }) { pullRequestReview { id } }
}
]]
		graphql(submit_query, {
			pullRequestReviewId = pr.pending_review_node_id,
			event = event,
			body = body,
		}, function()
			pr.pending_review_node_id = nil
			on_done(true)
		end, function(err)
			on_done(nil, "Failed to submit review: " .. err)
		end)
		return
	end

	local create_query = [[
mutation($pullRequestId: ID!, $event: PullRequestReviewEvent!, $body: String!) {
  addPullRequestReview(input: {
    pullRequestId: $pullRequestId event: $event body: $body
  }) { pullRequestReview { id } }
}
]]
	graphql(create_query, {
		pullRequestId = pr.node_id,
		event = event,
		body = body,
	}, function()
		on_done(true)
	end, function(err)
		on_done(nil, "Failed to submit review: " .. err)
	end)
end

---@param pr DiffCommentsPR
---@return string|nil
function M.pr_url(pr)
	return pr and pr.url or nil
end

return M
