local function augroup(name)
	return vim.api.nvim_create_augroup("user_" .. name, { clear = true })
end

-- Check if we need to reload the file when it changed.
vim.api.nvim_create_autocmd({ "FocusGained", "TermClose", "TermLeave" }, {
	group = augroup("checktime"),
	callback = function()
		if vim.o.buftype ~= "nofile" then
			vim.cmd("checktime")
		end
	end,
})

-- Also check on buffer enter and cursor hold.
vim.api.nvim_create_autocmd({ "BufEnter", "CursorHold", "CursorHoldI", "FocusGained" }, {
	group = augroup("checktime_events"),
	command = "if mode() != 'c' | checktime | endif",
	pattern = { "*" },
})

-- Highlight on yank.
vim.api.nvim_create_autocmd("TextYankPost", {
	group = augroup("highlight_yank"),
	callback = function()
		(vim.hl or vim.highlight).on_yank()
	end,
})

-- Resize splits if window got resized.
vim.api.nvim_create_autocmd({ "VimResized" }, {
	group = augroup("resize_splits"),
	callback = function()
		local current_tab = vim.fn.tabpagenr()
		vim.cmd("tabdo wincmd =")
		vim.cmd("tabnext " .. current_tab)
	end,
})

-- Close some filetypes with <q>.
vim.api.nvim_create_autocmd("FileType", {
	group = augroup("close_with_q"),
	pattern = {
		"PlenaryTestPopup",
		"checkhealth",
		"dbout",
		"gitsigns-blame",
		"grug-far",
		"help",
		"lspinfo",
		"neotest-output",
		"neotest-output-panel",
		"neotest-summary",
		"notify",
		"qf",
		"spectre_panel",
		"startuptime",
		"tsplayground",
		"gitsigns-blame",
		"DiffviewFileHistory",
		"nvim-undotree", -- 0.12 undotree plugin
	},
	callback = function(event)
		vim.bo[event.buf].buflisted = false
		vim.schedule(function()
			vim.keymap.set("n", "q", function()
				vim.cmd("close")
				pcall(vim.api.nvim_buf_delete, event.buf, { force = true })
			end, {
				buffer = event.buf,
				silent = true,
				desc = "Quit buffer",
			})
		end)
	end,
})

vim.api.nvim_create_autocmd("FileType", {
	group = augroup("qf_remove_entry"),
	pattern = "qf",
	callback = function(event)
		vim.keymap.set("n", "dd", function()
			local row = vim.fn.line(".")
			local list = vim.fn.getqflist()
			table.remove(list, row)
			vim.fn.setqflist(list, "r")
		end, { buffer = event.buf, silent = true, desc = "Remove qf entry" })
	end,
})

vim.api.nvim_create_autocmd({ "FileType" }, {
	group = augroup("json_conceal"),
	pattern = { "json", "jsonc", "json5" },
	callback = function()
		vim.opt_local.conceallevel = 0
	end,
})

vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
	group = augroup("env_filetype"),
	pattern = { "*.env", ".env.*" },
	callback = function()
		vim.opt_local.filetype = "sh"
	end,
})

-- Columnized formatting for quickfix entries: "<filename> │<lnum>:<col>│<type> <text>"
function _G.qftf(info)
	local fn = vim.fn
	local items
	if info.quickfix == 1 then
		items = fn.getqflist({ id = info.id, items = 0 }).items
	else
		items = fn.getloclist(info.winid, { id = info.id, items = 0 }).items
	end
	local limit = 31
	local fname_fmt_short = "%-" .. limit .. "s"
	local fname_fmt_long = "..%." .. (limit - 1) .. "s"
	local valid_fmt = "%s │%5d:%-3d│%s %s"
	local ret = {}
	for i = info.start_idx, info.end_idx do
		local e = items[i]
		local str
		if e.valid == 1 then
			local fname = ""
			if e.bufnr > 0 then
				fname = fn.bufname(e.bufnr)
				if fname == "" then
					fname = "[No Name]"
				else
					fname = fname:gsub("^" .. vim.env.HOME, "~")
				end
				if #fname <= limit then
					fname = fname_fmt_short:format(fname)
				else
					fname = fname_fmt_long:format(fname:sub(1 - limit))
				end
			end
			local lnum = e.lnum > 99999 and -1 or e.lnum
			local col = e.col > 999 and -1 or e.col
			local qtype = e.type == "" and "" or " " .. e.type:sub(1, 1):upper()
			str = valid_fmt:format(fname, lnum, col, qtype, e.text)
		else
			str = e.text
		end
		table.insert(ret, str)
	end
	return ret
end

vim.o.quickfixtextfunc = "{info -> v:lua._G.qftf(info)}"
