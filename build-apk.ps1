# FIRE-EYE One-Click Release APK Builder
$ErrorActionPreference = 'Stop'

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location (Join-Path $scriptDir "mobile_app")

$ANON_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inh3aXdtd2d5YXlxeWhrZmlpbm52Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTM0NTQwMTksImV4cCI6MjEwOTAzMDAxOX0.kOdGBwpIx0qUgHAp2tAwRNsOrTy9NULNbtdbKHDkrjI"

Write-Host "=================================================" -ForegroundColor Cyan
Write-Host " Building FIRE-EYE Release APK with Supabase Auth" -ForegroundColor Cyan
Write-Host "=================================================" -ForegroundColor Cyan

flutter build apk --release `
  --dart-define=BACKEND_BASE_URL=https://hackathon-1-cs4a.onrender.com `
  --dart-define=SUPABASE_URL=https://xwiwmwgyayqyhkfiinnv.supabase.co `
  --dart-define=SUPABASE_ANON_KEY=$ANON_KEY `
  --dart-define=MESH_HMAC_KEY=fire-eye-mesh-hmac-sha256-default-key-32b

if ($LASTEXITCODE -eq 0) {
    Write-Host "`n[SUCCESS] APK created at: mobile_app\build\app\outputs\flutter-apk\app-release.apk" -ForegroundColor Green
}

