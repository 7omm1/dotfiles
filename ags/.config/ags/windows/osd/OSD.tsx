import Gtk from "gi://Gtk?version=4.0"
import Gdk from "gi://Gdk?version=4.0"
import Astal from "gi://Astal?version=4.0"
import app from "ags/gtk4/app"
import GLib from "gi://GLib"
import { createComputed, createState } from "gnim"
import AstalWp from "gi://AstalWp?version=0.1"
import Brightness from "@utils/Brightness"

export default function OSD(monitor: Gdk.Monitor) {
  const brightness = Brightness.get_default()
  const wp = AstalWp.get_default()!
  const speaker = wp?.get_default_speaker()

  // ESTADOS REACTIVOS
  const [isRevealed, setIsRevealed] = createState(false)
  const [icon, setIcon] = createState("")
  const [value, setValue] = createState(0)

  // Temporizador para esconder el OSD
  let hideTimeout: number | null = null

  function show(v: number, icn: string) {
    setValue(v)
    setIcon(icn)
    setIsRevealed(true)

    // Si ya había un temporizador corriendo (ej. si presionas subir volumen varias veces), lo cancelamos
    if (hideTimeout) GLib.source_remove(hideTimeout)
    
    // Iniciamos un nuevo temporizador de 2 segundos
    hideTimeout = GLib.timeout_add(GLib.PRIORITY_DEFAULT, 2000, () => {
      setIsRevealed(false)
      hideTimeout = null
      return false // Falso para que el temporizador no se repita en bucle
    })
  }

  // CONEXIONES DE SEÑALES (Eventos de teclado/sistema)
  brightness.connect("notify::screen", () => show(brightness.screen, "display-brightness-symbolic"))
  if (speaker) speaker.connect("notify::volume", () => show(speaker.volume, speaker.volumeIcon))

  // Conexión específica para Spotify si está abierto
  wp?.connect("node-added", () => {
    wp.get_nodes()?.forEach((node) => {
      if (node.name === "Spotify") {
        node.connect("notify::volume", () => show(node.volume, "spotify"))
      }
    })
  })

  return (
    <window
      gdkmonitor={monitor}
      name="OSD"
      namespace="osd" // Llave para Hyprland
      application={app}
      layer={Astal.Layer.OVERLAY} // Capa superior para que pase por encima de tus juegos/apps
      anchor={Astal.WindowAnchor.RIGHT} // Centrado verticalmente a la derecha
      marginRight={16} // Margen para que sea flotante
    >
      {/* CAJA ANTI-BUG (Evita el error de Pixman) */}
      <box css="background: transparent; padding: 1px;">
        {/* MOTOR DE ANIMACIÓN: Se desliza desde la derecha */}
        <revealer
          revealChild={createComputed(() => isRevealed())}
          transitionType={Gtk.RevealerTransitionType.SLIDE_LEFT}
          transitionDuration={250} // Un poco más rápido para que la respuesta se sienta instantánea
        >
          {/* PÍLDORA DE CRISTAL */}
          <box
            orientation={Gtk.Orientation.VERTICAL}
            spacing={12}
            css="padding: 16px 12px; background-color: rgba(10, 10, 14, 0.35); border: 1px solid rgba(255,255,255,0.08); border-radius: 24px; box-shadow: 0 4px 20px rgba(0,0,0,0.5);"
          >
            {/* ICONO (Brillo, Volumen, etc) */}
            <image 
                iconName={createComputed(() => icon())} 
                pixelSize={24} 
                css="color: white;" 
            />
            
            {/* BARRA DE NIVEL */}
            <levelbar
              valign={Gtk.Align.CENTER}
              heightRequest={120}
              widthRequest={8}
              orientation={Gtk.Orientation.VERTICAL}
              inverted
              value={createComputed(() => value())}
            />
            
            {/* PORCENTAJE TEXTUAL */}
            <label 
              label={createComputed(() => `${Math.floor(value() * 100)}%`)} 
              css="color: white; font-weight: bold; font-size: 11px;" 
            />
          </box>
        </revealer>
      </box>
    </window>
  )
}
