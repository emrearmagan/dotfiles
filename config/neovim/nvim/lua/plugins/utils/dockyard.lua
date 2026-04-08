return {
	dir = "/Users/emrearmagan/development/nvim/dockyard.nvim",
	-- "emrearmagan/dockyard.nvim",
	dependencies = {
		"nvim-lua/plenary.nvim",
		"akinsho/toggleterm.nvim", -- optional
	},
	config = function()
		require("dockyard").setup({
			display = {
				views = {
					"compose",
					"images",
					"volumes",
					"networks",
				},
			},

			--- @type LogLensConfig
			loglens = {
				containers = {
					["shnt-backend-dev"] = {
						sources = {
							{
								name = "Frontend Logs",
								path = "/var/log/backend-log1.json",
								parser = "json",
								tails = 1000,
							},
							{
								name = "Backend Logs",
								path = "/var/log/backend-log2.json",
								parser = "json",
								tails = 1000,
							},
						},

						_order = {
							"time",
							"level",
							"service",
							"status",
							"request",
							"message",
							"project",
							"context",
							"session",
						},
						format = function(entry, ctx)
							local ts = entry.timestamp and entry.timestamp:sub(12, 19) or "--:--:--"
							local lvl = (entry.level or "info"):upper()
							local req = entry.request or {}
							local service = entry.service or "-"
							local status = tostring(entry.status_code or "-")
							local method = req.method or "-"
							local path = req.path or "-"
							local ip = req.ip or "-"
							local ectx = entry.context or {}
							return {
								time = ts,
								level = lvl,
								service = service,
								status = status,
								request = string.format("%s %s %s", method, path, ip),
								message = entry.message or "",
								project = ctx.name or "-",
								context = string.format("user=%s trace=%s", ectx.user_id or "-", entry.trace_id or "-"),
								session = ectx.session_id or "-",
							}
						end,

						highlights = {
							{ pattern = "user=%S+", color = "#50fa7b" },
							{ pattern = "trace=%S+", color = "#bd93f9" },
							{ pattern = "user=", color = "#6272a4" },
							{ pattern = "trace=", color = "#6272a4" },
						},
					},
				},
			},
		})
	end,
}
