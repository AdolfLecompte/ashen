#!/usr/bin/env bash
# Put the user-side dotfiles in place.
#
# This does NOT copy anything itself: scripts/ashen-setup already walks the
# package dirs, mirrors them onto $HOME, and moves an existing file aside to
# .bak rather than destroying it. The tree used to have stow doing the same job
# in parallel, and that is how the two drifted. One copier, called from here.

dots_place() {
    local src="${ASHEN_CONFIG_SRC:-$ASHEN_REPO}"
    local setup="$src/scripts/ashen-setup"
    local args=()

    [ -x "$setup" ] || setup="$(command -v ashen-setup 2>/dev/null)"
    [ -n "$setup" ] && [ -x "$setup" ] || {
        printf '  dotfiles: no ashen-setup found\n' >&2
        return 1
    }

    # --link, not a copy: from a checkout, editing the repo has to be editing the
    # live config. That is what stow was for.
    args+=(--link)
    [ "${ASHEN_DRY:-0}" -eq 1 ] && args+=(--dry-run)

    if [ "${ASHEN_DRY:-0}" -eq 1 ]; then
        # ashen-setup's rehearsal names every file, which is 200 lines nobody
        # reads. Counted per package instead: the question a rehearsal answers
        # is "what lands where", not "which 200 files".
        ASHEN_CONFIG_SRC="$src" "$setup" "${args[@]}" \
            | awk '{ n = $1; sub(/^\.config\//, "", n); sub(/\/.*$/, "", n)
                     if (n != "") c[n]++ }
                   END { for (k in c) printf "  would place    %-14s %d file(s)\n", k, c[k] }' \
            | sort
        return 0
    fi
    ASHEN_CONFIG_SRC="$src" "$setup" "${args[@]}"
}

# Run directly as well as sourced, so the probe can drive it.
if [ "${BASH_SOURCE[0]}" = "$0" ]; then
    for a in "$@"; do [ "$a" = "--dry-run" ] && ASHEN_DRY=1; done
    ASHEN_REPO="${ASHEN_REPO:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
    dots_place
fi
