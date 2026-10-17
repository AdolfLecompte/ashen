#!/usr/bin/env bash
# The questions the installer asks: the shell's language, the keyboard and the
# system language. Asked before anything installs, applied after the dotfiles.
# Without a terminal (a pipe, a dry run, the probes) nothing is asked: answers
# come from ASHEN_LANG / ASHEN_KB / ASHEN_LOCALE or from what the machine uses.

CHOICE_LANGS=(en es de ru)
CHOICE_LANG_NAMES=("English" "Español" "Deutsch" "Русский")

CHOICE_KBS=(us latam es gb de fr it pt br ru ua pl tr se no dk fi ch)
CHOICE_KB_NAMES=(
    "English (US)" "Spanish (Latin American)" "Spanish (Spain)" "English (UK)"
    "German" "French" "Italian" "Portuguese" "Portuguese (Brazil)" "Russian"
    "Ukrainian" "Polish" "Turkish" "Swedish" "Norwegian" "Danish" "Finnish"
    "Swiss"
)

CHOICE_LOCALES=(en_US en_GB es_ES es_MX es_AR es_CO es_CL es_PE de_DE de_AT de_CH
                fr_FR it_IT pt_BR pt_PT ru_RU uk_UA pl_PL)
CHOICE_LOCALE_NAMES=(
    "English (US)" "English (UK)" "Español (España)" "Español (México)"
    "Español (Argentina)" "Español (Colombia)" "Español (Chile)" "Español (Perú)"
    "Deutsch (Deutschland)" "Deutsch (Österreich)" "Deutsch (Schweiz)"
    "Français" "Italiano" "Português (Brasil)" "Português (Portugal)"
    "Русский" "Українська" "Polski"
)

ASHEN_LANG_PICK=""
ASHEN_KB_PICK=""
ASHEN_LOCALE_PICK=""

# What this machine already says: a re-run keeps the last answer.
choices_default_lang() {
    local prefs="$HOME/.config/ashen/prefs.json" l
    l=$(sed -n 's/.*"language": *"\([a-z]*\)".*/\1/p' "$prefs" 2>/dev/null | head -1)
    case " ${CHOICE_LANGS[*]} " in *" $l "*) printf '%s' "$l"; return ;; esac
    l="${LANG:-en}"
    l="${l%%_*}"; l="${l%%.*}"
    case " ${CHOICE_LANGS[*]} " in *" $l "*) printf '%s' "$l" ;; *) printf 'en' ;; esac
}

# The layout the machine already types with: X11 first, the console keymap after.
choices_default_kb() {
    local kb="" input="$HOME/.config/hypr/conf/input.lua"
    kb=$(sed -n 's/.*kb_layout = "\([^",]*\).*/\1/p' "$input" 2>/dev/null | head -1)
    [ "$kb" = us ] && kb=""
    [ -z "$kb" ] && kb=$(localectl status 2>/dev/null | awk -F': *' '/X11 Layout/ { print $2 }' | cut -d, -f1)
    if [ -z "$kb" ] && [ -r /etc/vconsole.conf ]; then
        case "$(sed -n 's/^KEYMAP=//p' /etc/vconsole.conf | tr -d '"')" in
            la-latin1*) kb=latam ;;
            es*) kb=es ;;
            de*) kb=de ;;
            fr*) kb=fr ;;
            uk*) kb=gb ;;
            ru*) kb=ru ;;
            it*) kb=it ;;
            br-*) kb=br ;;
            pt-*) kb=pt ;;
            pl*) kb=pl ;;
        esac
    fi
    printf '%s' "${kb:-us}"
}

# A layout code xkeyboard-config knows. Without its rules file only the shape is checked.
choices_valid_kb() {
    [[ "$1" =~ ^[a-z0-9_]+$ ]] || return 1
    local rules=/usr/share/X11/xkb/rules/evdev.lst
    [ -r "$rules" ] || return 0
    awk '/^! layout/{f=1;next} /^! /{f=0} f && NF {print $1}' "$rules" | grep -qx "$1"
}

# The system's LANG without its charset: en_US.UTF-8 -> en_US.
choices_current_locale() {
    local l
    l=$(localectl status 2>/dev/null | sed -n 's/.*System Locale: LANG=//p')
    [ -z "$l" ] && l=$(sed -n 's/^LANG=//p' /etc/locale.conf 2>/dev/null)
    l="${l%%.*}"
    printf '%s' "${l:-en_US}"
}

# A locale glibc can generate as UTF-8.
choices_valid_locale() {
    [[ "$1" =~ ^[A-Za-z]{2,3}_[A-Z]{2}(@[a-z]+)?$ ]] || return 1
    local sup=/usr/share/i18n/SUPPORTED
    [ -r "$sup" ] || return 0
    grep -qx "$1.UTF-8 UTF-8" "$sup"
}

