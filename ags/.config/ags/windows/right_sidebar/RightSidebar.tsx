import Gtk from "gi://Gtk?version=4.0"
import Gdk from "gi://Gdk?version=4.0"
import Astal from "gi://Astal?version=4.0"
import app from "ags/gtk4/app"
import GLib from "gi://GLib"
import { exec, execAsync } from "ags/process"
import { createBinding, createComputed, createState } from "gnim"
import AstalWp from "gi://AstalWp?version=0.1"

import { uptime, nightLightEnabled, doNotDisturb, setDoNotDisturb, setNightLightEnabled } from "@common/vars"
import { pathToURI } from "@common/functions"
import Brightness from "@utils/Brightness"

export let rightWin: Gtk.Window | null = null
const [isRightRevealed, setIsRightRevealed] = createState(false)
const [isRecording, setIsRecording] = createState(false)

export function toggleSidebar() {
    if (!rightWin) return
    if (isRightRevealed()) { setIsRightRevealed(false) } 
    else { rightWin.show(); setIsRightRevealed(true) }
}

// Anillo igual que el original pero con etiqueta debajo
function ResourceRing({ value, color, label }: { value: () => number, color: string, label: string }) {
    const ringCss = createComputed(() => `
        min-width: 52px; min-height: 52px; border-radius: 50%;
        background-image: conic-gradient(${color} ${value()}%, rgba(255,255,255,0.05) ${value()}%);
        padding: 5px;
    `)
    return <box orientation={Gtk.Orientation.VERTICAL} spacing={5} halign={Gtk.Align.CENTER}>
        <box css={ringCss} valign={Gtk.Align.CENTER} halign={Gtk.Align.CENTER}>
            <box css="background-color: rgba(15, 15, 20, 1); border-radius: 50%; min-width: 42px; min-height: 42px;"
                 valign={Gtk.Align.CENTER} halign={Gtk.Align.CENTER}>
                <label
                    label={createComputed(() => `${value()}%`)}
                    halign={Gtk.Align.CENTER}
                    css={`font-size: 10px; font-weight: 900; color: ${color};`}
                />
            </box>
        </box>
        <label
            label={label}
            halign={Gtk.Align.CENTER}
            css={`font-size: 9px; font-weight: 900; color: ${color}; letter-spacing: 1px;`}
        />
    </box>
}

