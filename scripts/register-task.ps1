# Registers the daily Windows scheduled task that runs the briefing.
#
#   powershell -ExecutionPolicy Bypass -File scripts\register-task.ps1 -At 6:30am

param([string]$At = '6:30am')

$runner = Join-Path $PSScriptRoot 'run-horizon.ps1'
$action = New-ScheduledTaskAction -Execute 'powershell.exe' `
    -Argument "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$runner`""
$trigger = New-ScheduledTaskTrigger -Daily -At $At
# Run late if the PC was off, only with a network, never overlap, stop after 45 min.
$settings = New-ScheduledTaskSettingsSet -StartWhenAvailable -RunOnlyIfNetworkAvailable `
    -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries `
    -ExecutionTimeLimit (New-TimeSpan -Minutes 45) -MultipleInstances IgnoreNew

Register-ScheduledTask -TaskName 'Horizon AI Daily' -Description 'Morning AI news briefing (Horizon)' `
    -Action $action -Trigger $trigger -Settings $settings -Force | Out-Null
Get-ScheduledTask -TaskName 'Horizon AI Daily' | Get-ScheduledTaskInfo | Select-Object TaskName, NextRunTime
