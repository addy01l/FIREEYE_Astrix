param(
  [string]$Device = '',
  [switch]$Release
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$backend = Join-Path $root 'backend'
$mobile = Join-Path $root 'mobile_app'
$python = Join-Path $backend 'venv\Scripts\python.exe'

if (-not (Test-Path $python)) {
  throw "Backend virtual environment not found at $python. Create it with: python -m venv backend\venv"
}

$backendProcess = Start-Process `
  -FilePath $python `
  -ArgumentList '-m', 'uvicorn', 'app.main:app', '--host', '0.0.0.0', '--port', '8000' `
  -WorkingDirectory $backend `
  -PassThru

try {
  $healthUrl = 'http://127.0.0.1:8000/health'
  $ready = $false
  for ($attempt = 0; $attempt -lt 30; $attempt++) {
    Start-Sleep -Seconds 1
    try {
      $health = Invoke-RestMethod -Uri $healthUrl -TimeoutSec 2
      if ($health.status -eq 'ok') {
        $ready = $true
        break
      }
    } catch {
      if ($backendProcess.HasExited) {
        throw "Backend exited before becoming ready."
      }
    }
  }
  if (-not $ready) {
    throw "Backend did not become ready at $healthUrl."
  }

  Push-Location $mobile
  try {
    $args = @('run')
    if ($Device -ne '') {
      $args += @('-d', $Device)
    }
    if ($Release) {
      $args += '--release'
    }
    & flutter @args
    if ($LASTEXITCODE -ne 0) {
      exit $LASTEXITCODE
    }
  } finally {
    Pop-Location
  }
} finally {
  if (-not $backendProcess.HasExited) {
    Stop-Process -Id $backendProcess.Id
  }
}
