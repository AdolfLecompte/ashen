#!/usr/bin/env bash
# Starts the first polkit authentication agent installed, so apps that need
# root can ask for the password. Without one, those requests fail silently.
set -u
for agent in \
    /usr/lib/hyprpolkitagent/hyprpolkitagent \
    /usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1 \
    /usr/lib/polkit-kde-authentication-agent-1 \
    /usr/lib/lxqt-policykit-agent \
    /usr/lib/mate-polkit/polkit-mate-authentication-agent-1; do
    [ -x "$agent" ] && exec "$agent"
done
command -v lxqt-policykit-agent >/dev/null && exec lxqt-policykit-agent
echo "ashen-polkit: no polkit agent installed" >&2
exit 1
