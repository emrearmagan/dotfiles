return {
	dir = "/Users/emrearmagan/development/nvim/dockyard.nvim",
	dependencies = { "akinsho/toggleterm.nvim" },
	config = function()
		require("dockyard").setup({
			loglens = {
				containers = {
					["shnt-backend-dev"] = {
						sources = {
							{
								name = "Backend JSON",
								type = "file",
								path = "/var/log/backend.json",
								parser = "json",

								_order = { "time", "level", "message", "context" },
								format = function(entry)
									local ts = entry.timestamp and entry.timestamp:sub(12, 19) or "--:--:--"
									local lvl = (entry.level or "info"):upper()
									local ctx = (entry.data and entry.data.context) or {}
									local user_id = ctx.user_id or "-"
									local trace_id = ctx.trace_id or "-"

									return {
										time = ts,
										level = lvl,
										message = entry.message or "",
										context = string.format("user=%s trace=%s", user_id, trace_id),
									}
								end,

								-- Highlights: pattern-based coloring
								highlights = {
									-- Timestamp in gray
									{ pattern = "%d%d:%d%d:%d%d", group = "Comment" },
									-- Log levels
									{ pattern = "%[ERROR%]", group = "ErrorMsg" },
									{ pattern = "%[CRITICAL%]", group = "ErrorMsg" },
									{ pattern = "%[WARN%]", group = "WarningMsg" },
									{ pattern = "%[WARNING%]", group = "WarningMsg" },
									{ pattern = "%[INFO%]", group = "Identifier" },
									{ pattern = "%[DEBUG%]", group = "Comment" },
								},
							},
						},
					},
				},
			},
		})
	end,
}
