<#
.SYNOPSIS
    Downloads and silently installs RustDesk on Windows for unattended/fleet deployment.

.DESCRIPTION
    Intended for IT/MSP deployment via RMM, GPO startup script, or Intune Win32 app.
    Must be run elevated (installer writes to Program Files / registers a service).

.PARAMETER Version
    RustDesk release tag to install (e.g. "1.3.9"). Defaults to "latest".

.PARAMETER ServerHost
    Hostname or IP of your self-hosted RustDesk rendezvous server (hbbs). Supplying this
    (with -Key) points the installed client at your private server instead of the public
    rustdesk.com relay network.

.PARAMETER Key
    The public key of your hbbs server (the single-line contents of id_ed25519.pub from
    the server's data directory). Required whenever -ServerHost is supplied.

.PARAMETER RelayServer
    Hostname/IP of the relay server (hbbr). Defaults to the same value as -ServerHost,
    which is correct when hbbs and hbbr run on the same box.

.PARAMETER ApiServer
    Optional address of a RustDesk API server (only relevant if you run rustdesk-server-pro
    or a compatible API backend). Defaults to "https://<ServerHost>".

.PARAMETER InstallArgs
    Extra raw arguments appended to the installer's --silent-install invocation, for
    anything not covered by the parameters above.

.PARAMETER SkipHashCheck
    Skip SHA256 verification against the checksum GitHub publishes alongside each asset.
    Only use this if the release has no .sha256 companion file.

.EXAMPLE
    .\Install-RustDesk.ps1

.EXAMPLE
    .\Install-RustDesk.ps1 -Version 1.3.9

.EXAMPLE
    .\Install-RustDesk.ps1 -ServerHost rustdesk.mycompany.com -Key 'AbCdEf...=='
#>

[CmdletBinding()]
param(
    [string]$Version = 'latest',
    [string]$ServerHost = '',
    [string]$Key = '',
    [string]$RelayServer = '',
    [string]$ApiServer = '',
    [string]$InstallArgs = '',
    [switch]$SkipHashCheck
)

if ($ServerHost -and -not $Key) {
    throw "-Key is required when -ServerHost is supplied (the hbbs server's public key)."
}
if ($Key -and -not $ServerHost) {
    throw "-ServerHost is required when -Key is supplied."
}

$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

function Assert-Admin {
    $id = [Security.Principal.WindowsIdentity]::GetCurrent()
    $p  = New-Object Security.Principal.WindowsPrincipal($id)
    if (-not $p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        throw "This script must be run as Administrator."
    }
}

function Get-ReleaseAsset {
    param([string]$Tag)

    $uri = if ($Tag -eq 'latest') {
        'https://api.github.com/repos/rustdesk/rustdesk/releases/latest'
    } else {
        "https://api.github.com/repos/rustdesk/rustdesk/releases/tags/$Tag"
    }

    $headers = @{ 'User-Agent' = 'Install-RustDesk-Script' }
    $release = Invoke-RestMethod -Uri $uri -Headers $headers

    $arch = if ([Environment]::Is64BitOperatingSystem) { 'x86_64' } else { 'i386' }
    $exe  = $release.assets | Where-Object {
        $_.name -like "rustdesk-*-$arch.exe"
    } | Select-Object -First 1

    if (-not $exe) {
        throw "Could not find a Windows $arch installer asset in release '$($release.tag_name)'."
    }

    $sha = $release.assets | Where-Object { $_.name -eq "$($exe.name).sha256" } | Select-Object -First 1

    [PSCustomObject]@{
        Tag         = $release.tag_name
        DownloadUrl = $exe.browser_download_url
        FileName    = $exe.name
        Sha256Url   = if ($sha) { $sha.browser_download_url } else { $null }
    }
}

Assert-Admin

Write-Host "Resolving RustDesk release ($Version)..."
$asset = Get-ReleaseAsset -Tag $Version
Write-Host "Found $($asset.FileName) (release $($asset.Tag))"

$installerPath = Join-Path $env:TEMP $asset.FileName
Write-Host "Downloading to $installerPath ..."
Invoke-WebRequest -Uri $asset.DownloadUrl -OutFile $installerPath -UseBasicParsing

if (-not $SkipHashCheck) {
    if ($asset.Sha256Url) {
        Write-Host "Verifying SHA256 checksum..."
        $expected = (Invoke-WebRequest -Uri $asset.Sha256Url -UseBasicParsing).Content.Trim().Split(' ')[0]
        $actual = (Get-FileHash -Path $installerPath -Algorithm SHA256).Hash
        if ($expected -and ($actual -ne $expected)) {
            Remove-Item $installerPath -Force -ErrorAction SilentlyContinue
            throw "Checksum mismatch: expected $expected, got $actual. Aborting."
        }
        Write-Host "Checksum OK."
    } else {
        Write-Warning "No published .sha256 file for this asset; skipping verification."
    }
}

if ($ServerHost) {
    # RustDesk's silent installer looks for a preset config file with the same base name
    # as the installer plus ".toml" sitting alongside it, and bakes those settings in as
    # the client's server config at install time. See RustDesk's client-deployment docs.
    $relay = if ($RelayServer) { $RelayServer } else { $ServerHost }
    $api   = if ($ApiServer)   { $ApiServer }   else { "https://$ServerHost" }

    $presetToml = @"
[options]
custom-rendezvous-server = '$ServerHost'
relay-server = '$relay'
api-server = '$api'
key = '$Key'
"@

    $presetPath = [IO.Path]::ChangeExtension($installerPath, '.toml')
    Write-Host "Writing private-server preset to $presetPath ..."
    Set-Content -Path $presetPath -Value $presetToml -Encoding UTF8
}

Write-Host "Installing silently..."
$argList = @('--silent-install')
if ($InstallArgs) { $argList += $InstallArgs.Split(' ') }

$proc = Start-Process -FilePath $installerPath -ArgumentList $argList -PassThru -Wait
if ($proc.ExitCode -ne 0) {
    throw "RustDesk installer exited with code $($proc.ExitCode)."
}

Remove-Item $installerPath -Force -ErrorAction SilentlyContinue
if ($ServerHost) {
    Remove-Item ([IO.Path]::ChangeExtension($installerPath, '.toml')) -Force -ErrorAction SilentlyContinue
}

# The installer registers "RustDesk" as an auto-start service; confirm it's up.
Start-Sleep -Seconds 3
$svc = Get-Service -Name 'RustDesk' -ErrorAction SilentlyContinue
if ($svc -and $svc.Status -eq 'Running') {
    Write-Host "RustDesk installed and running as a service." -ForegroundColor Green
} else {
    Write-Warning "Install finished but the RustDesk service was not detected as running. Check manually."
}

$rdExePath = Join-Path $env:ProgramFiles 'RustDesk\rustdesk.exe'
if (Test-Path $rdExePath) {
    Write-Host "RustDesk ID for this endpoint:"
    & $rdExePath --get-id

    if ($ServerHost) {
        Write-Host "Configured rendezvous server: $ServerHost"
        Write-Host "Verify with: & '$rdExePath' --get-id  (then check Settings > Network on a connecting client, or confirm the host shows up in hbbs logs)"
    }
}