export default function RightSidebar(monitor: Gdk.Monitor) {
    const [cpu, setCpu] = createState(0)
    const [ram, setRam] = createState(0)
    const [gpu, setGpu] = createState(0)
    
    GLib.timeout_add(GLib.PRIORITY_LOW, 2000, () => {
        execAsync(['bash', '-c', "top -bn1 | grep 'Cpu(s)' | awk '{print $2}'"])
            .then(o => setCpu(Math.round(Number(o)) || 0))
        execAsync(['bash', '-c', "free | grep Mem | awk '{print $3/$2 * 100.0}'"])
            .then(o => setRam(Math.round(Number(o)) || 0))
        execAsync(['bash', '-c', "nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits"])
            .then(o => setGpu(Math.round(Number(o)) || 0)).catch(() => {})
        return true
    })

    const speaker = AstalWp.get_default()?.audio?.defaultSpeaker!
    const brightness = Brightness.get_default()

    return <window 
        $={(self) => { 
            rightWin = self 
            const ctrl = new Gtk.EventControllerMotion()
            ctrl.connect("leave", () => { if (isRightRevealed()) toggleSidebar() })
            self.add_controller(ctrl)
        }} 
        name="RightSidebar" namespace="RightSidebar" application={app} visible={false} gdkmonitor={monitor} 
        anchor={Astal.WindowAnchor.TOP | Astal.WindowAnchor.RIGHT} 
        marginTop={15} marginRight={16}
    >
        <revealer
            revealChild={createComputed(() => isRightRevealed())}
            transitionType={Gtk.RevealerTransitionType.SLIDE_DOWN}
            $={(self) => { self.connect("notify::child-revealed", () => { if (!self.child_revealed && rightWin) rightWin.hide() }) }}
        >
            <box orientation={Gtk.Orientation.HORIZONTAL} spacing={15} cssClasses={["SidebarContainer"]} valign={Gtk.Align.START}>
                
                {/* COLUMNA 1: PERFIL Y ANILLOS */}
                <box orientation={Gtk.Orientation.VERTICAL} spacing={15} valign={Gtk.Align.FILL}>
                    <box cssClasses={["SidebarCard"]} spacing={12} widthRequest={180}>
                        <box widthRequest={40} heightRequest={40} css={`background-image: url('${pathToURI(GLib.get_user_config_dir() + "/ags/assets/tenma.jpg")}'); border-radius: 12px; background-size: cover;`} />
                        <box orientation={Gtk.Orientation.VERTICAL} valign={Gtk.Align.CENTER}>
                            <label label={exec("whoami")} halign={Gtk.Align.START} css="font-size: 14px; font-weight: 900; color: white;" />
                            <label label={uptime.as(u => `UP: ${u}`)} halign={Gtk.Align.START} css="font-size: 9px; color: #888;" />
                        </box>
                    </box>
                    {/* Anillos con etiqueta */}
                    <box cssClasses={["SidebarCard"]} spacing={10} homogeneous vexpand>
                        <ResourceRing value={cpu} color="#61afef" label="CPU" />
                        <ResourceRing value={ram} color="#98c379" label="RAM" />
                        <ResourceRing value={gpu} color="#c678dd" label="GPU" />
                    </box>
                </box>

                {/* COLUMNA 2: SLIDERS */}
                <box cssClasses={["SidebarCard"]} orientation={Gtk.Orientation.VERTICAL} spacing={15} widthRequest={240} valign={Gtk.Align.FILL}>
                    <label label="SISTEMA" css="font-size: 9px; font-weight: 900; color: #666; letter-spacing: 1px;" halign={Gtk.Align.START} />
                    <box orientation={Gtk.Orientation.VERTICAL} spacing={25} vexpand valign={Gtk.Align.CENTER}>
                        <box spacing={12} valign={Gtk.Align.CENTER}>
                            <label label="" css="font-size: 16px; color: #61afef;" />
                            <Gtk.Scale cssClasses={["SystemScale", "VolumeScale"]} hexpand drawValue={false} 
                                adjustment={new Gtk.Adjustment({ lower: 0, upper: 1, stepIncrement: 0.05, value: speaker?.volume || 0 })}
                                $={(self) => {
                                    self.connect("value-changed", () => { if (speaker) speaker.volume = self.adjustment.value })
                                    if (speaker) speaker.connect("notify::volume", () => self.adjustment.value = speaker.volume)
                                }} 
                            />
                            <label label={speaker ? createBinding(speaker, "volume").as(v => `${Math.floor(v * 100)}%`) : "0%"} css="font-size: 11px; font-weight: 800; color: white; min-width: 35px;" halign={Gtk.Align.END} />
                        </box>
                        <box spacing={12} valign={Gtk.Align.CENTER}>
                            <label label="󰃠" css="font-size: 16px; color: #e5c07b;" />
                            <Gtk.Scale cssClasses={["SystemScale", "BrightnessScale"]} hexpand drawValue={false}
                                adjustment={new Gtk.Adjustment({ lower: 0, upper: 1, stepIncrement: 0.05, value: brightness?.screen || 0 })}
                                $={(self) => {
                                    self.connect("value-changed", () => { if (brightness) brightness.screen = self.adjustment.value })
                                    if (brightness) brightness.connect("notify::screen", () => self.adjustment.value = brightness.screen)
                                }}
                            />
                            <label label={brightness ? createBinding(brightness, "screen").as(v => `${Math.floor(v * 100)}%`) : "0%"} css="font-size: 11px; font-weight: 800; color: white; min-width: 35px;" halign={Gtk.Align.END} />
                        </box>
                    </box>
                </box>

                {/* COLUMNA 3: ACCIONES RÁPIDAS */}
                <box cssClasses={["SidebarCard"]} orientation={Gtk.Orientation.VERTICAL} spacing={10} widthRequest={120} valign={Gtk.Align.FILL}>
                    <box spacing={8} homogeneous vexpand>
                        <button cssClasses={["SidebarBtn"]} onClicked={() => execAsync("nm-connection-editor").catch(() => {})}>
                            <label label="󰤨" css="color: #61afef; font-size: 16px;" />
                        </button>
                        <button cssClasses={["SidebarBtn"]} onClicked={() => execAsync("blueman-manager").catch(() => {})}>
                            <label label="󰂯" css="color: #c678dd; font-size: 16px;" />
                        </button>
                    </box>
                    <box spacing={8} homogeneous vexpand>
                        <button cssClasses={["SidebarBtn"]} onClicked={() => {
                            const isEnabled = nightLightEnabled.get()
                            if (isEnabled) { execAsync(['bash', '-c', 'pkill -x hyprsunset']).catch(() => {}) } 
                            else { execAsync(['bash', '-c', 'hyprsunset -t 3000']).catch(() => {}) }
                            setNightLightEnabled(!isEnabled)
                        }}>
                            <label label="󰤄" css={nightLightEnabled.as(n => `font-size: 16px; color: ${n ? '#e5c07b' : 'white'};`)} />
                        </button>
                        <button cssClasses={["SidebarBtn"]} onClicked={() => setDoNotDisturb(!doNotDisturb.get())}>
                            <label label="󰂛" css={doNotDisturb.as(d => `font-size: 16px; color: ${d ? '#e06c75' : 'white'};`)} />
                        </button>
                    </box>
                    <box spacing={8} homogeneous vexpand>
                        <button cssClasses={["SidebarBtn"]} onClicked={() => {
                            rightWin?.hide()
                            execAsync(['bash', '-c', 'sleep 0.2 && grim -g "$(slurp)" - | swappy -f -']).catch(() => {})
                        }}>
                            <label label="󰹑" css="font-size: 16px; color: white;" />
                        </button>
                        <button cssClasses={["SidebarBtn"]} onClicked={() => {
                            if (isRecording()) { 
                                execAsync(['bash', '-c', 'pkill --signal SIGINT wf-recorder']).catch(() => {}) 
                                setIsRecording(false) 
                            } else { 
                                execAsync(['bash', '-c', `wf-recorder --audio -f /home/tom/Vídeos/Rec_${Date.now()}.mp4`]).catch(() => {}) 
                                setIsRecording(true) 
                            }
                        }}>
                            <label label={createComputed(() => isRecording() ? "󰑊" : "󰑋")} css={createComputed(() => `font-size: 16px; color: ${isRecording() ? '#e06c75' : 'white'}`)} />
                        </button>
                    </box>
                </box>

                {/* COLUMNA 4: POWER */}
                <box orientation={Gtk.Orientation.VERTICAL} spacing={10} widthRequest={110} valign={Gtk.Align.FILL}>
                    <box spacing={10} homogeneous vexpand>
                        <button cssClasses={["SidebarBtn"]} onClicked={() => execAsync("swaylock")}>
                            <label label="󰌾" css="font-size: 14px; color: white;"/>
                        </button>
                        <button cssClasses={["SidebarBtn"]} onClicked={() => execAsync("hyprctl dispatch exit")}>
                            <label label="󰍃" css="font-size: 14px; color: white;"/>
                        </button>
                    </box>
                    <box spacing={10} homogeneous vexpand>
                        <button cssClasses={["SidebarBtn"]} onClicked={() => execAsync("systemctl suspend")}>
                            <label label="󰒲" css="font-size: 14px; color: white;"/>
                        </button>
                        <button cssClasses={["SidebarBtn"]} onClicked={() => execAsync("systemctl reboot")}>
                            <label label="" css="font-size: 14px; color: white;"/>
                        </button>
                    </box>
                    <button cssClasses={["PowerBtn"]} onClicked={() => execAsync("systemctl poweroff")}>
                        <label label="󰐥" css="font-size: 20px; color: white;" />
                    </button>
                </box>

            </box>
        </revealer>
    </window>
}
