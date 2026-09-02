pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

// Everything that paints a theme: the fixed palettes, and the commands that push
// the chosen one out to the shell, GTK, kitty, cava and the prompt. This used to
// live inside the Settings theme tab, so a scheme could only be applied while
// that tab existed -- a wallpaper profile has to be able to re-apply one with
// Settings closed.
Singleton {
    id: root

    // kitty appends "-<pid>" to the listen_on socket, so we have to walk
    // whichever ones exist instead of assuming the exact path.
    readonly property string kittySockets: "/tmp/kitty-ashen.sock-*"

    // The scheme on screen: an id from schemeCards, or "dynamic".
    property string schemeId: "classic"
    property string dynamicType: "scheme-tonal-spot"
    readonly property bool dynamicActive: root.schemeId === "dynamic"

    // Single source for the pills in Settings and the validity check on load
    readonly property var schemeCards: [
        { id: "classic", label: "Classic" },
        { id: "monochrome", label: "Monochrome" },
        { id: "cyberpunk", label: "Cyberpunk" },
        { id: "edgerunners", label: "Edgerunners" },
        { id: "tokyonight", label: "Tokyo Night" },
        { id: "dracula", label: "Dracula" },
        { id: "nord", label: "Nord" },
    ]

    readonly property var dynamicTypes: [
        { id: "scheme-neutral", label: "Neutral" },
        { id: "scheme-tonal-spot", label: "Tonal Spot" },
        { id: "scheme-vibrant", label: "Vibrant" },
        { id: "scheme-expressive", label: "Expressive" },
        { id: "scheme-fidelity", label: "Fidelity" },
        { id: "scheme-content", label: "Content" },
        { id: "scheme-rainbow", label: "Rainbow" },
        { id: "scheme-fruit-salad", label: "Fruit Salad" },
    ]

    property var schemes: {
        "classic": { abyss: "#080809", void_: "#0f0f11", crypt: "#16161a", surface: "#1c1c21", raised: "#242428", elevated: "#2e2e34", snow: "#e8e8ec", mist: "#9090a0", ash: "#4a4a54", ghost: "#6e6e7a", shade: "#4e4e5a", error_: "#c87a7a", neutral: "#8a8a96", papirusColor: "grey" },
        // Strictly greyscale -- no hue anywhere, error_ included (it stays
        // readable through brightness, not colour).
        "monochrome": { abyss: "#050505", void_: "#0d0d0d", crypt: "#131313", surface: "#1a1a1a", raised: "#242424", elevated: "#2e2e2e", snow: "#f2f2f2", mist: "#9e9e9e", ash: "#4d4d4d", ghost: "#d4d4d4", shade: "#8c8c8c", error_: "#b3b3b3", neutral: "#c4c4c4", papirusColor: "grey" },
        "cyberpunk": { abyss: "#0d0221", void_: "#150829", crypt: "#1a0b2e", surface: "#241b3d", raised: "#2d2347", elevated: "#3a2d5c", snow: "#f0f0ff", mist: "#b8a9d9", ash: "#5e4b8b", ghost: "#ff2e97", shade: "#cc1f7a", error_: "#ff3860", neutral: "#00fff2", papirusColor: "magenta" },
        "edgerunners": { abyss: "#05070a", void_: "#080c12", crypt: "#0c1119", surface: "#111827", raised: "#172032", elevated: "#1e2a3f", snow: "#eaf6ff", mist: "#5ef2a4", ash: "#3d5166", ghost: "#fcee0a", shade: "#c9be00", error_: "#ff003c", neutral: "#00e5ff", papirusColor: "yellow" },
        "tokyonight": { abyss: "#16161e", void_: "#1a1b26", crypt: "#1f2335", surface: "#24283b", raised: "#292e42", elevated: "#364a82", snow: "#c0caf5", mist: "#a9b1d6", ash: "#565f89", ghost: "#7aa2f7", shade: "#3d59a1", error_: "#f7768e", neutral: "#bb9af7", papirusColor: "blue" },
        "dracula": { abyss: "#21222c", void_: "#282a36", crypt: "#2d2f3f", surface: "#343746", raised: "#44475a", elevated: "#4d5066", snow: "#f8f8f2", mist: "#9ba0c4", ash: "#6272a4", ghost: "#bd93f9", shade: "#9580c9", error_: "#ff5555", neutral: "#ff79c6", papirusColor: "violet" },
        "nord": { abyss: "#2e3440", void_: "#3b4252", crypt: "#434c5e", surface: "#434c5e", raised: "#4c566a", elevated: "#4c566a", snow: "#eceff4", mist: "#d8dee9", ash: "#4c566a", ghost: "#88c0d0", shade: "#5e81ac", error_: "#bf616a", neutral: "#b48ead", papirusColor: "cyan" },
    }

    // The same seven, in light. Not an inversion: a palette that is merely
    // flipped comes out muddy, and an accent that reads on black is usually
    // too pale to read on white. The surface ladder still runs base -> raised,
    // it just runs upward in brightness instead of downward.
    property var lightSchemes: {
        "classic": { abyss: "#f4f4f6", void_: "#eeeef1", crypt: "#e7e7ec", surface: "#e0e0e6", raised: "#d6d6de", elevated: "#c9c9d3", snow: "#15151a", mist: "#45454f", ash: "#6e6e7a", ghost: "#4a4a58", shade: "#6a6a78", error_: "#b04a4a", neutral: "#6a6a78", papirusColor: "grey" },
        "monochrome": { abyss: "#fafafa", void_: "#f2f2f2", crypt: "#ebebeb", surface: "#e3e3e3", raised: "#d6d6d6", elevated: "#c7c7c7", snow: "#0b0b0b", mist: "#3d3d3d", ash: "#6b6b6b", ghost: "#242424", shade: "#565656", error_: "#5c5c5c", neutral: "#3d3d3d", papirusColor: "grey" },
        "cyberpunk": { abyss: "#f7f2ff", void_: "#f1e9fb", crypt: "#e9dff7", surface: "#e0d4f2", raised: "#d3c3ea", elevated: "#c2ade0", snow: "#1b0a2e", mist: "#4a2f70", ash: "#7a63a0", ghost: "#c1005f", shade: "#a8005699", error_: "#d10030", neutral: "#00877f", papirusColor: "magenta" },
        "edgerunners": { abyss: "#f6f9fc", void_: "#eef3f9", crypt: "#e4ebf4", surface: "#d9e3ef", raised: "#c9d6e6", elevated: "#b5c6db", snow: "#06121f", mist: "#0f5c3a", ash: "#5b6f85", ghost: "#6f5d00", shade: "#8f7a00", error_: "#c40030", neutral: "#0077a8", papirusColor: "yellow" },
        "tokyonight": { abyss: "#e9e9ed", void_: "#e1e2e7", crypt: "#d8dae2", surface: "#cfd2dc", raised: "#c3c7d4", elevated: "#b4bac9", snow: "#1f2335", mist: "#41508a", ash: "#5b6693", ghost: "#2557c9", shade: "#3f6bd6", error_: "#c64343", neutral: "#7847bd", papirusColor: "blue" },
        "dracula": { abyss: "#fbfbf6", void_: "#f4f4ee", crypt: "#ecece4", surface: "#e3e3da", raised: "#d7d7cc", elevated: "#c7c7ba", snow: "#1a1a1f", mist: "#4a4a63", ash: "#6b6b84", ghost: "#5236b8", shade: "#6e51cf", error_: "#cb3a3a", neutral: "#c2318f", papirusColor: "violet" },
        "nord": { abyss: "#eceff4", void_: "#e5e9f0", crypt: "#dde3ec", surface: "#d8dee9", raised: "#ccd4e0", elevated: "#bcc6d6", snow: "#2e3440", mist: "#3f4a5c", ash: "#5d6a7d", ghost: "#4a6d97", shade: "#5e81ac", error_: "#a8434c", neutral: "#9d6d92", papirusColor: "cyan" },
    }

    // The palette a scheme id resolves to right now.
    function paletteFor(id) {
        const set = Prefs.themeMode === "light" ? root.lightSchemes : root.schemes
        return set[id] || root.schemes[id]
    }

    // The colours a scheme will actually paint the shell in, taken from the
    // palette itself rather than a hand-written swatch list beside it.
    function swatchesOf(id) {
        const c = root.paletteFor(id)
        if (!c) return []
        return [c.abyss, c.surface, c.ghost, c.neutral, c.snow]
    }

    // Pick a scheme. A fixed palette paints itself; dynamic hands the job to
    // matugen, which reads the wallpaper (its frame, for gif and video).
    function setScheme(id) {
        root.schemeId = id
        if (id === "dynamic") {
            Quickshell.execDetached(["sh", "-c",
                "printf %s dynamic > \"$HOME/.cache/ashen_scheme_mode.txt\" && " +
                Paths.script("ashen-recolor.sh")
            ])
        } else {
            root.applyScheme(id)
        }
    }

    function applyScheme(schemeId) {
        let c = root.paletteFor(schemeId)
        if (!c) return
        let json = JSON.stringify({
            abyss: c.abyss, void_: c.void_, crypt: c.crypt, surface: c.surface,
            raised: c.raised, elevated: c.elevated, snow: c.snow, mist: c.mist,
            ash: c.ash, ghost: c.ghost, shade: c.shade, error_: c.error_, neutral: c.neutral
        })
        let borderHex = c.ghost.replace("#", "") + "ff"
        // Payload as argv ($1), never inlined into the script: Qt.btoa is
        // deprecated and base64 was only ever a way past the shell's parser.
        Quickshell.execDetached(["sh", "-c",
            "printf %s \"$1\" > \"$HOME/.cache/ashen_scheme.json\" && " +
            "echo '" + schemeId + "' > \"$HOME/.cache/ashen_scheme_mode.txt\" && " +
            // The accent everything outside the shell reads. On the dynamic
            // road ashen-accent.sh writes it; a fixed scheme has no matugen run
            // to hang off, so it says so itself -- without this the folders and
            // the border kept whichever wallpaper wrote it last.
            "printf %s '" + c.ghost.replace("#", "") + "' > \"$HOME/.cache/ashen_accent.txt\" && " +
            "hyprctl eval \"hl.config({ general = { col = { active_border = { colors = {'rgba(" + borderHex + ")'} } } } })\" && " +
            "sed -i 's/active_border = { colors = {\"rgba([^)]*)\"} }/active_border = { colors = {\"rgba(" + borderHex + ")\"} }/' \"$HOME/.config/hypr/conf/general.lua\"",
            "sh", json
        ])
        root.applyGtkTheme(c)
        root.applyKittyTheme(c)
        root.applyFolders()
        root.applyP10kTheme(c)
        root.applyCavaTheme(c)
    }

    // The standalone terminal cava. It reads a THEME file, named once in a
    // static ~/.config/cava/config that nothing regenerates -- the split cava
    // is built for. Rewriting the config under a running cava is what used to
    // break the bars: it reloads on change and read a half-written file.
    function applyCavaTheme(c) {
        // Bottom to top: the accent's dark end climbing to the lightest tone.
        const dim = root.darken(c.ghost, 0.45)
        const lines = [
            "# Generated by Ashen from the active scheme -- do NOT edit by hand",
            "[color]",
            "foreground = '" + c.ghost + "'",
            "gradient = 1",
            "gradient_color_1 = '" + dim + "'",
            "gradient_color_2 = '" + c.shade + "'",
            "gradient_color_3 = '" + c.ghost + "'",
            "gradient_color_4 = '" + c.neutral + "'",
            "gradient_color_5 = '" + c.snow + "'"
        ]
        const body = lines.map(l => '"' + l + '"').join(" ")
        Quickshell.execDetached(["sh", "-c",
            "mkdir -p \"$HOME/.config/cava/themes\" && " +
            "printf '%s\\n' " + body + " > \"$HOME/.config/cava/themes/ashen\""
        ])
    }

    // The accent taken most of the way down, on the string: Qt.darker hands
    // back a colour object and cava wants six hex digits.
    function darken(hex, k) {
        const n = parseInt(hex.replace("#", ""), 16)
        const two = v => Math.max(0, Math.min(255, Math.round(v))).toString(16).padStart(2, "0")
        return "#" + two(((n >> 16) & 255) * k) + two(((n >> 8) & 255) * k) + two((n & 255) * k)
    }

    function applyKittyTheme(c) {
        let conf = '# Generated by Ashen -- do NOT edit by hand, regenerated when the scheme changes\n' +
            'foreground            ' + c.snow + '\n' +
            'background            ' + c.abyss + '\n' +
            'selection_foreground  ' + c.abyss + '\n' +
            'selection_background  ' + c.ghost + '\n' +
            'cursor                ' + c.ghost + '\n' +
            'color0  ' + c.abyss + '\n' +
            'color1  ' + c.error_ + '\n' +
            'color2  #5a7a6a\n' +
            'color3  #8a7a5a\n' +
            // ANSI blue is the scheme accent (same as in p10k), so whatever the
            // terminal paints as "blue" follows the theme: fastfetch,
            // prompt, etc.
            'color4  ' + c.ghost + '\n' +
            'color5  #a89bc8\n' +
            'color6  #5a7a8a\n' +
            'color7  ' + c.mist + '\n' +
            'color8  ' + c.ash + '\n' +
            'color9  ' + c.error_ + '\n' +
            'color10 #7a9e7e\n' +
            'color11 #c4a882\n' +
            'color12 ' + c.neutral + '\n' +
            'color13 #c8b8e8\n' +
            'color14 #7aaabb\n' +
            'color15 ' + c.snow + '\n'
        Quickshell.execDetached(["sh", "-c",
            "printf %s \"$1\" > \"$HOME/.config/kitty/ashen-colors.conf\" && " +
            "for s in " + root.kittySockets + "; do kitten @ --to \"unix:$s\" set-colors --all " +
            "foreground=" + c.snow + " background=" + c.abyss + " " +
            "selection_foreground=" + c.abyss + " selection_background=" + c.ghost + " " +
            "cursor=" + c.ghost + " color0=" + c.abyss + " color1=" + c.error_ + " " +
            "color7=" + c.mist + " color8=" + c.ash + " color9=" + c.error_ + " color15=" + c.snow + " " +
            "2>/dev/null; done",
            "sh", conf
        ])
    }

    // The prompt follows the scheme through ONE file, sourced by .zshrc after
    // ~/.p10k.zsh so it wins. This used to sed `local grey=` and six friends
    // into that file -- lines no real p10k config has, so nothing ever changed.
    // Same path matugen's template writes; the last one wins.
    function applyP10kTheme(c) {
        const line = (name, hex) => "typeset -g POWERLEVEL9K_" + name + "='" + hex + "'"
        const lines = [
            "# Generated by Ashen from the active scheme -- do NOT edit by hand",
            line("DIR_FOREGROUND", c.ghost),
            line("DIR_ANCHOR_FOREGROUND", c.ghost),
            line("DIR_SHORTENED_FOREGROUND", c.ash),
            line("PROMPT_CHAR_OK_{VIINS,VICMD,VIVIS,VIOWR}_FOREGROUND", c.ghost),
            line("PROMPT_CHAR_ERROR_{VIINS,VICMD,VIVIS,VIOWR}_FOREGROUND", c.error_),
            line("VCS_CLEAN_FOREGROUND", c.mist),
            line("VCS_MODIFIED_FOREGROUND", c.neutral),
            line("VCS_UNTRACKED_FOREGROUND", c.shade),
            line("VCS_LOADING_FOREGROUND", c.ash),
            line("TIME_FOREGROUND", c.ash),
            line("RULER_FOREGROUND", c.ash),
            line("MULTILINE_FIRST_PROMPT_GAP_FOREGROUND", c.ash),
            line("OS_ICON_FOREGROUND", c.ghost),
            line("STATUS_OK_FOREGROUND", c.mist),
            line("STATUS_ERROR_FOREGROUND", c.error_),
            "typeset -g POWERLEVEL9K_BACKGROUND="
        ]
        const body = lines.map(l => '"' + l + '"').join(" ")
        Quickshell.execDetached(["sh", "-c",
            "printf '%s\\n' " + body + " > \"$HOME/.cache/ashen_p10k.zsh\" && " +
            "for s in " + root.kittySockets + "; do kitten @ --to \"unix:$s\" send-text --match all $'source ~/.cache/ashen_p10k.zsh\\r' 2>/dev/null; done"
        ])
    }

    // Repaint the folder icons from the accent just published. Its own call and
    // not part of the GTK one: the folders are an icon theme, not a stylesheet.
    function applyFolders() {
        Quickshell.execDetached([Paths.script("ashen-folders.sh"), "--apply"])
    }

    function applyGtkTheme(c) {
        let css = '/* ══════════════════════════════════════\n' +
            '   Ashen Ghost -- GTK3 overrides for Nemo\n' +
            '   ══════════════════════════════════════ */\n' +
            '@define-color theme_bg_color ' + c.void_ + ';\n' +
            '@define-color theme_fg_color ' + c.snow + ';\n' +
            '@define-color theme_base_color ' + c.void_ + ';\n' +
            '@define-color theme_text_color ' + c.snow + ';\n' +
            '@define-color theme_selected_bg_color ' + c.ghost + ';\n' +
            '@define-color theme_selected_fg_color ' + c.abyss + ';\n' +
            '@define-color insensitive_bg_color ' + c.surface + ';\n' +
            '@define-color insensitive_fg_color ' + c.ash + ';\n' +
            '@define-color borders ' + c.raised + ';\n' +
            '@define-color sidebar_bg_color ' + c.crypt + ';\n' +
            'toolbar, GtkToolbar {\n' +
            '    background-color: transparent;\n' +
            '    background-image: none;\n' +
            '    box-shadow: none;\n' +
            '    border: none;\n' +
            '}\n' +
            '.sidebar row:selected,\n' +
            '.sidebar row:selected:focus {\n' +
            '    background-color: ' + c.ghost + ';\n' +
            '    color: ' + c.abyss + ';\n' +
            '}\n' +
            'iconview.view:selected,\n' +
            'iconview.view:selected:focus,\n' +
            '.view:selected,\n' +
            '.view:selected:focus {\n' +
            '    background-color: alpha(' + c.ghost + ', 0.35);\n' +
            '    color: ' + c.snow + ';\n' +
            '    border-radius: 6px;\n' +
            '}\n' +
            'window, .background {\n' +
            '    background-color: ' + c.void_ + ';\n' +
            '    color: ' + c.snow + ';\n' +
            '}\n' +
            '.sidebar {\n' +
            '    background-color: ' + c.crypt + ';\n' +
            '}\n' +
            '.view,\n' +
            'iconview.view,\n' +
            'iconview {\n' +
            '    background-color: transparent;\n' +
            '    color: ' + c.snow + ';\n' +
            '}\n' +
            '.sidebar,\n' +
            '.sidebar .view,\n' +
            'placessidebar {\n' +
            '    background-color: ' + c.crypt + ';\n' +
            '    color: ' + c.snow + ';\n' +
            '}\n' +
            'button {\n' +
            '    border-radius: 8px;\n' +
            '}\n' +
            'dialog,\n' +
            'window.dialog,\n' +
            '.background.csd {\n' +
            '    border-radius: 12px;\n' +
            '}\n' +
            'button.suggested-action {\n' +
            '    background-color: ' + c.ghost + ';\n' +
            '    background-image: none;\n' +
            '    color: ' + c.abyss + ';\n' +
            '    border-color: ' + c.ghost + ';\n' +
            '}\n' +
            'button.suggested-action:hover {\n' +
            '    background-color: ' + c.neutral + ';\n' +
            '}\n' +
            'button.suggested-action:active {\n' +
            '    background-color: ' + c.shade + ';\n' +
            '}\n' +
            'list row:selected,\n' +
            'list row:selected:focus,\n' +
            'treeview:selected,\n' +
            'treeview:selected:focus {\n' +
            '    background-color: ' + c.ghost + ';\n' +
            '    color: ' + c.abyss + ';\n' +
            '}\n' +
            'check:checked,\n' +
            'radio:checked,\n' +
            'switch:checked {\n' +
            '    background-color: ' + c.ghost + ';\n' +
            '    border-color: ' + c.ghost + ';\n' +
            '}\n' +
            'selection,\n' +
            'entry selection,\n' +
            'textview text selection,\n' +
            'label selection {\n' +
            '    background-color: ' + c.ghost + ';\n' +
            '    color: ' + c.abyss + ';\n' +
            '}\n' +
            '.floating-bar {\n' +
            '    background-color: ' + c.surface + ';\n' +
            '    color: ' + c.snow + ';\n' +
            '    border: 1px solid alpha(' + c.ghost + ', 0.3);\n' +
            '    border-radius: 10px;\n' +
            '    padding: 4px 10px;\n' +
            '    box-shadow: none;\n' +
            '}\n' +
            '.floating-bar:backdrop {\n' +
            '    background-color: ' + c.surface + ';\n' +
            '}\n'
        // GTK4/libadwaita reads its own names, and every one it does not find
        // falls back to libadwaita's DARK default -- which is what left the
        // portal's file chooser half dark on a light scheme.
        const def = (name, hex) => '@define-color ' + name + ' ' + hex + ';\n'
        let css4 = '/* Ashen -- GTK4 / libadwaita overrides */\n' +
            def('accent_color', c.ghost) +
            def('accent_bg_color', c.ghost) +
            def('accent_fg_color', c.abyss) +
            def('destructive_color', c.error_) +
            def('destructive_bg_color', c.error_) +
            def('destructive_fg_color', c.abyss) +
            def('success_color', c.neutral) +
            def('warning_color', c.shade) +
            def('error_color', c.error_) +
            def('window_bg_color', c.void_) +
            def('window_fg_color', c.snow) +
            def('view_bg_color', c.void_) +
            def('view_fg_color', c.snow) +
            def('headerbar_bg_color', c.surface) +
            def('headerbar_fg_color', c.snow) +
            def('headerbar_backdrop_color', c.crypt) +
            def('card_bg_color', c.surface) +
            def('card_fg_color', c.snow) +
            def('card_shade_color', c.abyss) +
            def('dialog_bg_color', c.crypt) +
            def('dialog_fg_color', c.snow) +
            def('popover_bg_color', c.crypt) +
            def('popover_fg_color', c.snow) +
            def('sidebar_bg_color', c.crypt) +
            def('sidebar_fg_color', c.snow) +
            def('sidebar_backdrop_color', c.void_) +
            def('sidebar_shade_color', c.abyss) +
            def('secondary_sidebar_bg_color', c.surface) +
            def('secondary_sidebar_fg_color', c.snow) +
            def('thumbnail_bg_color', c.surface) +
            def('thumbnail_fg_color', c.snow) +
            def('shade_color', c.abyss) +
            'window, .background {\n' +
            '    background-color: ' + c.void_ + ';\n' +
            '    color: ' + c.snow + ';\n' +
            '}\n' +
            'headerbar {\n' +
            '    background-color: ' + c.surface + ';\n' +
            '    color: ' + c.snow + ';\n' +
            '}\n' +
            '.sidebar {\n' +
            '    background-color: ' + c.crypt + ';\n' +
            '    color: ' + c.snow + ';\n' +
            '}\n'

        // papirus-folders is not used: the accent folders are the folders now,
        // and pointing Papirus at one of its own colours only fights them.
        let papirusCmd = ""
        Quickshell.execDetached(["sh", "-c",
            "mkdir -p \"$HOME/.config/gtk-3.0\" \"$HOME/.config/gtk-4.0\" && " +
            "printf %s \"$1\" > \"$HOME/.config/gtk-3.0/gtk.css\" && " +
            "printf %s \"$2\" > \"$HOME/.config/gtk-4.0/gtk.css\"; " +
            papirusCmd,
            "sh", css, css4
        ])
        // Theme name, colour-scheme and the portal restart, all in one place.
        Quickshell.execDetached([Paths.script("ashen-gtk-mode.sh")])
    }

    // Light/dark is not a scheme, it is a variant of the one you are on:
    // switching it re-applies the same selection through the other palette,
    // or asks matugen for the other mode when the colours come from the
    // wallpaper.
    // Put the mode where the scripts read it, without asking anyone to
    // repaint. A wallpaper switch stages the mode this way: the run it is about
    // to make is the repaint.
    function stageMode(m) {
        Prefs.themeMode = m
        Quickshell.execDetached(["sh", "-c",
            'printf %s "$1" > "$HOME/.cache/ashen_theme_mode.txt"', "sh", m])
    }

    function setMode(m) {
        if (Prefs.themeMode === m) return
        // The scripts run outside the shell, so the mode has to be on disk
        // before they are asked to recolour.
        root.stageMode(m)
        // Both roads wait for that write: the fixed schemes now also run a
        // script (ashen-gtk-mode.sh) that reads the file, and it used to read
        // the mode it was replacing.
        modeRecolor.restart()
    }
    // matugen reads the file, so give the write a moment to land.
    Timer {
        id: modeRecolor
        interval: 60
        onTriggered: {
            if (root.dynamicActive) root.recolor()
            else root.applyScheme(root.schemeId)
        }
    }

    function setDynamicType(t) {
        root.dynamicType = t
        Quickshell.execDetached(["sh", "-c", "echo '" + t + "' > \"$HOME/.cache/ashen_dynamic_type.txt\""])
    }

    // Say "the colours come from the wallpaper" without asking for them yet:
    // the wallpaper script runs matugen itself, right after.
    function stageDynamic() {
        root.schemeId = "dynamic"
        Quickshell.execDetached(["sh", "-c",
            "printf %s dynamic > \"$HOME/.cache/ashen_scheme_mode.txt\""])
    }

    // Re-run matugen from the current wallpaper (frame for gif/video) with the
    // saved style. No-ops unless in dynamic mode.
    function recolor() {
        Quickshell.execDetached([Paths.script("ashen-recolor.sh")])
    }

    // Nothing builds a singleton until someone reads it, and this one has to
    // know the cached scheme whether or not Settings was ever opened.
    function arm() {}

    Component.onCompleted: {
        schemeModeProc.running = true
        dynTypeProc.running = true
    }

    Process {
        id: schemeModeProc
        command: ["sh", "-c", "cat \"$HOME/.cache/ashen_scheme_mode.txt\" 2>/dev/null"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                let s = text.trim()
                if (s.length > 0) root.schemeId = s
            }
        }
    }

    Process {
        id: dynTypeProc
        command: ["sh", "-c", "cat \"$HOME/.cache/ashen_dynamic_type.txt\" 2>/dev/null"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                let t = text.trim()
                // A cache written before monochrome moved out of Dynamic would
                // name a type that no longer exists: no pill would light up and
                // matugen would still be handed it.
                if (t.length > 0 && root.dynamicTypes.some(d => d.id === t)) {
                    root.dynamicType = t
                } else if (t.length > 0) {
                    root.setDynamicType("scheme-tonal-spot")
                }
            }
        }
    }
}
