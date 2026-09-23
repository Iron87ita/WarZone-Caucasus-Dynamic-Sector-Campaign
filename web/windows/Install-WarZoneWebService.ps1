param(
  [string]$TaskName = "WarZone Web Command Center",
  [int]$Port = 8787
)

$ErrorActionPreference = "Stop"

function Test-Administrator {
  $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
  $principal = New-Object Security.Principal.WindowsPrincipal($identity)
  return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

if (-not (Test-Administrator)) {
  Write-Host "Apri PowerShell come Amministratore e rilancia questo script." -ForegroundColor Yellow
  exit 1
}

$WebRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$Runner = Join-Path $PSScriptRoot "Start-WarZoneWebService.ps1"

$node = (Get-Command node.exe -ErrorAction SilentlyContinue).Source
if (-not $node) {
  $fallback = "C:\Program Files\nodejs\node.exe"
  if (Test-Path $fallback) { $node = $fallback }
}
if (-not $node) {
  throw "Node.js non trovato. Installa Node.js 20+ prima di continuare."
}

$stateCandidates = @(
  "$env:USERPROFILE\Saved Games\DCS.openbeta_server\WarZoneWeb\WarZoneWebState.json",
  "$env:USERPROFILE\Saved Games\DCS.server\WarZoneWeb\WarZoneWebState.json",
  "$env:USERPROFILE\Saved Games\DCS.openbeta\WarZoneWeb\WarZoneWebState.json",
  "$env:USERPROFILE\Saved Games\DCS\WarZoneWeb\WarZoneWebState.json"
)

$StateFile = $stateCandidates | Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $StateFile) {
  throw "WarZoneWebState.json non trovato. Avvia prima la missione WEB LIVE FIX2 in DCS."
}

$arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$Runner`" -StateFile `"$StateFile`" -HostAddress `"127.0.0.1`" -Port $Port"
$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument $arguments
$trigger = New-ScheduledTaskTrigger -AtStartup
$principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
$settings = New-ScheduledTaskSettingsSet `
  -AllowStartIfOnBatteries `
  -DontStopIfGoingOnBatteries `
  -StartWhenAvailable `
  -ExecutionTimeLimit ([TimeSpan]::Zero)

$existing = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
if ($existing) {
  Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
}

Register-ScheduledTask `
  -TaskName $TaskName `
  -Action $action `
  -Trigger $trigger `
  -Principal $principal `
  -Settings $settings `
  -Description "WarZone Caucasus live web command center" | Out-Null

Start-ScheduledTask -TaskName $TaskName
Start-Sleep -Seconds 3

Write-Host "" 
Write-Host "WarZone Web installato per l'avvio automatico di Windows." -ForegroundColor Green
Write-Host "Task: $TaskName"
Write-Host "State: $StateFile"
Write-Host "Locale: http://127.0.0.1:$Port"
Write-Host "Log: $(Join-Path $WebRoot 'logs')"

try {
  $response = Invoke-WebRequest -UseBasicParsing -Uri "http://127.0.0.1:$Port/api/health" -TimeoutSec 5
  Write-Host "Health check: HTTP $($response.StatusCode)" -ForegroundColor Green
} catch {
  Write-Host "Health check non ancora disponibile. Controlla web\logs\warzone-web-error.log." -ForegroundColor Yellow
}
