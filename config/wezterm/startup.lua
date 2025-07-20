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
	local home_pane = home_tab:active_pane():send_text("tmux a\n")

	local stats_tab = window:spawn_tab({ cwd = home })
	stats_tab:set_title("stats")

	local stats_pane = stats_tab:active_pane()
	stats_pane:send_text("df -h /\n")
	local bottom_pane = stats_pane:split({
		direction = "Bottom",
		size = 0.5,
		cwd = home,
	})
	bottom_pane:send_text("btop\n")

	-- activate home tab
	window:gui_window():perform_action(act.ActivateTab(0), home_tab:active_pane())
end)
