local spinner_ns = vim.api.nvim_create_namespace("my_llm_spinner")
local spinner_frames = { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" }

local function get_lsp_names(buf)
	local names = {}
	for _, client in ipairs(vim.lsp.get_clients({ bufnr = buf })) do
		table.insert(names, client.name)
	end
	table.sort(names)
	return table.concat(names, ", ")
end

local function get_context(buf)
	local filename = vim.api.nvim_buf_get_name(buf)
	local extension = filename ~= "" and vim.fn.fnamemodify(filename, ":e") or ""
	local lsp_names = get_lsp_names(buf)

	return table.concat({
		"Current buffer context:",
		"- filetype: " .. (vim.bo[buf].filetype ~= "" and vim.bo[buf].filetype or "unknown"),
		"- extension: " .. (extension ~= "" and extension or "none"),
		"- lsp: " .. (lsp_names ~= "" and lsp_names or "none"),
	}, "\n")
end

local function get_visual_selection()
	local mode = vim.fn.mode()
	if mode ~= "v" and mode ~= "V" and mode ~= "" then
		local s = vim.fn.getpos("'<")
		local e = vim.fn.getpos("'>")
		if s[2] == 0 or e[2] == 0 or (s[2] == e[2] and s[3] == e[3]) then
			return nil
		end
	end
	local lines = vim.fn.getline(vim.fn.line("'<"), vim.fn.line("'>"))
	if type(lines) == "string" then
		lines = { lines }
	end
	if #lines == 0 then
		return nil
	end
	return table.concat(lines, "\n")
end

local function start_spinner(buf, row, col, label)
	local active = true
	local frame = 1

	local function tick()
		if not active or not vim.api.nvim_buf_is_valid(buf) then
			return
		end

		pcall(vim.api.nvim_buf_set_extmark, buf, spinner_ns, row, col, {
			id = 1,
			virt_text = { { spinner_frames[frame] .. " " .. label, "Comment" } },
			virt_text_pos = "eol",
		})

		frame = frame % #spinner_frames + 1
		vim.defer_fn(tick, 80)
	end

	tick()

	return function()
		active = false
		if vim.api.nvim_buf_is_valid(buf) then
			pcall(vim.api.nvim_buf_del_extmark, buf, spinner_ns, 1)
		end
	end
end

local function start_corner_spinner(label)
	local buf = vim.api.nvim_create_buf(false, true)
	vim.bo[buf].buftype = "nofile"
	vim.bo[buf].bufhidden = "wipe"

	local width = #label + 4
	local win = vim.api.nvim_open_win(buf, false, {
		relative = "editor",
		anchor = "NE",
		row = 1,
		col = vim.o.columns - 1,
		width = width,
		height = 1,
		style = "minimal",
		focusable = false,
		border = "rounded",
		noautocmd = true,
		zindex = 100,
	})
	vim.wo[win].winhighlight = "NormalFloat:Comment,FloatBorder:Comment"

	local active = true
	local frame = 1
	local function tick()
		if not active or not vim.api.nvim_buf_is_valid(buf) then
			return
		end
		vim.api.nvim_buf_set_lines(buf, 0, -1, false, { " " .. spinner_frames[frame] .. " " .. label .. " " })
		frame = frame % #spinner_frames + 1
		vim.defer_fn(tick, 80)
	end
	tick()

	return function()
		active = false
		if vim.api.nvim_win_is_valid(win) then
			pcall(vim.api.nvim_win_close, win, true)
		end
	end
end

local function insert_at_position(buf, row, output)
	if not vim.api.nvim_buf_is_valid(buf) then
		return
	end
	local lines = vim.split(output, "\n", { plain = true })
	vim.api.nvim_buf_set_lines(buf, row, row, false, lines)
	return #lines
end

local function open_markdown_split(title, body)
	vim.cmd("botright split")
	vim.cmd("resize 12")
	local buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_win_set_buf(0, buf)
	vim.bo[buf].buftype = "nofile"
	vim.bo[buf].bufhidden = "wipe"
	vim.bo[buf].swapfile = false
	vim.bo[buf].filetype = "markdown"
	vim.api.nvim_buf_set_name(buf, "pi://" .. title)
	local lines = vim.split(body, "\n", { plain = true })
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
	vim.bo[buf].modifiable = false
	vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = buf, silent = true })
