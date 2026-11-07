# One-time setup: clone Horizon at the tested version, apply the fixes,
# install it into a virtual environment, and copy in this repo's config.
#
#   powershell -ExecutionPolicy Bypass -File scripts\setup.ps1
#
# Afterwards: fill in Horizon\.env and Horizon\data\subscribers.json, then
# run scripts\register-task.ps1 to schedule the daily run.

$ErrorActionPreference = 'Stop'
$repo    = Split-Path $PSScriptRoot -Parent
$horizon = Join-Path $repo 'Horizon'
$tested  = 'd7406f738c711df82b8f060fa1d5e9999d36cca0'   # Horizon main, 3 Nov 2026

if (-not (Test-Path $horizon)) {
    git clone https://github.com/Thysrael/Horizon.git $horizon
}
Push-Location $horizon
try {
    git checkout $tested
    git apply --check (Join-Path $repo 'patches\horizon-fixes.patch') 2>$null
    if ($LASTEXITCODE -eq 0) { git apply (Join-Path $repo 'patches\horizon-fixes.patch') }
    else { Write-Host 'Patch already applied or not applicable; skipping.' }

    if (-not (Test-Path '.venv')) { python -m venv .venv }
    .\.venv\Scripts\python.exe -m pip install --upgrade pip -q
    .\.venv\Scripts\python.exe -m pip install -e . -q

    Copy-Item (Join-Path $repo 'profiles\ai-news') 'profiles\ai-news' -Recurse -Force
    Copy-Item (Join-Path $repo 'config\config.json') 'data\config.json' -Force
    if (-not (Test-Path 'data\subscribers.json')) {
        Copy-Item (Join-Path $repo 'config\subscribers.example.json') 'data\subscribers.json'
    }
    if (-not (Test-Path '.env')) { Copy-Item (Join-Path $repo '.env.example') '.env' }
}
finally { Pop-Location }

Write-Host "`nDone. Next:"
Write-Host "  1. Put your keys in $horizon\.env"
Write-Host "  2. Set email.email_address in $horizon\data\config.json and your address in data\subscribers.json"
Write-Host "  3. Test:     $horizon\.venv\Scripts\horizon.exe --hours 4"
Write-Host "  4. Schedule: powershell -ExecutionPolicy Bypass -File scripts\register-task.ps1"
