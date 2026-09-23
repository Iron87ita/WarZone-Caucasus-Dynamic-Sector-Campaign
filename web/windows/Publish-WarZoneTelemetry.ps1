param(
  [Parameter(Mandatory=$true)][string]$Endpoint,
  [Parameter(Mandatory=$true)][string]$Token,
  [string]$StateFile = "$env:USERPROFILE\Saved Games\DCS\WarZoneWeb\WarZoneWebState.json",
  [int]$IntervalSeconds = 2
)

$ErrorActionPreference = 'Stop'
$headers = @{ Authorization = "Bearer $Token" }
$lastWrite = [datetime]::MinValue

Write-Host "WarZone telemetry publisher"
Write-Host "State file: $StateFile"
Write-Host "Endpoint:   $Endpoint"

while ($true) {
  try {
    if (Test-Path $StateFile) {
      $item = Get-Item $StateFile
      if ($item.LastWriteTimeUtc -gt $lastWrite) {
        $json = Get-Content -Raw -Path $StateFile
        $null = $json | ConvertFrom-Json
        Invoke-RestMethod -Method Post -Uri $Endpoint -Headers $headers -ContentType 'application/json' -Body $json -TimeoutSec 10 | Out-Null
        $lastWrite = $item.LastWriteTimeUtc
        Write-Host "[$(Get-Date -Format s)] telemetry sent"
      }
    } else {
      Write-Warning "State file not found: $StateFile"
    }
  } catch {
    Write-Warning "Telemetry send failed: $($_.Exception.Message)"
  }
  Start-Sleep -Seconds $IntervalSeconds
}
