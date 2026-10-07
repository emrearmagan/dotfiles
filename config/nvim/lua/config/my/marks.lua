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
		actions = {
			del_mark = function(picker, item)
				if item and item.label then
					pcall(vim.cmd, "delmarks " .. item.label)
				end
				picker:close()
				vim.schedule(function()
					vim.cmd("MyMarks")
				end)
			end,
		},
		win = {
			input = {
				keys = {
					["<C-d>"] = { "del_mark", mode = { "n", "i" }, desc = "Delete mark" },
				},
			},
		},
	})
end, {})

vim.api.nvim_create_user_command("MyAllMarks", function()
	require("snacks.picker").marks({
		actions = {
			del_mark = function(picker, item)
				if item and item.label then
					pcall(vim.cmd, "delmarks " .. item.label)
				end
				picker:close()
				vim.schedule(function()
					vim.cmd("MyAllMarks")
				end)
			end,
		},
		win = {
			input = {
				keys = {
					["<C-d>"] = { "del_mark", mode = { "n", "i" }, desc = "Delete mark" },
				},
			},
		},
	})
end, {})
