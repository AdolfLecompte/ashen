-- ══════════════════════════════════════════
--   Ashen — Window Rules
-- ══════════════════════════════════════════

-- Special Workspaces
hl.window_rule({ match = { class = "brave-cinhimbnkkaeohfgghhklpknlkffjgod-Default" }, workspace = "special:music"   })
hl.window_rule({ match = { class = "discord"        }, workspace = "special:discord" })
hl.window_rule({ match = { class = "obsidian"        }, workspace = "special:notes" })

-- Floating
hl.window_rule({ match = { class = "^(pavucontrol|org.pulseaudio.pavucontrol)$" }, float = true })

-- Picture-in-picture: small, above everything, out of the way.
hl.window_rule({ match = { title = "^(Picture-in-Picture|Picture in picture|Imagen en imagen)$" },
    float = true, pin = true, keep_aspect_ratio = true, size = "480 270", move = "100%-500 100%-350" })
-- The portal's file chooser floats centred instead of tiling.
hl.window_rule({ match = { class = "^(xdg-desktop-portal-gtk)$" }, float = true, center = true, size = "60% 70%" })

-- Opacity: global active/inactive_opacity from decoration.lua drives every
-- window, except browsers: their content is dense enough that the frosted
-- glass made it unreadable, so they get a bump.
-- brave.* also catches the PWAs (whatsapp, youtube music...), whose class is
-- brave-<app-id>-Default. Steam's UI is CEF-based and just as dense.
-- `override` is mandatory: without it Hyprland multiplies this value by the
-- global active/inactive_opacity instead of replacing it.
hl.window_rule({ match = { class = "^(brave.*|firefox|chromium|google-chrome|steam)$" }, opacity = "0.85 override 0.80 override" })

-- File managers and the portal's file chooser get the same bump, for the same
-- reason: they are a column of small text over whatever the wallpaper happens
-- to be, and at the global 0.70 a light wallpaper swallowed the file names.
hl.window_rule({ match = { class = "^(nemo|thunar|org.gnome.Nautilus|xdg-desktop-portal-gtk|zenity|file-roller)$" }, opacity = "0.96 override 0.92 override" })

-- Shell blur: the bar, panels and toasts (their layer is plain "quickshell")
hl.layer_rule({ match = { namespace = "^quickshell.*" }, blur = true })
-- The shell animates its own surfaces; Hyprland's fade on top doubled it.
hl.layer_rule({ match = { namespace = "^quickshell.*" }, no_anim = true })
hl.layer_rule({ match = { namespace = "^quickshell.*" }, ignore_alpha = 0.3 })
-- Desktop widgets live on their own layer ("ashen:desktop"): same glass.
hl.layer_rule({ match = { namespace = "^ashen:.*" }, blur = true })
hl.layer_rule({ match = { namespace = "^ashen:.*" }, ignore_alpha = 0.3 })

-- The screenshot selection must not animate OUT. grimblast asks for exactly
-- this itself -- `hyprctl keyword layerrule "match:selection, no_anim on"` --
-- but on a Lua config `hyprctl keyword` answers "can't work with non-legacy
-- parsers" and dies, so the rule never landed and grim caught the selection
-- mid-fade: that is the border that keeps appearing along the edge of a shot.
-- Set here, where it holds for good.
hl.layer_rule({ match = { namespace = "selection" }, no_anim = true })
