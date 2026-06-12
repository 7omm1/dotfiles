// ═══════════════════════════════════════════════════════════════
//  RIGHT SIDEBAR — Gota fluida anclada a la barra
// ═══════════════════════════════════════════════════════════════
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import Quickshell.Services.Pipewire
import QtQuick
import QtQuick.Layouts
import "../services"

Scope {
    id: root
    property bool isOpen:       RightSidebarState.visible
    property bool nightLight:   false
    property bool dnd:          false
    property bool recording:    false

    Variants {
        model: Quickshell.screens
        PanelWindow {
            id: panelWin
            required property var modelData
            screen: modelData
            
            // Fluidez de 144hz
            visible: false 
            
            color: "transparent"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
            
            anchors.top: true
            anchors.bottom: true
            anchors.left: true
            anchors.right: true

            Timer {
                id: closeTimer
                interval: 350
                onTriggered: {
                    if (!root.isOpen) panelWin.visible = false
                }
            }

            Connections {
                target: root
                function onIsOpenChanged() {
                    if (root.isOpen) {
                        panelWin.visible = true
                        closeTimer.stop()
                    } else {
                        closeTimer.restart()
                    }
                }
            }

            MouseArea { 
                anchors.fill: parent
                onClicked: RightSidebarState.hide()
                z: -1 
            }

            Rectangle {
                id: panel
                x: parent.width - width
                y: Theme.barH // Pegado directo debajo de la barra
                
                width: 360
                height: Math.min(parent.height - Theme.barH - 20, scroll.contentHeight + 4)
                color: Theme.bgShell
                radius: Theme.panelR

                border.color: Theme.borderSep
                border.width: 1

                // 🔴 Esquinas superiores cuadradas para fusionarse con la barra horizontal
                Rectangle {
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.margins: 1
                    height: Theme.panelR
                    color: Theme.bgShell
                }

                Rectangle {
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: 1
                    color: Theme.borderSep
                }

                // Animación succión 
                transform: Translate {
                    y: root.isOpen ? 0 : -(panel.height + 40)
                    Behavior on y { 
                        NumberAnimation { 
                            duration: 350
                            easing.type: root.isOpen ? Easing.OutExpo : Easing.InCirc 
                        } 
                    }
                }

                opacity: root.isOpen ? 1 : 0
                Behavior on opacity { 
                    NumberAnimation { 
                        duration: 250
                        easing.type: root.isOpen ? Easing.OutExpo : Easing.InCirc 
                    } 
                }

                clip: true

                Flickable {
                    id: scroll
                    anchors.fill: parent
                    contentWidth: width
                    contentHeight: col.implicitHeight + 32
                    boundsBehavior: Flickable.StopAtBounds
                    clip: true

                    ColumnLayout {
                        id: col
                        anchors.top: parent.top
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.margins: 14
                        anchors.topMargin: 18
                        spacing: 10

                        // ── Header: perfil + power ─────────────────
                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: 68
                            color: Theme.bgCard
                            radius: Theme.radiusLg
                            border.color: Theme.borderCard
                            border.width: 1
                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 12
                                spacing: 12
                                Rectangle {
                                    width: 42
                                    height: 42
                                    radius: 12
                                    color: Qt.rgba(0.92, 0.43, 0.57, 0.10)
                                    border.color: Theme.borderFocus
                                    border.width: 1
                                    Text { 
                                        anchors.centerIn: parent
                                        text: ""
                                        color: Theme.accent
                                        font.family: Theme.font
                                        font.pixelSize: 22 
                                    }
                                }
                                ColumnLayout { 
                                    Layout.fillWidth: true
                                    spacing: 1
                                    Text { 
                                        text: System.username
                                        color: Theme.fg
                                        font.family: Theme.font
                                        font.pixelSize: 14
                                        font.bold: true 
                                    }
                                    Text { 
                                        text: "UP: " + System.uptime
                                        color: Theme.fgMute
                                        font.family: Theme.font
                                        font.pixelSize: 9 
                                    }
                                }
                                Row { 
                                    spacing: 5
                                    PwrBtn { icon: "󰌾"; onAct: run("swaylock") }
                                    PwrBtn { icon: "󰑓"; onAct: run("systemctl reboot") }
                                    PwrBtn { icon: "󰐥"; hot: true; onAct: run("systemctl poweroff") }
                                }
                            }
                        }

                        // ── CPU / RAM / GPU rings ─────────────────
                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: 96
                            color: Theme.bgCard
                            radius: Theme.radiusLg
                            border.color: Theme.borderCard
                            border.width: 1
                            Row {
                                anchors.centerIn: parent
                                spacing: 18
                                ResourceRing { value: System.cpu; ringColor: Theme.accent; label: "CPU"; implicitWidth: 76; implicitHeight: 76 }
                                ResourceRing { value: System.ram; ringColor: Theme.iris; label: "RAM"; implicitWidth: 76; implicitHeight: 76 }
                                ResourceRing { value: System.gpu; ringColor: Theme.foam; label: "GPU"; show: System.hasGpu; implicitWidth: 76; implicitHeight: 76 }
                            }
                        }

                        // ── Volumen + Brillo ──────────────────────
                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: sliders.implicitHeight + 24
                            color: Theme.bgCard
                            radius: Theme.radiusLg
                            border.color: Theme.borderCard
                            border.width: 1
                            ColumnLayout {
                                id: sliders
                                anchors.fill: parent
                                anchors.margins: 14
                                spacing: 14
                                VolumeSlider {}
                                BrightnessSlider {}
                            }
                        }

                        // ── Toggle grid 4×2 ───────────────────────
                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: tgGrid.implicitHeight + 24
                            color: Theme.bgCard
                            radius: Theme.radiusLg
                            border.color: Theme.borderCard
                            border.width: 1
                            GridLayout {
                                id: tgGrid
                                anchors.fill: parent
                                anchors.margins: 12
                                columns: 4
                                rowSpacing: 8
                                columnSpacing: 8
                                
                                TBtn { icon: "󰤨"; lbl: "WiFi"; on: true; onT: run("nm-connection-editor") }
                                TBtn { icon: "󰂯"; lbl: "BT"; on: false; onT: run("blueman-manager") }
                                TBtn { icon: "󰔎"; lbl: "Noche"; on: root.nightLight; onT: { root.nightLight = !root.nightLight; if(root.nightLight) run("hyprsunset -t 3000"); else run("pkill -x hyprsunset") } }
                                TBtn { icon: "󰂛"; lbl: "DND"; on: root.dnd; onT: { root.dnd = !root.dnd } }
                                TBtn { icon: "󰹑"; lbl: "Captura"; on: false; onT: { RightSidebarState.hide(); run("bash -c 'sleep 0.3 && grim -g \"$(slurp)\" - | swappy -f -'") } }
                                TBtn { icon: root.recording ? "󰑊" : "󰑋"; lbl: "Rec"; on: root.recording; hot: root.recording; onT: { if(root.recording){ run("pkill --signal SIGINT wf-recorder"); root.recording = false } else { run("wf-recorder --audio -f ~/Videos/Rec_" + Date.now() + ".mp4"); root.recording = true } } }
                                TBtn { icon: "󰍃"; lbl: "Salir"; on: false; onT: run("hyprctl dispatch exit") }
                                TBtn { icon: "󰒲"; lbl: "Suspend"; on: false; onT: run("systemctl suspend") }
                            }
                        }

                        // ── Apps dock ─────────────────────────────
                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: 68
                            color: Theme.bgCard
                            radius: Theme.radiusLg
                            border.color: Theme.borderCard
                            border.width: 1
                            Row {
                                anchors.centerIn: parent
                                spacing: 8
                                Repeater {
                                    model: [
                                        {i: "󰈹", a: "firefox", c: "#ff7800"},
                                        {i: "󰆍", a: "kitty", c: "#9ccfd8"},
                                        {i: "󰨞", a: "code", c: "#007acc"},
                                        {i: "󰙯", a: "discord", c: "#7289da"},
                                        {i: "󰓓", a: "steam", c: "#66c0f4"}
                                    ]
                                    Rectangle {
                                        width: 46
                                        height: 46
                                        radius: 13
                                        color: ama.containsMouse ? Qt.rgba(1, 1, 1, 0.10) : Qt.rgba(1, 1, 1, 0.04)
                                        border.color: Theme.border
                                        border.width: 1
                                        scale: ama.containsMouse ? 1.1 : 1.0
                                        
                                        Behavior on scale { NumberAnimation { duration: 160; easing.type: Easing.OutBack } }
                                        Behavior on color { ColorAnimation { duration: 140 } }
                                        
                                        Text { 
                                            anchors.centerIn: parent
                                            text: modelData.i
                                            color: Qt.lighter(modelData.c, 1.4)
                                            font.family: Theme.font
                                            font.pixelSize: 22 
                                        }
                                        
                                        MouseArea { 
                                            id: ama
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            onClicked: { 
                                                RightSidebarState.hide()
                                                run(modelData.a) 
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        Item { implicitHeight: 8 }
                    }
                }
            }
        }
    }

    function run(cmd) {
        const p = Qt.createQmlObject('import Quickshell.Io; Process {}', root)
        p.command = ["bash", "-c", cmd]
        p.running = true
    }
}
