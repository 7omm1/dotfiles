pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick
Singleton {
    id: root
    property int    cpu:      0
    property int    ram:      0
    property int    gpu:      0
    property int    cpuTemp:  0
    property bool   hasGpu:   false
    property string netSpeed: "0 KB/s"
    property string uptime:   "—"
    property string username: "user"
    property string hostname: "arch"
    property string kernel:   "—"
    property string pkgs:     "0"
    property real   _rx:  0
    property real   _rt:  0
    Process { id: p_cpu; command: ["bash","-c","LC_ALL=C top -bn1 | grep 'Cpu(s)' | awk '{print $2+$4}'"]; stdout: StdioCollector { onStreamFinished: root.cpu = Math.min(100,Math.round(parseFloat(this.text)||0)) } }
    Process { id: p_ram; command: ["bash","-c","free | awk '/Mem/{printf \"%.0f\",$3/$2*100}'"]; stdout: StdioCollector { onStreamFinished: root.ram = Math.min(100,parseInt(this.text)||0) } }
    Process { id: p_gpu; command: ["bash","-c","nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits 2>/dev/null | head -1"]; stdout: StdioCollector { onStreamFinished: { const v=parseInt(this.text.trim()); if(!isNaN(v)){root.gpu=v;root.hasGpu=true} } } }
    Process { id: p_tmp; command: ["bash","-c","cat /sys/class/thermal/thermal_zone*/temp 2>/dev/null | sort -n | tail -1"]; stdout: StdioCollector { onStreamFinished: root.cpuTemp = Math.round((parseInt(this.text.trim())||0)/1000) } }
    Process { id: p_net; command: ["bash","-c","cat /sys/class/net/[ew]*/statistics/rx_bytes 2>/dev/null | awk '{s+=$1}END{print s+0}'"]; stdout: StdioCollector { onStreamFinished: { const rx=parseFloat(this.text.trim())||0,now=Date.now()/1000; if(root._rx>0&&rx>=root._rx){const k=((rx-root._rx)/(now-root._rt))/1024; root.netSpeed=k>1024?(k/1024).toFixed(1)+" MB/s":Math.floor(k)+" KB/s"} root._rx=rx;root._rt=now } } }
    Process { id: p_up; command: ["uptime","-p"]; stdout: StdioCollector { onStreamFinished: root.uptime=this.text.trim().replace(/^up /,"").replace(/ minutes?/,"m").replace(/ hours?/,"h").replace(/ days?/,"d") } }
    Process { id: p_who; command: ["whoami"]; running:true; stdout: StdioCollector { onStreamFinished: root.username=this.text.trim() } }
    Process { id: p_hst; command: ["bash", "-c", "hostname"]; running: true; stdout: StdioCollector { onStreamFinished: root.hostname = this.text.trim() } }
    Process { id: p_ker; command: ["uname","-r"]; running:true; stdout: StdioCollector { onStreamFinished: root.kernel=this.text.trim().replace(/-arch.*/,"-arch") } }
    Process { id: p_pkg; command: ["bash","-c","pacman -Qq 2>/dev/null | wc -l || echo 0"]; running:true; stdout: StdioCollector { onStreamFinished: root.pkgs=this.text.trim() } }
    Timer { interval:2000; running:true; repeat:true; onTriggered: { p_cpu.running=true; p_ram.running=true; p_gpu.running=true; p_net.running=true; p_tmp.running=true } }
    Timer { interval:60000; running:true; repeat:true; triggeredOnStart:true; onTriggered: p_up.running=true }
}
