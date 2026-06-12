pragma Singleton
import Quickshell
import QtQuick
Singleton {
    readonly property string time:     Qt.formatDateTime(clk.date, "HH:mm")
    readonly property string timeFull: Qt.formatDateTime(clk.date, "HH:mm:ss")
    readonly property string day:      Qt.formatDateTime(clk.date, "dddd")
    readonly property string date:     Qt.formatDateTime(clk.date, "dd MMM yyyy")
    readonly property string dayShort: Qt.formatDateTime(clk.date, "ddd dd MMM")
    readonly property int    hour:     clk.date.getHours()
    SystemClock { id: clk; precision: SystemClock.Seconds }
}
