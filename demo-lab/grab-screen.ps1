# Hackoween 2026 — Act 3 loot: desktop screenshot (lab victim VM only).
# Pure PowerShell via GDI. Captures the full virtual desktop (all monitors),
# saves to the Desktop, and pops it open so the audience sees it land.
#
# Blue-team note: a process loading System.Drawing and calling CopyFromScreen is a
# screen-capture signal — EDR can flag desktop-capture API use by an unexpected process.

Add-Type -AssemblyName System.Windows.Forms, System.Drawing

$bounds = [System.Windows.Forms.SystemInformation]::VirtualScreen
$bmp = New-Object System.Drawing.Bitmap($bounds.Width, $bounds.Height)
$gfx = [System.Drawing.Graphics]::FromImage($bmp)
$gfx.CopyFromScreen($bounds.Location, [System.Drawing.Point]::Empty, $bounds.Size)

$out = Join-Path $env:USERPROFILE ("Desktop\hackoween-screen-{0:yyyyMMdd-HHmmss}.png" -f (Get-Date))
$bmp.Save($out, [System.Drawing.Imaging.ImageFormat]::Png)
$gfx.Dispose(); $bmp.Dispose()

Write-Host "Screenshot saved: $out"
Invoke-Item $out   # comment out if you don't want it to auto-open on stage
