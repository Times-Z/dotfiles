-- Paths
hl.env("GOPATH", os.getenv("HOME") .. "/.local/share/go")
hl.env("PATH", os.getenv("PATH") ..
  ":" .. os.getenv("HOME") .. "/.cargo/bin" ..
  ":" .. os.getenv("GOPATH") .. "/bin" ..
  ":" .. os.getenv("HOME") .. "/.config/hypr/scripts" ..
  ":" .. os.getenv("HOME") .. "/.pyenv/bin")

-- Cursor size
hl.env("XCURSOR_SIZE", "20")
-- Qt en Wayland (fallback X11 si besoin)
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
-- GTK en Wayland (fallback X11)
hl.env("GDK_BACKEND", "wayland,x11")
hl.env("GSK_RENDERER", "vulkan")
-- Clutter en Wayland
hl.env("CLUTTER_BACKEND", "wayland")
-- Firefox/Thunderbird Wayland
hl.env("MOZ_ENABLE_WAYLAND", "1")
-- Hints de session
hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_TYPE", "wayland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")
-- Qt: pas de déco côté client
hl.env("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1")
-- Qt: HiDPI auto
hl.env("QT_AUTO_SCREEN_SCALE_FACTOR", "1")
-- XDG data dirs
hl.env("XDG_DATA_DIRS", "~/.local/share:/usr/local/share:/usr/share")

-- --- GPU / Proton / Gaming ---

-- Threading for GL (helps old OpenGL games)
hl.env("mesa_glthread", "true")
-- Disable unstable Vulkan optimizations under Wayland
hl.env("WINE_DISABLE_VULKAN_OPWR", "0")
-- Run Proton in native Wayland mode
hl.env("PROTON_ENABLE_WAYLAND", "1")
-- Allow esync (eventfd synchronization)
hl.env("PROTON_NO_ESYNC", "0")
-- Allow fsync (futex2 synchronization)
hl.env("PROTON_NO_FSYNC", "0")
-- Enable NGG (GPL) + SAM (Resizable BAR) for AMD
hl.env("RADV_PERFTEST", "gpl,sam")
-- Reasonable PulseAudio latency
hl.env("PULSE_LATENCY_MSEC", "60")
-- Disable steam debugging
hl.env("STEAM_RUNTIME_HEAVY_DEBUG", "0")

-- Rocm
hl.env("ROCM_PATH", "/opt/rocm")
