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

local function start_spinner(buf, row, col)
	local active = true
	local frame = 1

	local function tick()
		if not active or not vim.api.nvim_buf_is_valid(buf) then
			return
		end

		pcall(vim.api.nvim_buf_set_extmark, buf, spinner_ns, row, col, {
			id = 1,
			virt_text = { { spinner_frames[frame] .. " asking opencode", "Comment" } },
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

local function insert_at_position(buf, row, output)
	if not vim.api.nvim_buf_is_valid(buf) then
		return
	end

	local lines = vim.split(output, "\n", { plain = true })
	vim.api.nvim_buf_set_lines(buf, row, row, false, lines)
	return #lines
end

local function ask(prompt)
	local buf = vim.api.nvim_get_current_buf()
	local win = vim.api.nvim_get_current_win()
	local cursor = vim.api.nvim_win_get_cursor(win)
	local insert_row = cursor[1]
	local stop_spinner = start_spinner(buf, cursor[1] - 1, cursor[2])

	local command = {
		"opencode",
		"run",
		"--model",
		"openai/gpt-5.3-codex",
		table.concat({
			"You are a code generator.",
			"Use the current buffer context to choose the correct language and style.",
			"Output only the requested code.",
			"Do not include explanations, usage examples, markdown fences, headings, or surrounding prose.",
			"If the request is ambiguous, choose the most likely implementation and still output only code.",
			"",
			get_context(buf),
			"",
			"Request:",
			prompt,
		}, "\n"),
	}

	vim.system(command, { text = true }, function(result)
		vim.schedule(function()
			stop_spinner()

			if result.code ~= 0 then
				vim.notify(result.stderr ~= "" and result.stderr or "opencode failed", vim.log.levels.ERROR)
				return
			end

			local output = vim.trim(result.stdout or "")
			if output == "" then
				vim.notify("opencode returned no output", vim.log.levels.WARN)
				return
			end

			local inserted = insert_at_position(buf, insert_row, output)
			if inserted then
				vim.notify("Ask inserted " .. inserted .. " line" .. (inserted == 1 and "" or "s"), vim.log.levels.INFO)
			end
		end)
	end)
end

vim.api.nvim_create_user_command("Ask", function(opts)
	ask(opts.args)
end, {
	nargs = "+",
})
