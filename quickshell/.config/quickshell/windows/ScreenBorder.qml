import Quickshell
import Quickshell.Wayland
import QtQuick
import "../services"

Scope {
    Variants {
        model: Quickshell.screens

        PanelWindow {
            required property var modelData
            screen: modelData
            
            // Ocupa el 100% de la pantalla (Tus anclajes originales correctos)
            anchors.top: true
            anchors.bottom: true
            anchors.left: true
            anchors.right: true
            
            color: "transparent"
            WlrLayershell.namespace: "qs-border"
            WlrLayershell.layer: WlrLayer.Overlay 
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None 

            Item {
                // Aquí sí es válido el fill porque está dentro de la ventana
                anchors.fill: parent

                // EL BORDE FINO DE COLOR (Delimitador)
                Rectangle {
                    anchors.fill: parent
                    color: "transparent"
                    border.color: Theme.accent
                    border.width: 1
                    radius: Theme.monitorR
                }

                // LAS 4 ESQUINAS NEGRAS SÓLIDAS (Efecto Caelestia)
                
                // 1. Arriba-Izquierda
                Item {
                    anchors.top: parent.top
                    anchors.left: parent.left
                    width: Theme.monitorR
                    height: Theme.monitorR
                    clip: true
                    
                    Rectangle {
                        width: Theme.monitorR * 4
                        height: Theme.monitorR * 4
                        radius: Theme.monitorR * 2
                        x: -Theme.monitorR
                        y: -Theme.monitorR
                        color: "transparent"
                        border.color: "#000000"
                        border.width: Theme.monitorR
                    }
                }

                // 2. Arriba-Derecha
                Item {
                    anchors.top: parent.top
                    anchors.right: parent.right
                    width: Theme.monitorR
                    height: Theme.monitorR
                    clip: true
                    
                    Rectangle {
                        width: Theme.monitorR * 4
                        height: Theme.monitorR * 4
                        radius: Theme.monitorR * 2
                        x: -(Theme.monitorR * 3)
                        y: -Theme.monitorR
                        color: "transparent"
                        border.color: "#000000"
                        border.width: Theme.monitorR
                    }
                }

                // 3. Abajo-Izquierda
                Item {
                    anchors.bottom: parent.bottom
                    anchors.left: parent.left
                    width: Theme.monitorR
                    height: Theme.monitorR
                    clip: true
                    
                    Rectangle {
                        width: Theme.monitorR * 4
                        height: Theme.monitorR * 4
                        radius: Theme.monitorR * 2
                        x: -Theme.monitorR
                        y: -(Theme.monitorR * 3)
                        color: "transparent"
                        border.color: "#000000"
                        border.width: Theme.monitorR
                    }
                }

                // 4. Abajo-Derecha
                Item {
                    anchors.bottom: parent.bottom
                    anchors.right: parent.right
                    width: Theme.monitorR
                    height: Theme.monitorR
                    clip: true
                    
                    Rectangle {
                        width: Theme.monitorR * 4
                        height: Theme.monitorR * 4
                        radius: Theme.monitorR * 2
                        x: -(Theme.monitorR * 3)
                        y: -(Theme.monitorR * 3)
                        color: "transparent"
                        border.color: "#000000"
                        border.width: Theme.monitorR
                    }
                }
            }
        }
    }
}
