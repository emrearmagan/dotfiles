-- Bootstrap lazy.nvim - installs lazy on first start
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
	local lazyrepo = "https://github.com/folke/lazy.nvim.git"
	local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
	if vim.v.shell_error ~= 0 then
		vim.api.nvim_echo({
			{ "Failed to clone lazy.nvim:\n", "ErrorMsg" },
			{ out, "WarningMsg" },
			{ "\nPress any key to exit..." },
		}, true, {})
		vim.fn.getchar()
		os.exit(1)
	end
end
vim.opt.rtp:prepend(lazypath)

-- Function to dynamically discover plugin directories
local function get_plugin_imports()
	local imports = {}
	local plugins_path = vim.fn.stdpath("config") .. "/lua/plugins"
  --
	-- Add root plugins directory
	table.insert(imports, { import = "plugins" })

	-- Function to recursively scan directories
	local function scan_directory(path, import_path)
		local handle = vim.loop.fs_scandir(path)
		if handle then
			while true do
				local name, type = vim.loop.fs_scandir_next(handle)
				if not name then break end

				-- Skip hidden files and DS_Store
				if type == "directory" and not name:match("^%.") and name ~= ".DS_Store" then
					local subdir_path = path .. "/" .. name
					local subdir_import = import_path .. "." .. name

					-- Add the subdirectory import
					table.insert(imports, { import = subdir_import })

					-- Recursively scan subdirectories
					scan_directory(subdir_path, subdir_import)
				end
			end
		end
	end

	-- Start scanning from plugins directory
	scan_directory(plugins_path, "plugins")

	return imports
end

-- Setup lazy.nvim
require("lazy").setup({
	spec = get_plugin_imports(),

	-- automatically check for plugin updates
	checker = { enabled = true },
})
