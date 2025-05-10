<#
.SYNOPSIS
  Check-Winget.ps1 – Verifica presenza e versione di winget, applica upgrade di App Installer,
                     con messaggi esplicativi e pausa finale per mantenere aperta la finestra.

.DESCRIPTION
  1. Controlla se lo script è in esecuzione come Amministratore; in caso contrario si rilancia in elevazione.
  2. Ripristina la cartella WindowsApps nel PATH (necessario in sessione elevata).
  3. Verifica se winget esiste e ne riporta la versione.
  4. Controlla se esiste un aggiornamento per "Microsoft.DesktopAppInstaller" (che include winget).
  5. Se disponibile, applica l’upgrade e mostra la versione aggiornata.
  6. Se non ci sono update, lo segnala.
  7. Alla fine, attende la pressione di Invio per non chiudere immediatamente la finestra.

.NOTES
  Per eseguirlo: tasto destro → “Esegui con PowerShell” (o doppio click in Explorer).
#>

# -------- Imposta il comportamento in caso di errore --------
$ErrorActionPreference = 'Stop'

# -------- Funzione per verificare privilegi amministrativi --------
function Test-IsAdministrator {
    $current   = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($current)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

Write-Host "===== Inizio esecuzione: Check-Winget.ps1 =====" -ForegroundColor Cyan

# -------- 1) Rilancio in elevazione se necessario --------
Write-Host "1) Verifica privilegi amministrativi..." -NoNewline
if (-not (Test-IsAdministrator)) {
    Write-Host " NON amministratore" -ForegroundColor Yellow

    # Path a powershell.exe di sistema
    $psExe = Join-Path $env:WINDIR "System32\WindowsPowerShell\v1.0\powershell.exe"
    Write-Host "   → Rilancio lo script con elevazione UAC usando: $psExe" -ForegroundColor Yellow

    Start-Process -FilePath $psExe `
                  -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" `
                  -Verb RunAs
    exit
}
Write-Host " OK (sessione elevata)" -ForegroundColor Green

# -------- 2) Ripristino WindowsApps nel PATH --------
$windowsAppsPath = Join-Path $env:LOCALAPPDATA "Microsoft\WindowsApps"
if (Test-Path $windowsAppsPath) {
    $env:PATH += ";$windowsAppsPath"
    Write-Host "`n[Info] Cartella WindowsApps aggiunta al PATH: $windowsAppsPath"
} else {
    Write-Warning "`n[Warning] Cartella WindowsApps non trovata: $windowsAppsPath"
}

# -------- 3) Verifico presenza di winget e ne recupero il percorso --------
Write-Host "`n2) Verifico presenza di 'winget' nel PATH..."
$wingetCmd = Get-Command winget -ErrorAction SilentlyContinue
if (-not $wingetCmd) {
    Write-Error "   ✖ winget non trovato. Installa 'App Installer' dal Microsoft Store e riprova."
    Read-Host -Prompt "`nPremi Invio per chiudere"
    exit 1
}

$wingetPath = $wingetCmd.Path
Write-Host "   ✔ winget trovato in: $wingetPath"

# Leggo la versione corrente
$oldVersion = & $wingetPath --version 2>$null
Write-Host "   ✔ Versione corrente: $oldVersion"

# -------- 4) Verifico aggiornamenti per App Installer --------
Write-Host "`n3) Verifico aggiornamenti per 'Microsoft.DesktopAppInstaller' (winget)..."
$upgradeInfo = & $wingetPath upgrade --id Microsoft.DesktopAppInstaller --source winget 2>$null

if ($upgradeInfo) {
    Write-Host "   ⬆️  Aggiornamento disponibile:" -ForegroundColor Yellow
    Write-Host $upgradeInfo
    Write-Host "`n   → Avvio l’aggiornamento di App Installer..."
    & $wingetPath upgrade `
        --id Microsoft.DesktopAppInstaller `
        --source winget `
        --accept-source-agreements `
        --accept-package-agreements

    # -------- 5) Mostro versione aggiornata --------
    try {
        $newVersion = & $wingetPath --version
        Write-Host "`n   ✅ Aggiornamento completato con successo!" -ForegroundColor Green
        Write-Host "     Versione precedente: $oldVersion"
        Write-Host "     Nuova versione:      $newVersion"
    }
    catch {
        Write-Warning "   ⚠️  Aggiornamento eseguito, ma non sono riuscito a leggere la nuova versione."
    }
}
else {
    Write-Host "   ✔ Non ci sono aggiornamenti per winget. Resta alla versione: $oldVersion" -ForegroundColor Green
}

# -------- 6) Pausa finale per mantenere la finestra aperta --------
Write-Host "`n===== Esecuzione terminata =====" -ForegroundColor Cyan
Read-Host -Prompt "Premi Invio per chiudere questa finestra"
