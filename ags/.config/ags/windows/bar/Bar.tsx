/**
 * @file Bar.tsx
 */

import Gtk from "gi://Gtk?version=4.0"
import Gdk from "gi://Gdk?version=4.0"
import Pango from "gi://Pango?version=1.0"
import Astal from "gi://Astal?version=4.0"
import app from "ags/gtk4/app"
import GLib from "gi://GLib"
import { execAsync } from "ags/process"
import { createBinding, createComputed, createState, With, For } from "gnim" 

import AstalBattery from "gi://AstalBattery?version=0.1"
import AstalHyprland from "gi://AstalHyprland?version=0.1"
import AstalMpris from "gi://AstalMpris?version=0.1"
import AstalNetwork from "gi://AstalNetwork?version=0.1"
import AstalNotifd from "gi://AstalNotifd?version=0.1"
import AstalTray from "gi://AstalTray?version=0.1"

import { toggleLeftSidebar } from "@windows/left_sidebar/LeftSidebar"
import { toggleSidebar } from "@windows/right_sidebar/RightSidebar"
import { toggleCalendar } from "./CalendarWin"
import Time from "@widgets/Time/Time"
import { weatherReport } from "@common/vars"
import { getWeatherEmoji } from "@common/functions"

// --- COMPONENTES SECUNDARIOS ---

function NotificationMarquee() {
    const notifd = AstalNotifd.get_default()
    const [notifText, setNotifText] = createState("")
    const [show, setShow] = createState(false)
    let timeoutId: number | null = null

    notifd.connect("notified", (service, id) => {
        const n = service.get_notification(id)
        if (n) {
            const bodyText = n.body ? ` - ${n.body.replace(/\n/g, ' ')}` : ""
            setNotifText(`${n.summary}${bodyText}`)
            setShow(true)
            if (timeoutId) GLib.source_remove(timeoutId)
            timeoutId = GLib.timeout_add(GLib.PRIORITY_DEFAULT, 5000, () => {
                setShow(false)
                timeoutId = null
                return false
            })
        }
    })

    return <revealer revealChild={createComputed(() => show())} transitionType={Gtk.RevealerTransitionType.SLIDE_RIGHT} transitionDuration={400}>
        <box spacing={6} css="background: rgba(97, 175, 239, 0.15); padding: 4px 14px; border-radius: 12px; margin-left: 8px; border: 1px solid rgba(97, 175, 239, 0.3);">
            <label label="󰂚" css="color: #61afef; font-size: 14px;" />
            <label label={createComputed(() => notifText())} css="color: #61afef; font-size: 11px; font-weight: 900;" maxWidthChars={30} ellipsize={Pango.EllipsizeMode.END} />
        </box>
    </revealer>
}

function Workspaces() {
  const hypr = AstalHyprland.get_default()
  if (!hypr) return <box /> 
  const focused = createBinding(hypr, "focusedWorkspace")
  const workspaces = createBinding(hypr, "workspaces")
  const staticWorkspaces = [1, 2, 3, 4, 5]

  return <box spacing={6} valign={Gtk.Align.CENTER} cssClasses={["Workspaces"]}>
      {staticWorkspaces.map((id) => {
        const state = createComputed([focused, workspaces], (fw: AstalHyprland.Workspace, wsList: AstalHyprland.Workspace[]) => {
            if (fw && fw.id === id) return "focused"
            if (wsList && wsList.find(w => w.id === id)) return "occupied"
            return "empty"
        })
        
        return <button 
            cssClasses={createComputed(() => [state()])}
            css="cursor: pointer;"
            $={(btn: Gtk.Button) => {
                // Controlador de gestos infalible para GTK4
                const gesture = new Gtk.GestureClick()
                gesture.set_button(1) // Escucha específicamente el clic izquierdo
                
                gesture.connect("pressed", () => {
                    // 1. Intentamos el método nativo de Astal Hyprland
                    try {
                        hypr.dispatch("workspace", String(id))
                    } catch (e) {
                        console.error("Fallo el dispatch nativo", e)
                    }
                    
                    // 2. Failsafe: Forzamos la terminal directamente
                    execAsync(["bash", "-c", `hyprctl dispatch workspace ${id}`]).catch(() => {})
                    
                    // Le decimos a GTK que el clic ya fue procesado
                    gesture.set_state(Gtk.EventSequenceState.CLAIMED)
                })
                
                btn.add_controller(gesture)
            }}
        >
            <box cssClasses={["Circle"]} />
        </button>
      })}
  </box>
}

function WeatherInfo() {
    return <With value={weatherReport}>
        {(value: any) => {
            const current = value?.weather?.current_condition?.[0]
            if (!current) return <box />
            return <box spacing={6} css="background: rgba(255,255,255,0.04); padding: 2px 12px; border-radius: 10px; border: 1px solid rgba(255,255,255,0.02);">
                <label cssClasses={["weather-emoji"]} label={getWeatherEmoji(current.weatherDesc[0].value)} css="font-size: 14px;" />
                <label label={`${current.temp_C}°C`} css="font-size: 11px; font-weight: 800; color: white;" />
            </box>
        }}
    </With>
}

