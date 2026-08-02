import QtQuick
import QtQuick.Layouts
import "../services"

Item {
    id: root
    implicitHeight: mainLayout.implicitHeight
    implicitWidth: 340 // Un poco más ancho para dar respiro a la UI

    property int yr: new Date().getFullYear()
    property int mo: new Date().getMonth()
    property int td: new Date().getDate()

    // Funciones matemáticas limpias para fechas
    function getDaysInMonth(year, month) { return new Date(year, month + 1, 0).getDate(); }
    function getFirstDay(year, month) { return new Date(year, month, 1).getDay(); }
    function getDaysInPrevMonth(year, month) { return new Date(year, month, 0).getDate(); }

    ColumnLayout {
        id: mainLayout
        anchors { left: parent.left; right: parent.right }
        spacing: 16

        // ── HEADER DEL CALENDARIO ──
        RowLayout {
            Layout.fillWidth: true
            spacing: 14
            
            // Tarjeta del día actual
            Rectangle {
                width: 68; height: 68
                radius: Theme.radiusMd
                color: Qt.rgba(0.92, 0.43, 0.57, 0.12) // Tono sutil usando tus colores base
                border.color: Qt.rgba(0.92, 0.43, 0.57, 0.3)
                border.width: 1
                Column {
                    anchors.centerIn: parent
                    Text { 
                        text: Qt.locale("es_ES").dayName(new Date().getDay(), Locale.ShortFormat).toUpperCase()
                        color: Theme.accent; font.family: Theme.font; font.pixelSize: 11; font.bold: true
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                    Text { 
                        text: root.td
                        color: Theme.fg; font.family: Theme.font; font.pixelSize: 28; font.bold: true
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                }
            }

            // Controles de navegación y Ubicación
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4
                
                Text { 
                    text: "Cusco, PE" 
                    color: Theme.fgMute; font.family: Theme.font; font.pixelSize: 11; font.bold: true
                    leftPadding: 6
                }

                RowLayout {
                    Layout.fillWidth: true
                    Rectangle { 
                        width: 30; height: 30; radius: 8
                        color: pm.containsMouse ? Qt.rgba(1,1,1,0.08) : "transparent"
                        Text { anchors.centerIn: parent; text: "󰅁"; color: Theme.fgDim; font.family: Theme.font; font.pixelSize: 18 }
                        MouseArea { id: pm; anchors.fill: parent; hoverEnabled: true; onClicked: { root.mo--; if(root.mo < 0){ root.mo = 11; root.yr--; } } } 
                    }
                    
                    Text { 
                        Layout.fillWidth: true
                        text: (Qt.locale("es_ES").monthName(root.mo, Locale.LongFormat) + " " + root.yr).toUpperCase()
                        color: Theme.fg; font.family: Theme.font; font.pixelSize: 13; font.bold: true
                        horizontalAlignment: Text.AlignHCenter 
                    }
                    
                    Rectangle { 
                        width: 30; height: 30; radius: 8
                        color: nm.containsMouse ? Qt.rgba(1,1,1,0.08) : "transparent"
                        Text { anchors.centerIn: parent; text: "󰅂"; color: Theme.fgDim; font.family: Theme.font; font.pixelSize: 18 }
                        MouseArea { id: nm; anchors.fill: parent; hoverEnabled: true; onClicked: { root.mo++; if(root.mo > 11){ root.mo = 0; root.yr++; } } } 
                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true; height: 1; color: Theme.borderSep
        }

        // ── DÍAS DE LA SEMANA ──
        Row { 
            Layout.fillWidth: true; spacing: 0
            Repeater {
                model: ["Do", "Lu", "Ma", "Mi", "Ju", "Vi", "Sa"]
                Text { 
                    width: root.width / 7; text: modelData
                    // Los fines de semana tienen un sutil toque rojizo
                    color: (index === 0 || index === 6) ? Qt.rgba(0.92, 0.43, 0.57, 0.9) : Theme.fgMute
                    font.family: Theme.font; font.pixelSize: 11; font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                }
            } 
        }

        // ── CUADRÍCULA DE DÍAS (42 celdas siempre fijas) ──
        Grid { 
            id: calGrid
            Layout.fillWidth: true; columns: 7; spacing: 0
            
            property int firstDay: root.getFirstDay(root.yr, root.mo)
            property int daysInMonth: root.getDaysInMonth(root.yr, root.mo)
            property int daysInPrevMonth: root.getDaysInPrevMonth(root.yr, root.mo)
            
            Repeater { 
                model: 42 
                Rectangle {
                    property int dayNum: index - calGrid.firstDay + 1
                    property bool isPrevMonth: index < calGrid.firstDay
                    property bool isNextMonth: dayNum > calGrid.daysInMonth
                    property bool isCurrentMonth: !isPrevMonth && !isNextMonth
                    property bool isToday: isCurrentMonth && dayNum === root.td && root.mo === new Date().getMonth() && root.yr === new Date().getFullYear()
                    
                    // Lógica para renderizar los números de los meses adyacentes
                    property int displayNum: isPrevMonth ? (calGrid.daysInPrevMonth - calGrid.firstDay + index + 1) :
                                             isNextMonth ? (dayNum - calGrid.daysInMonth) : dayNum
                    
                    width: root.width / 7; height: 34; radius: 8
                    color: isToday ? Theme.accent : (ma.containsMouse && isCurrentMonth ? Qt.rgba(1,1,1,0.05) : "transparent")
                    
                    Text { 
                        anchors.centerIn: parent
                        text: parent.displayNum
                        // Cambio de color dinámico para los días que no son del mes
                        color: parent.isToday ? Theme.bgShell : (parent.isCurrentMonth ? Theme.fg : Theme.borderCard)
                        font.family: Theme.font; font.pixelSize: 12; font.bold: parent.isToday || parent.isCurrentMonth
                    }

                    // Pequeño indicador estético para "eventos" (se muestra en el día 16 y múltiplos de 7)
                    Rectangle {
                        visible: parent.isCurrentMonth && !parent.isToday && (parent.dayNum % 7 === 0 || parent.dayNum === 16)
                        width: 4; height: 4; radius: 2; color: Theme.foam
                        anchors { bottom: parent.bottom; bottomMargin: 4; horizontalCenter: parent.horizontalCenter }
                    }

                    MouseArea {
                        id: ma
                        anchors.fill: parent
                        hoverEnabled: parent.isCurrentMonth
                    }
                }
            }
        }
    }
}
