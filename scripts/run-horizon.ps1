# Daily AI news briefing: runs Horizon and keeps a log of each run.
# Started by the Windows scheduled task "Horizon AI Daily" (see register-task.ps1).

param(
    [string]$Horizon = (Join-Path (Split-Path $PSScriptRoot -Parent) 'Horizon'),
    [string]$LogDir  = (Join-Path (Split-Path $PSScriptRoot -Parent) 'logs')
)

$ErrorActionPreference = 'Continue'
New-Item -ItemType Directory -Force $LogDir | Out-Null
$log = Join-Path $LogDir ("horizon-{0}.log" -f (Get-Date -Format 'yyyy-MM-dd_HHmm'))

Set-Location $Horizon
$env:PYTHONIOENCODING = 'utf-8'
$env:COLUMNS = '250'
& (Join-Path $Horizon '.venv\Scripts\horizon.exe') -l WARNING *> $log
"`nExit code: $LASTEXITCODE" | Out-File $log -Append -Encoding utf8

# Keep the 30 most recent logs.
Get-ChildItem $LogDir -Filter 'horizon-*.log' | Sort-Object LastWriteTime -Descending |
    Select-Object -Skip 30 | Remove-Item -Force
