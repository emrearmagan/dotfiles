return {
	"yetone/avante.nvim",
	-- build function didnt work somehow. Had to run this manually:
	-- cd ~/.local/share/nvim/lazy/avante.nvim & make
	build = function()
		if vim.fn.has("win32") == 1 then
			return "powershell -ExecutionPolicy Bypass -File Build.ps1 -BuildFromSource false"
		else
			return "make"
		end
	end,
	event = "VeryLazy",
	version = false,
	opts = {
		provider = "copilot",
		mappings = {},
		hints = { enabled = false },
		selection = { hint_display = "none" },
		file_selector = "fzf",
		system_message = "You always respond in English unless explicitly asked",
		providers = {
			ollama = {
				__inherited_from = "openai",
				endpoint = "https://ollama.local.emrearmagan.dev/v1",
				model = "qwen2.5-coder:7b", -- DEFAULT MODEL
				timeout = 30000,

				models = {
					coder = {
						model = "qwen2.5-coder:7b",
						extra_request_body = {
							temperature = 0.2,
							max_tokens = 4096,
						},
					},

					reasoning = {
						model = "qwen3:8b",
						extra_request_body = {
							temperature = 0.3,
							max_tokens = 4096,
						},
					},

					lightweight = {
						model = "phi4-mini:3.8b",
						extra_request_body = {
							temperature = 0.1,
							max_tokens = 2048,
						},
					},
				},
			},
		},
	},

	dependencies = {
		"nvim-lua/plenary.nvim",
		"MunifTanjim/nui.nvim",
		-- Optional UI improvements
		"hrsh7th/nvim-cmp", -- autocompletion for avante commands and mentions
		"ibhagwan/fzf-lua", -- for file_selector provider fzf
	},
}
