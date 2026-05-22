hl.config({
    animations = {
        enabled = true,
    },
})

hl.curve("easeOut", { type = "bezier", points = { {0.22, 1},   {0.36,  1}    } })
hl.curve("easeIn",  { type = "bezier", points = { {0.36, 0},   {0.66, -0.01} } })
hl.curve("snappy",  { type = "bezier", points = { {0.05, 0.9}, {0.1,   1.05} } })

hl.animation({ leaf = "global", enabled = true, speed = 5, bezier = "default" })
hl.animation({ leaf = "windows",     enabled = true, speed = 5, bezier = "easeOut" })
hl.animation({ leaf = "windowsIn",   enabled = true, speed = 4, bezier = "easeOut" })
hl.animation({ leaf = "windowsOut",  enabled = true, speed = 6, bezier = "easeIn",  style = "popin 65%" })
hl.animation({ leaf = "windowsMove", enabled = true, speed = 5, bezier = "easeOut", style = "slide" })
hl.animation({ leaf = "fadeIn",      enabled = true, speed = 2, bezier = "easeOut" })
hl.animation({ leaf = "fadeOut",     enabled = true, speed = 2, bezier = "easeOut" })
hl.animation({ leaf = "layers",      enabled = true, speed = 5, bezier = "easeOut" })
hl.animation({ leaf = "layersIn",    enabled = true, speed = 5, bezier = "easeOut" })
hl.animation({ leaf = "layersOut",   enabled = true, speed = 5, bezier = "easeOut" })
hl.animation({ leaf = "fade",        enabled = true, speed = 2, bezier = "easeOut" })
hl.animation({ leaf = "border",      enabled = true, speed = 7, bezier = "easeOut" })
hl.animation({ leaf = "borderangle", enabled = true, speed = 7, bezier = "easeOut" })
hl.animation({ leaf = "workspaces",  enabled = true, speed = 5, bezier = "snappy"  })
