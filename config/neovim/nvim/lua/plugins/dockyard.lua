return {
	dir = "/Users/emrearmagan/development/nvim/dockyard.nvim",
	-- "emrearmagan/dockyard.nvim",
	cmd = { "Dockyard", "DockyardFloat" },
	lazy = true,
	dependencies = {
		"nvim-lua/plenary.nvim",
		"akinsho/toggleterm.nvim", -- optional
	},
	config = function()
		require("dockyard").setup({
			--- @type LogLensConfig
			loglens = {
				containers = {
					["shnt-backend-dev"] = {
						sources = {
							{
								name = "Backend JSON",
								path = "/var/log/backend.json",
								parser = "json",
								tails = 1000,

								_order = { "time", "level", "service", "status", "request", "message", "context" },
								format = function(entry)
									local ts = entry.timestamp and entry.timestamp:sub(12, 19) or "--:--:--"
									local lvl = (entry.level or "info"):upper()
									local req = entry.request or {}
									local ctx = entry.context or {}
									local user_id = ctx.user_id or "anonymous"
									local trace_id = entry.trace_id or ctx.trace_id or "-" -- important fix
									local service = entry.service or "-"
									local status = tostring(entry.status_code or "-")
									local method = req.method or "-"
									local path = req.path or "-"
									local ip = req.ip or "-"
									return {
										time = ts,
										level = lvl,
										service = service,
										status = status,
										request = string.format("%s %s %s", method, path, ip),
										message = entry.message or "",
										context = string.format("user=%s trace=%s", user_id, trace_id),
									}
								end,

								highlights = {
									{ pattern = "%d%d:%d%d:%d%d", group = "Comment" },
									{ pattern = "%f[%a]ERROR%f[^%a]", group = "ErrorMsg" },
									{ pattern = "%f[%a]CRITICAL%f[^%a]", group = "ErrorMsg" },
									{ pattern = "%f[%a]WARN%f[^%a]", group = "WarningMsg" },
									{ pattern = "%f[%a]WARNING%f[^%a]", group = "WarningMsg" },
									{ pattern = "%f[%a]INFO%f[^%a]", group = "Identifier" },
									{ pattern = "%f[%a]DEBUG%f[^%a]", group = "Comment" },
									{ pattern = "user=", group = "Identifier" },
									{ pattern = "trace=", group = "Identifier" },
									{ pattern = "%f[%w]u%-%w+%f[^%w]", group = "String" },
									{ pattern = "%f[%w]tr%-%x+%f[^%w]", group = "Special" },
									{ pattern = "%f[%d][45]%d%d%f[^%d]", group = "ErrorMsg" }, -- 4xx/5xx
								},
							},
						},
					},
				},
			},
		})
	end,
}
