require("config.options")
require("config.helper")

require("config.lazy")
require("config.which-key")
require("config.my")

-- Feature from Neovim 0.12 just for testing.
vim.cmd("packadd nvim.undotree") -- enable built-in undotree plugin
vim.opt.undofile = true
require("vim._core.ui2").enable({
	enable = true,
	msg = {
		targets = {
			bufwrite = "msg",
		},
		msg = {
			timeout = 1,
		},
	},
})
