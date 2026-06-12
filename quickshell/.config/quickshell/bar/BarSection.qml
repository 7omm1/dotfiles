// Zona de la barra — contiene elementos y tiene borde derecho
import QtQuick
import "../services"

Item {
    id: root
    implicitHeight: Theme.barH
    default property alias content: inner.data

    Item {
        id: inner
        anchors.fill: parent
    }
}
