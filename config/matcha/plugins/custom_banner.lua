-- custom_banner.lua
-- Replaces the default ASCII logo on the startup screen with a custom banner.
-- Demonstrates matcha.ui.set_banner().

local matcha = require("matcha")

local banner = [[
   )  )
  (  (         m a t c h a
 ▄▄▄▄▄▄▄▄
 █      █▀▄    your inbox, freshly brewed
 █      █▄▀
  ▀▄▄▄▄▀
]]


matcha.on("startup", function()
  matcha.ui.set_banner(banner)
end)

matcha.on("shutdown", function()
  matcha.ui.set_banner("")
end)
