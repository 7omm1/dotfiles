import QtQuick
import "../services"

Item {
    id: root
    property string icon: ""
    property color  iconColor: Theme.fgDim
    property int    leftPadding:  10
    property int    rightPadding: 10
    signal activated

    implicitWidth:  lbl.implicitWidth + leftPadding + rightPadding
    implicitHeight: Theme.barH

    Text {
        id: lbl
        anchors.centerIn: parent
        text: root.icon
        color: root.iconColor
        font.family: Theme.font
        font.pixelSize: 16
        Behavior on color { ColorAnimation { duration:180 } }
    }
}
