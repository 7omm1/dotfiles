import QtQuick
import "../services"

Rectangle {
    id: r
    property string icon: ""
    property bool   hot:  false
    signal act

    // Tamaño aumentado para el nuevo panel
    implicitWidth: 46; implicitHeight: 46; radius: 14

    color: hot ? (ma.containsMouse?Qt.rgba(0.92,0.43,0.57,0.25):Qt.rgba(0.92,0.43,0.57,0.12))
               : (ma.containsMouse?Qt.rgba(1,1,1,0.10):Qt.rgba(1,1,1,0.04))
    border.color: hot ? Qt.rgba(0.92,0.43,0.57,0.40) : Theme.border; border.width: 1
    Behavior on color{ColorAnimation{duration:130}}

    Text { 
        anchors.centerIn:parent; text:r.icon; 
        color:hot?Theme.accent:Theme.fgDim; font.family:Theme.font;
        font.pixelSize: 18 // Ícono más grande
    }
    MouseArea { id:ma; anchors.fill:parent; hoverEnabled:true; onClicked:r.act() }
}
