$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$backend = Join-Path $root 'backend'
$python = Join-Path $backend 'venv\Scripts\python.exe'

if (-not (Test-Path $python)) {
  throw "Backend virtual environment not found at $python. Create it with: python -m venv backend\venv"
}

Push-Location $backend
try {
  & $python -m uvicorn app.main:app --host 0.0.0.0 --port 8000
} finally {
  Pop-Location
}
