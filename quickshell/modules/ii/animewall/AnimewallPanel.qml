import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

/**
 * Window for the anime wallpaper panel (contents in AnimewallContent.qml).
 * Toggle with the bar button, `qs -c ii ipc call animewall toggle`, or the
 * `quickshell:animewallToggle` global shortcut.
 */
Scope {
    id: root

    Loader {
        id: panelLoader
        active: GlobalStates.animewallOpen

        sourceComponent: PanelWindow {
            id: panelWindow

            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.namespace: "quickshell:animewall"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
            color: "transparent"

            anchors.top: true
            margins {
                top: Config?.options.bar.vertical ? Appearance.sizes.hyprlandGapsOut : Appearance.sizes.barHeight + Appearance.sizes.hyprlandGapsOut
            }

            implicitWidth: content.implicitWidth + Appearance.sizes.elevationMargin * 2
            implicitHeight: content.implicitHeight + Appearance.sizes.elevationMargin * 2

            mask: Region {
                item: content
            }

            Component.onCompleted: {
                GlobalFocusGrab.addDismissable(panelWindow);
                Animewall.refresh();
            }
            Component.onDestruction: {
                GlobalFocusGrab.removeDismissable(panelWindow);
            }
            Connections {
                target: GlobalFocusGrab
                function onDismissed() {
                    GlobalStates.animewallOpen = false;
                }
            }

            // Keep the numbers fresh while the panel is open
            Timer {
                interval: 5000
                running: true
                repeat: true
                onTriggered: Animewall.refresh()
            }

            StyledRectangularShadow {
                target: content
            }

            AnimewallContent {
                id: content
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.topMargin: Appearance.sizes.elevationMargin
                width: implicitWidth
                height: implicitHeight
                focus: true
                Keys.onEscapePressed: GlobalStates.animewallOpen = false
            }
        }
    }

    IpcHandler {
        target: "animewall"

        function toggle(): void {
            GlobalStates.animewallOpen = !GlobalStates.animewallOpen;
        }

        function close(): void {
            GlobalStates.animewallOpen = false;
        }

        function next(): void {
            Animewall.skip();
        }

        function favorite(): void {
            Animewall.toggleFavorite();
        }

        function ban(): void {
            Animewall.ban();
        }
    }

    GlobalShortcut {
        name: "animewallToggle"
        description: "Toggle the anime wallpaper panel"
        onPressed: GlobalStates.animewallOpen = !GlobalStates.animewallOpen
    }
}
