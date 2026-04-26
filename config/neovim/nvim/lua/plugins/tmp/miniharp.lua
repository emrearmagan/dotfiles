return {
	"vieitesss/miniharp.nvim",
	version = "*",
	opts = {
		autoload = true, -- load marks for this cwd on startup (default: true)
		autosave = true, -- save marks for this cwd on exit (default: true)
		show_on_autoload = false, -- show popup list after a successful autoload (default: false)
		ui = {
			position = "center", -- 'center' | 'top-left' | 'top-right' | 'bottom-left' | 'bottom-right'
			show_hints = true, -- show close hints in the floating list (default: true)
			enter = true, -- enter the floating window when it opens (default: true)
		},
	},
	config = function(_, opts)
		local miniharp = require("miniharp")

		miniharp.setup(opts)

		vim.keymap.set("n", "<leader>m", miniharp.toggle_file, { desc = "which_key_ignore" })
		vim.keymap.set("n", "<C-n>", miniharp.next, { desc = "miniharp: next file mark" })
		vim.keymap.set("n", "<C-p>", miniharp.prev, { desc = "miniharp: prev file mark" })
		vim.keymap.set("n", "<leader>l", miniharp.show_list, { desc = "which_key_ignore" })

		vim.keymap.set("n", "<leader>1", function()
			miniharp.go_to(1)
		end, { desc = "which_key_ignore" })
		vim.keymap.set("n", "<leader>2", function()
			miniharp.go_to(2)
		end, { desc = "which_key_ignore" })
		vim.keymap.set("n", "<leader>3", function()
			miniharp.go_to(3)
		end, { desc = "which_key_ignore" })
		vim.keymap.set("n", "<leader>4", function()
			miniharp.go_to(4)
		end, { desc = "which_key_ignore" })
	end,
}
