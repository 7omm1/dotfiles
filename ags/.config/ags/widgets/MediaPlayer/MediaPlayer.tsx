import Gtk from "gi://Gtk?version=4.0"
import GLib from "gi://GLib"
import AstalMpris from "gi://AstalMpris?version=0.1"
import { createBinding, createComputed, createState, With } from "gnim"
import { execAsync } from "ags/process"

function lengthStr(length: number) {
    if (!length || length <= 0) return "0:00"
    const min = Math.floor(length / 60)
    const sec = Math.floor(length % 60)
    return `${min}:${sec < 10 ? "0" : ""}${sec}`
}

function isVideoPlayer(player: AstalMpris.Player): boolean {
    const identity = (player as any).identity?.toLowerCase() ?? ""
    const videoPlayers = ["mpv", "vlc", "celluloid", "totem", "clapper", "haruna", "gnome-mpv"]
    return videoPlayers.some(v => identity.includes(v))
}

function getAlbumOrSource(player: AstalMpris.Player): string {
    const album = (player as any).album
    if (album && album.trim() !== "") return album
    const url = (player as any).url ?? ""
    if (url) {
        const decoded = decodeURIComponent(url)
        const parts = decoded.split("/")
        const filename = parts[parts.length - 1]
        return filename.replace(/\.[^/.]+$/, "").replace(/[._-]+/g, " ").trim() || "Video"
    }
    return isVideoPlayer(player) ? "Video" : "Desconocido"
}

function getPlayerIcon(player: AstalMpris.Player): string {
    const identity = (player as any).identity?.toLowerCase() ?? ""
    if (identity.includes("spotify")) return "󰓇"
    if (identity.includes("firefox") || identity.includes("chrome") || identity.includes("chromium")) return "󰖟"
    if (identity.includes("mpv") || identity.includes("vlc")) return "󰕼"
    if (isVideoPlayer(player)) return "󰿎"
    return "󰝚"
}

type LyricLine = { time: number, text: string }

