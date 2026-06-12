import Gtk from "gi://Gtk?version=4.0"
import Gdk from "gi://Gdk?version=4.0"
import Astal from "gi://Astal?version=4.0"
import app from "ags/gtk4/app"
import { createComputed, createState } from "gnim"

export let calendarWin: Gtk.Window | null = null
const [isRevealed, setIsRevealed] = createState(false)

export function toggleCalendar() {
    if (!calendarWin) return
    if (isRevealed()) {
        setIsRevealed(false)
    } else {
        calendarWin.show()
        setIsRevealed(true)
    }
}

export default function CalendarWin(monitor: Gdk.Monitor) {
    return <window $={(self) => { 
        calendarWin = self 
        const ctrl = new Gtk.EventControllerMotion()
        ctrl.connect("leave", () => { if (isRevealed()) toggleCalendar() })
        self.add_controller(ctrl)
    }} name="CalendarWin" namespace="CalendarWin" application={app} visible={false} gdkmonitor={monitor} layer={Astal.Layer.TOP} anchor={Astal.WindowAnchor.TOP} marginTop={15}>
        <box css="background: transparent; padding: 1px;">
            <revealer 
                revealChild={createComputed(() => isRevealed())} 
                transitionType={Gtk.RevealerTransitionType.SLIDE_DOWN} 
                transitionDuration={300}
                $={(self) => {
                    self.connect("notify::child-revealed", () => {
                        if (!self.child_revealed && calendarWin) calendarWin.hide()
                    })
                }}
            >
                <box css="padding: 20px; background-color: rgba(10, 10, 14, 0.55); border: 1px solid rgba(255,255,255,0.08); border-radius: 24px; box-shadow: 0 4px 20px rgba(0,0,0,0.5);">
                    <Gtk.Calendar class="my-calendar" css="background: transparent; color: white; border: none;" />
                </box>
            </revealer>
        </box>
    </window>
}
