import Gtk from "gi://Gtk?version=4.0"
import Gdk from "gi://Gdk?version=4.0"
import Astal from "gi://Astal?version=4.0"
import app from "ags/gtk4/app"
import AstalMpris from "gi://AstalMpris?version=0.1"
import { createBinding, createComputed, createState, With } from "gnim"
import MediaPlayer from "@widgets/MediaPlayer/MediaPlayer"

export let leftWin: Gtk.Window | null = null
const [isRevealed, setIsRevealed] = createState(false)

export function toggleLeftSidebar() {
    if (!leftWin) return
    if (isRevealed()) {
        setIsRevealed(false)
    } else { 
        leftWin.show(); 
        setIsRevealed(true) 
    }
}

export default function LeftSidebar(monitor: Gdk.Monitor) {
    const mpris = AstalMpris.get_default()
    return <window 
        $={(self) => { 
            leftWin = self 
            const ctrl = new Gtk.EventControllerMotion()
            ctrl.connect("leave", () => { if (isRevealed()) toggleLeftSidebar() })
            self.add_controller(ctrl)
        }} 
        name="LeftSidebar" namespace="LeftSidebar" gdkmonitor={monitor} application={app} visible={false} 
        anchor={Astal.WindowAnchor.TOP}
        marginTop={15}
    >
        <revealer 
            revealChild={createComputed(() => isRevealed())} 
            transitionType={Gtk.RevealerTransitionType.SLIDE_DOWN} 
            transitionDuration={300}
            $={(self) => {
                self.connect("notify::child-revealed", () => {
                    if (!self.child_revealed && leftWin) leftWin.hide()
                })
            }}
        >
            {/* ENSANCHADO A 420px */}
            <box orientation={Gtk.Orientation.VERTICAL} widthRequest={420} spacing={10} css="padding: 24px; background-color: rgba(10, 10, 14, 0.65); border: 1px solid rgba(255,255,255,0.08); border-radius: 30px; box-shadow: 0 16px 40px rgba(0,0,0,0.6);">
                <label label="REPRODUCTOR" css="font-size: 9px; font-weight: 900; color: #777; letter-spacing: 2px;" halign={Gtk.Align.START} />
                <With value={createBinding(mpris, "players")}>
                    {(ps: Array<AstalMpris.Player>) => {
                        if (!ps || ps.length === 0) {
                            return <box css="padding: 30px 0;" halign={Gtk.Align.CENTER}>
                                <label label="Sin reproducción activa" css="color: #555; font-weight: bold; font-size: 12px;" />
                            </box>
                        }
                        // Mostrar todos los players activos (música + videos)
                        return <box orientation={Gtk.Orientation.VERTICAL} spacing={16}>
                            {ps.map((player: AstalMpris.Player, i: number) => (
                                <box orientation={Gtk.Orientation.VERTICAL} spacing={0}>
                                    {i > 0 ? <box css="min-height: 1px; background: rgba(255,255,255,0.07); margin: 8px 4px;" /> : null}
                                    {MediaPlayer(player)}
                                </box>
                            ))}
                        </box>
                    }}
                </With>
            </box>
        </revealer>
    </window>
}
