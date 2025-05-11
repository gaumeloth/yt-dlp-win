<#
.SYNOPSIS
  downloader.ps1 – Installa/aggiorna yt-dlp in modalità elevata, poi effettua il download (video o audio) senza privilegi elevati.

.DESCRIPTION
  - Senza parametro -Download:
      1) Rilancia in elevazione se non sei Admin.
      2) Installa o aggiorna yt-dlp tramite winget.
      3) Rilancia se stesso con -Download **in modalità normale**.
  - Con parametro -Download:
      1) Chiede URL del video e tipo di download.
      2) Esegue yt-dlp come utente standard.
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
    Write-Host "Installo/aggiorno yt-dlp tramite winget..." -NoNewline
    winget install --id yt-dlp.yt-dlp -e --accept-source-agreements --accept-package-agreements `
        -ErrorAction SilentlyContinue | Out-Null
    winget upgrade --id yt-dlp.yt-dlp -e --accept-source-agreements --accept-package-agreements `
        -ErrorAction SilentlyContinue | Out-Null
    Write-Host " OK" -ForegroundColor Green

    # 3) Rilancio in modalità download (utente normale)
    Write-Host "`n=== Fase 2: Avvio modalità download (utente normale) ===" -ForegroundColor Cyan
    $shell = New-Object -ComObject "Shell.Application"
    $args  = "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`" -Download"
    $shell.ShellExecute("powershell.exe", $args, "", "open", 1)
    exit
}

# ———————— qui siamo in modalità -Download ————————
Write-Host "=== Download con yt-dlp (utente normale) ===" -ForegroundColor Cyan

# 4) Chiedo URL
$videoUrl = Read-Host -Prompt "Inserisci il link del video"

# 5) Chiedo tipo di download
Write-Host "Scegli opzione di download:"
Write-Host "  1) Video completo"
Write-Host "  2) Solo audio"
$choice = Read-Host -Prompt "Digita 1 o 2"

# 6) Eseguo yt-dlp
switch ($choice) {
    '1' {
        Write-Host "`nScarico VIDEO + AUDIO (massima qualità)..." -ForegroundColor Cyan
        yt-dlp -f best $videoUrl
        break
    }
    '2' {
        Write-Host "`nScarico SOLO AUDIO (estrazione migliore)..." -ForegroundColor Cyan
        yt-dlp -x --audio-format mp3 $videoUrl
        break
    }
    default {
        Write-Warning "Opzione non valida; esco."
        exit 1
    }
}

# 7) Pausa finale
Write-Host "`nDownload completato." -ForegroundColor Green
Read-Host -Prompt "Premi Invio per chiudere"
