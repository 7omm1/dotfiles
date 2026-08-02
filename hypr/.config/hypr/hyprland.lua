-- ==========================================================
-- Variables Locales
-- ==========================================================
local terminal = "kitty"
local fileManager = "kitty -e yazi"
local menu = "wofi --show drun --conf ~/.config/wofi/config --style ~/.config/wofi/style.css"

-- ==========================================================
-- Configuración Principal (Monitores, Entorno, Apariencia)
-- ==========================================================
hl.config({
	-- --- Monitors ---
	monitor = {
		", preferred, auto, 1",
	},

	-- --- Environment Variables ---
	env = {
		"LIBVA_DRIVER_NAME,nvidia",
		"__GLX_VENDOR_LIBRARY_NAME,nvidia",
		"GBM_BACKEND,nvidia-drm",
		"NVD_BACKEND,direct",
		"ELECTRON_OZONE_PLATFORM_HINT,auto",
		"MOZ_ENABLE_WAYLAND,1",
		"XDG_SESSION_TYPE,wayland",
		"XDG_CURRENT_DESKTOP,Hyprland",
		"XDG_SESSION_DESKTOP,Hyprland",
		"QT_QPA_PLATFORM,wayland",
		"QT_QPA_PLATFORMTHEME,qt5ct",
		"QT_WAYLAND_DISABLE_WINDOWDECORATION,1",
		"GDK_FONT,JetBrainsMono Nerd Font",
		"QT_FONT,JetBrainsMono Nerd Font",
		"XCURSOR_THEME,Bibata-Modern-Ice",
		"XCURSOR_SIZE,24",
	},

	-- --- Appearance ---
	general = {
		gaps_in = 6,
		gaps_out = 12,
		border_size = 2,

		-- Nuevo formato explícito para gradientes en Lua
		["col.active_border"] = { colors = { "rgba(cdd6f4ff)", "rgba(89b4faff)" }, angle = 45 },
		["col.inactive_border"] = { colors = { "rgba(313244aa)" } },

		resize_on_border = true,
		allow_tearing = false,
		layout = "dwindle",
	},

	decoration = {
		rounding = 14,
		active_opacity = 1.0,
		inactive_opacity = 0.90,
		fullscreen_opacity = 1.0,

		blur = {
			enabled = true,
			size = 8,
			passes = 2,
			new_optimizations = true,
			ignore_opacity = true,
			xray = false,
			special = true,
			popups = true,
			popups_ignorealpha = 0.2,
		},

		shadow = {
			enabled = true,
			range = 24,
			render_power = 3,
			color = "rgba(00000066)",
			color_inactive = "rgba(00000033)",
		},
	},

	-- --- Input ---
	input = {
		kb_layout = "latam",
		follow_mouse = 1,
		mouse_refocus = false,

		touchpad = {
			natural_scroll = true,
			tap_to_click = true,
			drag_lock = true,
		},

		sensitivity = 0,
		accel_profile = "flat",
	},

	-- --- Animations ---
	animations = {
		enabled = true,

		bezier = {
			"easeOutExpo,    0.16,  1,     0.3,   1",
			"easeOutQuart,   0.25,  1,     0.5,   1",
			"easeInOutCubic, 0.65,  0,     0.35,  1",
			"spring,         0.155, 1.105, 0.295, 1.12",
			"linear,         0,     0,     1,     1",
		},

		animation = {
			"windows,          1, 4,  spring,         popin 75%",
			"windowsIn,        1, 4,  easeOutExpo,    popin 75%",
			"windowsOut,       1, 3,  easeInOutCubic, popin 85%",
			"windowsMove,      1, 3,  easeOutQuart,   slide",
			"border,           1, 8,  linear",
			"borderangle,      1, 60, linear,         loop",
			"fade,             1, 4,  easeOutExpo",
			"fadeIn,           1, 4,  easeOutExpo",
			"fadeOut,          1, 3,  easeInOutCubic",
			"workspaces,       1, 4,  easeOutQuart,   slidefade 25%",
			"specialWorkspace, 1, 4,  easeOutExpo,    slidevert",
			"layers,           1, 3,  easeOutExpo,    slide",
		},
	},

	-- --- Layout ---
	dwindle = {
		preserve_split = true,
		force_split = 1,
		smart_split = false,
		smart_resizing = true,
	},

	-- --- Misc ---
	misc = {
		force_default_wallpaper = 0,
		disable_hyprland_logo = true,
		focus_on_activate = true,
		vrr = 1,
		mouse_move_enables_dpms = true,
		key_press_enables_dpms = true,
	},
})

-- ==========================================================
-- Autostart (Eventos al iniciar)
-- ==========================================================
hl.on("hyprland.start", function()
	hl.exec_cmd("hyprlock")
	hl.exec_cmd("hypridle")
	hl.exec_cmd("qs")
	hl.exec_cmd("sleep 2 && snixembed --fork")
	hl.exec_cmd("awww-daemon")
	hl.exec_cmd("pypr")
	hl.exec_cmd("pactl set-sink-mute @DEFAULT_SINK@ 0")
	hl.exec_cmd("hyprctl setcursor Bibata-Modern-Ice 24")
end)

