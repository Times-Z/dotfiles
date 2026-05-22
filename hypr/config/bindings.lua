local mainMod = "SUPER"
local ctrl = "CTRL"
local alt = "ALT"

-- Launchers
hl.bind(ctrl .. " + " .. alt .. " + T", hl.dsp.exec_cmd("kitty"))
hl.bind(ctrl .. " + " .. alt .. " + Q", hl.dsp.window.close())
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd("nautilus --new-window ~"))
hl.bind(alt .. " + space", hl.dsp.exec_cmd("rofi -show drun"))
hl.bind(alt .. " + C", hl.dsp.exec_cmd("kitty --class clipse -e clipse"))
hl.bind("PRINT", hl.dsp.exec_cmd("grim -g \"$(slurp -d)\" - | satty -f - -o ~/Pictures/Screenshots/screenshot_$(date +'%Y%m%d_%H%M%S').png"))
hl.bind(mainMod .. " + semicolon", hl.dsp.exec_cmd("smile"))

-- Window management
hl.bind(mainMod .. " + W", hl.dsp.window.fullscreen({mode = 1}))
hl.bind(mainMod .. " + L", hl.dsp.exec_cmd("hyprlock"))
hl.bind(mainMod .. " + D", hl.dsp.window.float({action = "toggle"}))
hl.bind(mainMod .. " + M", hl.dsp.exit())

-- Workspace cycling (scripts)
hl.bind(mainMod .. " + TAB", hl.dsp.exec_cmd("~/.config/hypr/scripts/ws-cycle next"))
hl.bind(mainMod .. " + SHIFT + TAB", hl.dsp.exec_cmd("~/.config/hypr/scripts/ws-cycle prev"))

-- Move active window to workspace
hl.bind(mainMod .. " + SHIFT + ampersand", hl.dsp.window.move({workspace = 1}))
hl.bind(mainMod .. " + SHIFT + eacute", hl.dsp.window.move({workspace = 2}))
hl.bind(mainMod .. " + SHIFT + quotedbl", hl.dsp.window.move({workspace = 3}))
hl.bind(mainMod .. " + SHIFT + apostrophe", hl.dsp.window.move({workspace = 4}))
hl.bind(mainMod .. " + SHIFT + parenleft", hl.dsp.window.move({workspace = 5}))
hl.bind(mainMod .. " + SHIFT + minus", hl.dsp.window.move({workspace = 6}))

-- Move focus with arrow keys
hl.bind(mainMod .. " + left", hl.dsp.focus({direction = "left"}))
hl.bind(mainMod .. " + right", hl.dsp.focus({direction = "right"}))
hl.bind(mainMod .. " + up", hl.dsp.focus({direction = "up"}))
hl.bind(mainMod .. " + down", hl.dsp.focus({direction = "down"}))

-- Move/resize windows with mouse
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), {mouse = true})
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), {mouse = true})
