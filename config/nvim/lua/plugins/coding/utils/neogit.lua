return {
	"NeogitOrg/neogit",
	cmd = "Neogit",
	dependencies = {
		"esmuellert/codediff.nvim",
		"folke/snacks.nvim",
	},
	init = function()
		-- Shim codediff.ui.view.create for legacy Neogit integration schema
		local ok, view = pcall(require, "codediff.ui.view")
		if ok and view.create then
			local original_create = view.create
			local path = require("codediff.core.path")

			view.create = function(session_config, filetype, on_ready)
				if session_config.mode == "explorer" and not session_config.panel then
					session_config.panel = {
						name = "explorer",
						data = session_config.explorer_data or {},
					}
					session_config.original = session_config.original or path.empty()
					session_config.modified = session_config.modified or path.empty()
				end
				return original_create(session_config, filetype, on_ready)
			end
		end
	end,
	opts = {
		graph_style = "unicode",
		integrations = {
			codediff = true,
			snacks = true,
		},
		diff_viewer = "codediff",
	},
}
