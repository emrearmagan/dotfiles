require("config.options")

require("config.lazy")
require("config.which-key")

local custom_path = vim.fn.stdpath("config") .. "/lua/custom"
for _, file in ipairs(vim.fn.globpath(custom_path, "*.lua", false, true)) do
	local modname = "custom." .. vim.fn.fnamemodify(file, ":t:r")
	pcall(require, modname)
end
