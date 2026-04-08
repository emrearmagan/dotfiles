require("config.options")

require("config.lazy")
require("config.which-key")
require("config.autocmds")

-- Feature from Neovim 0.12 just for testing.
vim.cmd("packadd nvim.undotree") -- enable built-in undotree plugin
vim.opt.undofile = true
