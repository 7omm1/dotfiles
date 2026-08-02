import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import Quickshell.Services.Mpris
import QtQuick
import QtQuick.Layouts
import "../services"

Scope {
    id: root
    property bool isOpen: LeftSidebarState.visible
    property int  tab: 0

    Variants {
        model: Quickshell.screens
        PanelWindow {
            id: panelWin
            required property var modelData
            screen: modelData
            visible: false
            color: "transparent"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
            anchors.top:true; anchors.bottom:true; anchors.left:true; anchors.right:true

            Timer { id: closeTimer; interval: 350; onTriggered: { if (!root.isOpen) panelWin.visible = false } }
            Connections { target: root; function onIsOpenChanged() { if (root.isOpen) { panelWin.visible = true; closeTimer.stop() } else { closeTimer.restart() } } }
            MouseArea { anchors.fill:parent; onClicked:LeftSidebarState.hide(); z:-1 }

            Item {
                id: panel
                x: 10; y: 0   
                width: 360
                height: Math.min(parent.height - Theme.barH - 20, scroll.contentHeight + 4)

                // FÍSICA: Cae desde arriba igual que el derecho
                transform: Translate {
                    y: root.isOpen ? 0 : -(panel.height + 20)
                    Behavior on y { NumberAnimation { duration: 400; easing.type: root.isOpen ? Easing.OutExpo : Easing.InExpo } }
                }
                opacity: root.isOpen ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 300; easing.type: Easing.InOutQuad } }

                Rectangle { anchors.fill: parent; color: Theme.bgShell; radius: Theme.panelR; border.color: Theme.borderSep; border.width: 1 }
                // Parches superiores rectos
                Rectangle { anchors.top: parent.top; anchors.left: parent.left; width: Theme.panelR; height: Theme.panelR; color: Theme.bgShell; Rectangle { anchors.left: parent.left; anchors.top: parent.top; anchors.bottom: parent.bottom; width: 1; color: Theme.borderSep } }
                Rectangle { anchors.top: parent.top; anchors.right: parent.right; width: Theme.panelR; height: Theme.panelR; color: Theme.bgShell; Rectangle { anchors.right: parent.right; anchors.top: parent.top; anchors.bottom: parent.bottom; width: 1; color: Theme.borderSep } }
                Rectangle { anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right; height: 1; color: Theme.borderSep }

                Item {
                    anchors.fill: parent; clip: true
                    Flickable {
                        id: scroll
                        anchors.fill: parent; contentWidth: width; contentHeight: col.implicitHeight + 32
                        boundsBehavior: Flickable.StopAtBounds; clip: true

                        ColumnLayout {
                            id: col
                            anchors { top:parent.top; left:parent.left; right:parent.right; margins:16; topMargin:20 }
                            spacing: 12

                            // ── Header (Clima & Status) ──
                            Rectangle {
                                Layout.fillWidth:true; implicitHeight:72
                                color:Theme.bgCard; radius:Theme.radiusLg; border.color:Theme.borderCard; border.width:1
                                RowLayout {
                                    anchors { fill:parent; margins:14 } spacing:14
                                    Text { text: "🌤️"; font.pixelSize: 32 }
                                    ColumnLayout { Layout.fillWidth:true; spacing:2
                                        Text { text: "Cusco, PE"; color:Theme.fg; font.family:Theme.font; font.pixelSize:14; font.bold:true }
                                        Text { text: "16°C • Parcialmente nublado"; color:Theme.fgMute; font.family:Theme.font; font.pixelSize:10 }
                                    }
                                    ColumnLayout { spacing:0
                                        Text { text:Clock.time; color:Theme.accent; font.family:Theme.font; font.pixelSize:22; font.bold:true; Layout.alignment:Qt.AlignRight }
                                        Text { text:Clock.dayShort; color:Theme.fgMute; font.family:Theme.font; font.pixelSize:9; Layout.alignment:Qt.AlignRight }
                                    }
                                }
                            }

                            // ── Tabs (Productividad) ──
                            Rectangle {
                                Layout.fillWidth:true; implicitHeight:36
                                color:Theme.bgCard; radius:Theme.radiusMd; border.color:Theme.borderCard; border.width:1
                                RowLayout {
                                    anchors { fill:parent; margins:4 } spacing:4
                                    Repeater {
                                        model:[{i:"󰝚",l:"Media"},{i:"󰃭",l:"Tareas"}]
                                        Rectangle {
                                            Layout.fillWidth:true; Layout.fillHeight:true; radius:Theme.radiusSm
                                            color:root.tab===index ? Theme.bgSurface : (tm.containsMouse ? Qt.rgba(1,1,1,0.04):"transparent")
                                            border.color:root.tab===index ? Theme.borderFocus:"transparent"; border.width:1
                                            Behavior on color { ColorAnimation{duration:130} }
                                            Row { anchors.centerIn:parent; spacing:6
                                                Text { text:modelData.i; color:root.tab===index?Theme.accent:Theme.fgMute; font.family:Theme.font; font.pixelSize:13 }
                                                Text { text:modelData.l; color:root.tab===index?Theme.fg:Theme.fgDim; font.family:Theme.font; font.pixelSize:11; font.bold:true }
                                            }
                                            MouseArea { id:tm; anchors.fill:parent; hoverEnabled:true; onClicked:root.tab=index }
                                        }
                                    }
                                }
                            }

                            // ── Tab 0: Reproductor ──
                            Rectangle {
                                visible: root.tab === 0
                                Layout.fillWidth:true; implicitHeight: mp.implicitHeight + 28
                                color:Theme.bgCard; radius:Theme.radiusLg; border.color:Theme.borderCard; border.width:1
                                MediaPlayerFull { id: mp; anchors { top:parent.top; left:parent.left; right:parent.right; margins:14 } }
                            }

                            // ── Tab 1: To-Do List (Universidad & Dev) ──
                            ColumnLayout {
                                visible: root.tab === 1
                                Layout.fillWidth:true; spacing: 10
                                
                                Repeater {
                                    model: [
                                        "Finalizar MVP Dropshipping Agrícola",
                                        "Revisar diagramas UML de componentes",
                                        "Estudiar para Cálculo / Física"
                                    ]
                                    Rectangle {
                                        Layout.fillWidth: true; implicitHeight: 46
                                        color: Theme.bgCard; radius: Theme.radiusMd; border.color: Theme.borderCard; border.width: 1
                                        RowLayout {
                                            anchors.fill: parent; anchors.margins: 12; spacing: 12
                                            Rectangle { width: 14; height: 14; radius: 4; border.color: Theme.accent; border.width: 2; color: "transparent" }
                                            Text { text: modelData; color: Theme.fg; font.family: Theme.font; font.pixelSize: 12; Layout.fillWidth: true; elide: Text.ElideRight }
                                        }
                                    }
                                }
                            }

                            // ── Dock de apps ──
                            Rectangle {
                                Layout.fillWidth:true; implicitHeight:68
                                color:Theme.bgCard; radius:Theme.radiusLg; border.color:Theme.borderCard; border.width:1
                                Row {
                                    anchors.centerIn:parent; spacing:10
                                    Repeater {
                                        model:[
                                            {i:"󰈹",a:"firefox",c:"#ff7800"}, {i:"󰆍",a:"kitty",  c:"#9ccfd8"},
                                            {i:"󰨞",a:"code",   c:"#007acc"}, {i:"󰙯",a:"discord",c:"#7289da"},
                                            {i:"󰓓",a:"steam",  c:"#66c0f4"}, {i:"󰄮",a:"thunar", c:"#f6c177"}
                                        ]
                                        Rectangle {
                                            width:46; height:46; radius:13
                                            color:dma.containsMouse?Qt.rgba(1,1,1,0.10):Qt.rgba(1,1,1,0.04)
                                            border.color:dma.containsMouse?Theme.borderSep:Theme.border; border.width:1
                                            scale:dma.containsMouse?1.12:1.0
                                            Behavior on scale{NumberAnimation{duration:160;easing.type:Easing.OutBack}}
                                            Behavior on color{ColorAnimation{duration:140}}
                                            Text { anchors.centerIn:parent; text:modelData.i; color:Qt.lighter(modelData.c,1.3); font.family:Theme.font; font.pixelSize:22 }
                                            MouseArea { id:dma; anchors.fill:parent; hoverEnabled:true; onClicked: { LeftSidebarState.hide(); run(modelData.a) } }
                                        }
                                    }
                                }
                            }
                            Item { implicitHeight:8 }
                        }
                    }
                }
            }
        }
    }
    function run(cmd) { const p=Qt.createQmlObject('import Quickshell.Io; Process {}',root); p.command=["bash","-c",cmd]; p.running=true }
}
