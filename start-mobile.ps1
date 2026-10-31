param(
  [string]$Device = '',
  [switch]$Release,
  [switch]$Local,
  [switch]$Web
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$mobile = Join-Path $root 'mobile_app'

# Resolve Flutter executable
$flutterCmd = 'flutter'
if (-not (Get-Command 'flutter' -ErrorAction SilentlyContinue)) {
  $candidateFlutter = 'C:\Users\Gehu\flutter\bin\flutter.bat'
  if (Test-Path $candidateFlutter) {
    $flutterCmd = $candidateFlutter
  } else {
    throw "Flutter SDK executable not found in PATH or at C:\Users\Gehu\flutter\bin\flutter.bat"
  }
}

# Default target device
$targetDevice = $Device
if ($Web -or [string]::IsNullOrWhiteSpace($targetDevice)) {
  $targetDevice = 'chrome'
}

if ($Local) {
  $backend = Join-Path $root 'backend'
  $python = Join-Path $backend 'venv\Scripts\python.exe'

  if (-not (Test-Path $python)) {
    throw "Backend virtual environment not found at $python. Create it with: python -m venv backend\venv"
  }

  Write-Host "[FIRE-EYE] Starting local FastAPI backend at http://127.0.0.1:8000..." -ForegroundColor Yellow
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
      $args = @('run', "--device-id=$targetDevice", '--dart-define=BACKEND_BASE_URL=http://127.0.0.1:8000')
      if ($Release) {
        $args += '--release'
      }
      & $flutterCmd @args
    } finally {
      Pop-Location
    }
  } finally {
    if (-not $backendProcess.HasExited) {
      Stop-Process -Id $backendProcess.Id -Force
    }
  }
} else {
  Write-Host "[FIRE-EYE] Connecting frontend to Live Render Backend: https://fireeye-astrix-backend.onrender.com" -ForegroundColor Cyan
  Write-Host "[FIRE-EYE] Target Device: $targetDevice" -ForegroundColor Green
  Push-Location $mobile
  try {
    $args = @('run', "--device-id=$targetDevice")
    if ($Release) {
      $args += '--release'
    }
    & $flutterCmd @args
  } finally {
    Pop-Location
  }
}
