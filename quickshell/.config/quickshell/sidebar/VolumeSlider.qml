import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import "../services"

RowLayout {
    id: root
    spacing: 10
    property real v: 0.5 // Variable local nativa

    Component.onCompleted: readProc.running = true

    // LEER volumen del sistema sin usar Pipewire de Quickshell
    Process {
        id: readProc
        command: ["bash", "-c", "pactl get-sink-volume @DEFAULT_SINK@ | grep -Po '[0-9]+(?=%)' | head -n 1"]
        stdout: StdioCollector {
            onStreamFinished: {
                const val = parseFloat(this.text.trim());
                if (!isNaN(val)) root.v = val / 100.0;
            }
        }
    }

    // Actualiza la UI si cambias el volumen con las teclas del teclado
    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: readProc.running = true
    }

    // ESCRIBIR volumen
    Process { 
        id: writeProc 
        property real t: 0.5 
        command: ["bash", "-c", "pactl set-sink-volume @DEFAULT_SINK@ " + Math.round(writeProc.t * 100) + "%"] 
    }

    Text {
        text: root.v <= 0 ? "󰖁" : root.v < 0.33 ? "󰕿" : root.v < 0.66 ? "󰖀" : "󰕾"
        color: Theme.foam; font.family: Theme.font; font.pixelSize: 15
    }

    Item { 
        Layout.fillWidth: true; implicitHeight: 20
        
        Rectangle { 
            anchors.verticalCenter: parent.verticalCenter;
            width: parent.width; height: 5; radius: 3; color: Qt.rgba(1,1,1,0.10)
            Rectangle { 
                width: parent.width * root.v; height: parent.height; radius: 3;
                color: Theme.foam; Behavior on width { NumberAnimation { duration: 100 } } 
            } 
        }
        Rectangle { 
            x: Math.max(0, Math.min(root.v * parent.width - 9, parent.width - 18)); 
            anchors.verticalCenter: parent.verticalCenter; width: 18; height: 18; radius: 9;
            color: "white"; Behavior on x { NumberAnimation { duration: 100 } } 
        }
        MouseArea { 
            anchors.fill: parent
            onPositionChanged: (m) => {
                const newV = Math.max(0, Math.min(1, m.x / parent.width));
                root.v = newV; // UI reacciona instantáneamente
                writeProc.t = newV;
                writeProc.running = true; 
            }
            onClicked: (m) => {
                const newV = Math.max(0, Math.min(1, m.x / parent.width));
                root.v = newV; // UI reacciona instantáneamente
                writeProc.t = newV;
                writeProc.running = true;
            } 
        }
    }
    
    Text { 
        text: Math.floor(root.v * 100) + "%";
        color: Theme.fgDim; font.family: Theme.font; font.pixelSize: 10; font.bold: true; 
        width: 36; horizontalAlignment: Text.AlignRight 
    }
}
