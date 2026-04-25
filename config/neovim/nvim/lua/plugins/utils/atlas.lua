return {
	-- "emrearmagan/atlas.nvim",
	dir = "/Users/emrearmagan/development/nvim/atlas.nvim",
	config = function()
		local function open_live_command(title, cmd, on_exit)
			local width = math.floor(vim.o.columns * 0.4)
			local height = math.floor(vim.o.lines * 0.25)
			local row = math.floor((vim.o.lines - height) / 2) - 1
			local col = math.floor((vim.o.columns - width) / 2)
			local buf = vim.api.nvim_create_buf(false, true)
			vim.bo[buf].bufhidden = "wipe"
			local win = vim.api.nvim_open_win(buf, true, {
				relative = "editor",
				style = "minimal",
				border = "rounded",
				title = " " .. title .. " ",
				title_pos = "center",
				width = width,
				height = height,
				row = math.max(0, row),
				col = math.max(0, col),
			})
			vim.keymap.set("n", "q", function()
				if vim.api.nvim_win_is_valid(win) then
					vim.api.nvim_win_close(win, true)
				end
			end, { buffer = buf, silent = true })
			vim.fn.jobstart(cmd, {
				term = true,
				on_exit = function(_, code, _)
					vim.schedule(function()
						if on_exit then
							on_exit(code)
						end
					end)
				end,
			})
		end

		require("atlas").setup({
			---@class AtlasPullsConfig
			pulls = {
				diff = {
					open_cmd = "DiffviewOpen",
				},

				repo_config = {
					paths = {
						["emrearmaganxxx/*"] = "~/development/nvim/atlas.testing/new/*",
					},
				},

				custom_actions = {
					{
						id = "checkout_worktree",
						label = "Checkout (worktrees)",

						---@param _ PullRequest
						---@param ctx AtlasPullsCustomActionContext
						---@param done fun(ok: boolean|nil, message: string|nil)
						run = function(_, ctx, done)
							if not ctx.repo_path then
								done(false, "No repo path")
								return
							end

							local branch = tostring(ctx.pr.source.branch or "")
							if branch == "" then
								done(false, "Missing source branch")
								return
							end

							local destination = ctx.repo_path .. ".worktrees"

							open_live_command("worktrees", {
								"worktrees",
								branch,
								destination,
								ctx.repo_path,
								"--split=h",
								"--session=worktrees",
							}, function(code)
								if code ~= 0 then
									done(false, "worktrees failed (exit " .. tostring(code) .. ")")
									return
								end
								done(true, "Worktree ready for " .. branch)
							end)
						end,
					},
					{
						id = "code_review_worktree",
						label = "Code Review",

						---@param _ PullRequest
						---@param ctx AtlasPullsCustomActionContext
						---@param done fun(ok: boolean|nil, message: string|nil)
						run = function(_, ctx, done)
							if not ctx.repo_path then
								done(false, "No repo path")
								return
							end

							local branch = tostring(ctx.pr.source.branch or "")
							if branch == "" then
								done(false, "Missing source branch")
								return
							end

							local destination = ctx.repo_path .. ".reviews"

							open_live_command("worktrees-review", {
								"worktrees-review",
								branch,
								destination,
								ctx.repo_path,
								"--skip-unchanged",
							}, function(code)
								if code ~= 0 then
									done(false, "worktrees-review failed (exit " .. tostring(code) .. ")")
									return
								end
								done(true, "Code review started for " .. branch)
							end)
						end,
					},
				},

				providers = {
					---@type AtlasBitbucketConfig
					bitbucket = {
						user = os.getenv("BITBUCKET_USER") or "",
						token = os.getenv("BITBUCKET_TOKEN") or "",
						cache_ttl = 300,

						---@type AtlasBitbucketViewConfig[]
						views = {
							{
								name = "Me",
								key = "1",
								layout = "compact",
								repos = {
									{ workspace = "emrearmaganxxx", repo = "atlas" },
									{ workspace = "emrearmaganxxx", repo = "new" },
								},

								---@param pr PullRequest
								---@param user PullsUser|nil
								filter = function(pr, user)
									return pr.author and user and pr.author.id == user.id
								end,
							},
							{
								name = "Team",
								key = "2",
								layout = "plain",
								repos = {
									{ workspace = "emrearmaganxxx", repo = "atlas" },
									{ workspace = "emrearmaganxxx", repo = "new" },
								},
							},
						},
					},
				},
			},

			---@class AtlasIssuesConfig
			issues = {
				fetch_parent_issues = true,
				custom_actions = {
					{
						id = "review_ticket",
						label = "Review Ticket",

						---@param issue Issue
						---@param _ AtlasIssuesCustomActionContext
						---@param done fun(ok: boolean|nil, message: string|nil)
						run = function(issue, _, done)
							local issue_key = tostring(issue.key or "")
							if issue_key == "" then
								done(false, "Missing issue key")
								return
							end

							local summary = tostring(issue.summary or "")
							local issue_type = issue.type and tostring(issue.type.name or "") or ""
							local status = tostring(issue.status or "")
							local priority = tostring(issue.priority or "")
							local session = "ticket-review"
							local window = issue_key:gsub("[^%w_-]", "-")
							local prompt = table.concat({
								"Use the ticket-review subagent to review this Jira ticket for completeness and readiness.",
								"First fetch the full Jira issue, including description and comments if available, using the configured MCP/tools.",
								"First describe what the ticket is asking for, then return a Jira-comment-friendly review, and end with the Summary section.",
								"",
								"Issue key: " .. issue_key,
								"Summary: " .. summary,
								"Type: " .. issue_type,
								"Status: " .. status,
								"Priority: " .. priority,
							}, "\n")

							open_live_command("ticket-review", {
								"tmux-sessions",
								"run-window",
								session,
								window,
								"--",
								"opencode",
								"--prompt",
								prompt,
							}, function(code)
								if code ~= 0 then
									done(false, "ticket review failed to start (exit " .. tostring(code) .. ")")
									return
								end
								done(true, "Ticket review started in tmux session " .. session)
							end)
						end,
					},
				},
				jira = {
					base_url = os.getenv("JIRA_BASE_URL") or "",
					email = os.getenv("JIRA_EMAIL") or "",
					token = os.getenv("JIRA_TOKEN") or "",
					cache_ttl = 300,

					queries = {
						["Active Sprint"] = "project = '%s' AND (sprint in openSprints()) ORDER BY status ASC, assignee ASC, Rank ASC",
						["Next sprint"] = "project = '%s' AND (sprint in futureSprints() ) ORDER BY status ASC, assignee ASC, Rank ASC",
						["Backlog"] = "project = '%s' AND ((issuetype IN standardIssueTypes() OR issuetype = Sub-task) AND (sprint IS EMPTY OR sprint NOT IN openSprints()) OR issuetype = Epic) AND statusCategory != Done ORDER BY status ASC, assignee ASC, Rank ASC",
					},

					project_config = {
						story_points_field = "customfield_100016",
						["KAN"] = {
							customfield_10003 = {
								name = "Approvers",

								---@param value any
								---@return string|nil
								format = function(value)
									if type(value) ~= "table" or #value == 0 then
										return nil
									end

									local names = {}
									for _, user in ipairs(value) do
										local name = type(user) == "table" and user.displayName or nil
										if type(name) == "string" and name ~= "" then
											table.insert(names, name)
										end
									end
									if #names == 0 then
										return "NONE"
									end
									return table.concat(names, ", ")
								end,
								hl_group = "AtlasTextMuted",
								display = "table",
							},
							customfield_10019 = {
								name = "Other",

								---@param value any
								---@return string|nil
								format = function(value)
									return value
								end,
								hl_group = "AtlasTextMuted",
								display = "chip",
							},
						},
					},
					views = {
						{
							name = "Active Sprint",
							key = "S",
							jql = "project = KAN",
						},
						{
							name = "My Tasks",
							key = "M",
							jql = "project = KAN AND assignee = currentUser()",
						},
						{
							name = "To Do",
							key = "T",
							jql = 'project = KAN AND sprint in openSprints() AND statusCategory = "To Do" AND assignee is EMPTY ORDER BY priority ASC',
						},
					},
				},
			},
		})
	end,
}
