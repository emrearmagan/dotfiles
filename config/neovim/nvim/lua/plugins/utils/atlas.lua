return {
	-- "emrearmagan/atlas.nvim",
	name = "atlas.nvim",
	dir = "/Users/emrearmagan/development/nvim/atlas/atlas.nvim",
	-- dir = "/Users/emrearmagan/development/nvim/atlas/gitea-forgejo",
	cmd = { "Atlas", "AtlasDiff" },
	init = function()
		vim.cmd("cabbrev atlas Atlas")
	end,
	opts = {
		ui = {
			global_statusline = true,
			picker = "auto",
			listed_buffer = false,
		},

		---@class AtlasPullsConfig
		pulls = {
			delete_notes = true, -- Delete local PR notes after approval or merge.
			default_merge_method = "merge", -- "merge" or "squash".
			default_delete_branch = true,

			diff = {
				open_cmd = "AtlasDiff",
				layout = "inline",
				compact = true,
				compact_context_lines = 3,
				show_review_panel = false,
				comment_display = "virtual_lines",
				explorer = {
					grouped = true, -- Group changed files by directory.
					hidden = false,
					show_commits = false,
					width = 40,
					initial_focus = "explorer",
					ignore = { ".git/**", ".jj/**" },
				},
			},

			repo_config = {
				paths = {
					["emrearmagan/*"] = "~/development/*",
					["emrearmagan/*.nvim"] = "~/development/nvim/*.nvim",
					["emrearmagan/atlas.nvim"] = "~/development/nvim/atlas/atlas.nvim",
					["emrearmagan/atlas.test"] = "~/development/nvim/atlas/atlas.testing/atlas.test",
					["emrearmagan/atlas.test.gitlab"] = "~/development/nvim/atlas/atlas.testing/atlas.test.gitlab",
					["atlas/atlas.test.forgejo"] = "~/development/nvim/atlas/atlas.testing/atlas.test.forgejo",
					["atlas/atlas.test.gitea"] = "~/development/nvim/atlas/atlas.testing/atlas.test.gitea",
					["atlasxx/atlas.test.bitbucket"] = "~/development/nvim/atlas/atlas.testing/atlas.test.bitbucket",
					["ATLAS/atlas"] = "/Users/emrearmagan/development/nvim/atlas.testing/bitbucket-server/atlas",
				},
				settings = {
					["emrearmagan/atlas.nvim"] = {
						readme = "README.md",
						pr_template = ".github/pull_request_template.md",
					},
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
						local destination = ctx.repo_path .. ".worktrees"

						local output = ctx.output("worktrees")
						output:run({
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
						local destination = ctx.repo_path .. ".reviews"
						local target = tostring((ctx.pr.link or {}).html or "")
						local base = tostring((ctx.pr.destination or {}).branch or "")
						local command = {
							"worktrees-review",
							branch,
							destination,
							ctx.repo_path,
							"--skip-unchanged",
							"--target=" .. target,
							"--base=" .. base,
						}

						local output = ctx.output("worktrees-review")
						output:run(command, function(code)
							if code ~= 0 then
								done(false, "worktrees-review failed (exit " .. tostring(code) .. ")")
								return
							end
							done(true, "Code review started for " .. branch)
						end)
					end,
				},
				{
					id = "test_async_output",
					label = "Test Async Output",
					run = function(_, ctx, done)
						local output = ctx.output("Pull request output")
						output:write("Started")
						vim.defer_fn(function()
							output:write("Still running...")
						end, 500)
						vim.defer_fn(function()
							output:write("Finished")
							done(true, "Async output finished")
						end, 1000)
					end,
				},
			},

			providers = {
				---@type AtlasGiteaPullsConfig
				gitea = {
					base_url = "http://localhost:3001",
					token = vim.env.GITEA_TOKEN,
					views = {
						{
							name = "Gitea",
							key = "1",
							layout = "compact",
							repo = "atlas/atlas.test.gitea",
						},
					},
				},

				-- Forgejo:
				-- gitea = {
				-- 	api_type = "forgejo",
				-- 	base_url = "http://localhost:3000",
				-- 	token = vim.env.FORGEJO_TOKEN,
				-- 	views = {
				-- 		{
				-- 			name = "Forgejo",
				-- 			key = "1",
				-- 			layout = "compact",
				-- 			repo = "atlas/atlas.test.forgejo",
				-- 		},
				-- 	},
				-- },

				---@type AtlasGitHubConfig
				github = {
					cache_ttl = 3000,
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
					},
					bookmarks = {
						key = "S",
						label = "Search",
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
						key = "S",
						label = "Search",
						items = {
							["Reviewing"] = { scope = "all", extra_params = { reviewer_id = "Me" } },
							["GitLab Org"] = { group = "gitlab-org" },
							["Merged by me"] = { scope = "all", state = "merged", author_username = "emrearmagan" },
						},
					},
				},

				bitbucket = {
					user = vim.env.BITBUCKET_USER,
					token = vim.env.BITBUCKET_TOKEN,
					cache_ttl = 3000,

					---@type AtlasBitbucketViewConfig[]
					views = {
						{
							name = "Me",
							key = "1",
							layout = "compact",
							targets = {
								{ workspace = "atlasxx", repo = "atlas.test.bitbucket" },
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
							targets = {
								{ workspace = "atlasxx", project = "AT" },
							},
						},
					},
					bookmarks = {
						key = "S",
						label = "Search",
						items = {
							["Atlas"] = {
								targets = {
									{ workspace = "atlasxx", repo = "atlas.test.bitbucket" },
								},
							},
							["Ready"] = {
								targets = {
									{ workspace = "atlasxx", project = "AT" },
								},
								filter = function(pr)
									return not pr.draft
								end,
							},
						},
					},
				},
			},
		},

		---@class AtlasIssuesConfig
		issues = {
			max_results = 100,
			with_relationships = true,
			custom_actions = {
				{
					id = "review_ticket",
					label = "Review Ticket",

					---@param issue Issue
					---@param ctx AtlasIssuesCustomActionContext
					---@param done fun(ok: boolean|nil, message: string|nil)
					run = function(issue, ctx, done)
						local issue_key = tostring(issue.key or "")
						if issue_key == "" then
							done(false, "Missing issue key")
							return
						end

						local summary = tostring(issue.summary or "")
						local issue_type = issue.type and tostring(issue.type.name or "") or ""
						local status = tostring(issue.status or "")
						local priority = tostring(issue.priority or "")
						local session = "spec-review"
						local window = issue_key:gsub("[^%w_-]", "-")
						local prompt = table.concat({
							"Use the spec-review agent to review this Jira ticket.",
							"",
							"1. Fetch the full Jira issue content via Jira MCP/tools if available.",
							"2. Review it for engineering readiness: clarity, scope, blockers, acceptance criteria, risks, and missing descisions.",
							"3. Do not inspect inspect implementation code. This is a ticket/spec review only.",
							"",
							"Issue key: " .. issue_key,
							"Summary: " .. summary,
							"Type: " .. issue_type,
							"Status: " .. status,
							"Priority: " .. priority,
						}, "\n")

						local output = ctx.output("ticket-review")
						output:run({
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
				{
					id = "test_async_output",
					label = "Test Async Output",
					run = function(_, ctx, done)
						local output = ctx.output("Issue output")
						output:write("Started")
						vim.defer_fn(function()
							output:write("Still running...")
						end, 500)
						vim.defer_fn(function()
							output:write("Finished")
							done(true, "Async output finished")
						end, 1000)
					end,
				},
			},

			providers = {
				---@type AtlasGiteaIssuesConfig
				gitea = {
					base_url = "http://localhost:3001",
					token = vim.env.GITEA_TOKEN,
					views = {
						{
							name = "Gitea",
							key = "1",
							layout = "compact",
							repo = "atlas/atlas.test.gitea",
						},
					},
				},
				-- Forgejo:
				-- gitea = {
				-- 	api_type = "forgejo",
				-- 	base_url = "http://localhost:3000",
				-- 	token = vim.env.FORGEJO_TOKEN,
				-- 	views = {
				-- 		{
				-- 			name = "Forgejo",
				-- 			key = "1",
				-- 			layout = "compact",
				-- 			repo = "atlas/atlas.test.forgejo",
				-- 		},
				-- 	},
				-- },

				github = {
					cache_ttl = 3000,
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
						key = "S",
						label = "Search",
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
					cache_ttl = 300,
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
						key = "S",
						label = "Search",
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
					api_type = "cloud",
					auth_method = "basic",
					cache_ttl = 3000,

					bookmarks = {
						key = "J",
						label = "JQL",
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
	},
}
