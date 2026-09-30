# Hackoween 2026 — list DirectShow capture devices on the show machine.
# Run this on the actual victim (VM guest or physical laptop) to get the EXACT camera
# name to pass to capture-webcam.ps1 -Camera. dshow requires the exact string.

param(
    [string]$FfmpegPath = (Join-Path $PSScriptRoot 'ffmpeg.exe')
)

# ffmpeg prints the device list to stderr; 2>&1 captures it so we can read it.
& $FfmpegPath -hide_banner -list_devices true -f dshow -i dummy 2>&1 |
    Where-Object { $_ -match 'DirectShow (video|audio) devices|"' }