-- ==========================================================
-- Atajos de Teclado (Keybinds)
-- ==========================================================
-- Básicos
hl.bind("SUPER + RETURN", hl.dsp.exec_cmd(terminal))
hl.bind("SUPER + C", hl.dsp.window.close())
hl.bind("SUPER + E", hl.dsp.exec_cmd(fileManager))
hl.bind("SUPER + M", hl.dsp.exec_cmd("hyprlock"))
hl.bind("SUPER + N", hl.dsp.exec_cmd(terminal .. " -e nvim"))
hl.bind("SUPER + V", hl.dsp.window.float({ action = "toggle" }))
hl.bind("SUPER + SPACE", hl.dsp.exec_cmd(menu))
hl.bind("SUPER + F", hl.dsp.window.fullscreen())
hl.bind("SUPER + P", hl.dsp.window.pin())

-- Screenshots
hl.bind("SUPER + S", hl.dsp.exec_cmd('grim -g "$(slurp)" - | swappy -f -'))
hl.bind("SUPER + SHIFT + S", hl.dsp.exec_cmd("grim - | swappy -f -"))

-- Focus (Mover el foco)
hl.bind("SUPER + H", hl.dsp.focus({ direction = "l" }))
hl.bind("SUPER + L", hl.dsp.focus({ direction = "r" }))
hl.bind("SUPER + K", hl.dsp.focus({ direction = "u" }))
hl.bind("SUPER + J", hl.dsp.focus({ direction = "d" }))

-- Swapping (Intercambiar ventanas)
hl.bind("SUPER + CTRL + H", hl.dsp.window.swap({ direction = "l" }))
hl.bind("SUPER + CTRL + L", hl.dsp.window.swap({ direction = "r" }))
hl.bind("SUPER + CTRL + K", hl.dsp.window.swap({ direction = "u" }))
hl.bind("SUPER + CTRL + J", hl.dsp.window.swap({ direction = "d" }))

-- Workspace management (Navegar entre workspaces)
hl.bind("SUPER + 1", hl.dsp.focus({ workspace = "1" }))
hl.bind("SUPER + 2", hl.dsp.focus({ workspace = "2" }))
hl.bind("SUPER + 3", hl.dsp.focus({ workspace = "3" }))
hl.bind("SUPER + 4", hl.dsp.focus({ workspace = "4" }))
hl.bind("SUPER + 5", hl.dsp.focus({ workspace = "5" }))

hl.bind("SUPER + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind("SUPER + mouse_up", hl.dsp.focus({ workspace = "e-1" }))

-- Movetoworkspace (Mover ventana a otro workspace)
hl.bind("SUPER + SHIFT + 1", hl.dsp.window.move({ workspace = "1" }))
hl.bind("SUPER + SHIFT + 2", hl.dsp.window.move({ workspace = "2" }))
hl.bind("SUPER + SHIFT + 3", hl.dsp.window.move({ workspace = "3" }))
hl.bind("SUPER + SHIFT + 4", hl.dsp.window.move({ workspace = "4" }))
hl.bind("SUPER + SHIFT + 5", hl.dsp.window.move({ workspace = "5" }))

-- Resizing (Redimensionar ventanas con teclado)
-- NOTA: Se usa { repeating = true } para imitar la función de "binde"
hl.bind("SUPER + SHIFT + H", hl.dsp.window.resize({ x = -20, y = 0, relative = true }), { repeating = true })
hl.bind("SUPER + SHIFT + L", hl.dsp.window.resize({ x = 20, y = 0, relative = true }), { repeating = true })
hl.bind("SUPER + SHIFT + K", hl.dsp.window.resize({ x = 0, y = -20, relative = true }), { repeating = true })
hl.bind("SUPER + SHIFT + J", hl.dsp.window.resize({ x = 0, y = 20, relative = true }), { repeating = true })

-- Mouse bindings (Ratón)
-- NOTA: Se usa { mouse = true } de forma obligatoria para drag y resize
hl.bind("SUPER + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind("SUPER + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- ==========================================================
-- Window Rules (Reglas de Ventanas)
-- ==========================================================
hl.window_rule({ match = { class = "^(ags)$" }, opacity = "0.7" })
hl.window_rule({ match = { class = "^(zathura)$" }, opacity = "0.7" })
hl.window_rule({ match = { class = "^(mpvpaper)$" }, no_blur = true, no_shadow = true, pin = true })
hl.window_rule({ match = { class = "^(Spotify)$" }, workspace = "2" })
hl.window_rule({ match = { class = "^(steam)$" }, workspace = "3" })

hl.window_rule({ match = { class = "^(pavucontrol)$" }, float = true, size = { 700, 450 }, center = true })
hl.window_rule({ match = { class = "^(nm-connection-editor)$" }, float = true, center = true })

-- ==========================================================
-- Layer Rules (Reglas de Capas - AGS, Wofi, etc.)
-- ==========================================================
hl.layer_rule({ match = { namespace = "bar" }, blur = true, ignore_alpha = 0.1 })
hl.layer_rule({ match = { namespace = "LeftSidebar" }, blur = true, ignore_alpha = 0.1 })
hl.layer_rule({ match = { namespace = "RightSidebar" }, blur = true, ignore_alpha = 0.1 })
hl.layer_rule({ match = { namespace = "CalendarWin" }, blur = true })
hl.layer_rule({ match = { namespace = "WallpaperSelector" }, blur = true, ignore_alpha = 0.1 })
hl.layer_rule({ match = { namespace = "osd" }, blur = true, ignore_alpha = 0.1 })
hl.layer_rule({ match = { namespace = "wofi" }, blur = true, ignore_alpha = 0.1, animation = "slide" })
