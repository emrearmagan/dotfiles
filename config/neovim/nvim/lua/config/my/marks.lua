vim.api.nvim_create_user_command("MyMarks", function()
	require("snacks.picker").marks({
		global = true,
		["local"] = true,
		transform = function(item)
			if item.label:match("^[A-Za-z]$") then
				return item
			end
			return false
		end,
	})
end, {})

vim.api.nvim_create_user_command("MyAllMarks", function()
	require("snacks.picker").marks()
end, {})
