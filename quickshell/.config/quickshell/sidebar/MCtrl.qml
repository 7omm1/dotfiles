import QtQuick
import "../services"

Item {
    id: root
    property string icon: ""
    property bool   big:  false
    signal p

    // Aseguramos un tamaño base para que la animación de escala no corte el botón
    implicitWidth: big ? 54 : 44
    implicitHeight: big ? 54 : 44

    Rectangle {
        id: bgRect
        anchors.centerIn: parent
        // Hacemos el círculo ligeramente más pequeño que el Item padre para dejarle espacio para crecer
        width: parent.width - 8
        height: parent.height - 8
        radius: width / 2

        color: root.big ? (ma.containsMouse ? Qt.rgba(1,1,1,0.14) : Qt.rgba(1,1,1,0.08)) 
                        : (ma.containsMouse ? Qt.rgba(1,1,1,0.08) : "transparent")
        
        border.color: root.big ? (ma.containsMouse ? Qt.rgba(1,1,1,0.2) : Theme.borderCard) : "transparent"
        border.width: 1

        // Físicas de rebote (scale)
        scale: ma.pressed ? 0.85 : (ma.containsMouse ? 1.1 : 1.0)
        
        Behavior on scale { 
            NumberAnimation { duration: 250; easing.type: Easing.OutBack } 
        }
        Behavior on color { 
            ColorAnimation { duration: 150 } 
        }

        Text { 
            anchors.centerIn: parent
            text: root.icon
            color: Theme.fg
            font.family: Theme.font
            font.pixelSize: root.big ? 24 : 20 
        }
    }

    MouseArea { 
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        onClicked: root.p() 
    }
}
