#requires -Version 5.1

[CmdletBinding()]
param(
    [ValidateSet('Register', 'Inspect')]
    [string]$Action = 'Register'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'SourceArtBackup.Common.ps1')

$config = Get-SourceArtConfig
$taskName = [string]$config.scheduledTaskName
if ($Action -eq 'Inspect') {
    $task = Get-ScheduledTask -TaskName $taskName -ErrorAction Stop
    $info = Get-ScheduledTaskInfo -TaskName $taskName -ErrorAction Stop
    [pscustomobject]@{
        TaskName = $task.TaskName
        State = $task.State
        Enabled = $task.Settings.Enabled
        NextRunTime = $info.NextRunTime
        LastRunTime = $info.LastRunTime
        LastTaskResult = $info.LastTaskResult
        Execute = $task.Actions.Execute
        Arguments = $task.Actions.Arguments
        StartWhenAvailable = $task.Settings.StartWhenAvailable
    } | Format-List
    exit 0
}

$scheduledScript = Join-Path $PSScriptRoot 'Invoke-ScheduledSourceArtBackup.ps1'
if (-not (Test-Path -LiteralPath $scheduledScript -PathType Leaf)) {
    throw "Scheduled Source Art backup script does not exist: $scheduledScript"
}
$repositoryRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$time = [DateTime]::ParseExact([string]$config.scheduleLocalTime, 'HH:mm', [Globalization.CultureInfo]::InvariantCulture)
$arguments = '-NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "{0}"' -f $scheduledScript
$taskAction = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument $arguments -WorkingDirectory $repositoryRoot
$taskTrigger = New-ScheduledTaskTrigger -Daily -At $time
$taskSettings = New-ScheduledTaskSettingsSet -StartWhenAvailable -MultipleInstances IgnoreNew -ExecutionTimeLimit (New-TimeSpan -Hours 12)
$identity = [Security.Principal.WindowsIdentity]::GetCurrent().Name
$taskPrincipal = New-ScheduledTaskPrincipal -UserId $identity -LogonType Interactive -RunLevel Limited
$description = 'Creates a verified local Source Art generation for Broken Streets. Managed by BS-013A.'
Register-ScheduledTask -TaskName $taskName -Action $taskAction -Trigger $taskTrigger -Settings $taskSettings -Principal $taskPrincipal -Description $description -Force | Out-Null
Write-Host "[PASS] Registered scheduled task '$taskName' for $($config.scheduleLocalTime) daily."
& $PSCommandPath -Action Inspect
exit $LASTEXITCODE
