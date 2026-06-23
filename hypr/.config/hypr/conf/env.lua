-- ══════════════════════════════════════════
--   Ashen — Environment Variables
-- ══════════════════════════════════════════

-- Wayland
hl.env("XDG_SESSION_TYPE", "wayland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")
hl.env("XDG_CURRENT_DESKTOP", "Hyprland")

-- GTK
hl.env("GDK_BACKEND", "wayland,x11")
hl.env("GTK_THEME", "Adwaita:dark")

-- Qt
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("QT_AUTO_SCREEN_SCALE_FACTOR", "1")
hl.env("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1")

-- Cursor
hl.env("XCURSOR_THEME", "Bibata-Modern-Ice")
hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")

-- Intel GPU
hl.env("LIBVA_DRIVER_NAME", "iHD")
hl.env("VDPAU_DRIVER", "va_gl")
