import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Services.Mpris
import Quickshell.Services.SystemTray
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import "../services"
import "../sidebar"
import "../launcher"
import "../wallpapers"

Scope {
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: win
            required property var modelData
            screen: modelData
            
            // LA BARRA VUELVE A OCUPAR EL 100% DEL TECHO
            anchors.top: true
            anchors.left: true
            anchors.right: true
            implicitHeight: Theme.barH
            color: Theme.bgShell // Fondo completo
            
            WlrLayershell.namespace: "qs-bar"
            WlrLayershell.layer: WlrLayer.Top // Debajo del Overlay

            Rectangle {
                anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                height: 1
                color: Theme.borderSep
            }

            RowLayout {
                anchors.fill: parent
                spacing: 0
                
                // Mantiene tus iconos alejados de las esquinas negras
                anchors.leftMargin: Theme.monitorR
                anchors.rightMargin: Theme.monitorR

                // ═══════ ZONA IZQUIERDA ═══════════════════════════
                RowLayout {
                    Layout.alignment: Qt.AlignVCenter
                    spacing: 0

                    BarBtn {
                        icon: "󰣇"
                        iconColor: launchMa.containsMouse ? Theme.accent : Theme.fgDim
                        Item {
                            anchors.fill: parent
                            MouseArea {
                                id: launchMa
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: LauncherState.toggle()
                            }
                        }
                    }

                    BarBtn {
                        icon: "󰸉" 
                        iconColor: wallMa.containsMouse ? Theme.accent : Theme.fgDim
                        Item {
                            anchors.fill: parent
                            MouseArea {
                                id: wallMa
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: WallpaperState.toggle()
                            }
                        }
                    }

                    BarDivider {}

                    RowLayout {
                        spacing: 6
                        Item { implicitWidth: 6 }
                        Repeater {
                            model: [1, 2, 3, 4, 5]
                            Rectangle {
                                required property int modelData
                                property int wsId: modelData
                                property bool focused: Hyprland.focusedWorkspace?.id === wsId
                                property bool occupied: {
                                    for (let i = 0; i < Hyprland.workspaces.length; i++) {
                                        if (Hyprland.workspaces[i]?.id === wsId) return true
                                    }
                                    return false
                                }
                                Layout.alignment: Qt.AlignVCenter
                                implicitWidth:  focused ? 24 : (occupied ? 10 : 7)
                                implicitHeight: 7
                                radius: 4
                                color: focused  ? Theme.accent : occupied ? Qt.rgba(0.88, 0.87, 0.96, 0.45) : Qt.rgba(0.88, 0.87, 0.96, 0.12)
                                
                                Behavior on implicitWidth { NumberAnimation { duration: 280; easing.type: Easing.OutExpo } }
                                Behavior on color { ColorAnimation { duration: 200 } }
                                
                                Item {
                                    anchors.fill: parent
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: Hyprland.dispatch("workspace", String(wsId))
                                    }
                                }
                            }
                        }
                        Item { implicitWidth: 6 }
                    }

                    BarDivider {}

                    Text {
                        leftPadding: 12
                        rightPadding: 8
                        text: Hyprland.focusedWindow?.title ?? "Desktop"
                        color: Theme.fgMute
                        font.family: Theme.font
                        font.pixelSize: 11
                        elide: Text.ElideRight
                        width: Math.min(implicitWidth, 200)
                        Layout.alignment: Qt.AlignVCenter
                    }
                }

                Item { Layout.fillWidth: true }

                // ═══════ ZONA CENTRAL ═════════════════════════════
                Item {
                    implicitWidth: clockContent.implicitWidth + 32
                    implicitHeight: Theme.barH
                    Layout.alignment: Qt.AlignVCenter

                    RowLayout {
                        id: clockContent
                        anchors.centerIn: parent
                        spacing: 10

                        Text {
                            text: Clock.dayShort
                            color: Theme.fgDim
                            font.family: Theme.font
                            font.pixelSize: 11
                        }
                        Rectangle {
                            width: 1
                            height: 16
                            color: Theme.borderSep
                        }
                        Text {
                            text: Clock.time
                            color: Theme.fg
                            font.family: Theme.font
                            font.pixelSize: 14
                            font.bold: true
                        }
                    }

                    Item {
                        anchors.fill: parent
                        MouseArea {
                            anchors.fill: parent
                            onClicked: LeftSidebarState.toggle()
                            hoverEnabled: true
                            Rectangle {
                                anchors.fill: parent
                                color: parent.containsMouse ? Qt.rgba(1,1,1,0.04) : "transparent"
                                Behavior on color { ColorAnimation { duration: 150 } }
                            }
                        }
                    }
                }

                Item { Layout.fillWidth: true }

                // ═══════ ZONA DERECHA ═════════════════════════════
                RowLayout {
                    Layout.alignment: Qt.AlignVCenter
                    spacing: 0

                    // Música
                    Item {
                        visible: Mpris.players.length > 0
                        implicitWidth: musicRow.implicitWidth + 24
                        implicitHeight: Theme.barH
                        clip: true

                        Rectangle {
                            anchors.left: parent.left
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            width: {
                                const p = Mpris.players.length > 0 ? Mpris.players[0] : null
                                if (!p || p.length <= 0) return 0
                                return parent.width * Math.max(0, Math.min(1, p.position / p.length))
                            }
                            color: Qt.rgba(0.92, 0.43, 0.57, 0.12)
                            Behavior on width { NumberAnimation { duration: 500 } }
                        }

                        RowLayout {
                            id: musicRow
                            anchors.centerIn: parent
                            spacing: 7

                            Text {
                                text: Mpris.players.length > 0 && Mpris.players[0].playbackState === MprisPlaybackState.Playing ? "󰏤" : "󰐊"
                                color: Theme.accent
                                font.family: Theme.font
                                font.pixelSize: 12
                            }
                            Text {
                                text: Mpris.players.length > 0 ? (Mpris.players[0].trackTitle || "Unknown") : ""
                                color: Theme.fg
                                font.family: Theme.font
                                font.pixelSize: 11
                                font.bold: true
                                elide: Text.ElideRight
                                width: Math.min(implicitWidth, 160)
                            }
                        }

                        Item {
                            anchors.fill: parent
                            MouseArea {
                                anchors.fill: parent
                                acceptedButtons: Qt.LeftButton | Qt.RightButton
                                onClicked: (mouse) => {
                                    const p = Mpris.players.length > 0 ? Mpris.players[0] : null
                                    if (!p) return
                                    if (mouse.button === Qt.LeftButton)  p.togglePlaying()
                                    if (mouse.button === Qt.RightButton) p.next()
                                }
                            }
                        }
                    }

                    BarDivider { visible: Mpris.players.length > 0 }

                    // CPU
                    RowLayout {
                        spacing: 5
                        Item { implicitWidth: 10 }
                        Text {
                            text: "󰍛"
                            color: System.cpu > 80 ? Theme.accent : Theme.fgDim
                            font.family: Theme.font
                            font.pixelSize: 13
                            Behavior on color { ColorAnimation { duration: 300 } }
                        }
                        Text {
                            text: System.cpu + "%"
                            color: System.cpu > 80 ? Theme.accent : Theme.fgMute
                            font.family: Theme.font
                            font.pixelSize: 10
                            font.bold: true
                            Behavior on color { ColorAnimation { duration: 300 } }
                        }
                        Item { implicitWidth: 6 }
                    }

                    BarDivider {}

                    // RAM
                    RowLayout {
                        spacing: 5
                        Item { implicitWidth: 8 }
                        Text {
                            text: "󰘚"
                            color: System.ram > 80 ? Theme.love : Theme.foam
                            font.family: Theme.font
                            font.pixelSize: 13
                            Behavior on color { ColorAnimation { duration: 300 } }
                        }
                        Text {
                            text: System.ram + "%"
                            color: System.ram > 80 ? Theme.love : Theme.fgMute
                            font.family: Theme.font
                            font.pixelSize: 10
                            font.bold: true
                            Behavior on color { ColorAnimation { duration: 300 } }
                        }
                        Item { implicitWidth: 6 }
                    }

                    BarDivider {}

                    // Volumen
                    Item {
                        implicitWidth: volContent.implicitWidth
                        implicitHeight: Theme.barH
                        
                        RowLayout {
                            id: volContent
                            anchors.centerIn: parent
                            spacing: 5
                            property real v: 0.5
                            
                            Component.onCompleted: readBarProc.running = true

                            Process {
                                id: readBarProc
                                command: ["bash", "-c", "pactl get-sink-volume @DEFAULT_SINK@ | grep -Po '[0-9]+(?=%)' | head -n 1"]
                                stdout: StdioCollector {
                                    onStreamFinished: {
                                        const val = parseFloat(this.text.trim());
                                        if (!isNaN(val)) volContent.v = val / 100.0;
                                    }
                                }
                            }

                            Timer { interval: 1000; running: true; repeat: true; onTriggered: readBarProc.running = true }

                            Item { implicitWidth: 8 }
                            Text {
                                text: volContent.v <= 0 ? "󰖁" : volContent.v < 0.33 ? "󰕿" : volContent.v < 0.66 ? "󰖀" : "󰕾"
                                color: Theme.foam
                                font.family: Theme.font
                                font.pixelSize: 13
                            }
                            Text {
                                text: Math.floor(volContent.v * 100) + "%"
                                color: Theme.fgMute
                                font.family: Theme.font
                                font.pixelSize: 10
                                font.bold: true
                            }
                            Item { implicitWidth: 6 }
                        }

                        Item {
                            anchors.fill: parent
                            MouseArea {
                                anchors.fill: parent
                                onClicked: RightSidebarState.toggle()
                                onWheel: (wheel) => {
                                    const delta = wheel.angleDelta.y > 0 ? 0.05 : -0.05
                                    const next = Math.max(0, Math.min(1, volContent.v + delta))
                                    volContent.v = next 
                                    const p = Qt.createQmlObject('import Quickshell.Io; Process {}', parent)
                                    p.command = ["bash", "-c", "pactl set-sink-volume @DEFAULT_SINK@ " + Math.round(next * 100) + "%"]
                                    p.running = true
                                }
                            }
                        }
                    }

                    BarDivider {}

                    // Clima
                    RowLayout {
                        spacing: 5
                        Item { implicitWidth: 10 }
                        Text {
                            text: Weather.emoji
                            font.family: Theme.font
                            font.pixelSize: 14
                        }
                        Text {
                            text: Weather.temp
                            color: Theme.fgDim
                            font.family: Theme.font
                            font.pixelSize: 11
                            font.bold: true
                        }
                        Item { implicitWidth: 6 }
                    }

                    BarDivider {}

                    // Red
                    RowLayout {
                        spacing: 5
                        Item { implicitWidth: 8 }
                        Text {
                            text: System.netSpeed.includes("MB") ? "󰈀" : "󰤨"
                            color: Theme.foam
                            font.family: Theme.font
                            font.pixelSize: 14
                        }
                        Text {
                            text: System.netSpeed
                            color: Theme.fgMute
                            font.family: Theme.font
                            font.pixelSize: 10
                            font.bold: true
                            width: 54
                        }
                        Item { implicitWidth: 8 }
                    }

                    BarDivider { visible: SystemTray.items.length > 0 }

                    // System Tray
                    RowLayout {
                        spacing: 6
                        visible: SystemTray.items.length > 0
                        Item { implicitWidth: SystemTray.items.length > 0 ? 8 : 0 }
                        Repeater {
                            model: SystemTray.items
                            Item {
                                required property SystemTrayItem modelData
                                implicitWidth: 20
                                implicitHeight: 20
                                Image {
                                    anchors.fill: parent
                                    source: modelData.icon
                                    smooth: true
                                }
                                Item {
                                    anchors.fill: parent
                                    MouseArea {
                                        anchors.fill: parent
                                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                                        onClicked: (mouse) => {
                                            if (mouse.button === Qt.LeftButton) {
                                                modelData.activate()
                                            } else {
                                                modelData.secondaryActivate()
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        Item { implicitWidth: SystemTray.items.length > 0 ? 8 : 0 }
                    }

                    BarDivider {}

                    BarBtn {
                        icon: "󰒓"
                        iconColor: RightSidebarState.visible ? Theme.accent : Theme.fgMute
                        leftPadding: 8
                        rightPadding: 10
                        Item {
                            anchors.fill: parent
                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: RightSidebarState.toggle()
                            }
                        }
                    }
                }
            }
        }
    }
    readonly property var sh: Qt.createQmlObject('import Quickshell.Io; Process {}', win)
}
