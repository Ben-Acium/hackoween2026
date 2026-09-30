# Hackoween 2026 — Act 3 loot: single webcam frame (lab victim VM only).
# PowerShell has no reliable native single-frame camera API, so this drives ffmpeg
# (DirectShow). Put a portable ffmpeg.exe on the lab VM (or on PATH); default assumes
# it sits next to this script.
#
# FIND THE EXACT DEVICE NAME FIRST (dshow needs the exact string):
#   ffmpeg -list_devices true -f dshow -i dummy      (or run list-cameras.ps1)
# Built-in laptop cams commonly enumerate as "Integrated Camera" / "Integrated Webcam"
# or a vendor string (e.g. "HP TrueVision HD"). Confirm on the actual show machine.
#
# NOTE ON VMs: a built-in laptop camera does NOT pass into a guest VM automatically.
#   - VMware Workstation / VirtualBox: attach the cam to the guest as a USB device, THEN
#     run this inside the guest.
#   - Hyper-V: no clean webcam passthrough — run this on the physical laptop instead.
# Point the cam at the presenter (or a prop), never at the audience.
#
# Blue-team note: a process opening the camera device is a sensitive-API signal — this
# is the "camera access" alert on the defender pane during the loot round.

param(
    [string]$Camera = 'Integrated Camera',
    [string]$FfmpegPath = (Join-Path $PSScriptRoot 'ffmpeg.exe')
)

$out = Join-Path $env:USERPROFILE ("Desktop\hackoween-cam-{0:yyyyMMdd-HHmmss}.jpg" -f (Get-Date))

# Grab 5 frames and keep the last (-update 1 overwrites): first frame(s) from a webcam
# are often black while the sensor warms up, so throwing the early ones away is the fix.
& $FfmpegPath -y -f dshow -rtbufsize 100M -i "video=$Camera" -frames:v 5 -update 1 $out

if (Test-Path $out) {
    Write-Host "Webcam frame saved: $out"
    Invoke-Item $out   # comment out if you don't want it to auto-open on stage
} else {
    Write-Warning "No frame captured. Check the device name with: ffmpeg -list_devices true -f dshow -i dummy"
}
