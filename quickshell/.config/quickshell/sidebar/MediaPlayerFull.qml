import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import "../services"

Item {
    id: root
    
    // --- VARIABLES MANUALES ---
    property bool hasPlayer: false
    property string activePlayer: "" // Guardamos el nombre exacto del reproductor
    property string trackTitle: "Silencio"
    property string trackArtist: "—"
    property string trackArt: ""
    property bool isPlaying: false
    property real position: 0
    property real length: 0

    property bool showLyrics: false
    property string lyricsText: "Presiona 󰍬 para buscar letras..."
    implicitHeight: body.implicitHeight

    // EL MOTOR INTELIGENTE: Escanea cada segundo buscando quién está haciendo ruido
    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: playerctlProc.running = true
    }

    Process {
        id: playerctlProc
        // 1. Busca el reproductor en estado 'Playing'. Si no hay, agarra el primero.
        // 2. Extrae la info solo de ESE reproductor específico.
        command: [
            "bash", "-c", 
            "ACT=$(playerctl -l 2>/dev/null | while read p; do if [ \"$(playerctl -p $p status 2>/dev/null)\" = 'Playing' ]; then echo $p; break; fi; done); if [ -z \"$ACT\" ]; then ACT=$(playerctl -l 2>/dev/null | head -n 1); fi; if [ -z \"$ACT\" ]; then echo 'NONE'; else INFO=$(playerctl -p $ACT metadata --format '{{title}}|~|{{artist}}|~|{{mpris:artUrl}}|~|{{status}}|~|{{mpris:length}}|~|{{xesam:url}}' 2>/dev/null); POS=$(playerctl -p $ACT position 2>/dev/null || echo '0'); echo \"${ACT}|~|${INFO}|~|${POS}\"; fi"
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                const res = this.text.trim();
                if (res === "" || res === "NONE") {
                    root.hasPlayer = false;
                    root.activePlayer = "";
                    root.trackTitle = "Silencio";
                    root.trackArtist = "—";
                    root.trackArt = "";
                    root.position = 0;
                    root.length = 0;
                    return;
                }
                
                root.hasPlayer = true;
                const parts = res.split("|~|");
                
                root.activePlayer = parts[0] || "";
                root.trackTitle = parts[1] || "Desconocido";
                root.trackArtist = parts[2] || "—";
                let rawArt = parts[3] || "";
                root.isPlaying = parts[4] === "Playing";
                
                const lenMicro = parseFloat(parts[5]) || 0;
                const trackUrl = parts[6] || "";
                const posSec = parseFloat(parts[7]) || 0; 
                
                root.length = lenMicro / 1000000.0;
                root.position = posSec;

                // 1. FIX DE RUTAS LOCALES
                if (rawArt.startsWith("/")) {
                    rawArt = "file://" + rawArt;
                }
                
                // 2. URL ENCODING PARA ARCHIVOS LOCALES
                if (rawArt.startsWith("file://") && rawArt.includes(" ")) {
                    rawArt = rawArt.replace(/ /g, "%20");
                }

                // 3. MAGIA DE YOUTUBE
                if (rawArt === "" && trackUrl.includes("youtube.com/watch")) {
                    const vidMatch = trackUrl.match(/[?&]v=([^&]+)/);
                    if (vidMatch && vidMatch[1]) rawArt = "https://i.ytimg.com/vi/" + vidMatch[1] + "/hqdefault.jpg";
                } else if (rawArt === "" && trackUrl.includes("youtu.be/")) {
                    const vidMatch = trackUrl.match(/youtu\.be\/([^?]+)/);
                    if (vidMatch && vidMatch[1]) rawArt = "https://i.ytimg.com/vi/" + vidMatch[1] + "/hqdefault.jpg";
                }

                root.trackArt = rawArt;
            }
        }
    }

    ColumnLayout {
        id: body
        anchors { left:parent.left; right:parent.right }
        spacing: 12

        RowLayout { spacing:14; Layout.fillWidth:true

            // ── CARÁTULA CON BORDES CURVOS ──
            Item {
                width: 100; height: 100
                
                Image { 
                    id: artImg
                    anchors.fill: parent; 
                    source: root.trackArt
                    fillMode: Image.PreserveAspectCrop; 
                    smooth: true 
                    visible: false 
                }
                
                Rectangle {
                    id: artMask
                    anchors.fill: parent
                    radius: Theme.radiusMd
                    color: "black"
                    visible: false 
                }
                
                OpacityMask {
                    anchors.fill: parent
                    source: artImg
                    maskSource: artMask
                    visible: artImg.status === Image.Ready
                }

                Rectangle {
                    anchors.fill: parent
                    radius: Theme.radiusMd
                    color: artImg.status !== Image.Ready ? Qt.rgba(1,1,1,0.04) : "transparent"
                    border.color: Theme.borderCard
                    border.width: 1
                    
                    Text { 
                        anchors.centerIn: parent; text: "󰝚"; color: Qt.rgba(1,1,1,0.12)
                        font.family: Theme.font; font.pixelSize: 38
                        visible: artImg.status !== Image.Ready
                    }
                }
            }

            ColumnLayout { Layout.fillWidth:true; spacing:8

                RowLayout { Layout.fillWidth:true
                    ColumnLayout { Layout.fillWidth:true; spacing:3
                        Text { text:root.trackTitle; color:Theme.fg; font.family:Theme.font; font.pixelSize:14; font.bold:true; elide:Text.ElideRight; Layout.fillWidth:true }
                        Text { text:root.trackArtist; color:Theme.fgDim; font.family:Theme.font; font.pixelSize:11; elide:Text.ElideRight; Layout.fillWidth:true }
                    }
                    Rectangle { width:26; height:26; radius:7; color:root.showLyrics?Qt.rgba(0.77,0.65,0.91,0.18):Qt.rgba(1,1,1,0.05); border.color:root.showLyrics?Theme.borderFocus:Theme.borderCard; border.width:1
                        Text { anchors.centerIn:parent; text:"󰍬"; color:root.showLyrics?Theme.iris:Theme.fgMute; font.family:Theme.font; font.pixelSize:13 }
                        MouseArea { anchors.fill:parent; onClicked: { root.showLyrics=!root.showLyrics; if(root.showLyrics)root.fetchLyrics() } }
                    }
                }

                // ── CONTROLES ANCLADOS AL REPRODUCTOR ACTIVO ──
                RowLayout { spacing:8
                    MCtrl { icon:"󰒮"; onP:() => { runCmd("playerctl -p " + root.activePlayer + " previous") } }
                    MCtrl { icon:root.isPlaying ? "󰏤" : "󰐊"; big:true; onP:() => { runCmd("playerctl -p " + root.activePlayer + " play-pause") } }
                    MCtrl { icon:"󰒭"; onP:() => { runCmd("playerctl -p " + root.activePlayer + " next") } }
                }

                // Progress
                ColumnLayout { Layout.fillWidth:true; spacing:4
                    Rectangle { Layout.fillWidth:true; implicitHeight:4; radius:2; color:Qt.rgba(1,1,1,0.08)
                        Rectangle { 
                            width: parent.width * Math.max(0, Math.min(1, root.length > 0 ? (root.position / root.length) : 0)); 
                            height: parent.height; radius:2; color:Theme.accent; 
                            Behavior on width { NumberAnimation { duration:400 } } 
                        } 
                    }
                    RowLayout {
                        Text { text:fmt(root.position); color:Theme.accent; font.family:Theme.font; font.pixelSize:9; font.bold:true }
                        Item { Layout.fillWidth:true }
                        Text { text:fmt(root.length); color:Theme.fgMute; font.family:Theme.font; font.pixelSize:9 }
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

    function runCmd(cmd) {
        if (root.activePlayer === "") return;
        const p = Qt.createQmlObject('import Quickshell.Io; Process {}', root);
        p.command = ["bash", "-c", cmd];
        p.running = true;
    }

    function fmt(sec) { 
        if(!sec||sec<=0) return"0:00"; 
        return Math.floor(sec/60)+":"+String(Math.floor(sec%60)).padStart(2,"0") 
    }

    function fetchLyrics() {
        if (!root.hasPlayer) return;
        const t=encodeURIComponent(root.trackTitle), a=encodeURIComponent(root.trackArtist)
        root.lyricsText="Buscando..."
        lp.command=["bash","-c","curl -s \"https://lrclib.net/api/get?track_name="+t+"&artist_name="+a+"\""]
        lp.running=true
    }
    
    Process { id:lp; stdout:StdioCollector { onStreamFinished: {
        try { 
            const d=JSON.parse(this.text); 
            if(d.plainLyrics) root.lyricsText=d.plainLyrics; 
            else if(d.syncedLyrics) root.lyricsText=d.syncedLyrics.replace(/\[\d{2}:\d{2}\.\d{2}\]/g,""); 
            else root.lyricsText="No se encontraron letras." 
        } catch(e) { root.lyricsText="Error." } 
    } } }
}
