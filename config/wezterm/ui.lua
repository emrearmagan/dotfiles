local wezterm = require("wezterm")

-- Helper to format tab titles with padding
local format_title = function(title, is_active, max_width)
  local title_len = #title
  local pad_len = math.floor((max_width - title_len) / 2)

  local formatted_title = {
    Text = string.rep(" ", pad_len) .. title .. string.rep(" ", pad_len),
  }

  return { formatted_title }
end

-- Allow user to dynamically change the tab title using `wezterm cli set-user-var tab_title "New Title"`
local user_var_tab_title_key = "tab_title"

-- Custom tab title formatting
wezterm.on("format-tab-title", function(tab, _, _, _, _, max_width)
  local user_title = tab.tab_title
  -- If user has explicitly set a tab title (via wezterm CLI), use it
  if type(user_title) == "string" and #user_title > 0 then
    return format_title(tab.tab_title, tab.is_active, max_width)
  end

  return format_title(user_title, max_width)
end)

-- Add current time and custom mode message to right side of status bar
wezterm.on("update-right-status", function(window)
  local date = wezterm.strftime("%Y-%m-%d %H:%M:%S ")
  window:set_right_status(date)
end)

-- Handle dynamic user var changes for updating tab title
wezterm.on("user-var-changed", function(_, pane, name, value)
  if name == user_var_tab_title_key then
    pane:tab():set_title(value)
  end
end)

-- UI Config (exported)
return {
  -- Rendering
  animation_fps = 240,
  max_fps = 240,
  front_end = "WebGpu",
  webgpu_power_preference = "HighPerformance",

  -- Appearance
  color_scheme = "Tokyo Night",
  font = wezterm.font("JetBrainsMono Nerd Font", { weight = "Medium" }),
  font_rules = {
    {
      italic = true,
      font = wezterm.font({
        family = "JetBrainsMono Nerd Font Mono",
        weight = "DemiBold",
        italic = true,
      })

    },
  },
  font_size = 14,
  adjust_window_size_when_changing_font_size = false,
  window_background_opacity = 1,

  -- Tab bar
  tab_max_width = 18,
  tab_bar_at_bottom = false,
  use_fancy_tab_bar = false,

  --- window_decorations = "RESIZE",
  window_decorations = "RESIZE",
  initial_rows = 40,  -- height (default is 24)
  initial_cols = 120, -- width (default is 80)
}
