vim.api.nvim_create_user_command("MyTodoList", function()
	pcall(function()
		require("lazy").load({ plugins = { "todo-comments.nvim" } })
	end)

	require("todo-comments.search").setloclist({ open = true })
end, {})
