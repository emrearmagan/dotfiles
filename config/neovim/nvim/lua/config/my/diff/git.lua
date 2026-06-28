local M = {}

---@param root string
---@param args string[]
---@return string|nil
local function git(root, args)
	if type(root) ~= "string" or root == "" then
		return nil
	end
	local cmd = { "git", "-C", root }
	vim.list_extend(cmd, args)
	local result = vim.system(cmd, { text = true }):wait()
	if not result or result.code ~= 0 then
		return nil
	end
	local stdout = vim.trim(result.stdout or "")
	return stdout ~= "" and stdout or nil
end

---@param root string
---@return string|nil
function M.remote_url(root)
	return git(root, { "remote", "get-url", "origin" })
end

return M
