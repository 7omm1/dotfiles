import app from 'ags/gtk4/app'
import { monitorFile } from 'ags/file'
import { exec } from 'ags/process'

const TMP = "/tmp"

export function compileScss(): string {
  try {
    // Usamos el SRC nativo inyectado por AGS globalmente
    exec(`sass --no-charset --quiet-deps ${SRC}/style.scss ${TMP}/style.css`)
    app.apply_css(`${TMP}/style.css`)
    return `${TMP}/style.css` 
  } catch(err) {
    console.error('Error en SASS:', err)
    return ''
  }
}

(function() {
  try {
    const scssFiles = exec(`find -L ${SRC} -iname '*.scss'`).split('\n')
    compileScss()
    scssFiles.forEach(file => { if (file) monitorFile(file, compileScss) })
  } catch(err) { console.error('Error HotReload:', err) }
})()
