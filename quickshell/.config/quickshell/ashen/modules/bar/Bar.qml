import Quickshell
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts

import "root:/modules/bar/components"

Scope {
    id: root

    Variants {
        model: Quickshell.screens

        PanelWindow {
            property var modelData
            screen: modelData
            anchors { top: true; left: true; right: true }
            implicitHeight: 56
            color: "transparent"
            exclusionMode: ExclusionMode.Exclusive

            Item {
                anchors.fill: parent

                // ── Izquierda ──────────────────────────
                Workspaces {
                    anchors.left: parent.left
                    anchors.leftMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                }

                // ── Centro ─────────────────────────────
                Clock {
                    anchors.centerIn: parent
                }

                // ── Derecha ────────────────────────────
                Row {
                    anchors.right: parent.right
                    anchors.rightMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 6

                    TrayPill {}
                    SystemPill {}
                    PowerPill {}
                }
            }
        }
    }
}
