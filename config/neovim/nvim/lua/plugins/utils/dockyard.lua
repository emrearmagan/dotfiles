return {
	dir = "/Users/emrearmagan/development/nvim/dockyard.nvim",
	-- "emrearmagan/dockyard.nvim",
	event = "VeryLazy",
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
								name = "Application Logs",
							},
						},

						highlights = {
							-- levels
							{ pattern = "INFO", color = "#8be9fd" },
							{ pattern = "WARN", color = "#f1fa8c" },
							{ pattern = "ERROR", color = "#ff5555" },
							{ pattern = "DEBUG", color = "#6272a4" },
							{ pattern = "FATAL", color = "#ff79c6" },

							-- timestamp + brackets, muted
							{ pattern = "%[%d+:%d+:%d+%]", color = "#6272a4" },

							-- request keyword
							{ pattern = "request", color = "#bd93f9" },

							-- generic key=value: key muted, value highlighted
							{ pattern = "%w+=", color = "#6272a4" },
							{ pattern = "=[^%s]+", color = "#f8f8f2" },

							-- specific ones called out
							{ pattern = "status=%d+", color = "#50fa7b" },
							{ pattern = "method=%u+", color = "#ffb86c" },
							{ pattern = "path=%S+", color = "#8be9fd" },
							{ pattern = "latency_ms=%S+", color = "#f1fa8c" },
							{ pattern = "user_id=%S+", color = "#50fa7b" },
							{ pattern = "request_id=%S+", color = "#bd93f9" },
							{ pattern = "client_ip=%S+", color = "#ffb86c" },
							{ pattern = "error=%S+", color = "#ff5555" },
						},
					},
				},
			},
		})
	end,
}
