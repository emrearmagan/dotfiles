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

	dependencies = {
		"nvim-lua/plenary.nvim",
		"MunifTanjim/nui.nvim",
		-- Optional UI improvements
		"hrsh7th/nvim-cmp", -- autocompletion for avante commands and mentions
	},
	opts = {
		provider = "copilot",
		hints = { enabled = false },
		selection = { hint_display = "none" },
		file_selector = "fzf",
		system_message = "You always respond in English unless explicitly asked",
		behaviour = {
			auto_set_highlight_group = true,
			auto_set_keymaps = true,
			auto_apply_diff_after_generation = false,
			support_paste_from_clipboard = true,
		},
		windows = {
			ask = {
				floating = true, -- Open the 'AvanteAsk' prompt in a floating window
			},
		},

		selector = {
			provider = "snacks",
			provider_opts = {
				preview = false,
			},
		},

		input = {
			provider = "snacks",
			provider_opts = {
				preview = false,
			},
		},

		providers = {
			openrouter = {
				__inherited_from = "openai",
				endpoint = "https://openrouter.ai/api/v1",
				api_key_name = "OPENROUTER_API_KEY",
				model = "google/gemini-2.5-flash",
				timeout = 60000,
				model_names = {
					"google/gemini-3-flash-preview",
					"google/gemini-2.5-flash",
					"minimax/minimax-m2.5",
					"stepfun/step-3.5-flash:free",
					"openrouter/openrouter/free",
				},
			},
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
		acp_providers = {
			opencode = {
				command = "opencode",
				args = { "acp" },
			},
		},
	},
	config = function(_, opts)
		require("avante").setup(opts)

		vim.api.nvim_set_hl(0, "AvanteSidebarBg", { bg = "#181825" })
		vim.api.nvim_set_hl(0, "AvanteSidebarBorder", { bg = "#181825", fg = "#6c7086" })
		vim.api.nvim_set_hl(0, "AvanteSidebarNormal", { bg = "#181825" })
		vim.api.nvim_set_hl(0, "AvanteReversedNormal", { bg = "#181825" }) -- chat area

		vim.api.nvim_create_autocmd("FileType", {
			pattern = "Avante",
			callback = function()
				vim.opt_local.winhighlight = "NormalFloat:AvanteSidebarBg,FloatBorder:AvanteSidebarBorder"
			end,
		})
	end,
}
