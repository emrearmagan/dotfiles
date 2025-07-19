local wezterm = require("wezterm")

wezterm.on("format-tab-title", function(tab, _, _, _, _, max_width)
	local title = tab.tab_title
	if not title or title == "" then
		title = tab.active_pane.title
	end

	local is_active = tab.is_active
	local edge_bg = "#1e2030"
	local bg = is_active and "#7aa2f7" or "#1e2030"
	local fg = is_active and "#1e2030" or "#7aa2f7"

	local left_arrow = utf8.char(0xe0b6) -- 
	local right_arrow = utf8.char(0xe0b4) -- 

	return {
		{ Foreground = { Color = bg } },
		{ Background = { Color = bg } },
		{ Foreground = { Color = fg } },
		{ Text = " " .. wezterm.truncate_right(title, max_width - 3) .. " " },
		{ Background = { Color = edge_bg } },
		{ Foreground = { Color = bg } },
		{ Text = right_arrow },
	}
end)

-- Add current time and custom mode message to right side of status bar
wezterm.on("update-right-status", function(window)
	local date = wezterm.strftime("%Y-%m-%d %H:%M:%S ")
	window:set_right_status(date)
end)

-- Allow user to dynamically change the tab title using `wezterm cli set-user-var tab_title "New Title"`
local user_var_tab_title_key = "tab_title"
-- Handle dynamic user var changes for updating tab title
wezterm.on("user-var-changed", function(_, pane, name, value)
	if name == user_var_tab_title_key then
		pane:tab():set_title(value)
	end
end)

return {
	-- Rendering
	animation_fps = 240,
	max_fps = 240,
	front_end = "WebGpu",
	webgpu_power_preference = "HighPerformance",

	-- Appearance
	color_scheme = "Catppuccin Mocha", -- or "Catppuccin Macchiato", etc.

	font = wezterm.font("JetBrainsMono Nerd Font", { weight = "Medium" }),
	font_rules = {
		{
			italic = true,
			font = wezterm.font({
				family = "JetBrainsMono Nerd Font Mono",
				weight = "DemiBold",
				italic = true,
			}),
		},
	},
	font_size = 13,
	adjust_window_size_when_changing_font_size = false,
	window_background_opacity = 1,

	-- Tab bar
	tab_max_width = 18,
	tab_bar_at_bottom = false,
	use_fancy_tab_bar = false,
	hide_tab_bar_if_only_one_tab = true,

	--- window_decorations = "RESIZE",
	window_decorations = "RESIZE",
	initial_rows = 40, -- height (default is 24)
	initial_cols = 120, -- width (default is 80)
}
