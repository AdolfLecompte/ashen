#!/usr/bin/env bash
# The login screen. Installed to /usr/share/sddm/themes, which is root's, so
# this is the one step that asks for more than the packages did.
#
# Never silently: switching the greeter is a change you meet at the next reboot,
# with no session to fix it from if it goes wrong.

sddm_install() {
    local src="$ASHEN_REPO/sddm/ashen"
    local dst=/usr/share/sddm/themes/ashen

    [ -d "$src" ] || { printf '  no sddm theme in this checkout\n'; return 0; }
    if ! command -v sddm >/dev/null 2>&1; then
        printf '  sddm is not installed -- skipping the login screen\n'
        return 0
    fi

    if [ "${ASHEN_DRY:-0}" -eq 1 ]; then
        printf '  would install   %s\n' "$dst"
        printf '  would point     /etc/sddm.conf.d/10-ashen.conf at it\n'
        if [ -f /etc/sddm.conf ] && grep -qE '^[[:space:]]*Current[[:space:]]*=' /etc/sddm.conf; then
            printf '  would repoint   /etc/sddm.conf (it outranks the drop-in), backup kept\n'
        fi
        return 0
    fi

    sudo mkdir -p "$dst" >>"$ASHEN_LOG" 2>&1
    sudo cp -r "$src"/. "$dst"/ >>"$ASHEN_LOG" 2>&1 || {
        printf '  could not copy the theme into %s\n' "$dst"; return 1
    }

    # The greeter runs as the `sddm` user and cannot read a home (drwx------),
    # so everything it needs has to live here, readable by everyone.
    sudo chmod -R a+rX "$dst" >>"$ASHEN_LOG" 2>&1

    # The theme is Qt6 and MUST say so: without `QtVersion=6` in its metadata
    # SDDM starts /usr/bin/sddm-greeter, which is linked against Qt5, and on a
    # Qt6-only machine that dies with 127 before drawing anything -- the login
    # screen simply never appears and the machine sits at the boot console.
    if ! grep -q '^QtVersion=6' "$dst/metadata.desktop" 2>/dev/null; then
        printf '  the theme does not declare QtVersion=6 -- refusing to point sddm at it\n'
        return 1
    fi
    if [ ! -x /usr/bin/sddm-greeter-qt6 ]; then
        printf '  no Qt6 greeter on this system (/usr/bin/sddm-greeter-qt6) -- theme copied, sddm left alone\n'
        return 1
    fi
    # Present is not the same as runnable, and that distinction is the whole
    # story: /usr/bin/sddm-greeter EXISTS on this machine and still dies with
    # 127, because it is linked against Qt5 and there is no Qt5 here. A greeter
    # that cannot resolve its libraries takes the login screen with it.
    if ldd /usr/bin/sddm-greeter-qt6 2>/dev/null | grep -q 'not found'; then
        printf '  the Qt6 greeter is missing libraries -- theme copied, sddm left alone\n'
        ldd /usr/bin/sddm-greeter-qt6 2>/dev/null | grep 'not found' | sed 's/^/    /'
        return 1
    fi

    # The drop-in first: it is where a theme choice belongs.
    sudo mkdir -p /etc/sddm.conf.d >>"$ASHEN_LOG" 2>&1
    printf '[Theme]\nCurrent=ashen\n' | sudo tee /etc/sddm.conf.d/10-ashen.conf >/dev/null 2>&1 || {
        printf '  could not write /etc/sddm.conf.d/10-ashen.conf\n'; return 1
    }

    # ...but a drop-in is NOT enough here. sddm.conf(5) loads the directories
    # FIRST and /etc/sddm.conf LAST, "with the latter having highest
    # precedence" -- the opposite of systemd's drop-ins. So a Current= left in
    # /etc/sddm.conf silently wins and the login screen never changes.
    if [ -f /etc/sddm.conf ] && grep -qE '^[[:space:]]*Current[[:space:]]*=' /etc/sddm.conf; then
        local cur
        cur=$(grep -E '^[[:space:]]*Current[[:space:]]*=' /etc/sddm.conf | head -1 | cut -d= -f2- | tr -d ' ')
        if [ "$cur" != "ashen" ]; then
            # Kept, not discarded: this is someone's login screen.
            sudo cp -n /etc/sddm.conf /etc/sddm.conf.ashen-bak >>"$ASHEN_LOG" 2>&1
            sudo sed -i -E 's/^([[:space:]]*Current[[:space:]]*=).*/\1ashen/' /etc/sddm.conf >>"$ASHEN_LOG" 2>&1 || {
                printf '  could not point /etc/sddm.conf at ashen (it had %s)\n' "$cur"; return 1
            }
            printf '  /etc/sddm.conf had %s and outranks the drop-in -- repointed (backup: /etc/sddm.conf.ashen-bak)\n' "$cur"
        fi
    fi
    printf '  login screen set to ashen\n'
    # A login screen is met at the next boot, with no session to fix it from.
    # The way back belongs in the report, not in a README nobody has open.
    if [ -f /etc/sddm.conf.ashen-bak ]; then
        printf '  to undo: sudo cp /etc/sddm.conf.ashen-bak /etc/sddm.conf && sudo rm /etc/sddm.conf.d/10-ashen.conf\n'
    else
        printf '  to undo: sudo rm /etc/sddm.conf.d/10-ashen.conf\n'
    fi
}
