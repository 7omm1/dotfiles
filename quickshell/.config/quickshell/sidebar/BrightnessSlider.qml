import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import "../services"

RowLayout {
    id: root
    spacing: 10
    property real b: 0.5 

    Component.onCompleted: readProc.running = true

    // LECTURA INFALIBLE: Extrae el porcentaje exacto (ej. "45") ignorando el resto de la basura
    Process {
        id: readProc
        command: ["bash", "-c", "brightnessctl -m | grep -oE '[0-9]+%' | head -n 1 | tr -d '%'"]
        stdout: StdioCollector {
            onStreamFinished: {
                const val = parseFloat(this.text.trim());
                if (!isNaN(val)) root.b = val / 100.0;
            }
        }
    }

    // Actualiza la UI si cambias el brillo con el teclado
    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: readProc.running = true
    }

    // ESCRITURA
    Process { 
        id: writeProc 
        property real t: 0.5 
        command: ["bash", "-c", "brightnessctl set " + Math.round(writeProc.t * 100) + "%"] 
    }

    // ANTI-SATURACIÓN: Agrupa los comandos para no crashear Linux al mover rápido el ratón
    Timer {
        id: writeTimer
        interval: 50 
        property real targetB: 0.5
        onTriggered: {
            writeProc.t = targetB;
            writeProc.running = true;
        }
    }

    Text { 
        text: "󰃠"
        color: Theme.gold; font.family: Theme.font; font.pixelSize: 15 
    }

    Item { 
        Layout.fillWidth: true; implicitHeight: 20
        
        Rectangle { 
            anchors.verticalCenter: parent.verticalCenter;
            width: parent.width; height: 5; radius: 3; color: Qt.rgba(1,1,1,0.10)
            Rectangle { 
                width: parent.width * root.b; height: parent.height; radius: 3;
                color: Theme.gold; Behavior on width { NumberAnimation { duration: 100 } } 
            } 
        }
        Rectangle { 
            x: Math.max(0, Math.min(root.b * parent.width - 9, parent.width - 18)); 
            anchors.verticalCenter: parent.verticalCenter; width: 18; height: 18; radius: 9;
            color: "white"; Behavior on x { NumberAnimation { duration: 100 } } 
        }
        MouseArea { 
            anchors.fill: parent
            onPositionChanged: (m) => {
                const newB = Math.max(0.05, Math.min(1, m.x / parent.width));
                root.b = newB; // UI instantánea para que no se sienta lag
                writeTimer.targetB = newB;
                writeTimer.restart(); // Dispara a la terminal controladamente
            }
            onClicked: (m) => {
                const newB = Math.max(0.05, Math.min(1, m.x / parent.width));
                root.b = newB; 
                writeTimer.targetB = newB;
                writeTimer.restart();
            } 
        }
    }
    
    Text { 
        text: Math.floor(root.b * 100) + "%";
        color: Theme.fgDim; font.family: Theme.font; font.pixelSize: 10; font.bold: true; 
        width: 36; horizontalAlignment: Text.AlignRight 
    }
}
