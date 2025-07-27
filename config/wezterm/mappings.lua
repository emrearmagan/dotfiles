local wezterm = require("wezterm")
local act = wezterm.action

-- Helper function to decide whether to send vim-style key or switch pane
local function activate_pane(window, pane, pane_direction, vim_direction)
	-- Check if current process is (n)vim
	local isViProcess = pane:get_foreground_process_name():find("n?vim") ~= nil

	if isViProcess then
		-- Inside vim: send movement key (h/j/k/l) with CTRL modifier
		window:perform_action(act.SendKey({ key = vim_direction, mods = "CTRL" }), pane)
	else
		-- Outside vim: switch pane using wezterm's direction
		window:perform_action(act.ActivatePaneDirection(pane_direction), pane)
	end
end

-- Register events for smart directional navigation
-- These are triggered via `EmitEvent("activate_pane_*")` in keybindings

wezterm.on("activate_pane_r", function(window, pane)
	activate_pane(window, pane, "Right", "l")
end)

wezterm.on("activate_pane_l", function(window, pane)
	activate_pane(window, pane, "Left", "h")
end)

wezterm.on("activate_pane_u", function(window, pane)
	activate_pane(window, pane, "Up", "k")
end)

wezterm.on("activate_pane_d", function(window, pane)
	activate_pane(window, pane, "Down", "j")
end)

return {
	leader = { key = "F12", mods = "", timeout_milliseconds = 5000 },
	keys = {
		{ key = "/", mods = "LEADER", action = act.Search("CurrentSelectionOrEmptyString") },

		-- use the default german shortut for ToggleFullScreen
		{
			key = "f",
			mods = "CMD|CTRL",
			action = wezterm.action.ToggleFullScreen,
		},
	},
}
