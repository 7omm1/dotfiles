import Gtk from "gi://Gtk?version=4.0"
import Gdk from "gi://Gdk?version=4.0"
import Astal from "gi://Astal?version=4.0"
import app from "ags/gtk4/app"
import GLib from "gi://GLib"
import { createComputed, createState, With } from "gnim"
import { execAsync } from "ags/process"
import { pathToURI } from "@common/functions"

export let wallWin: Gtk.Window | null = null
const [isRevealed, setIsRevealed] = createState(false)
const [wallpapers, setWallpapers] = createState<string[]>([])

// =========================================================
// ⚠️ IMPORTANTE: CAMBIA ESTA RUTA A TU CARPETA DE FONDOS
// =========================================================
const WALLPAPER_DIR = GLib.get_home_dir() + "/Imágenes/Wallpapers" 

export function toggleWallpapers() {
    if (!wallWin) return
    if (isRevealed()) {
        setIsRevealed(false)
    } else {
        loadWallpapers()
        wallWin.show()
        setIsRevealed(true)
    }
}

function loadWallpapers() {
    // Busca archivos jpg y png en tu carpeta
    execAsync(['bash', '-c', `ls ${WALLPAPER_DIR}/*.{jpg,jpeg,png} 2>/dev/null`])
        .then(out => {
            const files = out.split('\n').filter(f => f.trim() !== '')
            setWallpapers(files)
        })
        .catch(() => {
            print("No se encontraron imágenes en: " + WALLPAPER_DIR)
            setWallpapers([])
        })
}

function setWallpaper(path: string) {
    // Usa swww para aplicar la transición que viste en el video
    execAsync(['swww', 'img', path, '--transition-type', 'wipe', '--transition-duration', '1.5'])
        .catch(err => print("Error con swww: " + err))
    
    // Cierra el panel después de elegir
    toggleWallpapers()
}

export default function WallpaperSelector(monitor: Gdk.Monitor) {
    return <window 
        $={(self) => { 
            wallWin = self 
            const ctrl = new Gtk.EventControllerMotion()
            ctrl.connect("leave", () => { if (isRevealed()) toggleWallpapers() })
            self.add_controller(ctrl)
        }}
        name="WallpaperSelector" namespace="WallpaperSelector" application={app} visible={false} gdkmonitor={monitor}
        layer={Astal.Layer.TOP} 
        anchor={Astal.WindowAnchor.TOP | Astal.WindowAnchor.BOTTOM} // Centrado
        marginTop={65} marginBottom={65}
    >
        <box css="background: transparent; padding: 1px;">
            <revealer 
                revealChild={createComputed(() => isRevealed())} 
                transitionType={Gtk.RevealerTransitionType.SLIDE_DOWN} 
                transitionDuration={300}
                $={(self) => {
                    self.connect("notify::child-revealed", () => {
                        if (!self.child_revealed && wallWin) wallWin.hide()
                    })
                }}
            >
                <box orientation={Gtk.Orientation.VERTICAL} widthRequest={560} heightRequest={400} spacing={15}
                    css="padding: 24px; background-color: rgba(10, 10, 14, 0.35); border: 1px solid rgba(255,255,255,0.08); border-radius: 30px; box-shadow: 0 4px 20px rgba(0,0,0,0.5);">
                    
                    <label label="TUS FONDOS" css="font-size: 14px; font-weight: 900; color: white; letter-spacing: 2px;" halign={Gtk.Align.CENTER} />
                    
                    <scrolledwindow hexpand vexpand css="border-radius: 16px;">
                        <box css="padding: 10px;">
                            <With value={createComputed(() => wallpapers())}>
                                {(walls: string[]) => {
                                    if (walls.length === 0) return <label label="Carpeta vacía o ruta incorrecta." css="color: #888; font-weight: bold;" halign={Gtk.Align.CENTER} vexpand />
                                    
                                    // Separamos las imágenes en filas de 3 para simular una grilla (Grid)
                                    const rows = []
                                    for (let i = 0; i < walls.length; i += 3) rows.push(walls.slice(i, i + 3))
                                    
                                    return <box orientation={Gtk.Orientation.VERTICAL} spacing={12}>
                                        {rows.map(row => (
                                            <box orientation={Gtk.Orientation.HORIZONTAL} spacing={12} homogeneous>
                                                {row.map(w => (
                                                    <button 
                                                        onClicked={() => setWallpaper(w)}
                                                        css={`min-width: 150px; min-height: 90px; border-radius: 14px; background-image: url('${pathToURI(w)}'); background-size: cover; background-position: center; border: 1px solid rgba(255,255,255,0.05); transition: all 0.2s;`}
                                                    />
                                                ))}
                                            </box>
                                        ))}
                                    </box>
                                }}
                            </With>
                        </box>
                    </scrolledwindow>
                </box>
            </revealer>
        </box>
    </window>
}
