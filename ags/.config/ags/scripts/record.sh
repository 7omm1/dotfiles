#!/bin/bash

# Carpeta donde se guardan
DIR="$HOME/Videos/"
mkdir -p "$DIR"

# Nombre del archivo con fecha
FILE="$DIR/Grabacion_$(date '+%Y-%m-%d_%H-%M-%S').mp4"

# Comprobar si ya estamos grabando
if pgrep -x "wf-recorder" > /dev/null; then
    # SI YA ESTÁ GRABANDO -> DETENER
    pkill -INT wf-recorder
    notify-send "Grabación terminada" "Guardada en: $FILE" -i video-x-generic
else
    # SI NO ESTÁ GRABANDO -> EMPEZAR
    notify-send "Iniciando grabación..." "Capturando pantalla y audio" -i media-record
    
    # EXPLICACIÓN DEL COMANDO:
    # --audio : Graba el sonido del sistema (lo que escuchas por los altavoces)
    # -f : El archivo de destino
    # --pixel-format yuv420p : Para que el video sea compatible con WhatsApp/Telegram/Windows
    
    wf-recorder --audio --pixel-format yuv420p -f "$FILE"
fi