end

local PI_BASE = {
	"pi",
	"-p",
	"--no-skills",
	"--no-extensions",
	"--no-tools",
	"--no-session",
	"--model",
	"openai-codex/gpt-5.4-mini",
}

local function run_pi(args, prompt, on_done)
	local cmd = vim.list_extend(vim.deepcopy(PI_BASE), args)
	table.insert(cmd, prompt)
	vim.system(cmd, { text = true }, function(result)
		vim.schedule(function()
			if result.code ~= 0 then
				vim.notify(result.stderr ~= "" and result.stderr or "pi failed", vim.log.levels.ERROR)
				return
			end
			local output = vim.trim(result.stdout or "")
			if output == "" then
				vim.notify("pi returned no output", vim.log.levels.WARN)
				return
			end
			on_done(output)
		end)
	end)
end

local function pi_write(prompt)
	local buf = vim.api.nvim_get_current_buf()
	local cursor = vim.api.nvim_win_get_cursor(0)
	local insert_row = cursor[1]
	local stop = start_spinner(buf, cursor[1] - 1, cursor[2], "asking pi (write)")

	local system =
		"You are a code generator. Output only the requested code — no explanations, usage examples, markdown fences, headings, or surrounding prose. Use the buffer context provided in the user message to pick the correct language and style. If the request is ambiguous, choose the most likely implementation and still output only code."
	local user = table.concat({ get_context(buf), "", "Request:", prompt }, "\n")

	run_pi({ "--system-prompt", system }, user, function(output)
		stop()
		local n = insert_at_position(buf, insert_row, output)
		if n then
			vim.notify("PiWrite inserted " .. n .. " line" .. (n == 1 and "" or "s"), vim.log.levels.INFO)
		end
	end)
end

local MAX_BUFFER_BYTES = 24000

local function get_buffer_text(buf)
	local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
	local text = table.concat(lines, "\n")
	if #text > MAX_BUFFER_BYTES then
		text = text:sub(1, MAX_BUFFER_BYTES) .. "\n… (truncated)"
	end
	return text
end

local function pi_ask(prompt, has_selection)
	local buf = vim.api.nvim_get_current_buf()
	local stop = start_corner_spinner("asking pi")

	local system =
		"You are a code assistant answering questions about the user's current buffer or selection. Reply in concise markdown — explanations, references, and code blocks fenced by language. No filler, no preamble."

	local user_parts = { get_context(buf), "" }
	local code, label
	if has_selection then
		code = get_visual_selection()
		label = "Selected code:"
	else
		code = get_buffer_text(buf)
		label = "Buffer content:"
	end
	if code and code ~= "" then
		table.insert(user_parts, label)
		table.insert(user_parts, "```")
		table.insert(user_parts, code)
		table.insert(user_parts, "```")
		table.insert(user_parts, "")
	end
	table.insert(user_parts, "Question:")
	table.insert(user_parts, prompt)

	run_pi({ "--system-prompt", system }, table.concat(user_parts, "\n"), function(output)
		stop()
		open_markdown_split(prompt:sub(1, 40), output)
	end)
end

vim.api.nvim_create_user_command("PiWrite", function(opts)
	pi_write(opts.args)
end, { nargs = "+", desc = "Generate code with pi and insert at cursor" })

vim.api.nvim_create_user_command("PiAsk", function(opts)
	pi_ask(opts.args, opts.range > 0)
end, { nargs = "+", range = true, desc = "Ask pi about the buffer or visual selection; output in a markdown vsplit" })
