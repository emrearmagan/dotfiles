-------------------- Settings ------------------------

maki.setup({
	always_thinking = "xhigh",
	ui = {
		splash_animation = true,
		notifications = "off",
		theme = "catppuccin_mocha",
		thinking_lines = 0,
		tool_output_lines = {
			bash = 1,
			code_execution = 1,
			index = 1,
			grep = 1,
			read = 1,
			write = 1,
			web = 1,
			other = 1,
		},
	},
	provider = {
		default_model = "openai/gpt-6-astra",
		allowed_models = { "openai/*", "copilot/*", "ollama/*" },
		excluded_models = { "*/*-preview", "*-image", "*-tts", "*-transcribe" },
	},
})

-------------------- Keymaps ------------------------

maki.keymap.set("n", "<C-b>", function()
	local _, err = maki.task.focus("main")
	if err then
		maki.ui.flash(err)
	end
end, { desc = "Back to main chat" })

-------------------- Hooks ------------------------

local ask_commands = {
	"git commit",
	"git push",
	"git %-C %S+ push",
	"git checkout",
	"git switch",
	"git rebase",
	"git reset %-%-hard",
	"git stash",
	"gh pr create",
	"gh pr merge",
	"gh pr comment",
	"gh pr review",
	"gh issue create",
	"gh issue comment",
}

local function is_force_remove(part)
	if not part:find("^rm%s") then
		return false
	end
	local flags = ""
	for flag in part:gmatch("%s%-(%S+)") do
		flags = flags .. flag
	end
	return flags:find("[rR]") ~= nil and flags:find("f") ~= nil
end

maki.api.set_slot("tool.bash.input", function(prev, input, ctx)
	input.command = input.command:gsub("^grep %-r ", "rg ")
	for part in input.command:gmatch("[^;&|\n]+") do
		part = part:match("^%s*(.-)%s*$")
		if is_force_remove(part) then
			return nil, "rm -rf is blocked. Run it yourself if it is really wanted."
		end
		for _, pattern in ipairs(ask_commands) do
			if part:find("^" .. pattern) then
				return input, { ask = "Changes git history or posts to GitHub." }
			end
		end
	end
	return prev(input, ctx)
end)

local public_env_files = { [".env.example"] = true, [".env.sample"] = true, [".env.dist"] = true }

local function is_secret(path)
	local name = path:match("[^/]+$") or path
	if public_env_files[name] then
		return false
	end
	return name == ".env" or name == ".dev.vars" or name:find("^%.env%.") ~= nil
end

for _, tool in ipairs({ "read", "write", "edit", "multiedit", "edit_lines" }) do
	maki.api.set_slot("tool." .. tool .. ".input", function(prev, input, ctx)
		if input.path and is_secret(input.path) then
			return nil, "Secret files like .env are off limits."
		end
		return prev(input, ctx)
	end)
end

-------------------- Agent status ------------------------

local status_hook = maki.uv.os_homedir() .. "/.config/scripts/agent-status-hook"
local states = { working = "working", needs_input = "attention", idle = "idle" }

local function report_status(session_id, event, state)
	maki.fn.jobstart(
		("exec %s --provider maki --event %s --state %s </dev/null"):format(status_hook, event, state),
		{ scope = { session = session_id }, stdout = false, stderr = false }
	)
end

maki.api.create_autocmd("SessionStatusChanged", {
	callback = function(ev)
		local state = states[ev.data.status]
		if state then
			report_status(ev.data.session_id, "SessionStatusChanged", state)
		end
	end,
})

maki.api.create_autocmd("SessionEnd", {
	callback = function(ev)
		if ev.data.reason == "shutdown" then
			report_status(ev.data.session_id, "SessionEnd", "close")
		end
	end,
})
