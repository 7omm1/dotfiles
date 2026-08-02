import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import "../services"

Scope {
    Variants {
        model: Quickshell.screens
        PanelWindow {
            required property var modelData
            screen: modelData
            visible: CalendarState.visible
            color: "transparent"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
            anchors.top: true
            anchors.bottom: true
            anchors.left: true
            anchors.right: true

            MouseArea {
                anchors.fill: parent
                onClicked: CalendarState.hide()
                z: -1
            }

            Rectangle {
                anchors.top: parent.top
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.topMargin: Theme.barH + 10
                width: 280
                implicitHeight: calLayout.implicitHeight + 24
                color: Theme.bgShell
                radius: Theme.radiusLg
                border.color: Theme.borderCard
                border.width: 1

                transform: Translate {
                    y: CalendarState.visible ? 0 : -20
                    Behavior on y { NumberAnimation { duration: 300; easing.type: Easing.OutBack } }
                }
                opacity: CalendarState.visible ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 200 } }

                ColumnLayout {
                    id: calLayout
                    anchors.fill: parent
                    anchors.margins: 12
                    MiniCalendar {
                        Layout.fillWidth: true
                    }
                }
            }
        }
    }
}
