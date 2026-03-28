return {
	-- "emrearmagan/atlas.nvim",
	dir = "/Users/emrearmagan/development/nvim/atlas.nvim",
	-- lazy = true,
	config = function()
		require("atlas").setup({
			bitbucket = {
				user = os.getenv("BITBUCKET_USER"),
				token = os.getenv("BITBUCKET_TOKEN"),
				ttl = 300,

				views = {
					{
						name = "Me",
						key = "m",
						layout = "compact",
						repos = {
							{ workspace = "emrearmaganxx", repo = "atlas" },
						},

						filter = function(pr, account_id)
							return pr.author and pr.author.account_id == account_id
						end,
					},
					{
						name = "Others",
						key = "o",
						layout = "grouped",
						repos = {
							{ workspace = "emrearmaganxx", repo = "atlas" },
							{ workspace = "emrearmaganxx", repo = "Dockyard" },
						},
						filter = function(pr, account_id)
							return pr.author_account_id ~= account_id and not (pr.repo and pr.repo:match("^vv%-ham%-"))
						end,
					},
					{
						name = "App",
						key = "a",
						layout = "plain",
						repos = {
							{ workspace = "emrearmaganxx", repo = "atlas" },
							{ workspace = "emrearmaganxx", repo = "Dockyard" },
						},
						filter = function(pr, account_id)
							return pr.repo and pr.repo:match("^vv%-ham%-")
						end,
					},
				},
			},

			jira = {
				base = os.getenv("JIRA_BASE_URL"),
				email = os.getenv("JIRA_EMAIL"),
				token = os.getenv("JIRA_TOKEN"),
				type = os.getenv("JIRA_AUTH_TYPE") or "basic",
				api_version = "3",
				limit = 200,
				projects = {
					["ZAHN"] = {
						story_point_field = "customfield_10035",
						custom_fields = {
							{ key = "customfield_10016", label = "Acceptance Criteriaa" },
						},
					},
				},
				queries = {
					["Active Sprint"] = "project = '%s' AND (sprint in openSprints()) ORDER BY status ASC, assignee ASC, Rank ASC",
					["Next sprint"] = "project = '%s' AND (sprint in futureSprints() ) ORDER BY status ASC, assignee ASC, Rank ASC",
					["Backlog"] = "project = '%s' AND ((issuetype IN standardIssueTypes() OR issuetype = Sub-task) AND (sprint IS EMPTY OR sprint NOT IN openSprints()) OR issuetype = Epic) AND statusCategory != Done ORDER BY status ASC, assignee ASC, Rank ASC",
				},
				views = {
					{
						name = "My Tasks",
						key = "M",
						jql = "project = '%s' AND assignee = currentUser() AND statusCategory != Done ORDER BY status ASC, assignee ASC, updated DESC",
					},
					{
						name = "Active Sprint",
						key = "S",
					},
					{
						name = "To Do",
						key = "T",
						jql = "project = '%s' AND sprint in openSprints() AND statusCategory = \"To Do\" AND assignee is EMPTY ORDER BY priority ASC",
					},
				},
			},
		})
	end,
}
