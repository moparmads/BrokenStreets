#requires -Version 5.1

[CmdletBinding()]
param(
    [ValidateSet('Register', 'Inspect')]
    [string]$Action = 'Register'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$configPath = Join-Path $PSScriptRoot 'RepositoryBackupConfig.json'
$config = Get-Content -Raw -LiteralPath $configPath | ConvertFrom-Json
if ([int]$config.schemaVersion -ne 1) {
    throw "Unsupported backup configuration schema: $($config.schemaVersion)"
}

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

$repositoryRoot = [System.IO.Path]::GetFullPath([string]$config.repositoryRoot).TrimEnd([char[]]@('\', '/'))
$backupScript = Join-Path $repositoryRoot 'Tools\Backup\Invoke-RepositoryBackup.ps1'
if (-not (Test-Path -LiteralPath $backupScript -PathType Leaf)) {
    throw "Backup script does not exist: $backupScript"
}

$time = [DateTime]::ParseExact([string]$config.scheduleLocalTime, 'HH:mm', [Globalization.CultureInfo]::InvariantCulture)
$powershellArguments = '-NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "{0}" -AllowDirty' -f $backupScript
$taskAction = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument $powershellArguments -WorkingDirectory $repositoryRoot
$taskTrigger = New-ScheduledTaskTrigger -Daily -At $time
$taskSettings = New-ScheduledTaskSettingsSet -StartWhenAvailable -MultipleInstances IgnoreNew -ExecutionTimeLimit (New-TimeSpan -Hours 6)
$identity = [Security.Principal.WindowsIdentity]::GetCurrent().Name
$taskPrincipal = New-ScheduledTaskPrincipal -UserId $identity -LogonType Interactive -RunLevel Limited

$description = 'Creates a verified independent Git and Git LFS backup for Broken Streets. Managed by BS-010A.'
Register-ScheduledTask -TaskName $taskName -Action $taskAction -Trigger $taskTrigger -Settings $taskSettings -Principal $taskPrincipal -Description $description -Force | Out-Null

Write-Host "[PASS] Registered scheduled task '$taskName' for $($config.scheduleLocalTime) daily."
& $PSCommandPath -Action Inspect
exit $LASTEXITCODE
