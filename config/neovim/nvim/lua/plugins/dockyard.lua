return {
	dir = "/Users/emrearmagan/development/nvim/dockyard.nvim",
	dependencies = { "akinsho/toggleterm.nvim" },
	-- lazy = true,
	config = function()
		require("dockyard").setup({
			loglens = {
				containers = {
					["shnt-backend-dev"] = {
						{
							name = "Backend JSON",
							type = "file",
							path = "/var/log/backend.json",
							format = "json",

							-- 1. Optimized Main List Parser
							parser = function(line)
								local ok, obj = pcall(vim.json.decode, line)
								if not ok then
									return nil
								end

								local level = (obj.level or "info"):upper()
								local timestamp = obj.timestamp and obj.timestamp:sub(12, 19) or "--:--:--"

								return {
									row = string.format("%s [%s] %s", timestamp, level, obj.message or ""),

									-- USER DEFINED COLORS:
									highlight = function(buf, lnum)
										local hl_group = "Comment"
										if level == "ERROR" or level == "CRITICAL" then
											hl_group = "ErrorMsg"
										elseif level == "WARN" or level == "WARNING" then
											hl_group = "WarningMsg"
										elseif level == "INFO" then
											hl_group = "Identifier"
										end

										-- Highlights just the [LEVEL] badge
										-- Timestamp (8) + Space (1) = 9. Start at column 9.
										local badge_length = #level + 2
										vim.api.nvim_buf_add_highlight(buf, -1, hl_group, lnum, 9, 9 + badge_length)
									end,
								}
							end,

							-- 2. Lazy Detail Parser (Only runs when you press 'o')
							detail_parser = function(line)
								local ok, obj = pcall(vim.json.decode, line)
								if not ok then
									return { line }
								end

								return {
									"Level:      " .. (obj.level or "unknown"):upper(),
									"Timestamp:  " .. (obj.timestamp or "N/A"),
									"Message:    " .. (obj.message or "N/A"),
									"-----------------------------------",
									"USER INFO:",
									"  ID:       " .. (obj.context and obj.context.user_id or "N/A"),
									"  Trace:    " .. (obj.context and obj.context.trace_id or "N/A"),
									"-----------------------------------",
									"METRICS:",
									"  Iteration: " .. (obj.iteration or 0),
									"  Latency:   " .. (obj.latency or "unknown"),
								}
							end,
						},
					},
				},
			},
		})
	end,
}
