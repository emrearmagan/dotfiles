return {
	-- "emrearmagan/atlas.nvim",
	dir = "/Users/emrearmagan/development/nvim/atlas.nvim",
	config = function()
		local function open_live_command(title, cmd, on_exit)
			local width = math.floor(vim.o.columns * 0.2)
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
			---@type BitbucketConfig
			bitbucket = {
				user = os.getenv("BITBUCKET_USER") or "",
				token = os.getenv("BITBUCKET_TOKEN") or "",
				cache_ttl = 300,
				repo_config = {
					settings = {
						["emrearmaganxx/atlas"] = {
							readme = "Atlas",
						},
					},
					paths = {
						["emrearmaganxx/*"] = "~/development/nvim/atlas.testing/*",
					},
				},

				custom_actions = {
					{
						id = "checkout_worktree",
						label = "Checkout (worktrees)",

						---@param _ BitbucketPR
						---@param ctx BitbucketCustomActionContext
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

						---@param _ BitbucketPR
						---@param ctx BitbucketCustomActionContext
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
								"--skip-unchaned",
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

				---@type BitbucketViewConfig[]
				views = {
					{
						name = "Me",
						key = "M",
						layout = "compact",
						repos = {
							{ workspace = "emrearmaganxx", repo = "atlas", readme = "Atlas" },
							{ workspace = "emrearmaganxx", repo = "dockyard" },
						},

						---@param pr BitbucketPR
						---@param ctx table
						filter = function(pr, ctx)
							local user = ctx.user or {}
							return pr.author and pr.author.account_id == user.account_id
						end,
					},
					{
						name = "Others",
						key = "O",
						layout = "plain",
						repos = {
							{ workspace = "emrearmaganxx", repo = "atlas" },
							{ workspace = "emrearmaganxx", repo = "dockyard" },
						},
					},
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
		})
	end,
}
