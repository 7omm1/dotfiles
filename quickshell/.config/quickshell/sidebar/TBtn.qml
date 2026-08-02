import QtQuick
import QtQuick.Layouts
import "../services"

Item {
    id: root
    property string icon: ""
    property string lbl:  ""
    property bool   on:   false
    property bool   hot:  false
    signal t

    // Forzamos un tamaño cuadrado/proporcionado como en AGS
    implicitWidth: 70 // <-- MODIFICADO: Antes 76. Lo ajustamos para que entren 4 columnas cómodamente.
    implicitHeight: 64

    Rectangle {
        id: btnRect
        anchors.fill: parent
        anchors.margins: 2 // <-- MODIFICADO: Antes 4. Reducimos el margen interno para no perder tanta área de botón.
        radius: Theme.radiusMd
        
        color: root.on ?
            (root.hot ? Qt.rgba(0.92,0.43,0.57,0.2) : Qt.rgba(0.60,0.80,0.85,0.15))
                       : (ma.containsMouse ? Qt.rgba(1,1,1,0.08) : Qt.rgba(1,1,1,0.03))
        
        border.color: root.on ?
            (root.hot ? Qt.rgba(0.92,0.43,0.57,0.5) : Qt.rgba(0.60,0.80,0.85,0.5)) 
                              : Qt.rgba(1,1,1,0.08)
        border.width: 1

        // Animación suave de color
        Behavior on color { ColorAnimation { duration: 150 } }

        // FÍSICAS DE REBOTE
        scale: ma.pressed ? 0.92 : (ma.containsMouse ? 1.08 : 1.0)
        Behavior on scale { 
            NumberAnimation { duration: 250; easing.type: Easing.OutBack }
        }

        ColumnLayout { 
            anchors.centerIn: parent; spacing: 4
            Text { 
                text: root.icon
                color: root.on ? (root.hot ? Theme.accent : Theme.foam) : Theme.fgMute
                font.family: Theme.font; font.pixelSize: 20
                Layout.alignment: Qt.AlignHCenter 
            }
            Text { 
                text: root.lbl
                color: root.on ? Theme.fg : Theme.fgMute
                font.family: Theme.font; font.pixelSize: 10; font.bold: true
                Layout.alignment: Qt.AlignHCenter 
            }
        }
    }

    MouseArea { 
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        onClicked: root.t() 
    }
}