function NetworkIndicator() {
    const net = AstalNetwork.get_default()
    const [speed, setSpeed] = createState("0 KB/s")
    let lastRx = 0
    let lastTime = GLib.get_monotonic_time()

    GLib.timeout_add(GLib.PRIORITY_DEFAULT, 1000, () => {
        execAsync(["bash", "-c", "cat /sys/class/net/[ew]*/statistics/rx_bytes | awk '{s+=$1} END {print s}'"])
            .then(out => {
                const currentRx = Number(out) || 0
                const currentTime = GLib.get_monotonic_time()
                if (lastRx > 0 && currentRx >= lastRx) {
                    const elapsed = (currentTime - lastTime) / 1000000
                    const kbps = ((currentRx - lastRx) / elapsed) / 1024
                    setSpeed(kbps > 1024 ? (kbps/1024).toFixed(1) + " MB/s" : Math.floor(kbps) + " KB/s")
                }
                lastRx = currentRx
                lastTime = currentTime
            }).catch(() => {})
        return true
    })

    return <box spacing={8} css="background: rgba(255,255,255,0.05); padding: 2px 10px; border-radius: 10px;">
        <label 
            label={createBinding(net, "primary").as(p => p === AstalNetwork.Primary.UNKNOWN ? "󰤮" : (p === AstalNetwork.Primary.WIFI ? "󰤨" : "󰈀"))} 
            css="color: #98c379; font-size: 13px;" 
        />
        <label label={createComputed(() => speed())} css="font-size: 11px; font-weight: 900; color: white; min-width: 45px;" />
    </box>
}

// --- SYSTRAY REESCRITO ---
function SysTray() {
    const tray = AstalTray.get_default()
    const items = createBinding(tray, "items")

    return <box spacing={4} css="background: rgba(255,255,255,0.05); padding: 2px 8px; border-radius: 10px; min-height: 28px;" valign={Gtk.Align.CENTER}>
        <For each={items}>
            {(item: AstalTray.TrayItem) => {
                let popover: Gtk.PopoverMenu | null = null

                return <button
                    tooltipMarkup={createBinding(item, "tooltipMarkup")}
                    valign={Gtk.Align.CENTER}
                    css="background: transparent; border: none; padding: 3px 5px; border-radius: 8px;"
                    $={(btn: Gtk.Button) => {
                        popover = new Gtk.PopoverMenu()
                        popover.set_parent(btn)
                        popover.set_has_arrow(false)
                        popover.set_position(Gtk.PositionType.BOTTOM)

                        const syncMenu = () => {
                            if (!popover) return
                            const model = item.get_menu_model?.() ?? (item as any).menuModel
                            const group = item.get_action_group?.() ?? (item as any).actionGroup
                            if (model) popover.set_menu_model(model)
                            if (group) btn.insert_action_group("dbusmenu", group)
                        }

                        syncMenu()
                        item.connect("notify::menu-model", syncMenu)
                        item.connect("notify::action-group", syncMenu)

                        const gesture = new Gtk.GestureClick()
                        gesture.set_button(0)

                        gesture.connect("pressed", (_g, _n, x, y) => {
                            const btn_pressed = gesture.get_current_button()
                            if (btn_pressed === 1) {
                                try { item.activate(Math.round(x), Math.round(y)) } catch {}
                                gesture.set_state(Gtk.EventSequenceState.CLAIMED)
                            } else if (btn_pressed === 3) {
                                if (popover) {
                                    const rect = new Gdk.Rectangle()
                                    rect.x = Math.round(x)
                                    rect.y = Math.round(y)
                                    rect.width = 1
                                    rect.height = 1
                                    popover.set_pointing_to(rect)
                                    popover.popup()
                                }
                                gesture.set_state(Gtk.EventSequenceState.CLAIMED)
                            }
                        })

                        btn.add_controller(gesture)

                        const motionCtrl = new Gtk.EventControllerMotion()
                        motionCtrl.connect("enter", () => btn.set_css_classes(["tray-btn-hover"]))
                        motionCtrl.connect("leave", () => btn.set_css_classes([]))
                        btn.add_controller(motionCtrl)
                    }}
                >
                    <image
                        gicon={createBinding(item, "gicon")}
                        pixelSize={18}
                        valign={Gtk.Align.CENTER}
                        halign={Gtk.Align.CENTER}
                    />
                </button>
            }}
        </For>

        <label
            visible={items.as((i: AstalTray.TrayItem[]) => i.length === 0)}
            label="󰍜"
            css="color: rgba(255,255,255,0.2); font-size: 14px; margin: 0 4px;"
        />
    </box>
}

