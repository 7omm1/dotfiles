pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    // Valores por defecto (Rose Pine Style)
    property color bgShell:     "#1e1b2e"
    property color bgCard:      "#2a273f"
    property color bgCardHover: "#302d47"
    property color bgInput:     "#232136"
    property color bgSurface:   "#393552"
    property color fg:          "#e0def4"
    property color fgDim:       "#908caa"
    property color fgMute:      "#6e6a86"
    property color fgSubtle:    "#44415a"
    property color accent:      "#eb6f92"
    property color gold:        "#f6c177"
    property color rose:        "#ea9a97"
    property color pine:        "#3e8fb0"
    property color foam:        "#9ccfd8"
    property color iris:        "#c4a7e7"
    property color love:        "#eb6f92"
    property color border:      "#2a273f"
    property color borderSep:   "#302d47"
    property color borderCard:  "#332e4a"
    property color borderFocus: "#eb6f92"

    // Constantes de diseño
    readonly property int   radiusSm:    8
    readonly property int   radiusMd:    14
    readonly property int   radiusLg:    20
    readonly property int   radiusXl:    26
    readonly property int   panelR:      24
    readonly property string font:       "JetBrainsMono Nerd Font"
    readonly property int   barH:        40
    
    // 🔴 EFECTO CAELESTIA: Tamaño de la curva del monitor
    readonly property int   monitorR:    30 

    // Cargador de Pywal intacto
    Process {
        id: loader
        command: ["bash", "-c", "cat ~/.cache/wal/colors.json"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const data = JSON.parse(this.text);
                    const colors = data.colors;
                    const special = data.special;

                    root.bgShell     = special.background;
                    root.fg          = special.foreground;
                    root.accent      = colors.color1;
                    root.love        = colors.color1;
                    root.gold        = colors.color3;
                    root.rose        = colors.color5;
                    root.pine        = colors.color4;
                    root.foam        = colors.color6;
                    root.iris        = colors.color13;
                    root.bgCard      = Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.05);
                    root.bgCardHover = Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.1);
                    root.bgSurface   = Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.15);
                    root.border      = Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.3);
                    root.borderSep   = Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.1);
                    root.borderCard  = Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.08);
                    root.borderFocus = Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.5);
                    root.fgDim       = Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.6);
                    root.fgMute      = Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.4);
                } catch(e) { }
            }
        }
    }
    
    // CORRECCIÓN DEL ERROR DE CONSOLA: Se usa 'loader.running = true'
    Timer { 
        interval: 5000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: loader.running = true 
    }
}