export default function MediaPlayer(player: AstalMpris.Player) {
    const [showLyrics, setShowLyrics] = createState(false)
    const [lyricsLines, setLyricsLines] = createState<LyricLine[]>([])
    const [lyricsLoading, setLyricsLoading] = createState(false)
    const [activeIndex, setActiveIndex] = createState(0)
    
    let scrollWin: Gtk.ScrolledWindow
    let lyricsBox: Gtk.Box
    let scrollAnimId: number | null = null

    const fetchLyrics = () => {
        const title = player.title
        const artist = player.artist
        
        setActiveIndex(0) 

        if (!title) {
            setLyricsLines([{ time: 0, text: "No hay canción en reproducción." }])
            return
        }
        setLyricsLoading(true)
        setLyricsLines([{ time: 0, text: `Buscando letras...\n${title}` }])

        const urlTitle = encodeURIComponent(title)
        const urlArtist = encodeURIComponent(artist || "")
        const url = `https://lrclib.net/api/get?track_name=${urlTitle}&artist_name=${urlArtist}`

        execAsync(["bash", "-c", `curl -s "${url}"`])
            .then(out => {
                setLyricsLoading(false)
                try {
                    const data = JSON.parse(out)
                    if (data.syncedLyrics) {
                        const parsed = data.syncedLyrics.split('\n').map((line: string) => {
                            const match = line.match(/\[(\d{2}):(\d{2}\.\d{2})\](.*)/)
                            if (!match) return null
                            const time = parseInt(match[1]) * 60 + parseFloat(match[2])
                            return { time, text: match[3].trim() }
                        }).filter(Boolean) as LyricLine[]
                        setLyricsLines(parsed.length > 0 ? parsed : [{ time: 0, text: data.plainLyrics }])
                    } 
                    else if (data.plainLyrics) {
                        setLyricsLines([{ time: 0, text: data.plainLyrics }])
                    } else {
                        setLyricsLines([{ time: 0, text: "No se encontraron letras." }])
                    }
                    
                    // Aseguramos que haga scroll al inicio una vez cargado
                    GLib.timeout_add(GLib.PRIORITY_DEFAULT, 150, () => {
                        scrollToActive(activeIndex())
                        return GLib.SOURCE_REMOVE
                    })

                } catch {
                    setLyricsLines([{ time: 0, text: "Error al procesar las letras." }])
                }
            })
            .catch(() => {
                setLyricsLoading(false)
                setLyricsLines([{ time: 0, text: "Error de red." }])
            })
    }

    const scrollToActive = (index: number) => {
        if (!scrollWin || !lyricsBox) return
        
        GLib.idle_add(GLib.PRIORITY_DEFAULT_IDLE, () => {
            if (!lyricsBox) return GLib.SOURCE_REMOVE

            // SOLUCIÓN: Escaneamos el DOM en tiempo real para no perder nunca las letras
            const children: Gtk.Widget[] = []
            let child = lyricsBox.get_first_child()
            
            while (child) {
                // Filtramos solo los botones reales de la canción
                if (child.get_name() === "lyric-line") {
                    children.push(child)
                }
                child = child.get_next_sibling()
            }

            const activeChild = children[index]
            if (!activeChild) return GLib.SOURCE_REMOVE

            const alloc = activeChild.get_allocation()
            
            // FRENO DE SEGURIDAD ABSOLUTO: 
            // Si la coordenada Y es 0, GTK todavía no ha dibujado la página. 
            // Esperamos 50ms y lo volvemos a intentar. ¡Esto evita que te tire arriba!
            if (alloc.y === 0 || alloc.height <= 1) {
                GLib.timeout_add(GLib.PRIORITY_DEFAULT, 50, () => {
                    scrollToActive(index)
                    return GLib.SOURCE_REMOVE
                })
                return GLib.SOURCE_REMOVE
            }

            const adj = scrollWin.get_vadjustment()
            if (!adj) return GLib.SOURCE_REMOVE

            const scrollHeight = scrollWin.get_allocated_height() > 0 ? scrollWin.get_allocated_height() : 250
            
            // Ahora la fórmula es perfecta: alloc.y incluye naturalmente las cajas espaciadoras.
            const target = alloc.y - (scrollHeight / 2) + (alloc.height / 2)
            
            let maxScroll = adj.get_upper() - adj.get_page_size()
            if (maxScroll < 0) maxScroll = 0 
            
            const clampedTarget = Math.max(0, Math.min(target, maxScroll))
            
            if (scrollAnimId) {
                GLib.source_remove(scrollAnimId)
                scrollAnimId = null
            }

            let current = adj.get_value()
            const diff = clampedTarget - current
            if (Math.abs(diff) < 1 || isNaN(clampedTarget)) {
                if (!isNaN(clampedTarget)) adj.set_value(clampedTarget)
                return GLib.SOURCE_REMOVE
            }

            let stepCount = 0
            const totalSteps = 22 
            
            scrollAnimId = GLib.timeout_add(GLib.PRIORITY_DEFAULT, 16, () => {
                if (!scrollWin || !scrollWin.get_vadjustment()) return GLib.SOURCE_REMOVE
                
                stepCount++
                const t = stepCount / totalSteps
                const easeOutCubic = 1 - Math.pow(1 - t, 3);
                
                adj.set_value(current + (diff * easeOutCubic))
                
                if (stepCount >= totalSteps) {
                    adj.set_value(clampedTarget)
                    scrollAnimId = null
                    return GLib.SOURCE_REMOVE
                }
                return GLib.SOURCE_CONTINUE
            })
            
            return GLib.SOURCE_REMOVE
        })
    }

    player.connect("notify::title", () => {
        if (showLyrics()) {
            GLib.timeout_add(GLib.PRIORITY_DEFAULT, 500, () => {
                fetchLyrics()
                return GLib.SOURCE_REMOVE
            })
        } else {
            setLyricsLines([{ time: 0, text: "Presiona el botón de letras..." }])
        }
    })

    player.connect("notify::position", () => {
        if (!showLyrics() || lyricsLines().length <= 1) return
        
        const pos = player.position + 0.4 
        const lines = lyricsLines()
        const index = lines.findIndex((line, i) => {
            const nextTime = lines[i + 1]?.time ?? Infinity
            return line.time <= pos && nextTime > pos
        })
        
        if (index !== -1 && index !== activeIndex()) {
            setActiveIndex(index)
            scrollToActive(index)
        }
    })

    // Cover art mejorado: reacciona al cambio de título y formatea la ruta
    const coverCss = createComputed([
        createBinding(player, "coverArt"),
        createBinding(player, "title") // Dependencia extra para forzar refresco
    ], () => {
        const c = player.coverArt
        if (c && c.trim() !== "") {
            // Aseguramos que la ruta tenga el protocolo correcto para GTK
            const safeUrl = c.startsWith("file://") || c.startsWith("http") ? c : `file://${c}`
            return `background-image: url('${safeUrl}'); background-size: cover; background-position: center; border-radius: 18px; box-shadow: 0 8px 25px rgba(0,0,0,0.6); border: 1px solid rgba(255,255,255,0.08);`
        }
        return `background: linear-gradient(135deg, rgba(20,20,28,0.95) 0%, rgba(40,40,55,0.95) 100%); border-radius: 18px; border: 1px solid rgba(255,255,255,0.08); box-shadow: 0 8px 25px rgba(0,0,0,0.6);`
    })

    return <box orientation={Gtk.Orientation.VERTICAL} cssClasses={["MediaPlayerWidget"]}>
        {/* REPRODUCTOR SUPERIOR */}
        <box orientation={Gtk.Orientation.HORIZONTAL} spacing={18} valign={Gtk.Align.CENTER}>
            <box valign={Gtk.Align.CENTER} widthRequest={130} heightRequest={130} cssClasses={["cover-art"]} css={coverCss}>
                <label
                    visible={createBinding(player, "coverArt").as((c: string | null) => !c || c.trim() === "")}
                    label={isVideoPlayer(player) ? "󰿎" : "󰝚"}
                    css="font-size: 42px; color: rgba(255,255,255,0.2);"
                    halign={Gtk.Align.CENTER} hexpand
                />
            </box>

            <box orientation={Gtk.Orientation.VERTICAL} spacing={8} hexpand valign={Gtk.Align.CENTER}>
                <box orientation={Gtk.Orientation.HORIZONTAL} hexpand valign={Gtk.Align.CENTER}>
                    <box orientation={Gtk.Orientation.VERTICAL} spacing={2} halign={Gtk.Align.START} hexpand>
                        <label
                            label={createBinding(player, "title").as((t: string) => t || "Desconocido")}
                            css="font-size: 16px; font-weight: 900; color: #cdd6f4; text-shadow: 0 1px 3px rgba(0,0,0,0.4);"
                            halign={Gtk.Align.START} maxWidthChars={18} ellipsize={3}
                        />
                        <label
                            label={createBinding(player, "artist").as((a: string) => a || "Sin artista")}
                            css="font-size: 12px; color: #a6adc8; font-weight: 600;"
                            halign={Gtk.Align.START} maxWidthChars={22} ellipsize={3}
                        />
                        <box spacing={5} halign={Gtk.Align.START} css="margin-top: 4px;">
                            <label label={getPlayerIcon(player)} css="font-size: 11px; color: #89b4fa;" />
                            <label
                                label={createComputed([createBinding(player, "title"), createBinding(player, "artist")], () => getAlbumOrSource(player))}
                                css="font-size: 10px; color: #89b4fa; font-weight: 800; letter-spacing: 0.5px; text-transform: uppercase;"
                                halign={Gtk.Align.START} maxWidthChars={20} ellipsize={3}
                            />
                        </box>
                    </box>

                    <button
                        onClicked={() => {
                            const next = !showLyrics()
                            setShowLyrics(next)
                            if (next) {
                                if (lyricsLines().length <= 1) {
                                    fetchLyrics()
                                } else {
                                    GLib.timeout_add(GLib.PRIORITY_DEFAULT, 350, () => {
                                        scrollToActive(activeIndex())
                                        return GLib.SOURCE_REMOVE
                                    })
                                }
                            }
                        }}
                        cssClasses={createComputed(() => ["lyrics-btn", showLyrics() ? "active" : ""])}
                        halign={Gtk.Align.END}
                        valign={Gtk.Align.CENTER}
                    >
                        <label label={createComputed(() => lyricsLoading() ? "󰔟" : "󰍬")} halign={Gtk.Align.CENTER} valign={Gtk.Align.CENTER} />
                    </button>
                </box>

                <box spacing={12} halign={Gtk.Align.START} cssClasses={["controls"]} css="margin-top: 4px;">
                    <button onClicked={() => player.previous()} cssClasses={["control-btn", "small"]}>
                        <label label="󰒮" halign={Gtk.Align.CENTER} valign={Gtk.Align.CENTER} />
                    </button>
                    <button onClicked={() => player.play_pause()} cssClasses={["control-btn", "play"]}>
                        <label 
                            label={createBinding(player, "playbackStatus").as((s) => s === AstalMpris.PlaybackStatus.PLAYING ? "󰏤" : "󰐊")} 
                            halign={Gtk.Align.CENTER} valign={Gtk.Align.CENTER} 
                        />
                    </button>
                    <button onClicked={() => player.next()} cssClasses={["control-btn", "small"]}>
                        <label label="󰒭" halign={Gtk.Align.CENTER} valign={Gtk.Align.CENTER} />
                    </button>
                </box>

                <box spacing={8} valign={Gtk.Align.CENTER}>
                    <label label={createBinding(player, "position").as(lengthStr)} css="font-size: 9px; font-weight: bold; color: #89b4fa;" />
                    <Gtk.Scale hexpand drawValue={false} $={(self) => {
                        player.connect("notify::position", () => self.adjustment.value = player.position)
                        player.connect("notify::length", () => self.adjustment.upper = player.length)
                        self.connect("value-changed", () => {
                            if (Math.abs(self.adjustment.value - player.position) > 2) player.set_position(self.adjustment.value)
                        })
                    }}/>
                    <label label={createBinding(player, "length").as(lengthStr)} css="font-size: 9px; font-weight: bold; color: #555;" />
                </box>
            </box>
        </box>

        {/* PANEL DE LETRAS KARAOKE TIPO SPOTIFY */}
        <revealer revealChild={createComputed(() => showLyrics())} transitionType={Gtk.RevealerTransitionType.SLIDE_DOWN} transitionDuration={350}>
            <box orientation={Gtk.Orientation.VERTICAL} cssClasses={["lyrics-panel"]}>
                <Gtk.ScrolledWindow 
                    $={(ref) => scrollWin = ref} 
                    heightRequest={250} 
                    hscrollbarPolicy={Gtk.PolicyType.NEVER}
                >
                    <With value={lyricsLines}>
                        {(lines: LyricLine[]) => (
                            <box 
                                $={(ref) => lyricsBox = ref}
                                orientation={Gtk.Orientation.VERTICAL} 
                                spacing={2} 
                            >
                                {/* CAJA ESPACIADORA SUPERIOR REAL */}
                                <box heightRequest={125} />

                                {lines.map((line, i) => {
                                    const isEmpty = line.text === ""

                                    return (
                                        <button
                                            name="lyric-line"
                                            onClicked={() => line.time > 0 && player.set_position(line.time)}
                                            cssClasses={createComputed(() => ["lyric-line", i === activeIndex() ? "active" : ""])}
                                            css={isEmpty ? "margin-top: 14px; margin-bottom: 14px;" : "padding: 3px 12px;"}
                                        >
                                            <label 
                                                label={isEmpty ? "♪" : line.text} 
                                                wrap 
                                                justify={Gtk.Justification.CENTER} 
                                                css={isEmpty ? "font-size: 16px; color: rgba(255,255,255,0.15);" : ""}
                                            />
                                        </button>
                                    )
                                })}

                                {/* CAJA ESPACIADORA INFERIOR REAL */}
                                <box heightRequest={125} />
                            </box>
                        )}
                    </With>
                </Gtk.ScrolledWindow>
            </box>
        </revealer>
    </box>
}
