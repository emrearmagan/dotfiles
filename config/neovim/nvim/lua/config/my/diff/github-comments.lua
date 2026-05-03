-- Thanks to this amazing guy: https://github.com/fredrikaverpil/dotfiles/blob/main/nvim-fredrik/plugin/github_comments.lua
if not vim.g.use_codediff then
	return {}
end

local M = { name = "github" }

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

local function origin_url(root)
	if type(root) ~= "string" or root == "" then
		return ""
	end
	local result = vim.system({ "git", "-C", root, "remote", "get-url", "origin" }, { text = true }):wait()
	if not result or result.code ~= 0 then
		return ""
	end
	return trim(result.stdout)
end

function M.can_handle(session)
	return session ~= nil and origin_url(session.git_root):find("github", 1, false) ~= nil
end

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

local function pr_from_codediff_revision(session, callback)
	if not session or not session.git_root then
		callback(nil)
		return
	end

	local sha = tostring(session.modified_revision or "")
	if sha == "" or sha == "WORKING" or sha == "STAGED" then
		callback(nil)
		return
	end

	repo_slug_from_root(session.git_root, function(owner, repo)
		if not owner or not repo then
			callback(nil)
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
					callback(nil)
					return
				end

				local ok, pulls = pcall(vim.json.decode, result.stdout or "")
				if not ok or type(pulls) ~= "table" or #pulls == 0 then
					callback(nil)
					return
				end

				local selected = pulls[1]
				for _, pr in ipairs(pulls) do
					if pr.state == "open" then
						selected = pr
						break
					end
				end

				local number = tostring(selected.number or "")
				if number == "" then
					callback(nil)
					return
				end

				callback({
					number = number,
					owner = owner,
					repo = repo,
					url = ("https://github.com/%s/%s/pull/%s"):format(owner, repo, number),
					pending_review_ids = {},
					pending_review_node_ids = {},
				})
			end)
		end)
	end)
end

local function wait_for_codediff_pr(session, attempt, callback)
	attempt = attempt or 1
	pr_from_codediff_revision(session, function(pr)
		if pr then
			callback(pr)
			return
		end
		if attempt >= 12 then
			callback(nil)
			return
		end
		vim.defer_fn(function()
			wait_for_codediff_pr(session, attempt + 1, callback)
		end, 100)
	end)
end

local function pr_from_current_branch(session, callback)
	vim.system(
		{ "gh", "pr", "view", "--json", "number", "--jq", ".number" },
		{ text = true, cwd = session.git_root },
		function(result)
			vim.schedule(function()
				local number = result and result.code == 0 and trim(result.stdout) or ""
				if number == "" then
					callback(nil)
					return
				end
				repo_slug_from_root(session.git_root, function(owner, repo)
					if not owner or not repo then
						callback(nil)
						return
					end
					callback({
						number = number,
						owner = owner,
						repo = repo,
						url = ("https://github.com/%s/%s/pull/%s"):format(owner, repo, number),
						pending_review_ids = {},
						pending_review_node_ids = {},
					})
				end)
			end)
		end
	)
end

function M.find_pr(session, callback)
	wait_for_codediff_pr(session, 1, function(pr)
		if pr then
			callback(pr)
			return
		end

		pr_from_current_branch(session, function(branch_pr)
			if not branch_pr then
				callback(nil, "No GitHub PR found")
				return
			end
			callback(branch_pr)
		end)
	end)
end

function M.fetch_diff_files(pr, callback)
	local stdout_chunks = {}
	local cmd = ("gh api repos/{owner}/{repo}/pulls/%s/files --paginate"):format(pr.number)

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

				local ok, files = pcall(vim.json.decode, table.concat(stdout_chunks, ""))
				if not ok or type(files) ~= "table" then
					callback({})
					return
				end

				local by_path = {}
				for _, file in ipairs(files) do
					by_path[file.filename] = file
				end
				callback(by_path)
			end)
		end,
	})
end

local function fetch_review_comments(pr, callback)
	local stdout_chunks = {}
	local cmd = ("gh api repos/{owner}/{repo}/pulls/%s/comments --paginate"):format(pr.number)

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
					local pending = pr.pending_review_ids[comment.pull_request_review_id] == true
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
						pending = pending,
					})
				end
				callback(comments)
			end)
		end,
	})
end

local function fetch_review_comments_for_review(pr, review_id, callback)
	local stdout_chunks = {}
	local cmd = ("gh api repos/{owner}/{repo}/pulls/%s/reviews/%s/comments --paginate"):format(pr.number, review_id)

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
						pending = true,
					})
				end
				callback(comments)
			end)
		end,
	})
end

local function fetch_pending_review_comments(pr, callback)
	local review_ids = vim.tbl_keys(pr.pending_review_ids or {})
	if #review_ids == 0 then
		callback({})
		return
	end

	local remaining = #review_ids
	local all_comments = {}
	for _, review_id in ipairs(review_ids) do
		fetch_review_comments_for_review(pr, review_id, function(comments)
			all_comments = merge_comments(all_comments, comments)
			remaining = remaining - 1
			if remaining == 0 then
				callback(all_comments)
			end
		end)
	end
end

