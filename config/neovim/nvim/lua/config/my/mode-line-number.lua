local group = vim.api.nvim_create_augroup("user_mode_line_number", { clear = true })

local colors = {
	normal = "#f2cdcd",
	insert = "#a6e3a1",
	visual = "#cba6f7",
	replace = "#f38ba8",
	command = "#fab387",
	terminal = "#94e2d5",
	pending = "#f9e2af",
}

local function color_for_mode(mode)
	if mode:sub(1, 2) == "no" then
		return ({
			d = colors.replace,
			c = colors.command,
			y = colors.pending,
		})[vim.v.operator] or colors.pending
	end

	local first = mode:sub(1, 1)
	if first == "i" then
		return colors.insert
	elseif first == "R" then
		return colors.replace
	elseif first == "v" or first == "V" or first == "\22" or first == "s" or first == "S" or first == "\19" then
		return colors.visual
	elseif first == "c" then
		return colors.command
	elseif first == "t" then
		return colors.terminal
	end

	return colors.normal
end

local function update(mode)
	vim.api.nvim_set_hl(0, "CursorLineNr", {
		fg = color_for_mode(mode or vim.api.nvim_get_mode().mode),
		bold = true,
	})
end

vim.api.nvim_create_autocmd("ModeChanged", {
	group = group,
	callback = function()
		update(vim.v.event.new_mode)
	end,
})

vim.api.nvim_create_autocmd("ColorScheme", {
	group = group,
	callback = function()
		vim.schedule(update)
	end,
})

update()
