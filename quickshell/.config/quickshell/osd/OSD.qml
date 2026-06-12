import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick
import "../services"

Scope {
    id: root
    property real  val:  0
    property bool  show: false
    property string ico: "󰕾"
    property real  _lastVal: -1

    // Vigila el volumen nativo cada 300ms
    Process {
        id: readOsdProc
        command: ["bash", "-c", "pactl get-sink-volume @DEFAULT_SINK@ | grep -Po '[0-9]+(?=%)' | head -n 1"]
        stdout: StdioCollector {
            onStreamFinished: {
                const parsed = parseFloat(this.text.trim());
                if (isNaN(parsed)) return;
                const newVal = parsed / 100.0;

                // Si detecta un cambio (con teclas o slider), salta a la pantalla
                if (root._lastVal !== -1 && Math.abs(root._lastVal - newVal) > 0.01) {
                    root.val = newVal;
                    root.ico = root.val > 0.6 ? "󰕾" : root.val > 0.3 ? "󰖀" : root.val > 0 ? "󰕿" : "󰖁";
                    root.show = true;
                    ht.restart();
                }
                root._lastVal = newVal;
            }
        }
    }

    Timer { interval: 300; running: true; repeat: true; onTriggered: readOsdProc.running = true }
    Timer { id: ht; interval: 2200; onTriggered: root.show = false }

    Variants {
        model: Quickshell.screens
        PanelWindow {
            required property var modelData
            screen: modelData
            visible: root.show
            color: "transparent"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
            anchors.top:true; anchors.bottom:true; anchors.left:true; anchors.right:true

            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 56
                width: osdInner.implicitWidth + 56
                height: 54
                color: Theme.bgShell
                radius: 27
                border.color: Theme.borderFocus; border.width: 1

                transform: Translate {
                    y: root.show ? 0 : 60
                    Behavior on y { NumberAnimation { duration: 400; easing.type: Easing.OutBack } }
                }

                scale: root.show ? 1.0 : 0.8
                Behavior on scale { NumberAnimation { duration: 400; easing.type: Easing.OutBack } }

                opacity: root.show ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }

                Rectangle {
                    anchors { left:parent.left; top:parent.top; bottom:parent.bottom }
                    width: parent.width * root.val
                    radius: parent.radius
                    color: Qt.rgba(0.60,0.81,0.85, 0.15)
                    Behavior on width { NumberAnimation { duration:150; easing.type: Easing.OutCubic } }
                }

                Row {
                    id: osdInner
                    anchors.centerIn: parent
                    spacing: 16

                    Text {
                        text:root.ico; color:Theme.foam; font.family:Theme.font; font.pixelSize:22;
                        anchors.verticalCenter:parent.verticalCenter
                    }

                    Item {
                        width:130; height:6; anchors.verticalCenter:parent.verticalCenter
                        Rectangle { anchors.fill:parent; radius:3; color:Qt.rgba(1,1,1,0.12) }
                        Rectangle {
                            width:parent.width*root.val; height:parent.height; radius:3; color:Theme.foam;
                            Behavior on width{NumberAnimation{duration:150; easing.type: Easing.OutCubic}}
                        }
                    }

                    Text {
                        text:Math.round(root.val*100)+"%"; color:Theme.fg;
                        font.family:Theme.font; font.pixelSize:15; font.bold:true;
                        anchors.verticalCenter:parent.verticalCenter
                    }
                }
            }
        }
    }
}