function M.fetch_comments(pr, callback)
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

	local loaded = {
		review_comments = false,
		pending_comments = false,
		done = false,
	}
	local all_comments = {}

	local function finish()
		if loaded.done or not loaded.review_comments or not loaded.pending_comments then
			return
		end
		loaded.done = true
		callback(all_comments)
	end

	graphql(query, { owner = pr.owner, repo = pr.repo, pr = tonumber(pr.number) }, function(data)
		local gh_pr = data.repository and data.repository.pullRequest
		if gh_pr then
			pr.node_id = gh_pr.id
			pr.pending_review_ids = {}
			pr.pending_review_node_ids = {}
			pr.pending_review_node_id = nil
			for _, review in ipairs(gh_pr.reviews and gh_pr.reviews.nodes or {}) do
				if review.state == "PENDING" then
					pr.pending_review_ids[review.databaseId] = true
					pr.pending_review_node_ids[review.databaseId] = review.id
					pr.pending_review_node_id = review.id
				end
			end
		end

		fetch_review_comments(pr, function(comments)
			all_comments = merge_comments(all_comments, comments)
			loaded.review_comments = true
			finish()
		end)

		fetch_pending_review_comments(pr, function(comments)
			all_comments = merge_comments(all_comments, comments)
			loaded.pending_comments = true
			finish()
		end)
	end, function(err)
		notify(vim.log.levels.WARN, "Failed to fetch pending review ids: " .. err)
		fetch_review_comments(pr, function(comments)
			all_comments = comments
			loaded.review_comments = true
			loaded.pending_comments = true
			finish()
		end)
	end)
end

local function thread_variables(context, body)
	local vars = {
		path = context.file_path,
		body = body,
		line = context.end_line,
		side = context.side,
	}
	if context.start_line ~= context.end_line then
		vars.startSide = context.side
		vars.startLine = context.start_line
	end
	return vars
end

local function add_pending_comment(pr, context, body, callback)
	local variables = thread_variables(context, body)
	local query = [[
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

	local function add_thread(review_id)
		variables.pullRequestReviewId = review_id
		graphql(query, variables, function()
			callback(true)
		end, function(err)
			callback(nil, "Failed to add review thread: " .. err)
		end)
	end

	if pr.pending_review_node_id then
		add_thread(pr.pending_review_node_id)
		return
	end

	if not pr.node_id then
		callback(nil, "No GitHub PR node data cached")
		return
	end

	local create_query = [[
mutation($pullRequestId: ID!) {
  addPullRequestReview(input: { pullRequestId: $pullRequestId }) {
    pullRequestReview { id }
  }
}
]]

	graphql(create_query, { pullRequestId = pr.node_id }, function(data)
		local review_id = data.addPullRequestReview
			and data.addPullRequestReview.pullRequestReview
			and data.addPullRequestReview.pullRequestReview.id
		if not review_id then
			callback(nil, "Failed to create pending review")
			return
		end
		pr.pending_review_node_id = review_id
		add_thread(review_id)
	end, function(err)
		callback(nil, "Failed to create pending review: " .. err)
	end)
end

local function add_instant_comment(pr, context, body, callback)
	if not pr.node_id then
		callback(nil, "No GitHub PR node data cached")
		return
	end

	local variables = thread_variables(context, body)
	variables.pullRequestId = pr.node_id
	local query = [[
mutation($pullRequestId: ID!, $path: String!, $body: String!, $line: Int!, $side: DiffSide!, $startSide: DiffSide, $startLine: Int) {
  addPullRequestReviewThread(input: {
    pullRequestId: $pullRequestId
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

	graphql(query, variables, function()
		callback(true)
	end, function(err)
		callback(nil, "Failed to post comment: " .. err)
	end)
end

function M.add_comment(pr, context, body, opts, callback)
	if opts and opts.pending then
		add_pending_comment(pr, context, body, callback)
	else
		add_instant_comment(pr, context, body, callback)
	end
end

function M.reply(pr, root_comment, body, callback)
	if root_comment.pending or pr.pending_review_ids[root_comment.pull_request_review_id] then
		local review_id = pr.pending_review_node_ids[root_comment.pull_request_review_id] or pr.pending_review_node_id
		if not review_id or not root_comment.node_id then
			callback(nil, "Missing pending review node data. Refresh CodeDiff and try again.")
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
			pullRequestReviewId = review_id,
			inReplyTo = root_comment.node_id,
			body = body,
		}, function()
			callback(true)
		end, function(err)
			callback(nil, "Failed to post pending reply: " .. err)
		end)
		return
	end

	local payload = vim.json.encode({ body = body })
	local stderr_chunks = {}
	local cmd = ("gh api repos/{owner}/{repo}/pulls/%s/comments/%s/replies --method POST --input -"):format(
		pr.number,
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
					callback(nil, "Failed to post reply: " .. table.concat(stderr_chunks, ""))
					return
				end
				callback(true)
			end)
		end,
	})

	vim.fn.chansend(job_id, payload)
	vim.fn.chanclose(job_id, "stdin")
end

function M.delete_comment(_, comment, callback)
	if not comment or not comment.id then
		callback(nil, "No comment selected")
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
					callback(nil, "Failed to delete comment: " .. table.concat(stderr_chunks, ""))
					return
				end
				callback(true)
			end)
		end,
	})
end

function M.pr_url(pr)
	return pr and pr.url or nil
end

return M
