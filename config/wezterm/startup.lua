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

  local stats_tab = window:spawn_tab({ cwd = home })
  stats_tab:set_title("stats")

  local stats_pane = stats_tab:active_pane()
  local right_pane = stats_pane:split({
    direction = "Right",
    size = 80,
    cwd = home,
  })
  right_pane:send_text("htop\n")

  window:gui_window():perform_action(act.ActivateTab(0), stats_tab:active_pane())
end)