// --- BARRA PRINCIPAL ---
export default function Bar(monitor: Gdk.Monitor) {
  const { TOP, LEFT, RIGHT } = Astal.WindowAnchor
  const mpris = AstalMpris.get_default()

  return <window 
      name={`Bar-${monitor.get_connector() || '0'}`} 
      namespace="bar" 
      gdkmonitor={monitor} 
      exclusivity={Astal.Exclusivity.EXCLUSIVE} 
      application={app} 
      visible={true} 
      layer={Astal.Layer.TOP} 
      anchor={TOP | LEFT | RIGHT} 
      marginTop={10} marginLeft={16} marginRight={16}
  >
      <box spacing={12} cssClasses={["BarContainer"]}>
          
          <box css="background-color: rgba(10, 10, 14, 0.55); border: 1px solid rgba(255,255,255,0.08); border-radius: 18px; padding: 6px 16px;">
             <button 
                css="background: transparent; border: none; padding: 0; margin-right: 12px;"
                $={(self: Gtk.Button) => {
                    const gesture = new Gtk.GestureClick()
                    gesture.set_button(1)
                    gesture.connect("pressed", (_g: Gtk.GestureClick, _n: number, x: number, y: number) => {
                        const native = self.get_native()
                        if (!native) { execAsync(["wofi", "--show", "drun"]).catch(() => {}); return }
                        const [ok, wx, wy] = (self as any).translate_coordinates(native, 0, 0)
                        const allocation = self.get_allocation()
                        
                        const barHeight = 46 
                        const xPos = Math.round(wx)
                        const yPos = barHeight + 20 
                        execAsync([
                            "bash", "-c",
                            `wofi --show drun --xoffset=${xPos} --yoffset=${yPos} --width=300 --height=400`
                        ]).catch(() => {
                            execAsync(["wofi", "--show", "drun"]).catch(() => {})
                        })
                        gesture.set_state(Gtk.EventSequenceState.CLAIMED)
                    })
                    self.add_controller(gesture)
                    
                    const motion = new Gtk.EventControllerMotion()
                    motion.connect("enter", () => (self as any).set_css_classes(["logo-hover"]))
                    motion.connect("leave", () => (self as any).set_css_classes([]))
                    self.add_controller(motion)
                }}
             >
                <label label="" css="color: #61afef; font-size: 18px;" />
             </button>
             <Workspaces />
             <NotificationMarquee />
          </box>

          <box hexpand />

          <button onClicked={() => toggleLeftSidebar()} css="background: transparent; border: none; padding: 0;">
              <box cssClasses={["DynamicIsland", "Media"]}>
                <With value={createBinding(mpris, "players")}>
                    {(ps: Array<AstalMpris.Player>) => {
                        const player = ps?.[0]
                        if (!player) return <box css="padding: 6px 20px; background-color: rgba(10, 10, 14, 0.55); border-radius: 18px;"><label label="System Silence" css="color: rgba(255,255,255,0.2); font-size: 11px;" /></box>
                        
                        const progress = createComputed([
                            createBinding(player, "position"), 
                            createBinding(player, "length")
                        ], (pos: number, len: number) => len > 0 ? (pos / len) * 100 : 0)
                        
                        return <box spacing={8} css={progress.as((p: number) => `background: linear-gradient(to right, rgba(97, 175, 239, 0.25) ${p}%, rgba(10, 10, 14, 0.55) ${p}%); padding: 6px 20px; border-radius: 18px; transition: background 0.5s linear;`)}>
                            <label label={createBinding(player, "identity" as any).as((id: string) => { const i = (id || "").toLowerCase(); if (i.includes("spotify")) return "󰓇"; if (i.includes("mpv") || i.includes("vlc")) return "󰕼"; if (i.includes("firefox") || i.includes("chrome")) return "󰖟"; return "󰝚"; })} css="color: #61afef; font-size: 12px;" />
                            <label maxWidthChars={30} ellipsize={Pango.EllipsizeMode.END} label={createBinding(player, "title").as(t => t || "Unknown")} css="font-size: 11px; font-weight: 600; color: white;" />
                        </box>
                    }}
                </With>
              </box>
          </button>

          <box hexpand />

          <box spacing={12} css="background-color: rgba(10, 10, 14, 0.55); border: 1px solid rgba(255,255,255,0.08); border-radius: 18px; padding: 6px 16px;">
             <WeatherInfo />
             <NetworkIndicator />
             <SysTray />
             <button cssClasses={["ClockBtn"]} onClicked={() => toggleCalendar()} css="font-size: 12px; font-weight: 900;"><Time /></button>
             <button cssClasses={["SidebarToggle"]} onClicked={() => toggleSidebar()} css="font-size: 10px; font-weight: 900;"><label label="PANEL" /></button>
          </box>
      </box>
  </window>
}
