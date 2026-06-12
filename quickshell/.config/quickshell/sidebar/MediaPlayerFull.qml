import Quickshell.Services.Mpris
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import "../services"

Item {
    id: root
    property var  player: Mpris.players.length > 0 ? Mpris.players[0] : null
    property bool showLyrics: false
    property string lyricsText: "Presiona 󰍬 para buscar letras..."
    implicitHeight: body.implicitHeight

    ColumnLayout {
        id: body
        anchors { left:parent.left; right:parent.right }
        spacing: 12

        // ── Carátula + info + controles ──
        RowLayout { spacing:14; Layout.fillWidth:true

            // Carátula
            Rectangle {
                width:100; height:100; radius:Theme.radiusMd
                color:Qt.rgba(1,1,1,0.04); border.color:Theme.borderCard; border.width:1; clip:true
                Image { anchors.fill:parent; source:root.player?.trackArtUrl??""; fillMode:Image.PreserveAspectCrop; smooth:true }
                Text { anchors.centerIn:parent; text:"󰝚"; color:Qt.rgba(1,1,1,0.12); font.family:Theme.font; font.pixelSize:38
                    visible:!root.player || root.player.trackArtUrl==="" }
            }

            ColumnLayout { Layout.fillWidth:true; spacing:8

                RowLayout { Layout.fillWidth:true
                    ColumnLayout { Layout.fillWidth:true; spacing:3
                        Text { text:root.player?.trackTitle??"Silencio"; color:Theme.fg; font.family:Theme.font; font.pixelSize:14; font.bold:true; elide:Text.ElideRight; Layout.fillWidth:true }
                        Text { text:root.player ? (root.player.trackArtists.join(", ")||"—") : "—"; color:Theme.fgDim; font.family:Theme.font; font.pixelSize:11; elide:Text.ElideRight; Layout.fillWidth:true }
                    }
                    Rectangle { width:26; height:26; radius:7; color:root.showLyrics?Qt.rgba(0.77,0.65,0.91,0.18):Qt.rgba(1,1,1,0.05); border.color:root.showLyrics?Theme.borderFocus:Theme.borderCard; border.width:1
                        Text { anchors.centerIn:parent; text:"󰍬"; color:root.showLyrics?Theme.iris:Theme.fgMute; font.family:Theme.font; font.pixelSize:13 }
                        MouseArea { anchors.fill:parent; onClicked: { root.showLyrics=!root.showLyrics; if(root.showLyrics)root.fetchLyrics() } }
                    }
                }

                // Controles
                RowLayout { spacing:8
                    MCtrl { icon:"󰒮"; onP:() => { if(root.player) root.player.previous() } }
                    MCtrl { icon:root.player?.playbackState===MprisPlaybackState.Playing?"󰏤":"󰐊"; big:true; onP:() => { if(root.player) root.player.playPause() } }
                    MCtrl { icon:"󰒭"; onP:() => { if(root.player) root.player.next() } }
                }

                // Progress
                ColumnLayout { Layout.fillWidth:true; spacing:4
                    Rectangle { Layout.fillWidth:true; implicitHeight:4; radius:2; color:Qt.rgba(1,1,1,0.08)
                        Rectangle { width:parent.width*Math.max(0,Math.min(1,(root.player?.length??0)>0?(root.player.position/root.player.length):0)); height:parent.height; radius:2; color:Theme.accent; Behavior on width{NumberAnimation{duration:400}} } }
                    RowLayout {
                        Text { text:fmt(root.player?.position??0); color:Theme.accent; font.family:Theme.font; font.pixelSize:9; font.bold:true }
                        Item { Layout.fillWidth:true }
                        Text { text:fmt(root.player?.length??0); color:Theme.fgMute; font.family:Theme.font; font.pixelSize:9 }
                    }
                }
            }
        }

        // ── Letras ──
        Item {
            visible: root.showLyrics
            Layout.fillWidth:true; implicitHeight:180
            Rectangle { anchors{top:parent.top;left:parent.left;right:parent.right} height:1; color:Theme.borderCard }
            Flickable {
                anchors{fill:parent;topMargin:8} contentHeight:ltxt.contentHeight; clip:true
                Text { id:ltxt; width:parent.width; text:root.lyricsText; color:Theme.fgDim; font.family:Theme.font; font.pixelSize:12; wrapMode:Text.WordWrap; horizontalAlignment:Text.AlignHCenter; lineHeight:1.7 }
            }
        }
    }

    function fmt(s) { if(!s||s<=0)return"0:00"; return Math.floor(s/60)+":"+String(Math.floor(s%60)).padStart(2,"0") }
    function fetchLyrics() {
        const t=encodeURIComponent(root.player?.trackTitle??""), a=encodeURIComponent(root.player?.trackArtists[0]??"")
        root.lyricsText="Buscando..."
        lp.command=["bash","-c","curl -s \"https://lrclib.net/api/get?track_name="+t+"&artist_name="+a+"\""]
        lp.running=true
    }
    Process { id:lp; stdout:StdioCollector { onStreamFinished: {
        try { const d=JSON.parse(this.text); if(d.plainLyrics)root.lyricsText=d.plainLyrics; else if(d.syncedLyrics)root.lyricsText=d.syncedLyrics.replace(/\[\d{2}:\d{2}\.\d{2}\]/g,""); else root.lyricsText="No se encontraron letras." } catch(e){root.lyricsText="Error."} } } }
}
