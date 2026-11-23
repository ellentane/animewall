import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

/**
 * Anime wallpaper panel: shows the current wallpaper and controls the animewall
 * rotation (source, purities, favorites, bans, interval, pause, downloads).
 * Toggle with `qs -c ii ipc call animewall toggle`.
 */
Scope {
    id: root
    readonly property int panelWidth: 460
    readonly property int padding: 14

    Loader {
        id: panelLoader
        active: GlobalStates.animewallOpen

        sourceComponent: PanelWindow {
            id: panelWindow
            readonly property HyprlandMonitor monitor: Hyprland.monitorFor(panelWindow.screen)

            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.namespace: "quickshell:animewall"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
            color: "transparent"

            anchors.top: true
            margins {
                top: Config?.options.bar.vertical ? Appearance.sizes.hyprlandGapsOut : Appearance.sizes.barHeight + Appearance.sizes.hyprlandGapsOut
            }

            implicitWidth: root.panelWidth + Appearance.sizes.elevationMargin * 2
            implicitHeight: content.height + Appearance.sizes.elevationMargin * 2

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

            // Keep the panel's numbers fresh while it is open
            Timer {
                interval: 5000
                running: true
                repeat: true
                onTriggered: Animewall.refresh()
            }

            StyledRectangularShadow {
                target: content
            }

            Rectangle {
                id: content
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.topMargin: Appearance.sizes.elevationMargin
                width: root.panelWidth
                height: body.implicitHeight + root.padding * 2
                radius: Appearance.rounding.windowRounding
                color: Appearance.colors.colLayer0
                focus: true
                Keys.onEscapePressed: GlobalStates.animewallOpen = false

                ColumnLayout {
                    id: body
                    anchors {
                        left: parent.left
                        right: parent.right
                        top: parent.top
                        margins: root.padding
                    }
                    spacing: 12

                    // Now showing
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12

                        Rectangle {
                            implicitWidth: 176
                            implicitHeight: 99
                            radius: Appearance.rounding.small
                            color: Appearance.colors.colLayer1
                            clip: true

                            StyledImage {
                                anchors.fill: parent
                                source: Animewall.imageUrl(Animewall.current?.path)
                                fillMode: Image.PreserveAspectCrop
                                sourceSize.width: 352
                                sourceSize.height: 198
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignTop
                            spacing: 4

                            StyledText {
                                Layout.fillWidth: true
                                text: Animewall.current ? Animewall.current.name : "No wallpaper set"
                                elide: Text.ElideMiddle
                                font.pixelSize: Appearance.font.pixelSize.normal
                                color: Appearance.colors.colOnLayer0
                            }
                            StyledText {
                                Layout.fillWidth: true
                                text: Animewall.current?.library
                                    ? `${Animewall.current.library} · ${Animewall.current.purity}`
                                    : "Not from the animewall libraries"
                                font.pixelSize: Appearance.font.pixelSize.small
                                color: Appearance.colors.colSubtext
                            }
                            StyledText {
                                Layout.fillWidth: true
                                visible: Animewall.current?.favorite ?? false
                                text: "★ In favorites"
                                font.pixelSize: Appearance.font.pixelSize.small
                                color: Appearance.colors.colPrimary
                            }
                            StyledText {
                                Layout.fillWidth: true
                                text: Animewall.rotating && root.nextTime()
                                    ? `Next change at ${root.nextTime()}`
                                    : "Rotation paused"
                                font.pixelSize: Appearance.font.pixelSize.small
                                color: Appearance.colors.colSubtext
                            }
                        }
                    }

                    // Actions on the current wallpaper
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        Chip {
                            label: "Skip"
                            iconName: "skip_next"
                            onClicked: Animewall.skip()
                        }
                        Chip {
                            label: Animewall.current?.favorite ? "Unfavorite" : "Favorite"
                            iconName: Animewall.current?.favorite ? "heart_minus" : "favorite"
                            toggled: Animewall.current?.favorite ?? false
                            onClicked: Animewall.toggleFavorite()
                        }
                        Chip {
                            label: "Ban"
                            iconName: "block"
                            onClicked: Animewall.ban()
                        }
                        Chip {
                            label: "Wallhaven"
                            iconName: "open_in_new"
                            enabled: !!Animewall.current?.wallhaven_id
                            onClicked: Animewall.openWallhaven()
                        }
                    }

                    SectionLabel {
                        text: "Rotate from"
                    }
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        Repeater {
                            model: Animewall.sources
                            delegate: Chip {
                                required property var modelData
                                label: modelData.label
                                iconName: modelData.icon
                                toggled: Animewall.source === modelData.id
                                onClicked: Animewall.setSource(modelData.id)
                            }
                        }
                    }

                    SectionLabel {
                        text: "Purities"
                    }
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        Repeater {
                            model: Animewall.purityIds
                            delegate: Chip {
                                required property string modelData
                                label: modelData.toUpperCase()
                                toggled: Animewall.purities.includes(modelData)
                                onClicked: Animewall.togglePurity(modelData)
                            }
                        }
                    }

                    SectionLabel {
                        text: "Change every"
                    }
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        Repeater {
                            model: Animewall.intervals
                            delegate: Chip {
                                required property int modelData
                                label: modelData === 60 ? "1 h" : `${modelData} min`
                                toggled: Animewall.interval === modelData
                                onClicked: Animewall.setInterval(modelData)
                            }
                        }
                    }

                    // Rotation and downloads
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        Chip {
                            label: Animewall.rotating ? "Pause rotation" : "Resume rotation"
                            iconName: Animewall.rotating ? "pause" : "play_arrow"
                            toggled: !Animewall.rotating
                            onClicked: Animewall.toggleRotation()
                        }
                        Chip {
                            label: Animewall.downloading ? "Stop downloads" : "Download more"
                            iconName: Animewall.downloading ? "stop" : "cloud_download"
                            toggled: Animewall.downloading
                            onClicked: Animewall.toggleDownload()
                        }
                    }

                    StyledText {
                        Layout.fillWidth: true
                        visible: Animewall.loaded && Animewall.pool === 0
                        wrapMode: Text.WordWrap
                        text: "Nothing matches this selection yet. Pick another source or purity, or download more."
                        font.pixelSize: Appearance.font.pixelSize.small
                        color: Appearance.colors.colPrimary
                    }

                    // Library counts
                    StyledText {
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                        text: Animewall.loaded ? libraryLine() : "Loading…"
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        color: Appearance.colors.colSubtext
                    }
                }
            }
        }
    }

    // "Mon 2026-11-23 06:55:00 CET" -> "06:55"
    function nextTime() {
        const parts = Animewall.nextChange.split(" ");
        return parts.length >= 3 ? parts[2].slice(0, 5) : "";
    }

    function libraryLine() {
        const libs = Animewall.libraries;
        const total = name => Object.values(libs[name] ?? {}).reduce((a, b) => a + b, 0);
        return `Anime ${total("anime")} · Real ${total("real")} · Favorites ${total("favorites")} · `
            + `Banned ${Animewall.banned} · Pool for this selection ${Animewall.pool}`;
    }

    // A pill-style button with an optional icon, used for every control in the panel.
    component Chip: RippleButton {
        id: chip
        required property string label
        property string iconName: ""
        readonly property color textColor: chip.toggled ? Appearance.colors.colOnPrimary : Appearance.colors.colOnLayer1

        Layout.fillWidth: true
        implicitHeight: 34
        buttonRadius: Appearance.rounding.full
        contentItem: RowLayout {
            spacing: 5

            Item {
                Layout.fillWidth: true
            }
            MaterialSymbol {
                visible: chip.iconName.length > 0
                text: chip.iconName
                iconSize: 18
                color: chip.textColor
            }
            StyledText {
                text: chip.label
                font.pixelSize: Appearance.font.pixelSize.small
                color: chip.textColor
                elide: Text.ElideRight
                Layout.maximumWidth: chip.width - 40
            }
            Item {
                Layout.fillWidth: true
            }
        }
    }

    component SectionLabel: StyledText {
        Layout.topMargin: 2
        font.pixelSize: Appearance.font.pixelSize.smaller
        color: Appearance.colors.colSubtext
    }

    IpcHandler {
        target: "animewall"

        function toggle(): void {
            GlobalStates.animewallOpen = !GlobalStates.animewallOpen;
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
