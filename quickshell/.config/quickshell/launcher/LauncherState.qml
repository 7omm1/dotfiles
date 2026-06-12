pragma Singleton
import Quickshell
import QtQuick
Singleton { property bool visible: false; function toggle() { visible=!visible } function show() { visible=true } function hide() { visible=false } }
