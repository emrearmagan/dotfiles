-- Keymap registry + help popup for PR diff buffers.

local M = {}

local function mode_label(mode)
	if type(mode) == "table" then
		return table.concat(mode, ",")
	end
	return tostring(mode)
end

local function show_help(entries)
	local title = " PR Diff Keymaps "
	local lines = { "" }
	local widest_lhs = 0
	local widest_mode = 0
	for _, e in ipairs(entries) do
		widest_lhs = math.max(widest_lhs, #e.lhs)
		widest_mode = math.max(widest_mode, #mode_label(e.mode))
	end

	for _, e in ipairs(entries) do
		table.insert(
			lines,
			string.format(
				"  %-" .. widest_lhs .. "s  [%-" .. widest_mode .. "s]  %s",
				e.lhs,
				mode_label(e.mode),
				e.desc
			)
		)
	end
	table.insert(lines, "")
	table.insert(lines, "  press q or <Esc> to close")

	local width = #title
	for _, l in ipairs(lines) do
		width = math.max(width, #l)
	end
	local height = #lines

	local buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
	vim.bo[buf].modifiable = false
	vim.bo[buf].bufhidden = "wipe"
	vim.bo[buf].filetype = "diff_keymaps_help"

	local win = vim.api.nvim_open_win(buf, true, {
		relative = "editor",
		style = "minimal",
		border = "rounded",
		title = title,
		title_pos = "center",
		width = width + 2,
		height = height,
		row = math.max(0, math.floor((vim.o.lines - height) / 2) - 1),
		col = math.max(0, math.floor((vim.o.columns - width - 2) / 2)),
	})

	local function close()
		if vim.api.nvim_win_is_valid(win) then
			vim.api.nvim_win_close(win, true)
		end
	end
	vim.keymap.set("n", "q", close, { buffer = buf, silent = true })
	vim.keymap.set("n", "<Esc>", close, { buffer = buf, silent = true })
end

---@param buf integer
---@param entries table[]  list of { mode, lhs, rhs, desc }
function M.attach(buf, entries)
	if not buf or not vim.api.nvim_buf_is_valid(buf) then
		return
	end
	if vim.b[buf].my_diff_keymaps then
		return
	end
	vim.b[buf].my_diff_keymaps = true

	local opts = { buffer = buf, silent = true }
	for _, e in ipairs(entries) do
		vim.keymap.set(e.mode, e.lhs, e.rhs, vim.tbl_extend("force", opts, { desc = e.desc }))
	end

	vim.keymap.set("n", "?", function()
		show_help(entries)
	end, vim.tbl_extend("force", opts, { desc = "Show PR diff keymaps" }))
end

M.show_help = show_help

return M
