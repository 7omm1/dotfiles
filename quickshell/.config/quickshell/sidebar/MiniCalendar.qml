import QtQuick
import QtQuick.Layouts
import "../services"
Item {
    id: root
    implicitHeight: c.implicitHeight
    property int yr: new Date().getFullYear()
    property int mo: new Date().getMonth()
    property int td: new Date().getDate()
    function dim(y,m){return new Date(y,m+1,0).getDate()}
    function fd(y,m){return new Date(y,m,1).getDay()}
    ColumnLayout { id:c; anchors{left:parent.left;right:parent.right} spacing:8
        RowLayout { Layout.fillWidth:true
            Rectangle { width:24;height:24;radius:7;color:pm.containsMouse?Qt.rgba(1,1,1,0.08):"transparent"; Text{anchors.centerIn:parent;text:"";color:Theme.fgDim;font.family:Theme.font;font.pixelSize:11} MouseArea{id:pm;anchors.fill:parent;hoverEnabled:true;onClicked:{root.mo--;if(root.mo<0){root.mo=11;root.yr--}}} }
            Text { Layout.fillWidth:true; text:Qt.locale("es_ES").monthName(root.mo,Locale.LongFormat)+" "+root.yr; color:Theme.fg; font.family:Theme.font; font.pixelSize:12; font.bold:true; horizontalAlignment:Text.AlignHCenter }
            Rectangle { width:24;height:24;radius:7;color:nm.containsMouse?Qt.rgba(1,1,1,0.08):"transparent"; Text{anchors.centerIn:parent;text:"";color:Theme.fgDim;font.family:Theme.font;font.pixelSize:11} MouseArea{id:nm;anchors.fill:parent;hoverEnabled:true;onClicked:{root.mo++;if(root.mo>11){root.mo=0;root.yr++}}} }
        }
        Row { Layout.fillWidth:true; spacing:0; Repeater{model:["D","L","M","X","J","V","S"]; Text{width:(root.width)/7;text:modelData;color:Theme.fgMute;font.family:Theme.font;font.pixelSize:10;font.bold:true;horizontalAlignment:Text.AlignHCenter}} }
        Grid { Layout.fillWidth:true; columns:7; spacing:0
            property int off: root.fd(root.yr,root.mo)
            Repeater { model: parent.off + root.dim(root.yr,root.mo)
                Rectangle {
                    property int d: index-parent.parent.off+1
                    property bool isToday: d===root.td && root.mo===new Date().getMonth() && root.yr===new Date().getFullYear()
                    property bool empty: index < parent.parent.off
                    width:root.width/7; height:28; radius:7
                    color:isToday?Theme.accent:"transparent"
                    Text { anchors.centerIn:parent; text:parent.empty?"":parent.d; color:parent.isToday?"#1e1b2e":Theme.fgDim; font.family:Theme.font; font.pixelSize:11; font.bold:parent.isToday }
                }
            }
        }
    }
}
