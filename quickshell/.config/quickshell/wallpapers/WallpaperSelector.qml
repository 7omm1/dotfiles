import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import "../services"

Scope {
    id: root
    property string wallDir: "/home/" + System.username + "/Imágenes/Wallpapers"
    property var wallpapers: []

    Process {
        id: readWalls
        command: ["bash", "-c", "find " + root.wallDir + " -type f \\( -name '*.jpg' -o -name '*.png' -o -name '*.jpeg' -o -name '*.gif' -o -name '*.mp4' -o -name '*.mkv' -o -name '*.webm' \\)"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const files = this.text.trim().split("\n").filter(f => f.length > 0);
                root.wallpapers = files;
            }
        }
    }

    Variants {
        model: Quickshell.screens
        PanelWindow {
            required property var modelData
            screen: modelData
            visible: WallpaperState.visible
            color: "transparent"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
            anchors.top:true; anchors.bottom:true; anchors.left:true; anchors.right:true

            MouseArea { anchors.fill:parent; onClicked: WallpaperState.hide(); z:-1 }

            Rectangle {
                anchors.centerIn: parent
                width: 720; height: 500
                color: Theme.bgShell
                radius: Theme.panelR
                border.color: Theme.borderFocus; border.width: 1
                clip: true

                transform: Translate {
                    y: WallpaperState.visible ? 0 : 50
                    Behavior on y { NumberAnimation { duration: 350; easing.type: Easing.OutBack } }
                }
                scale: WallpaperState.visible ? 1.0 : 0.9
                Behavior on scale { NumberAnimation { duration: 350; easing.type: Easing.OutBack } }
                opacity: WallpaperState.visible ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 200 } }

                ColumnLayout {
                    anchors { fill: parent; margins: 20 }
                    spacing: 16

                    Text {
                        text: "󰸉 Fondos de Pantalla"
                        color: Theme.fg; font.family: Theme.font; font.pixelSize: 20; font.bold: true
                    }

                    Flickable {
                        Layout.fillWidth: true; Layout.fillHeight: true
                        contentHeight: grid.implicitHeight
                        boundsBehavior: Flickable.StopAtBounds
                        clip: true

                        Grid {
                            id: grid
                            width: parent.width
                            columns: 3
                            spacing: 14

                            Repeater {
                                model: root.wallpapers
                                Rectangle {
                                    required property string modelData
                                    property bool isVideo: modelData.endsWith(".mp4") || modelData.endsWith(".mkv") || modelData.endsWith(".webm")
                                    
                                    width: 216; height: 120
                                    radius: Theme.radiusMd
                                    color: Theme.bgCard
                                    border.color: wma.containsMouse ? Theme.accent : "transparent"
                                    border.width: 2
                                    
                                    clip: true // <-- ESTO es el secreto para redondear las imágenes de adentro sin usar shaders

                                    scale: wma.pressed ? 0.95 : (wma.containsMouse ? 1.05 : 1.0)
                                    Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }

                                    Image {
                                        visible: !parent.isVideo
                                        anchors.fill: parent
                                        // Si es video, le mandamos texto vacío para que no tire error intentando decodificarlo
                                        source: parent.isVideo ? "" : "file://" + modelData
                                        fillMode: Image.PreserveAspectCrop
                                        smooth: true
                                    }
                                    
                                    Rectangle {
                                        visible: parent.isVideo
                                        anchors.fill: parent
                                        color: Qt.rgba(0,0,0, 0.4)
                                        Text {
                                            anchors.centerIn: parent
                                            text: "󰕧\nVideo"
                                            color: Theme.fgMute
                                            font.family: Theme.font
                                            font.pixelSize: 24
                                            horizontalAlignment: Text.AlignHCenter
                                        }
                                    }

                                    MouseArea {
                                        id: wma
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        onClicked: {
                                            const p = Qt.createQmlObject('import Quickshell.Io; Process {}', root);
                                            if (parent.isVideo) {
                                                p.command = [
                                                    "bash", "-c", 
                                                    "pkill swww; pkill mpvpaper; " + 
                                                    "mpvpaper -o '--loop --no-audio' '*' '" + modelData + "' & " +
                                                    "ffmpeg -y -i '" + modelData + "' -vframes 1 /tmp/wal_frame.jpg && wal -i /tmp/wal_frame.jpg -n"
                                                ];
                                            } else {
                                                p.command = [
                                                    "bash", "-c", 
                                                    "pkill mpvpaper; " +
                                                    "swww img '" + modelData + "' --transition-type wipe && wal -i '" + modelData + "' -n"
                                                ];
                                            }
                                            p.running = true;
                                            WallpaperState.hide();
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            onVisibleChanged: { if (visible) readWalls.running = true }
        }
    }
}
