// ══════════════════════════════════════════════════════════════════════════
//   Ashen — a Hyprland + Quickshell rice.   by Adolf — github.com/AdolfLecompte
//   Root of the shell: wires every module (bar, lock, launcher, …) together.
// ══════════════════════════════════════════════════════════════════════════
import Quickshell
import QtQuick

import "root:/modules/bar"
import "root:/modules/lock"
import "root:/modules/launcher"
import "root:/modules/wallpaper"
import "root:/modules/settings"
import "root:/modules/emojis"
import "root:/modules/glyph"
import "root:/modules/clipboard"

ShellRoot {
    Bar {}
    MediaPanel {}
    OsdPanel {}
    VolumePanel {}
    BrightnessPanel {}
    BatteryPanel {}
    NotificationPanel {}
    NotificationToast {}
    SettingsPanel {}
    PowerMenu {}
    Calendar {}
    NetworkPanel {}
    BluetoothPanel {}
    USBPanel {}
    TrayMenu {}
    ProcessTrigger {}
    ProcessPanel {}
    LockScreen {}
    Launcher {}
    WallpaperPicker {}
    Emojis {}
    Glyph {}
    Clipboard {}
}
