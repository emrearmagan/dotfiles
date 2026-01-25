local wezterm = require("wezterm")

require("startup")
local keys = require("mappings")
local ui = require("ui")

local config = {
  -- Force XWayland
  enable_wayland = false,

  -- Important for arch linux: disbale background GUI
  mux_enable = false,

	notification_handling = "AlwaysShow",
	audible_bell = "Disabled",
	-- macos_forward_to_ime_modifier_mask = 'SHIFT',

	-- Ensure AltGr (right Alt) works correctly for German layouts
	--   send_composed_key_when_left_alt_is_pressed = true,
	--   send_composed_key_when_right_alt_is_pressed = true,
	--
	-- Support dead-keys (umlauts, tilde, etc.) on European layouts
	-- use_dead_keys = true,
}

for k, v in pairs(ui) do
	config[k] = v
end

for k, v in pairs(keys) do
	config[k] = v
end

return config
