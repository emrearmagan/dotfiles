return {
	"mistweaverco/kulala.nvim",
	dependencies = {
		"nvim-treesitter/nvim-treesitter",
	},
	ft = { "http", "rest" },
	opts = {
		-- global_keymaps = true,
		-- global_keymaps_prefix = "<leader>Z",
		-- kulala_keymaps_prefix = "",
		vscode_rest_client_environmentvars = true,
		treesitter = {
			enable = false,
		},
		lsp = {
			enable = true,
			filetypes = { "http", "rest" },
		},
		kulala_keymaps = {
			["Previous tab"] = {
				"<S-Tab>",
				function()
					require("kulala.ui").show_previous_tab()
				end,
				mode = { "n" },
			},
			["Next tab"] = {
				"<Tab>",
				function()
					require("kulala.ui").show_next_tab()
				end,
				mode = { "n" },
			},
			["Show headers"] = false,
			["Show body"] = false,
			["Show headers and body"] = false,
			["Show verbose"] = false,
			["Show script output"] = false,
			["Show stats"] = false,
			["Show report"] = false,
			["Show filter"] = false,
		},

		ui = {
			max_response_size = 500000,
			display_mode = "split", -- show response in split
			split_direction = "vertical", -- right side split
			winbar = true,
			win_opts = {
				width = math.floor(vim.o.columns * 0.5),
			},
		},

		contenttypes = {
			["application/json"] = {
				ft = "json",
				formatter = vim.fn.executable("jq") == 1 and { "jq", "." } or nil,
			},
		},
	},

	config = function(_, opts)
		require("kulala").setup(opts)

		vim.api.nvim_create_autocmd("FileType", {
			pattern = { "http", "rest" },
			callback = function()
				local cfg = { buffer = true, silent = true }
				vim.keymap.set({ "n", "v" }, "<leader>R", function()
					require("kulala").run()
				end, vim.tbl_extend("force", cfg, { desc = "Run request" }))

				vim.keymap.set({ "n", "v" }, "<leader>I", function()
					require("kulala").inspect()
				end, vim.tbl_extend("force", cfg, { desc = "Inpect request" }))

				vim.keymap.set("n", "<leader>L", function()
					require("kulala").replay()
				end, vim.tbl_extend("force", cfg, { desc = "Replay last request" }))

				vim.keymap.set("n", "<leader>E", function()
					require("kulala").set_selected_env()
				end, vim.tbl_extend("force", cfg, { desc = "Select env" }))

				vim.keymap.set("n", "<leader>C", function()
					require("kulala").copy()
				end, vim.tbl_extend("force", cfg, { desc = "Copy curl" }))
			end,
		})
	end,
}
