if vim.env.ATLAS_DEV == "1" then
	return dofile(vim.fn.expand("~/development/nvim/atlas/atlas-dev.lua"))
end

return {
	name = "atlas.nvim",
	dir = "/Users/emrearmagan/development/nvim/atlas/atlas.nvim",

	---@type AtlasConfig
	opts = {
		ui = {
			statusline = { atlas = true, diff = true },
			picker = "auto",
			listed_buffer = false,
		},
		keymaps = {
			pulls = {
				custom = {
					{
						key = "gP",
						desc = "Open pipelines",
						callback = function(context, done)
							local actions = require("atlas.pulls.actions")
							actions.run("open_pipelines", context, done)
						end,
					},
				},
			},
		},

		---@type AtlasPullsConfig
		pulls = {
			delete_notes = true, -- Delete local PR notes after approval or merge.
			default_merge_method = "merge", -- "merge" or "squash".
			default_delete_branch = true,
			git_transport = "https",

			diff = {
				open_cmd = "auto",
				layout = "inline",
				compact = true,
				review_panel = {
					hidden = false,
				},
				comment_display = "virtual_lines", -- "virtual_lines" or compact "virtual_text" hints.
				lsp = {
					-- enabled = true,
					dir = nil,
					link = {},
				},
				explorer = {
					grouped = true, -- Group changed files by directory.
					hidden = false,
					show_commits = true,
					width = 40,
					initial_focus = "explorer",
					preview = true,
					focus_on_select = false,
					ignore = { ".git/**", ".jj/**" },
				},
			},

			repo_config = {
				paths = {
					["emrearmagan/*"] = "~/development/*",
					["emrearmagan/*.nvim"] = "~/development/nvim/*.nvim",
					["emrearmagan/atlas.nvim"] = "~/development/nvim/atlas/atlas.nvim",
				},
			},

			---@type AtlasGitHubPullsConfig
			github = {
				views = {
					{
						name = "My PRs",
						key = "1",
						layout = "compact",
						search = "is:pr is:open author:@me sort:updated-desc",
					},
					{
						name = "Review Requested",
						key = "2",
						layout = "compact",
						search = "is:pr is:open review-requested:@me sort:updated-desc",
					},
					{
						name = "My Repos",
						key = "3",
						layout = "grouped",
						search = "is:pr is:open user:emrearmagan sort:updated-desc",
					},
				},
				bookmarks = {
					key = "S",
					label = "Search",
					items = {
						["Neovim"] = {
							layout = "grouped",
							search = "is:pr repo:neovim/neovim (is:open OR is:merged) sort:updated-desc",
						},
						["My merged PRs"] = "is:pr is:merged author:@me sort:updated-desc",
						["My declined PRs"] = "is:pr is:closed -is:merged author:@me sort:updated-desc",
					},
				},
			},

			---@type AtlasGitLabPullsConfig
			gitlab = {
				views = {
					{
						name = "My MRs",
						key = "1",
						layout = "compact",
						scope = "created_by_me",
					},
					{
						name = "Review Requested",
						key = "2",
						layout = "compact",
						scope = "reviews_for_me",
					},
					{
						name = "Current Repo",
						key = "3",
						layout = "compact",
						current_repo = true,
						scope = "all",
					},
				},
				bookmarks = {
					key = "S",
					label = "Search",
					items = {
						["Assigned"] = { scope = "assigned_to_me" },
						["My merged MRs"] = { scope = "created_by_me", extra_params = { state = "merged" } },
						["My closed MRs"] = { scope = "created_by_me", extra_params = { state = "closed" } },
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
			},
		},

		---@type AtlasIssuesConfig
		issues = {
			max_results = 100,
			with_relationships = true,

			---@type AtlasGitHubIssuesConfig
			github = {
				views = {
					{
						name = "Assigned",
						key = "1",
						layout = "compact",
						search = "is:issue is:open assignee:@me sort:updated-desc",
					},
					{
						name = "Created",
						key = "2",
						layout = "compact",
						search = "is:issue is:open author:@me sort:updated-desc",
					},
					{
						name = "My Repos",
						key = "3",
						layout = "compact",
						search = "is:issue is:open user:emrearmagan sort:updated-desc",
					},
					{
						name = "Current Repo",
						key = "4",
						layout = "compact",
						current_repo = true,
						search = "is:issue is:open sort:updated-desc",
					},
				},
				bookmarks = {
					key = "S",
					label = "Search",
					items = {
						["Neovim"] = "is:issue is:open repo:neovim/neovim sort:updated-desc",
						["Neovim bugs"] = "is:issue is:open repo:neovim/neovim label:bug sort:reactions-desc",
						["Mentioned"] = "is:issue is:open mentions:@me sort:updated-desc",
						["My closed issues"] = "is:issue is:closed author:@me sort:updated-desc",
					},
				},
			},

			---@type AtlasGitLabIssuesConfig
			gitlab = {
				views = {
					{
						name = "Assigned",
						key = "1",
						layout = "compact",
						scope = "assigned_to_me",
					},
					{
						name = "Created",
						key = "2",
						layout = "compact",
						scope = "created_by_me",
					},
					{
						name = "Current Repo",
						key = "3",
						layout = "compact",
						current_repo = true,
						scope = "all",
					},
				},
				bookmarks = {
					key = "S",
					label = "Search",
					items = {
						["My closed issues"] = { scope = "created_by_me", state = "closed" },
					},
				},
			},
		},

		providers = {
			github = {
				cache_ttl = 3000,
			},
			gitlab = {
				base_url = "https://gitlab.com",
				token = vim.env.GITLAB_TOKEN,
				cache_ttl = 300,
			},
		},
	},
}
