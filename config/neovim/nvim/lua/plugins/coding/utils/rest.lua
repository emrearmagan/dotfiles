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
		vscode_rest_client_environmentvars = true, -- load from shell env vars
		max_response_size = 500000,

		ui = {
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
				--  i dont know why there was no highlight for http filetypes, maybe treesitter was not started? this helps for now
				local ft = vim.bo.filetype
				local lang = vim.treesitter.language.get_lang(ft) or ft
				local ok_parser, parser = pcall(vim.treesitter.get_parser, 0)
				if ok_parser and parser and parser.lang and parser:lang() ~= lang then
					pcall(vim.treesitter.stop, 0)
				end
				pcall(vim.treesitter.start, 0, lang)

				--- Keymaps

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
