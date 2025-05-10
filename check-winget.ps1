<#
.SYNOPSIS
  Check-Winget.ps1 – Verifica presenza e versione di winget, applica upgrade di App Installer,
                     con messaggi esplicativi e pausa finale per mantenere aperta la finestra.

.DESCRIPTION
  1. Controlla se lo script è in esecuzione come Amministratore; in caso contrario si rilancia in elevazione.
  2. Verifica se winget esiste e ne riporta la versione.
  3. Controlla se esiste un aggiornamento per "Microsoft.DesktopAppInstaller" (che include winget).
  4. Se disponibile, applica l’upgrade e mostra la versione aggiornata.
  5. Se non ci sono update, lo segnala.
  6. Alla fine, attende la pressione di Invio per non chiudere immediatamente la finestra.

.NOTES
  Per eseguirlo: tasto destro → “Esegui con PowerShell” (o doppio click in Explorer).
#>

# -------- Imposta il comportamento in caso di errore --------
$ErrorActionPreference = 'Stop'

# -------- Funzione per verificare privilegi amministrativi --------
function Test-IsAdministrator {
    $current = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($current)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

Write-Host "===== Inizio esecuzione: Check-Winget.ps1 =====" -ForegroundColor Cyan

# -------- 1) Rilancio in elevazione se necessario --------
Write-Host "1) Verifica privilegi amministrativi..." -NoNewline
if (-not (Test-IsAdministrator)) {
    Write-Host " NON amministratore" -ForegroundColor Yellow
    Write-Host "   → Rilancio lo script con elevazione UAC..." -ForegroundColor Yellow
    Start-Process -FilePath pwsh.exe `
                  -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" `
                  -Verb RunAs
    exit
}
Write-Host " OK (sessione elevata)" -ForegroundColor Green

# -------- 2) Controllo presenza e versione di winget --------
Write-Host "`n2) Controllo se 'winget' è installato e ne leggo la versione..."
try {
    $oldVersion = winget --version 2>$null
    Write-Host "   ✔ winget trovato. Versione corrente: $oldVersion"
}
catch {
    Write-Error "   ✖ winget NON è installato. Installa 'App Installer' da Microsoft Store e riprova."
    Read-Host -Prompt "`nPremi Invio per chiudere"
    exit 1
}

# -------- 3) Verifico aggiornamenti per App Installer --------
Write-Host "`n3) Verifico aggiornamenti per 'Microsoft.DesktopAppInstaller' (winget)..."
$upgradeInfo = winget upgrade --id Microsoft.DesktopAppInstaller --source winget 2>$null

if ($upgradeInfo) {
    Write-Host "   ⬆️  Aggiornamento disponibile:" -ForegroundColor Yellow
    Write-Host $upgradeInfo
    Write-Host "`n   → Avvio l’aggiornamento di App Installer..."
    winget upgrade `
        --id Microsoft.DesktopAppInstaller `
        --source winget `
        --accept-source-agreements `
        --accept-package-agreements

    # -------- 4) Mostro versione aggiornata --------
    try {
        $newVersion = winget --version
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

# -------- 5) Pausa finale per mantenere la finestra aperta --------
Write-Host "`n===== Esecuzione terminata =====" -ForegroundColor Cyan
Read-Host -Prompt "Premi Invio per chiudere questa finestra"
