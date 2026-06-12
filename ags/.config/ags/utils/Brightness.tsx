import { execAsync } from "ags/process"
import GObject, { register, getter, setter } from "gnim/gobject"

let instance: Brightness

@register({ GTypeName: "Brightness" })
export default class Brightness extends GObject.Object {
  declare $signals: GObject.Object.SignalSignatures & {
    "notify::screen": () => void
    "notify::kbd": () => void
  }

  static get_default() {
    if (!instance) instance = new Brightness()
    return instance
  }

  #screen = 0
  #useDdcutil = false
  #isUpdating = false
  #pendingUpdate = false

  @getter(Number)
  get screen() {
    return this.#screen
  }

  @setter(Number)
  set screen(percent) {
    if (percent < 0) percent = 0
    if (percent > 1) percent = 1

    // Actualización visual instantánea
    this.#screen = percent
    this.notify("screen")

    if (this.#useDdcutil) {
      // Lógica lenta para monitores de escritorio
      if (this.#isUpdating) {
        this.#pendingUpdate = true
        return
      }
      this.applyDdcutilBrightness(Math.floor(percent * 100))
    } else {
      // Lógica instantánea para laptops
      execAsync(`brightnessctl set ${Math.floor(percent * 100)}% -q`).catch(console.error)
    }
  }

  constructor() {
    super()
    this.detectHardware()
  }

  async detectHardware() {
    try {
      // Revisamos si existen carpetas de brillo de laptop
      const backlightDirs = await execAsync("ls -A /sys/class/backlight")
      
      if (backlightDirs.trim() === "") {
        // No hay brillo de laptop, debe ser PC de escritorio
        this.#useDdcutil = true
        this.fetchDdcutilBrightness()
      } else {
        // Es una laptop (o usa el módulo ddcci)
        this.#useDdcutil = false
        this.fetchLaptopBrightness()
      }
    } catch (e) {
      // Si la carpeta ni siquiera existe, asumimos escritorio
      this.#useDdcutil = true
      this.fetchDdcutilBrightness()
    }
  }

  // --- MÉTODOS PARA LAPTOP ---
  async fetchLaptopBrightness() {
    try {
      const max = Number(await execAsync("brightnessctl max"))
      const current = Number(await execAsync("brightnessctl get"))
      if (!isNaN(max) && !isNaN(current) && max > 0) {
        this.#screen = current / max
        this.notify("screen")
      }
    } catch (e) {
      console.error("Error al obtener brillo de laptop:", e)
    }
  }

  // --- MÉTODOS PARA ESCRITORIO ---
  async fetchDdcutilBrightness() {
    try {
      const out = await execAsync(["bash", "-c", "ddcutil getvcp 10 --terse | awk '{print $4}'"])
      const val = Number(out)
      if (!isNaN(val)) {
        this.#screen = val / 100
        this.notify("screen")
      }
    } catch (e) {
      console.error("Error con ddcutil:", e)
    }
  }

  private async applyDdcutilBrightness(value: number) {
    this.#isUpdating = true
    this.#pendingUpdate = false

    try {
      await execAsync(`ddcutil setvcp 10 ${value} --noverify`)
    } catch (e) {
      console.error("Error al setear el brillo con ddcutil:", e)
    } finally {
      this.#isUpdating = false
      if (this.#pendingUpdate) {
        this.applyDdcutilBrightness(Math.floor(this.#screen * 100))
      }
    }
  }
}
