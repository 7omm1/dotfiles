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
            required property var modelData
            screen: modelData
            visible: root.isOpen
        
            color: "transparent"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
            anchors.top:true; anchors.bottom:true; anchors.left:true; anchors.right:true

            MouseArea { anchors.fill:parent; onClicked:LeftSidebarState.hide(); z:-1 }

            // ── Gota rectangular ─────────────────────────────────────
            Rectangle {
                id: panel
                x: 0
                y: Theme.barH   // Justo debajo de la barra, sin gap
                width: 420
                height: Math.min(parent.height - Theme.barH - 20, scroll.contentHeight + 4)
                color: Theme.bgShell
                radius: Theme.panelR

                // --- MAGIA DE ANIMACIÓN FLUIDA MAC OS ---
                transform: Translate {
                    x: root.isOpen ? 0 : -450
                    Behavior on x { NumberAnimation { duration: 350; easing.type: Easing.OutExpo } }
                }

                opacity: root.isOpen ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                // ----------------------------------------

                // Parche para eliminar radio superior
                Rectangle {
                    anchors { top:parent.top; left:parent.left; right:parent.right }
                    height: Theme.panelR
                    color: Theme.bgShell
                }
                // Borde derecho e inferior
                Rectangle {
                    anchors { right:parent.right; top:parent.top; bottom:parent.bottom }
                    width: 1; color: Theme.borderSep
                    Rectangle { width:parent.width; height:1; anchors.bottom:parent.bottom; color:Theme.borderSep }
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
                        anchors { top:parent.top; left:parent.left; right:parent.right; margins:16; topMargin:20 }
                        spacing: 12

                        // ── Header ────────────────────────────────────
                        Rectangle {
                            Layout.fillWidth:true; implicitHeight:72
                            color:Theme.bgCard; radius:Theme.radiusLg; border.color:Theme.borderCard; border.width:1

                            RowLayout {
                                anchors { fill:parent; margins:14 } spacing:14

                                Rectangle {
                                    width:44; height:44; radius:12
                                    color:Qt.rgba(0.92,0.43,0.57,0.10)
                                    border.color:Theme.borderFocus; border.width:1
                                    Text { anchors.centerIn:parent; text:""; color:Theme.accent; font.family:Theme.font; font.pixelSize:22 }
                                }
                                ColumnLayout { Layout.fillWidth:true; spacing:2
                                    Text {
                                        text: { const h=Clock.hour; return h<12?"Buenos días ,":h<19?"Buenas tardes ,":"Buenas noches ," }
                                        color:Theme.fgMute; font.family:Theme.font; font.pixelSize:10; font.bold:true
                                    }
                                    Text { text:System.username+"@"+System.hostname; color:Theme.fg; font.family:Theme.font; font.pixelSize:14; font.bold:true }
                                }
                                ColumnLayout { spacing:0
                                    Text { text:Clock.time; color:Theme.accent; font.family:Theme.font; font.pixelSize:22; font.bold:true; Layout.alignment:Qt.AlignRight }
                                    Text { text:Clock.dayShort; color:Theme.fgMute; font.family:Theme.font; font.pixelSize:9; Layout.alignment:Qt.AlignRight }
                                }
                            }
                        }

                        // ── Tabs ──────────────────────────────────────
                        Rectangle {
                            Layout.fillWidth:true; implicitHeight:36
                            color:Theme.bgCard; radius:Theme.radiusMd; border.color:Theme.borderCard; border.width:1
                            RowLayout {
                                anchors { fill:parent; margins:4 } spacing:4
                                Repeater {
                                    model:[{i:"󰝚",l:"Media"},{i:"󰻠",l:"Sistema"},{i:"󰃭",l:"Agenda"}]
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

                        // ── Tab 0: Reproductor ────────────────────────
                        Rectangle {
                            visible: root.tab === 0
                            Layout.fillWidth:true
                            implicitHeight: mp.implicitHeight + 28
                            color:Theme.bgCard; radius:Theme.radiusLg; border.color:Theme.borderCard; border.width:1
                            MediaPlayerFull {
                                id: mp
                                anchors { top:parent.top; left:parent.left; right:parent.right; margins:14 }
                            }
                        }

                        // ── Tab 1: Sistema ────────────────────────────
                        ColumnLayout {
                            visible: root.tab === 1
                            Layout.fillWidth:true; spacing:10

                            // Anillos grandes
                            Rectangle {
                                Layout.fillWidth:true; implicitHeight:110
                                color:Theme.bgCard; radius:Theme.radiusLg; border.color:Theme.borderCard; border.width:1
                                Row {
                                    anchors.centerIn:parent; spacing:24
                                    ResourceRing { value:System.cpu; ringColor:Theme.accent; label:"CPU"; implicitWidth:86; implicitHeight:86 }
                                    ResourceRing { value:System.ram; ringColor:Theme.iris;   label:"RAM"; implicitWidth:86; implicitHeight:86 }
                                    ResourceRing { value:System.gpu; ringColor:Theme.foam;   label:"GPU"; show:System.hasGpu; implicitWidth:86; implicitHeight:86 }
                                }
                            }

                            // Info grid
                            Rectangle {
                                Layout.fillWidth:true; implicitHeight:infoGrid.implicitHeight+24
                                color:Theme.bgCard; radius:Theme.radiusLg; border.color:Theme.borderCard; border.width:1
                                GridLayout {
                                    id:infoGrid
                                    anchors { fill:parent; margins:14 } columns:2; rowSpacing:10; columnSpacing:16
                                    Repeater {
                                        model:[
                                            {i:"",  l:"Kernel",   v:()=>System.kernel},
                                            {i:"󰔚", l:"Uptime",   v:()=>System.uptime},
                                            {i:"󰏗", l:"Paquetes", v:()=>System.pkgs+" (pacman)"},
                                            {i:"󰌌", l:"Temp CPU", v:()=>System.cpuTemp+"°C"},
                                        ]
                                        RowLayout { spacing:8
                                            Text { text:modelData.i; color:Theme.fgMute; font.family:Theme.font; font.pixelSize:14 }
                                            ColumnLayout { spacing:1
                                                Text { text:modelData.l; color:Theme.fgMute; font.family:Theme.font; font.pixelSize:9; font.bold:true }
                                                Text { text:modelData.v(); color:Theme.fgDim; font.family:Theme.font; font.pixelSize:11 }
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // ── Tab 2: Agenda/Calendario ──────────────────
                        Rectangle {
                            visible: root.tab === 2
                            Layout.fillWidth:true; implicitHeight:calBody.implicitHeight+28
                            color:Theme.bgCard; radius:Theme.radiusLg; border.color:Theme.borderCard; border.width:1
                            ColumnLayout {
                                id:calBody
                                anchors { top:parent.top; left:parent.left; right:parent.right; margins:16 } spacing:10
                                Text { text:Clock.day; color:Theme.accent; font.family:Theme.font; font.pixelSize:20; font.bold:true; Layout.alignment:Qt.AlignHCenter }
                                Text { text:Clock.date; color:Theme.fgDim; font.family:Theme.font; font.pixelSize:12; Layout.alignment:Qt.AlignHCenter }
                                MiniCalendar { Layout.fillWidth:true }
                            }
                        }

                        // ── Dock de apps ──────────────────────────────
                        Rectangle {
                            Layout.fillWidth:true; implicitHeight:68
                            color:Theme.bgCard; radius:Theme.radiusLg; border.color:Theme.borderCard; border.width:1
                            Row {
                                anchors.centerIn:parent; spacing:10
                                Repeater {
                                    model:[
                                        {i:"󰈹",a:"firefox",c:"#ff7800"},
                                        {i:"󰆍",a:"kitty",  c:"#9ccfd8"},
                                        {i:"󰨞",a:"code",   c:"#007acc"},
                                        {i:"󰙯",a:"discord",c:"#7289da"},
                                        {i:"󰓓",a:"steam",  c:"#66c0f4"},
                                        {i:"󰄮",a:"thunar", c:"#f6c177"},
                                    ]
                                    Rectangle {
                                        width:46; height:46; radius:13
                                        color:dma.containsMouse?Qt.rgba(1,1,1,0.10):Qt.rgba(1,1,1,0.04)
                                        border.color:dma.containsMouse?Theme.borderSep:Theme.border; border.width:1
                                        scale:dma.containsMouse?1.12:1.0
                                        Behavior on scale{NumberAnimation{duration:160;easing.type:Easing.OutBack}}
                                        Behavior on color{ColorAnimation{duration:140}}
                                        Text { anchors.centerIn:parent; text:modelData.i; color:Qt.lighter(modelData.c,1.3); font.family:Theme.font; font.pixelSize:22 }
                                        MouseArea { id:dma; anchors.fill:parent; hoverEnabled:true
                                            onClicked: { LeftSidebarState.hide(); run(modelData.a) }
                                        }
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

    function run(cmd) {
        const p=Qt.createQmlObject('import Quickshell.Io; Process {}',root)
        p.command=["bash","-c",cmd]; p.running=true
    }
}
