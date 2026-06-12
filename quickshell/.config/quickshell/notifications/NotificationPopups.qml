import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Notifications
import QtQuick
import QtQuick.Layouts
import "../services"

Scope {
    NotificationServer { id: ns; actionsSupported:true; bodyMarkupSupported:true }

    Variants {
        model: Quickshell.screens
        PanelWindow {
            required property var modelData
            screen: modelData
            visible: ns.trackedNotifications.length > 0
            color: "transparent"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
            anchors.top:true; anchors.bottom:true; anchors.left:true; anchors.right:true

            Column {
                anchors { top:parent.top; right:parent.right }
                anchors.topMargin:   Theme.barH + 16
                anchors.rightMargin: 16
                width: 360
                spacing: 10

                Repeater {
                    model: ns.trackedNotifications
                    Rectangle {
                        id: notifCard
                        required property var modelData
                        property var n: modelData
                        
                        width:360; implicitHeight:nc.implicitHeight+32
                        color:Theme.bgShell; radius:Theme.radiusLg; 
                        border.color: hoverArea.containsMouse ? Theme.borderFocus : Theme.borderCard; 
                        border.width:1

                        // --- MAGIA ANIMACIÓN DE NOTIFICACIÓN ---
                        // Deslizamiento elástico de entrada desde la derecha
                        transform: Translate { id: trans; x: 400 }
                        Component.onCompleted: {
                            enterAnim.start()
                        }
                        NumberAnimation { 
                            id: enterAnim; target: trans; property: "x"; 
                            to: 0; duration: 400; easing.type: Easing.OutExpo 
                        }
                        
                        // Físicas de hover en la tarjeta
                        scale: hoverArea.pressed ? 0.98 : (hoverArea.containsMouse ? 1.02 : 1.0)
                        Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }
                        Behavior on border.color { ColorAnimation { duration: 150 } }
                        // ---------------------------------------

                        // Barra de tiempo descendente
                        Rectangle {
                            anchors{left:parent.left; bottom:parent.bottom}
                            height:4; radius:2; color:Theme.accent
                            width: parent.width
                            SequentialAnimation on width { 
                                running:true; 
                                NumberAnimation{to:0; duration:n.expireTimeout>0?n.expireTimeout:5000; easing.type:Easing.Linear} 
                            }
                        }

                        ColumnLayout { 
                            id:nc; 
                            anchors{left:parent.left;right:parent.right;top:parent.top;margins:16} 
                            spacing:6
                            RowLayout { 
                                Layout.fillWidth:true; spacing:10
                                Text { text:"󰂚"; color:Theme.accent; font.family:Theme.font; font.pixelSize:18 }
                                Text { 
                                    text:n.appName||"Sistema"; color:Theme.fgMute; 
                                    font.family:Theme.font; font.pixelSize:12; font.bold:true; Layout.fillWidth:true 
                                }
                                Rectangle {
                                    width: 24; height: 24; radius: 12
                                    color: closeArea.containsMouse ? Qt.rgba(0.92,0.43,0.57,0.2) : "transparent"
                                    Behavior on color { ColorAnimation {duration:100} }
                                    Text { 
                                        anchors.centerIn: parent; text:"󰅖"; color:Theme.fgMute; 
                                        font.family:Theme.font; font.pixelSize:14; 
                                    }
                                    MouseArea { id: closeArea; anchors.fill:parent; hoverEnabled:true; onClicked:n.dismiss() }
                                }
                            }
                            Text { 
                                text:n.summary; color:Theme.fg; font.family:Theme.font; 
                                font.pixelSize:14; font.bold:true; elide:Text.ElideRight; Layout.fillWidth:true 
                            }
                            Text { 
                                text:n.body; color:Theme.fgDim; font.family:Theme.font; font.pixelSize:12; 
                                elide:Text.ElideRight; maximumLineCount:3; wrapMode:Text.WordWrap; 
                                visible:n.body!==""; Layout.fillWidth:true; lineHeight: 1.2
                            }
                        }

                        MouseArea { 
                            id: hoverArea; anchors.fill:parent; hoverEnabled: true; z: -1
                            onClicked: n.dismiss()
                        }

                        Timer { interval:n.expireTimeout>0?n.expireTimeout:5000; running:true; onTriggered:n.dismiss() }
                    }
                }
            }
        }
    }
}
