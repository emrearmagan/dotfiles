local M = {}

local ENABLED_FILETYPES = { "markdown", "text", "gitcommit", "norg" }

local function buffer_root()
	local vault = vim.g.obsidian_vault
	if vault and vault ~= "" then
		local file = vim.api.nvim_buf_get_name(0)
		if file:sub(1, #vault) == vault then
			return vault
		end
	end
	local out = vim.fn.systemlist("git rev-parse --show-toplevel")
	if vim.v.shell_error == 0 and out[1] and out[1] ~= "" then
		return out[1]
	end
	return vim.fn.getcwd()
end

local function list_files(root)
	local cmd
	if vim.fn.executable("rg") == 1 then
		cmd = { "rg", "--files", "--hidden", "--glob", "!.git/*", root }
	elseif vim.fn.executable("fd") == 1 then
		cmd = { "fd", "--type", "f", "--hidden", "--exclude", ".git", ".", root }
	else
		cmd = { "find", root, "-type", "f", "-not", "-path", "*/.git/*" }
	end
	return vim.fn.systemlist(cmd)
end

function M.new()
	return setmetatable({}, { __index = M })
end

function M:is_available()
	return vim.tbl_contains(ENABLED_FILETYPES, vim.bo.filetype)
end

function M:get_trigger_characters()
	return { "@" }
end

function M:get_keyword_pattern()
	return [[@[\w./_-]*]]
end

function M:complete(_, callback)
	local root = buffer_root()
	local files = list_files(root)
	local items = {}
	for _, abs in ipairs(files) do
		local rel = abs:gsub("^" .. vim.pesc(root) .. "/?", "")
		table.insert(items, {
			label = "@" .. rel,
			insertText = "@" .. rel,
			kind = 17, -- CompletionItemKind.File
		})
	end
	callback({ items = items, isIncomplete = false })
end

return M
