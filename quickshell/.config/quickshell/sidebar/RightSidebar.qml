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

            // ═══════ CONTENEDOR PRINCIPAL DEL PANEL ══════════════════════════
            Item {
                id: panel
                x: parent.width - width - 10
                y: 0 
                
                width: 360
                height: Math.min(parent.height - Theme.barH - 20, scroll.contentHeight + 4)

                // Animación succión 
                transform: Translate {
                    y: root.isOpen ? 0 : -(panel.height + 20)
                    Behavior on y { 
                        NumberAnimation { 
                            duration: 400
                            easing.type: root.isOpen ? Easing.OutExpo : Easing.InExpo 
                        } 
                    }
                }

                opacity: root.isOpen ? 1 : 0
                Behavior on opacity { 
                    NumberAnimation { 
                        duration: 300
                        easing.type: Easing.InOutQuad 
                    } 
                }

                // 1. Fondo base (redondeado en las 4 esquinas)
                Rectangle {
                    anchors.fill: parent
                    color: Theme.bgShell
                    radius: Theme.panelR
                    border.color: Theme.borderSep
                    border.width: 1
                }

                // 2. Parche superior izquierdo (Ángulo de 90°)
                Rectangle {
                    anchors.top: parent.top
                    anchors.left: parent.left
                    width: Theme.panelR
                    height: Theme.panelR
                    color: Theme.bgShell
                    // Reconstruimos la línea de borde izquierdo que el parche tapa
                    Rectangle { 
                        anchors.left: parent.left; anchors.top: parent.top; anchors.bottom: parent.bottom
                        width: 1; color: Theme.borderSep 
                    }
                }

                // 3. Parche superior derecho (Ángulo de 90°)
                Rectangle {
                    anchors.top: parent.top
                    anchors.right: parent.right
                    width: Theme.panelR
                    height: Theme.panelR
                    color: Theme.bgShell
                    // Reconstruimos la línea de borde derecho que el parche tapa
                    Rectangle { 
                        anchors.right: parent.right; anchors.top: parent.top; anchors.bottom: parent.bottom
                        width: 1; color: Theme.borderSep 
                    }
                }

                // 4. Línea superior horizontal
                Rectangle {
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: 1
                    color: Theme.borderSep
                }

                // 5. Contenedor de contenido (Clip protege las esquinas redondeadas inferiores)
                Item {
                    anchors.fill: parent
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
                            spacing: 14 

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
                                implicitHeight: 110 
                                color: Theme.bgCard
                                radius: Theme.radiusLg
                                border.color: Theme.borderCard
                                border.width: 1
                                Row {
                                    anchors.centerIn: parent
                                    spacing: 24 
                                    ResourceRing { value: System.cpu; ringColor: Theme.accent; label: "CPU"; implicitWidth: 76; implicitHeight: 76 }
                                    ResourceRing { value: System.ram; ringColor: Theme.iris; label: "RAM"; implicitWidth: 76; implicitHeight: 76 }
                                    ResourceRing { value: System.gpu; ringColor: Theme.foam; label: "GPU"; show: System.hasGpu; implicitWidth: 76; implicitHeight: 76 }
                                }
                            }

                            // ── Volumen + Brillo ──────────────────────
                            Rectangle {
                                Layout.fillWidth: true
                                implicitHeight: sliders.implicitHeight + 32 
                                color: Theme.bgCard
                                radius: Theme.radiusLg
                                border.color: Theme.borderCard
                                border.width: 1
                                ColumnLayout {
                                    id: sliders
                                    anchors.fill: parent
                                    anchors.margins: 16 
                                    spacing: 18 
                                    VolumeSlider {}
                                    BrightnessSlider {}
                                }
                            }

                            // ── Toggle grid 4×2 ───────────────────────
                            Rectangle {
                                Layout.fillWidth: true
                                implicitHeight: tgGrid.implicitHeight + 32 
                                color: Theme.bgCard
                                radius: Theme.radiusLg
                                border.color: Theme.borderCard
                                border.width: 1
                                GridLayout {
                                    id: tgGrid
                                    anchors.fill: parent
                                    anchors.margins: 16 
                                    columns: 4
                                    rowSpacing: 12 
                                    columnSpacing: 10 
                                    
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

                            Item { implicitHeight: 8 }
                        }
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

