import QtQuick
import QtQuick.Shapes
import "../services"

Item {
    id: root
    property color  ringColor: Theme.accent
    property real   value:     0
    property string label:     ""
    property bool   show:      true
    
    implicitWidth: 76
    implicitHeight: 76
    visible: show

    // Rebote suave al pasar el ratón
    scale: ma.containsMouse ? 1.08 : 1.0
    Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutBack } }

    // 1. Anillo de Fondo (Track)
    Shape { 
        anchors.fill: parent; layer.enabled: true; layer.samples: 4
        ShapePath { 
            fillColor: "transparent"; 
            strokeColor: Qt.rgba(root.ringColor.r, root.ringColor.g, root.ringColor.b, 0.15)
            strokeWidth: 6; capStyle: ShapePath.RoundCap
            PathAngleArc { 
                centerX: root.width/2; centerY: root.height/2; 
                radiusX: root.width/2 - 6; radiusY: root.height/2 - 6; 
                startAngle: -90; sweepAngle: 360 
            } 
        } 
    }

    // 2. Anillo de "Brillo" (Glow simulado - más grueso y casi transparente)
    Shape { 
        anchors.fill: parent; layer.enabled: true; layer.samples: 4
        ShapePath { 
            fillColor: "transparent"; 
            strokeColor: Qt.rgba(root.ringColor.r, root.ringColor.g, root.ringColor.b, 0.25)
            strokeWidth: 14; capStyle: ShapePath.RoundCap
            PathAngleArc { 
                centerX: root.width/2; centerY: root.height/2; 
                radiusX: root.width/2 - 6; radiusY: root.height/2 - 6; 
                startAngle: -90; 
                sweepAngle: root.value * 3.6 
                Behavior on sweepAngle { NumberAnimation { duration: 1000; easing.type: Easing.OutExpo } }
            } 
        } 
    }

    // 3. Anillo Principal (Progreso real)
    Shape { 
        anchors.fill: parent; layer.enabled: true; layer.samples: 4
        ShapePath { 
            fillColor: "transparent"; 
            strokeColor: root.ringColor; 
            strokeWidth: 6; capStyle: ShapePath.RoundCap
            PathAngleArc { 
                centerX: root.width/2; centerY: root.height/2; 
                radiusX: root.width/2 - 6; radiusY: root.height/2 - 6; 
                startAngle: -90
                sweepAngle: root.value * 3.6
                Behavior on sweepAngle { NumberAnimation { duration: 1000; easing.type: Easing.OutExpo } } 
            } 
        } 
    }

    Column { 
        anchors.centerIn: parent; spacing: 2
        Text { 
            text: Math.round(root.value) + "%"; 
            color: Theme.fg; font.family: Theme.font; font.pixelSize: 13; font.bold: true;
            anchors.horizontalCenter: parent.horizontalCenter 
        }
        Text { 
            text: root.label; 
            color: Theme.fgMute; font.family: Theme.font; font.pixelSize: 9; font.bold: true;
            anchors.horizontalCenter: parent.horizontalCenter 
        }
    }

    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
    }
}
