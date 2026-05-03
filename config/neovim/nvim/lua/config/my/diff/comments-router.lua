local github = require("config.my.diff.github-comments")
local bitbucket = require("config.my.diff.bitbucket-comments")

local function provider()
	if bitbucket.can_handle and bitbucket.can_handle() then
		return bitbucket
	end
	if github.can_handle and github.can_handle() then
		return github
	end
end

vim.keymap.set("v", "<leader>gcc", function()
	local mod = provider()
	if mod and mod.add_pending_comment_visual then
		mod.add_pending_comment_visual()
	elseif mod and mod.add_comment_visual then
		mod.add_comment_visual()
	end
end, { desc = "Add pending PR comment" })

vim.keymap.set("n", "<leader>gcc", function()
	local mod = provider()
	if mod and mod.add_pending_comment_line then
		mod.add_pending_comment_line()
	elseif mod and mod.add_comment_line then
		mod.add_comment_line()
	end
end, { desc = "Add pending PR comment" })

vim.keymap.set("v", "<leader>gcC", function()
	local mod = provider()
	if mod and mod.add_instant_comment_visual then
		mod.add_instant_comment_visual()
	end
end, { desc = "Add PR comment" })

vim.keymap.set("n", "<leader>gcC", function()
	local mod = provider()
	if mod and mod.add_instant_comment_line then
		mod.add_instant_comment_line()
	end
end, { desc = "Add PR comment" })

vim.keymap.set("n", "<leader>gcv", function()
	local mod = provider()
	if mod and mod.view_thread then
		mod.view_thread()
	end
end, { desc = "View PR thread" })

vim.keymap.set("n", "gx", function()
	local mod = provider()
	if mod and mod.open_pr then
		mod.open_pr()
		return
	end
	vim.cmd.normal({ "gx", bang = true })
end, { desc = "Open PR" })
