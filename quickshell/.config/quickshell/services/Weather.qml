pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick
Singleton {
    id: root
    property string emoji: "󰖙"
    property string temp:  "--°C"
    property string desc:  ""
    function emo(d) {
        d=(d||"").toLowerCase()
        if(d.includes("sunny")||d.includes("clear"))return "󰖙"
        if(d.includes("partly"))return "󰖕"
        if(d.includes("cloudy")||d.includes("overcast"))return "󰖐"
        if(d.includes("rain")||d.includes("drizzle"))return "󰖗"
        if(d.includes("thunder"))return "󰖓"
        if(d.includes("snow"))return "󰼶"
        if(d.includes("fog")||d.includes("mist"))return "󰖑"
        return "󰖔"
    }
    Process { id: wp; command: ["bash","-c","curl -s --max-time 10 'wttr.in/Cusco,Peru?format=j1' 2>/dev/null"]
        stdout: StdioCollector { onStreamFinished: { try { const d=JSON.parse(this.text),c=d?.current_condition?.[0]; if(c){root.temp=c.temp_C+"°C";root.desc=c.weatherDesc?.[0]?.value||"";root.emoji=root.emo(root.desc)} } catch(e){} } } }
    Timer { interval:1200000; running:true; repeat:true; triggeredOnStart:true; onTriggered: wp.running=true }
}
