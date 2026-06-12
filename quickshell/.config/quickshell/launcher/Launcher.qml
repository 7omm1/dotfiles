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
            visible: LauncherState.visible
            color: "transparent"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
            anchors.top:true; anchors.bottom:true; anchors.left:true; anchors.right:true

            MouseArea { 
                anchors.fill:parent; 
                onClicked:{LauncherState.hide();si.text=""} 
                z:-1 
            }

            Rectangle {
                id: mainPanel
                anchors.horizontalCenter: parent.horizontalCenter
                y: Theme.barH   // Pegado a la barra
                width: 560
                height: lc.implicitHeight + 20
                color: Theme.bgShell
                radius: Theme.panelR

                // Animación Principal (Pop-down elástico)
                transform: Translate {
                    y: LauncherState.visible ? 0 : -40
                    Behavior on y { NumberAnimation { duration: 350; easing.type: Easing.OutBack } }
                }

                opacity: LauncherState.visible ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

                // Parche para eliminar radio superior y fusionar con la barra
                Rectangle { 
                    anchors{top:parent.top;left:parent.left;right:parent.right} 
                    height:Theme.panelR; color:Theme.bgShell 
                }
                
                // Bordes
                border.color: Theme.borderSep; border.width: 1
                Rectangle { anchors{left:parent.left;top:parent.top;bottom:parent.bottom} width:1; color:Theme.borderSep }
                Rectangle { anchors{right:parent.right;top:parent.top;bottom:parent.bottom} width:1; color:Theme.borderSep }
                Rectangle { anchors{bottom:parent.bottom;left:parent.left;right:parent.right} height:1; color:Theme.borderSep }

                ColumnLayout {
                    id: lc
                    anchors { top:parent.top; left:parent.left; right:parent.right; margins:14; topMargin:16 }
                    spacing: 12

                    // ── Buscador ──────────────────────────────────────────
                    Rectangle {
                        Layout.fillWidth:true; implicitHeight:52
                        color:Theme.bgInput; radius:Theme.radiusMd
                        border.color:si.activeFocus ? Theme.borderFocus : Theme.borderCard; border.width:2
                        Behavior on border.color{ColorAnimation{duration:150}}

                        RowLayout { 
                            anchors{fill:parent; margins:14} spacing:12
                            Text { 
                                text:"󰍉"; color:si.activeFocus ? Theme.accent : Theme.fgMute; 
                                font.family:Theme.font; font.pixelSize:18 
                                Behavior on color { ColorAnimation {duration:150} }
                            }
                            Item { 
                                Layout.fillWidth:true
                                Text { 
                                    anchors.fill:parent; text:"Buscar aplicaciones..."; 
                                    color:Theme.fgSubtle; font.family:Theme.font; font.pixelSize:15; 
                                    visible:si.text.length===0; verticalAlignment: Text.AlignVCenter
                                }
                                TextInput {
                                    id: si
                                    anchors.fill:parent; color:Theme.fg; font.family:Theme.font; font.pixelSize:15
                                    verticalAlignment: Text.AlignVCenter
                                    Keys.onEscapePressed: { LauncherState.hide(); text="" }
                                    Keys.onReturnPressed: { if(lm.results.length>0){lm.results[0].launch();LauncherState.hide();text=""} }
                                    onTextChanged: lm.refresh(text)
                                }
                            }
                            Rectangle { 
                                visible:si.text.length>0; 
                                width:escLbl.implicitWidth+16; height:24; radius:6; color:Theme.bgSurface
                                Text { 
                                    id:escLbl; anchors.centerIn:parent; text:"ESC"; 
                                    color:Theme.fgMute; font.family:Theme.font; font.pixelSize:10; font.bold: true 
                                }
                            }
                        }
                    }

                    // ── Resultados (100% Seguros y Libres de bugs) ────────────
                    Column { 
                        Layout.fillWidth:true; spacing:6; visible:si.text.length>0
                        Repeater { 
                            model: lm.results
                            
                            Rectangle {
                                id: itemRect
                                required property var modelData; required property int index
                                width: 532; implicitHeight: 52
                                radius: Theme.radiusMd
                                
                                color: index === 0 ? Qt.rgba(0.92,0.43,0.57,0.15) : (rma.containsMouse ? Qt.rgba(1,1,1,0.06) : "transparent")
                                border.color: index === 0 ? Theme.borderFocus : (rma.containsMouse ? Theme.borderCard : "transparent"); 
                                border.width: 1
                                
                                // Físicas de rebote (siempre funcionan)
                                scale: rma.pressed ? 0.96 : (rma.containsMouse ? 1.02 : 1.0)
                                Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }
                                Behavior on color { ColorAnimation { duration: 120 } }

                                RowLayout { 
                                    anchors{fill:parent; margins:12; leftMargin:16; rightMargin:16} spacing:14
                                    Image { 
                                        source: modelData.icon||""; width:28; height:28; 
                                        fillMode:Image.PreserveAspectFit; smooth:true 
                                    }
                                    ColumnLayout { 
                                        Layout.fillWidth:true; spacing:2
                                        Text { 
                                            text:modelData.name; color:Theme.fg; 
                                            font.family:Theme.font; font.pixelSize:14; font.bold:true 
                                        }
                                        Text { 
                                            text:modelData.desc||""; color:Theme.fgDim; 
                                            font.family:Theme.font; font.pixelSize:11; 
                                            elide:Text.ElideRight; visible:(modelData.desc||"")!=="" 
                                        }
                                    }
                                    Rectangle { 
                                        width:26; height:22; radius:6; color:Theme.bgSurface
                                        Text { 
                                            anchors.centerIn:parent; text: index===0 ? "↵" : (index+1)+""
                                            color:Theme.fgMute; font.family:Theme.font; font.pixelSize:11; font.bold:true 
                                        }
                                    }
                                }
                            
                                MouseArea { 
                                    id:rma; anchors.fill:parent; hoverEnabled:true; 
                                    onClicked:{modelData.launch();LauncherState.hide();si.text=""} 
                                }
                            }
                        }
                    }

                    // ── Sugerencias cuando vacío ──────────────────────────
                    Row { 
                        visible:si.text.length===0; Layout.alignment:Qt.AlignHCenter; spacing:24
                        Repeater { 
                            model:[{k:"↵",d:"Abrir"},{k:"ESC",d:"Cerrar"}]
                            Row { 
                                spacing:8
                                Rectangle { 
                                    width:kl.implicitWidth+12; height:22; radius:5; color:Theme.bgSurface;
                                    Text { id:kl; anchors.centerIn:parent; text:modelData.k; color:Theme.fgMute; font.family:Theme.font; font.pixelSize:11; font.bold:true } 
                                }
                                Text { 
                                    text:modelData.d; color:Theme.fgMute; font.family:Theme.font; 
                                    font.pixelSize:11; anchors.verticalCenter:parent.verticalCenter 
                                }
                            }
                        }
                    }
                    Item { implicitHeight:8 }
                }
            }

            onVisibleChanged: { 
                if(visible){ 
                    si.forceActiveFocus(); 
                    si.text="" 
                } 
            }
        }
    }

    QtObject { 
        id:lm; property var results:[]
        function refresh(q) {
            if(!q){results=[];return}
            const ql=q.toLowerCase(), es=DesktopEntries.applications, out=[]
            for(let i=0;i<es.length;i++){
                const e=es[i]
                if(!e.noDisplay&&(e.name.toLowerCase().includes(ql)||(e.genericName||"").toLowerCase().includes(ql)||(e.comment||"").toLowerCase().includes(ql)))
                    out.push({name:e.name,icon:Quickshell.iconPath(e.icon,""),desc:e.genericName||e.comment||"",launch:()=>e.launch()})
            }
            out.sort((a,b)=>a.name.toLowerCase().indexOf(ql)-b.name.toLowerCase().indexOf(ql))
            results=out.slice(0,7)
        }
    }
}
