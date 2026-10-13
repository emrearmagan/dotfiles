local ns = vim.api.nvim_create_namespace("my_quickfix_signs")
local group = vim.api.nvim_create_augroup("user_quickfix_signs", { clear = true })
local marked = {}
local last_id, last_tick
local redraw_version = 0

local function highlights()
	vim.api.nvim_set_hl(0, "QuickfixSign", { default = true, link = "DiagnosticInfo" })
end

local function refresh(force)
	local list = vim.fn.getqflist({ id = 0, changedtick = 0 })
	if not force and list.id == last_id and list.changedtick == last_tick then
		return
	end
	last_id, last_tick = list.id, list.changedtick

	local changed = false
	for buf in pairs(marked) do
		if vim.api.nvim_buf_is_loaded(buf) then
			vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
			changed = true
		end
	end
	marked = {}

	for _, item in ipairs(vim.fn.getqflist()) do
		local buf, line = item.bufnr, item.lnum
		if item.valid == 1 and buf > 0 and line > 0 and vim.api.nvim_buf_is_loaded(buf) then
			if line <= vim.api.nvim_buf_line_count(buf) and not (marked[buf] and marked[buf][line]) then
				vim.api.nvim_buf_set_extmark(buf, ns, line - 1, 0, {
					sign_text = "▸",
					sign_hl_group = "QuickfixSign",
					priority = 5,
				})
				marked[buf] = marked[buf] or {}
				marked[buf][line] = true
				changed = true
			end
		end
	end

	-- Snacks caches signs for 50 ms; redraw after that cache has expired.
	if changed then
		redraw_version = redraw_version + 1
		local version = redraw_version
		vim.defer_fn(function()
			if version == redraw_version then
				vim.api.nvim__redraw({ statuscolumn = true, flush = true })
			end
		end, 60)
	end
end

highlights()
vim.api.nvim_create_autocmd("ColorScheme", { group = group, callback = highlights })

-- Covers commands, plugin updates, and quickfix history switches.
vim.api.nvim_create_autocmd("SafeState", {
	group = group,
	callback = function()
		refresh()
	end,
})

-- Restored lists can refer to files that have not been opened yet.
vim.api.nvim_create_autocmd({ "BufReadPost", "BufNewFile" }, {
	group = group,
	callback = function()
		refresh(true)
	end,
})

vim.schedule(refresh)