# Arrow-key list on the terminal. Prints nothing; sets CHOICE_INDEX.
#   choices_menu "title" <default index> "option" "option" ...
choices_menu() {
    local title=$1 sel=$2; shift 2
    local opts=("$@") n=$# i key rest
    printf '\n  %s%s%s  %s↑↓ enter%s\n' "$BOLD" "$title" "$RESET" "$C_DIM" "$RESET"
    for (( i = 0; i < n; i++ )); do printf '\n'; done
    while true; do
        _tui_up "$n"
        for (( i = 0; i < n; i++ )); do
            if [ "$i" -eq "$sel" ]; then _tui_line "  ${BOLD}▸ ${opts[$i]}${RESET}"
            else _tui_line "    ${C_DIM}${opts[$i]}${RESET}"; fi
        done
        IFS= read -rsn1 key </dev/tty || break
        if [ "$key" = $'\e' ]; then
            IFS= read -rsn2 -t 0.05 rest </dev/tty
            key+=$rest
        fi
        case "$key" in
            $'\e[A'|k) sel=$(( (sel - 1 + n) % n )) ;;
            $'\e[B'|j) sel=$(( (sel + 1) % n )) ;;
            "") break ;;
        esac
    done
    CHOICE_INDEX=$sel
}

# A typed layout code, for one that is not on the short list.
choices_type_kb() {
    local code
    while true; do
        stty echo 2>/dev/null; printf '\e[?25h'
        printf '  layout code (e.g. %s): ' "$(choices_default_kb)"
        IFS= read -r code </dev/tty || { stty -echo 2>/dev/null; return 1; }
        stty -echo 2>/dev/null; printf '\e[?25l'
        code=$(printf '%s' "$code" | tr '[:upper:]' '[:lower:]' | tr -d ' ')
        if choices_valid_kb "$code"; then ASHEN_KB_PICK=$code; return 0; fi
        printf '  %s✗%s unknown layout: %s\n' "$C_BAD" "$RESET" "$code"
    done
}

choices_type_locale() {
    local code
    while true; do
        stty echo 2>/dev/null; printf '\e[?25h'
        printf '  locale (e.g. es_MX): '
        IFS= read -r code </dev/tty || { stty -echo 2>/dev/null; return 1; }
        stty -echo 2>/dev/null; printf '\e[?25l'
        code=$(printf '%s' "$code" | tr -d ' ')
        code="${code%%.*}"
        if choices_valid_locale "$code"; then ASHEN_LOCALE_PICK=$code; return 0; fi
        printf '  %s✗%s unknown locale: %s\n' "$C_BAD" "$RESET" "$code"
    done
}

choices_ask() {
    local lang kb i def
    local loc ask=1
    lang="${ASHEN_LANG:-$(choices_default_lang)}"
    kb="${ASHEN_KB:-$(choices_default_kb)}"
    loc="${ASHEN_LOCALE:-$(choices_current_locale)}"
    ASHEN_LANG_PICK=$lang; ASHEN_KB_PICK=$kb; ASHEN_LOCALE_PICK=${loc%%.*}

    if [ "${ASHEN_DRY:-0}" -eq 1 ] || [ ! -t 1 ] || [ ! -r /dev/tty ]; then ask=0; fi
    [ "$ask" -eq 1 ] && [ -z "${ASHEN_LANG:-}" ] && choices_ask_lang "$lang"
    [ "$ask" -eq 1 ] && [ -z "${ASHEN_KB:-}" ] && choices_ask_kb "$kb"
    [ "$ask" -eq 1 ] && [ -z "${ASHEN_LOCALE:-}" ] && choices_ask_locale "$loc"
    [ "$ask" -eq 1 ] && printf '\n'
    return 0
}

choices_ask_lang() {
    local lang=$1 i def=0
    for i in "${!CHOICE_LANGS[@]}"; do [ "${CHOICE_LANGS[$i]}" = "$lang" ] && def=$i; done
    choices_menu "Shell language" "$def" "${CHOICE_LANG_NAMES[@]}"
    ASHEN_LANG_PICK=${CHOICE_LANGS[$CHOICE_INDEX]}
}

choices_ask_kb() {
    local kb=$1 i def
    # The machine's own layout leads the list when the short list lacks it.
    local codes=("${CHOICE_KBS[@]}") names=("${CHOICE_KB_NAMES[@]}")
    case " ${codes[*]} " in
        *" $kb "*) ;;
        *) codes=("$kb" "${codes[@]}"); names=("$kb" "${names[@]}") ;;
    esac
    def=0
    for i in "${!codes[@]}"; do [ "${codes[$i]}" = "$kb" ] && def=$i; done
    choices_menu "Keyboard" "$def" "${names[@]}" "Other…"
    if [ "$CHOICE_INDEX" -eq "${#codes[@]}" ]; then choices_type_kb
    else ASHEN_KB_PICK=${codes[$CHOICE_INDEX]}; fi
}

