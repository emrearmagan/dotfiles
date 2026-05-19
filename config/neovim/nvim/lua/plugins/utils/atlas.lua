return {
	-- "emrearmagan/atlas.nvim",
	dir = "/Users/emrearmagan/development/nvim/atlas.nvim",
	event = "VeryLazy",
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
					open_cmd = "CodeDiff",
				},

				repo_config = {
					paths = {
						["emrearmagan/*"] = "~/development/*",
						["emrearmagan/*.nvim"] = "~/development/nvim/*.nvim",
						["emrearmagan/test"] = "~/development/nvim/atlas.testing/test",
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
					---@type AtlasGitHubConfig
					github = {
						views = {
							{
								name = "Review",
								key = "1",
								layout = "compact",
								search = "is:pr user:emrearmagan is:pr sort:updated-desc",
							},
							{
								name = "My PRs",
								key = "2",
								layout = "compact",
								search = "author:@me sort:updated-desc",
							},
							{
								name = "Neovim",
								key = "3",
								layout = "plain",
								search = "repo:neovim/neovim sort:updated-desc",
							},
							{
								name = "Best",
								key = "4",
								layout = "plain",
								search = "repo:folke/lazy.nvim repo:nvim-telescope/telescope.nvim repo:hrsh7th/nvim-cmp repo:lewis6991/gitsigns.nvim repo:nvim-treesitter/nvim-treesitter sort:updated-desc",
							},
						},
						bookmarks = {
							items = {
								["Review requested"] = "is:pr is:open review-requested:@me sort:updated-desc",
								["Recently merged"] = "is:pr is:merged author:@me sort:updated-desc",
								["Drafts"] = "is:pr is:draft author:@me",
							},
						},
					},
					gitlab = {
						base_url = "https://gitlab.com",
						token = vim.env.GITLAB_TOKEN,
						cache_ttl = 300,
						views = {
							{ name = "Assigned", key = "1", scope = "assigned_to_me" },
							{ name = "Created", key = "2", scope = "created_by_me" },
							{
								name = "GitLab",
								key = "3",
								group = "gitlab-org",
							},
						},
						bookmarks = {
							items = {
								["Reviewing"] = { scope = "all", extra_params = { reviewer_id = "Me" } },
								["GitLab Org"] = { group = "gitlab-org" },
								["Merged by me"] = { scope = "all", state = "merged", author_username = "emrearmagan" },
							},
						},
					},

					---@type AtlasBitbucketConfig
					bitbucket = {
						user = vim.env.BITBUCKET_USER,
						token = vim.env.BITBUCKET_TOKEN,
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
								---@param ctx { user: PullsUser|nil }
								filter = function(pr, ctx)
									local user = ctx.user
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
								"Load /skill:ticket-review and apply it to this Jira ticket.",
								"Fetch the full Jira issue content if Jira MCP/tools are available.",
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
								"pi",
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

				providers = {
					github = {
						views = {
							{
								name = "Issues",
								key = "1",
								layout = "compact",
								search = "is:issue user:emrearmagan is:open sort:updated-desc",
							},
							{
								name = "Issues (all)",
								key = "2",
								layout = "plain",
								search = "is:issue user:emrearmagan sort:updated-desc",
							},
							{
								name = "Issues",
								key = "3",
								search = "is:issue repo:neovim/neovim is:open sort:updated-desc",
							},
							{
								name = "Tracked Issues",
								key = "4",
								search = "repo:neovim/neovim is:issue 32280 19624 sort:updated-desc",
							},
						},
						bookmarks = {
							items = {
								["Assigned to me"] = "is:issue is:open assignee:@me",
								["Mentions"] = "is:issue is:open mentions:@me",
								["Recently closed"] = "is:issue is:closed author:@me sort:updated-desc",
								["Bugs (neovim)"] = "is:issue is:open repo:neovim/neovim label:bug sort:reactions-desc",
							},
						},
					},
					gitlab = {
						base_url = "https://gitlab.com",
						token = vim.env.GITLAB_TOKEN,
						views = {
							{ name = "Assigned", key = "1", scope = "assigned_to_me", state = "opened" },
							{ name = "Created", key = "2", scope = "created_by_me", state = "opened" },
							{
								name = "Reviewing",
								key = "3",
								scope = "all",
								state = "opened",
							},
						},
						bookmarks = {
							items = {
								["Assigned open"] = { scope = "assigned_to_me", state = "opened" },
								["Created closed"] = { scope = "created_by_me", state = "closed" },
								["No labels"] = {
									scope = "all",
									state = "opened",
									extra_params = { ["not[labels]"] = "*" },
								},
							},
						},
					},

					jira = {
						base_url = vim.env.JIRA_BASE_URL,
						email = vim.env.JIRA_EMAIL,
						token = vim.env.JIRA_TOKEN,
						cache_ttl = 300,

						bookmarks = {
							-- key = "J", -- default
							-- label = "JQL", -- default
							items = {
								["Backlog"] = "project = KAN AND statusCategory != Done AND (sprint IS EMPTY OR sprint NOT IN openSprints()) ORDER BY Rank ASC",
								["Next sprint"] = "project = KAN AND sprint in futureSprints() ORDER BY Rank ASC",
								["My open"] = "assignee = currentUser() AND statusCategory != Done ORDER BY updated DESC",
								["Recently updated"] = "project = KAN ORDER BY updated DESC",
							},
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
								key = "1",
								jql = "project = KAN",
							},
							{
								name = "My Tasks",
								key = "2",
								layout = "compact",
								jql = "project = KAN AND assignee = currentUser()",
							},
							{
								name = "To Do",
								key = "3",
								jql = 'project = KAN AND sprint in openSprints() AND statusCategory = "To Do" AND assignee is EMPTY ORDER BY priority ASC',
							},
						},
					},
				},
			},
		})
	end,
}
