local M = {}

--------------------------------------------------------------------------------
-- Help popup
--------------------------------------------------------------------------------

---@param mode string|string[]
---@return string
local function mode_label(mode)
	if type(mode) == "table" then
		return table.concat(mode, ",")
	end
	return tostring(mode)
end

---@param entries { mode: string|string[], lhs: string, desc: string }[]
local function show_help(entries)
	local title = " PR Diff Keymaps "
	local lines = { "" }
	local widest_lhs, widest_mode = 0, 0
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

--------------------------------------------------------------------------------
-- Setup
--------------------------------------------------------------------------------

---@class DiffActions
---@field add_comment fun(opts: { pending: boolean, is_task: boolean|nil })
---@field add_comment_range fun(opts: { pending: boolean, is_task: boolean|nil })
---@field view_thread fun()
---@field submit_review fun(event: "APPROVE"|"REQUEST_CHANGES")
---@field refresh fun()
---@field jump fun(direction: 1|-1)
---@field open_pr_url fun()

---@param buf integer
---@param actions DiffActions
function M.setup(buf, actions)
	if not buf or not vim.api.nvim_buf_is_valid(buf) then
		return
	end
	if vim.b[buf].my_diff_keymaps then
		return
	end
	vim.b[buf].my_diff_keymaps = true

	local entries = {
		{
			mode = "n",
			lhs = "gc",
			desc = "Add pending PR comment",
			rhs = function()
				actions.add_comment({ pending = true })
			end,
		},
		{
			mode = "v",
			lhs = "gc",
			desc = "Add pending PR comment",
			rhs = function()
				actions.add_comment_range({ pending = true })
			end,
		},
		{
			mode = "n",
			lhs = "gC",
			desc = "Add PR comment",
			rhs = function()
				actions.add_comment({ pending = false })
			end,
		},
		{
			mode = "v",
			lhs = "gC",
			desc = "Add PR comment",
			rhs = function()
				actions.add_comment_range({ pending = false })
			end,
		},
		{
			mode = "n",
			lhs = "gt",
			desc = "Add PR task",
			rhs = function()
				actions.add_comment({ pending = false, is_task = true })
			end,
		},
		{ mode = "n", lhs = "gv", desc = "View PR thread", rhs = actions.view_thread },
		{
			mode = "n",
			lhs = "ga",
			desc = "Approve PR",
			rhs = function()
				actions.submit_review("APPROVE")
			end,
		},
		{
			mode = "n",
			lhs = "gd",
			desc = "Request PR changes",
			rhs = function()
				actions.submit_review("REQUEST_CHANGES")
			end,
		},
		{ mode = "n", lhs = "gr", desc = "Refresh PR comments", rhs = actions.refresh },
		{
			mode = "n",
			lhs = "]c",
			desc = "Next PR comment",
			rhs = function()
				actions.jump(1)
			end,
		},
		{
			mode = "n",
			lhs = "[c",
			desc = "Previous PR comment",
			rhs = function()
				actions.jump(-1)
			end,
		},
		{ mode = "n", lhs = "gx", desc = "Open PR", rhs = actions.open_pr_url },
	}

	local opts = { buffer = buf, silent = true, nowait = true }
	for _, e in ipairs(entries) do
		vim.keymap.set(e.mode, e.lhs, e.rhs, vim.tbl_extend("force", opts, { desc = e.desc }))
	end
	vim.keymap.set("n", "?", function()
		show_help(entries)
	end, vim.tbl_extend("force", opts, { desc = "Show PR diff keymaps" }))
end

return M
