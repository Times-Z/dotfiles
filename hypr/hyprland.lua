-- Hyprland configuration file

hl.monitor({
    output   = "DP-1",
    mode     = "5120x1440@240.00",
    position = "0x0",
    scale    = 1.0,
    bitdepth = 10,
    cm       = "wide",
    vrr      = true,
    supports_hdr = true,
})

require("config.startup")
require("config.env")
require("config.input")
require("config.bindings")
require("config.general")
require("config.decoration")
require("config.layout")
require("config.animations")
require("config.windowrules")

if os.getenv("HYPR_DEBUG") == "true" then
    require("config.debug")
end
