vim.api.nvim_create_user_command("MyTodoList", function()
	pcall(function()
		require("lazy").load({ plugins = { "todo-comments.nvim" } })
	end)

	if vim.fn.exists(":TodoTelescope") == 2 then
		vim.cmd("TodoTelescope")
		return
	end

	require("todo-comments.search").setqflist("")
	vim.cmd("copen")
end, {})
