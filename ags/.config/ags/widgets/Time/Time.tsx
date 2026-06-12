import Gtk from "gi://Gtk?version=4.0"
import { currentTime } from "@common/vars"

export default function Time() {
  return (
    <label
      class="Time"
      // En caso de que cargue vacío, mostramos 00:00 por un instante
      label={currentTime.as(t => t || "00:00")}
      halign={Gtk.Align.CENTER}
      valign={Gtk.Align.CENTER}
    />
  )
}
