-- Rofi
hl.window_rule({
    name  = "rofi",
    match = { class = "Rofi" },
    opacity      = 0.8,
    stay_focused = true,
})

-- Screen sharing & Layout
hl.window_rule({
    name  = "no-screen-share-vesktop",
    match = { class = "vesktop" },
    no_screen_share = true,
})
hl.window_rule({
    name  = "no-screen-share-element",
    match = { class = "Element" },
    no_screen_share = true,
})
hl.window_rule({
    name  = "satty-float",
    match = { class = "com.gabm.satty" },
    float  = true,
    center = true,
})
hl.window_rule({
    name  = "loupe-float",
    match = { class = "org.gnome.Loupe" },
    float = true,
})
hl.window_rule({
    name  = "godot-tile",
    match = { class = "Godot" },
    tile  = true,
})

-- Zenity & Portals
hl.window_rule({
    name  = "zenity",
    match = { class = "zenity" },
    float  = true,
    center = true,
    tag    = "+float_disable_effetcs",
})
hl.window_rule({
    name  = "xdg-portal-gtk-tag",
    match = { class = "Xdg-desktop-portal-gtk" },
    tag   = "+float_disable_effetcs",
})

-- Tag Rules (float_disable_effetcs)
hl.window_rule({
    name  = "float-disable-effects",
    match = { tag = "float_disable_effetcs" },
    decorate          = false,
    no_blur           = true,
    focus_on_activate = true,
    no_dim            = true,
    stay_focused      = true,
})

-- Steam Big Picture
hl.window_rule({
    name  = "steam-bigpicture",
    match = { class = "steam", title = ".*Big.*Picture.*" },
    float  = true,
    center = true,
    size   = "1920 1080",
})

-- Wakfu
hl.window_rule({
    name  = "wakfu",
    match = { class = "com-ankamagames-wakfu-client-WakfuClient" },
    rounding   = 0,
    fullscreen = true,
})

-- Clipse
hl.window_rule({
    name  = "clipse",
    match = { class = "clipse" },
    float             = true,
    size              = "600 400",
    center            = true,
    focus_on_activate = true,
    stay_focused      = true,
})

-- Smile (Emoji picker)
hl.window_rule({
    name  = "smile",
    match = { class = "it.mijorus.smile" },
    float             = true,
    size              = "600 400",
    center            = true,
    focus_on_activate = true,
    stay_focused      = true,
})

-- HDR/Media Applications Tags
hl.window_rule({
    name  = "hdr-tag-mpv",
    match = { class = "mpv" },
    tag = "+hdr_app",
})
hl.window_rule({
    name  = "hdr-tag-vlc",
    match = { class = "vlc" },
    tag = "+hdr_app",
})
hl.window_rule({
    name  = "hdr-tag-firefox",
    match = { class = "firefox.*" },
    tag = "+hdr_app",
})
hl.window_rule({
    name  = "hdr-tag-chromium",
    match = { class = "chromium" },
    tag = "+hdr_app",
})
hl.window_rule({
    name  = "hdr-tag-brave",
    match = { class = "brave-browser" },
    tag = "+hdr_app",
})
hl.window_rule({
    name  = "hdr-tag-steam-app",
    match = { class = "steam_app_.*" },
    tag = "+hdr_app",
})

-- HDR Apps optimizations
hl.window_rule({
    name  = "hdr-app-base",
    match = { tag = "hdr_app" },
    immediate = true,
    no_dim    = true,
})
hl.window_rule({
    name  = "hdr-app-fullscreen",
    match = { tag = "hdr_app", fullscreen = true },
    decorate = false,
    no_blur  = true,
})

-- xdg-desktop-portal-gtk
hl.window_rule({
    name  = "xdg-portal-gtk",
    match = { class = "xdg-desktop-portal-gtk" },
    float        = true,
    center       = true,
    size         = "900 600",
    stay_focused = true,
})

-- Zagrimètre
hl.window_rule({
    name  = "zagrimetre",
    match = { class = "zagrimetre", title = "Zagrimètre" },
    float  = true,
    center = true,
    size   = "1920 1080",
})
