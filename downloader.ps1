<#
.SYNOPSIS
  Check-Winget.ps1 – Installa/aggiorna yt-dlp con elevazione e poi effettua il download (video o audio) senza elevazione.

.DESCRIPTION
  - Senza parametri:
    1) Rilancia in elevazione se necessario.
    2) Installa o aggiorna yt-dlp tramite winget.
    3) Rilancia se stesso in modalità "download" **senza** elevazione.
  - Con parametro -Download:
    1) Chiede URL e tipo di download (video o audio).
    2) Esegue yt-dlp **come utente normale**.
    3) Pausa finale.
#>

param(
    [switch]$Download
)

$ErrorActionPreference = 'Stop'
$scriptPath = $PSCommandPath

function Test-IsAdministrator {
    $id    = [Security.Principal.WindowsIdentity]::GetCurrent()
    $user  = New-Object Security.Principal.WindowsPrincipal($id)
    return $user.IsInRole(
        [Security.Principal.WindowsBuiltInRole]::Administrator
    )
}

if (-not $Download) {
    Write-Host "=== Fase 1: Install/Upgrade yt-dlp (richiede Admin) ===" -ForegroundColor Cyan

    # 1) Elevazione
    if (-not (Test-IsAdministrator)) {
        $psExe = Join-Path $env:WINDIR "System32\WindowsPowerShell\v1.0\powershell.exe"
        Write-Host "Rilancio in elevazione..." -ForegroundColor Yellow
        Start-Process -FilePath $psExe `
                      -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`"" `
                      -Verb RunAs
        exit
    }
    Write-Host "Sessione elevata confermata." -ForegroundColor Green

    # 2) Installa o aggiorna yt-dlp
    Write-Host "Installo/aggiorno yt-dlp tramite winget..."
    winget install --id yt-dlp.yt-dlp -e --accept-source-agreements --accept-package-agreements `
        -ErrorAction SilentlyContinue | Out-Null
    winget upgrade --id yt-dlp.yt-dlp -e --accept-source-agreements --accept-package-agreements `
        -ErrorAction SilentlyContinue | Out-Null
    Write-Host "✔ yt-dlp è installato e aggiornato." -ForegroundColor Green

    # 3) Rilancio in modalità download **senza** elevazione
    Write-Host "`n=== Fase 2: Launch download (utente normale) ===" -ForegroundColor Cyan
    $shell = New-Object -ComObject "Shell.Application"
    $args  = "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`" -Download"
    $shell.ShellExecute("powershell.exe", $args, "", "open", 1)
    exit
}

# ----------------------------------------------------
# SE ARRIVIAMO QUI: siamo in modalità -Download, con UTENTE NORMALE
# ----------------------------------------------------
Write-Host "=== Download con yt-dlp (normale) ===" -ForegroundColor Cyan

# Input URL
$videoUrl = Read-Host -Prompt "Inserisci il link del video"

# Scelta download
Write-Host "Scegli opzione di download:"
Write-Host "  1) Video completo"
Write-Host "  2) Solo audio"
$choice = Read-Host -Prompt "Digita 1 o 2"

# Esegui yt-dlp come utente non elevato
switch ($choice) {
    '1' {
        Write-Host "`nScarico VIDEO + AUDIO (massima qualità)..." -ForegroundColor Cyan
        yt-dlp -f best "$videoUrl"
    }
    '2' {
        Write-Host "`nScarico SOLO AUDIO (estrazione migliore)..." -ForegroundColor Cyan
        yt-dlp -x --audio-format mp3 "$videoUrl"
    }
    default {
        Write-Warning "Opzione non valida; esco."
        exit 1
    }
}

Write-Host "`nDownload completato." -ForegroundColor Green
Read-Host -Prompt "Premi Invio per chiudere"
