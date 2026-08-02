pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    // FONDOS: Negro Absoluto y tarjetas oscuras
    property color bgShell:     "#000000" 
    property color bgCard:      "#0a0a0a" 
    property color bgCardHover: "#141414" 
    property color bgInput:     "#0a0a0a"
    property color bgSurface:   "#141414"
    
    // TEXTOS: Blancos nítidos de alto contraste
    property color fg:          "#ffffff"
    property color fgDim:       "#a1a1aa"
    property color fgMute:      "#71717a"
    property color fgSubtle:    "#3f3f46"
    
    // ACENTOS: Monocromáticos limpios
    property color accent:      "#ffffff"
    property color gold:        "#ffffff"
    property color rose:        "#ffffff"
    property color pine:        "#ffffff"
    property color foam:        "#a1a1aa" 
    property color iris:        "#d4d4d8" 
    property color love:        "#ffffff" 
    
    // BORDES: Minimalistas
    property color border:      "transparent"
    property color borderSep:   "transparent" 
    property color borderCard:  "#27272a"
    property color borderFocus: "#ffffff"

    // CONSTANTES DE DISEÑO
    readonly property int   radiusSm:    8
    readonly property int   radiusMd:    14
    readonly property int   radiusLg:    20
    readonly property int   radiusXl:    26
    readonly property int   panelR:      24
    readonly property string font:       "JetBrainsMono Nerd Font"
    readonly property int   barH:        40
    
    readonly property int   monitorR:    30 
}
