param(
  [Parameter(Mandatory = $true)]
  [string]$StateFile,

  [string]$HostAddress = "127.0.0.1",
  [int]$Port = 8787
)

$ErrorActionPreference = "Stop"

$WebRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$ServerFile = Join-Path $WebRoot "server.js"
$LogDir = Join-Path $WebRoot "logs"
$StdoutLog = Join-Path $LogDir "warzone-web.log"
$StderrLog = Join-Path $LogDir "warzone-web-error.log"

New-Item -ItemType Directory -Force -Path $LogDir | Out-Null

$node = (Get-Command node.exe -ErrorAction SilentlyContinue).Source
if (-not $node) {
  $fallback = "C:\Program Files\nodejs\node.exe"
  if (Test-Path $fallback) { $node = $fallback }
}

if (-not $node) {
  Add-Content -Path $StderrLog -Value "$(Get-Date -Format o) Node.js not found."
  exit 1
}

$env:HOST = $HostAddress
$env:PORT = [string]$Port
$env:WARZONE_STATE_FILE = $StateFile
$env:WARZONE_HEALTH_DETAILS = "0"

Set-Location $WebRoot

while ($true) {
  Add-Content -Path $StdoutLog -Value "$(Get-Date -Format o) Starting WarZone Web Command Center on $HostAddress`:$Port"
  & $node $ServerFile 1>> $StdoutLog 2>> $StderrLog
  $exitCode = $LASTEXITCODE
  Add-Content -Path $StderrLog -Value "$(Get-Date -Format o) Node exited with code $exitCode. Restarting in 5 seconds."
  Start-Sleep -Seconds 5
}
