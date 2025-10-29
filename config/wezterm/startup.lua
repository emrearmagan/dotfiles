local wezterm = require("wezterm")
local act = wezterm.action
local mux = wezterm.mux

wezterm.on("gui-startup", function(cmd)
	-- allow `wezterm start -- something` to affect what we spawn
	-- in our initial window
	local args = {}
	if cmd then
		args = cmd.args
	end

	local home = wezterm.home_dir

	local home_tab, _, window = mux.spawn_window({
		workspace = "default",
		cwd = home,
		args = args,
	})
	home_tab:set_title("home")
	home_tab:active_pane():send_text("tmux a\n")

	local empty_tab = window:spawn_tab({ cwd = home })
	empty_tab:set_title("scratch")

	local stats_tab = window:spawn_tab({ cwd = home })
	stats_tab:set_title("stats")
	stats_tab:active_pane():send_text("btop\n")

	-- activate home tab
	window:gui_window():perform_action(act.ActivateTab(0), home_tab:active_pane())
end)
