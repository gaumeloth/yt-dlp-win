<#
  Script: Check-Winget.ps1
  Scopo: verifica winget, controlla versione e applica eventuale upgrade di App Installer,
         rilanciandosi con privilegi amministrativi se necessario.
#>

# Funzione: verifica se lo script è in esecuzione con privilegi Admin
function Test-IsAdministrator {
    $current = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($current)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# 1) Se non sono admin, rilancio lo script elevato e esco
if (-not (Test-IsAdministrator)) {
    Write-Warning "Lo script necessita di privilegi di amministratore. Rilancio con elevazione UAC..."
    Start-Process -FilePath pwsh.exe `
                  -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" `
                  -Verb RunAs
    exit
}

# 2) Controllo presenza e versione di winget
try {
    $version = winget --version 2>$null
    Write-Host "✔ winget trovato, versione installata: $version"
}
catch {
    Write-Error "✖ winget NON è installato. Installa 'App Installer' da Microsoft Store."
    exit 1
}

# 3) Verifico e applico aggiornamento di App Installer (winget stesso)
$upgradeInfo = winget upgrade --id Microsoft.DesktopAppInstaller --source winget 2>$null
if ($upgradeInfo) {
    Write-Host "⬆️  Aggiornamento disponibile per App Installer:"
    Write-Host $upgradeInfo
    Write-Host "→ Avvio aggiornamento..."
    winget upgrade `
        --id Microsoft.DesktopAppInstaller `
        --source winget `
        --accept-source-agreements `
        --accept-package-agreements
    Write-Host "✅ Aggiornamento completato."
}
else {
    Write-Host "✔ winget è già all'ultima versione."
}
