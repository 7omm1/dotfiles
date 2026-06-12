import Gdk from "gi://Gdk?version=4.0"
import app from "ags/gtk4/app"
import requestHandler from "./requestHandler"
import { compileScss } from "./common/cssHotReload"

// Importamos todas tus ventanas
import Bar from "./windows/bar/Bar"
import LeftSidebar from "./windows/left_sidebar/LeftSidebar"
import RightSidebar from "./windows/right_sidebar/RightSidebar"
import CalendarWin from "./windows/bar/CalendarWin"
import WallpaperSelector from "./windows/wallpapers/WallpaperSelector"
import OSD from "./windows/osd/OSD"
import Crosshair from "./windows/crosshair/Crosshair"
import Launcher from "./windows/launcher/Launcher"
import NotificationPopups from "./windows/notification_popups/NotificationPopups"

function getTargetMonitor(monitors: Array<Gdk.Monitor>) {
  // Ajusta esto si tus monitores tienen otros nombres, o dejará el por defecto
  const notebookModel = "0x9051"
  const pcModel = "24G2W1G4"

  const notebookMonitor = monitors.find(m => m.model === notebookModel)
  const pcMonitor = monitors.find(m => m.model === pcModel)

  return notebookMonitor || pcMonitor || monitors[0]
}

// ESTA es la función clave que mantiene el programa abierto
app.start({
  css: compileScss(),
  requestHandler: requestHandler,
  main() {
    const targetMonitor = getTargetMonitor(app.get_monitors())

    // Inicializamos todas las ventanas en el monitor objetivo
    Bar(targetMonitor)
    CalendarWin(targetMonitor)
    WallpaperSelector(targetMonitor)
    Launcher(targetMonitor)
    LeftSidebar(targetMonitor)
    RightSidebar(targetMonitor)
    OSD(targetMonitor)
    Crosshair(targetMonitor)
    NotificationPopups(targetMonitor)

    print(`\n[✓] Interfaz cargada en el monitor: ${targetMonitor?.model || 'Desconocido'}`)
  },
})