# Keeping what the system has is the first answer, and the default.
choices_ask_locale() {
    local cur=${1%%.*} i
    choices_menu "System language" 0 "Keep current ($cur)" "${CHOICE_LOCALE_NAMES[@]}" "Other…"
    i=$CHOICE_INDEX
    if [ "$i" -eq 0 ]; then ASHEN_LOCALE_PICK=$cur
    elif [ "$i" -gt "${#CHOICE_LOCALES[@]}" ]; then choices_type_locale
    else ASHEN_LOCALE_PICK=${CHOICE_LOCALES[$((i - 1))]}; fi
}

# Writes the picks where the shell, Hyprland and the login screen read them.
choices_apply() {
    local lang=${ASHEN_LANG_PICK:-en} kb=${ASHEN_KB_PICK:-us}
    local prefs="$HOME/.config/ashen/prefs.json"
    local input="$HOME/.config/hypr/conf/input.lua"

    if [ "${ASHEN_DRY:-0}" -eq 1 ]; then
        printf '  would set      language %s, keyboard %s, system %s\n' "$lang" "$kb" "${ASHEN_LOCALE_PICK:-unchanged}"
        return 0
    fi

    mkdir -p "$(dirname "$prefs")"
    if [ ! -s "$prefs" ]; then
        printf '{\n    "language": "%s"\n}\n' "$lang" >"$prefs"
    elif grep -q '"language"' "$prefs"; then
        sed -i "s/\"language\": *\"[^\"]*\"/\"language\": \"$lang\"/" "$prefs"
    else
        sed -i "0,/{/s//{\n    \"language\": \"$lang\",/" "$prefs"
    fi
    printf '  language       %s\n' "$lang"

    # sed -i turns a linked input.lua into a file of its own: the layout is
    # this machine's, not the repo's.
    # The pick goes first; layouts already added in Settings stay after it.
    # The shipped "us" is a placeholder, not a choice, so it is replaced.
    if [ -e "$input" ]; then
        local old list
        old=$(sed -n 's/.*kb_layout = "\([^"]*\)".*/\1/p' "$input" | head -1)
        list=$kb
        if [ "$old" != us ]; then
            local IFS=,
            for c in $old; do [ "$c" != "$kb" ] && [ -n "$c" ] && list+=",$c"; done
            unset IFS
        fi
        list=$(printf '%s' "$list" | cut -d, -f1-4)
        sed -i "s/kb_layout = \"[^\"]*\"/kb_layout = \"$list\"/" "$input"
        kb=$list
        printf '  keyboard       %s\n' "$kb"
    else
        printf '  keyboard: no %s\n' "$input"; return 1
    fi

    # SDDM reads the X11 keymap, so the password is typed on the same layout.
    sudo localectl set-x11-keymap "${kb%%,*}" >>"$ASHEN_LOG" 2>&1 \
        || printf '  could not set the login screen keyboard (localectl)\n'
    choices_apply_locale
}

# Generates the locale if glibc has not yet and makes it the system's LANG.
# Applies from the next login, which the installer already asks for.
choices_apply_locale() {
    local loc=${ASHEN_LOCALE_PICK:-} gen=/etc/locale.gen
    if [ -z "$loc" ] || [ "$loc" = "$(choices_current_locale)" ]; then
        printf '  system         %s (kept)\n' "$(choices_current_locale)"
        return 0
    fi
    choices_valid_locale "$loc" || { printf '  unknown locale: %s\n' "$loc"; return 1; }
    if grep -q "^$loc\.UTF-8 UTF-8" "$gen" 2>/dev/null; then
        :
    elif grep -q "^#\s*$loc\.UTF-8 UTF-8" "$gen" 2>/dev/null; then
        sudo sed -i "s/^#\s*\($loc\.UTF-8 UTF-8\)/\1/" "$gen" >>"$ASHEN_LOG" 2>&1
    else
        printf '%s.UTF-8 UTF-8\n' "$loc" | sudo tee -a "$gen" >>"$ASHEN_LOG" 2>&1
    fi
    sudo locale-gen >>"$ASHEN_LOG" 2>&1 \
        || { printf '  locale-gen failed — see the log\n'; return 1; }
    sudo localectl set-locale "LANG=$loc.UTF-8" >>"$ASHEN_LOG" 2>&1 \
        || { printf '  could not set the system language (localectl)\n'; return 1; }
    printf '  system         %s\n' "$loc.UTF-8"
}
