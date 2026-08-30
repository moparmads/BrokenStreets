#requires -Version 5.1

[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'SourceArtBackup.Common.ps1')

$config = Get-SourceArtConfig
$repositoryRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$logRoot = Join-Path $repositoryRoot 'Saved\SourceArtBackupScheduled'
New-Item -ItemType Directory -Path $logRoot -Force | Out-Null
$logPath = Join-Path $logRoot ('Scheduled-{0}.log' -f [DateTime]::UtcNow.ToString('yyyyMMddTHHmmssZ'))
$backupScript = Join-Path $PSScriptRoot 'Invoke-SourceArtBackup.ps1'
$previousErrorActionPreference = $ErrorActionPreference
try {
    $ErrorActionPreference = 'Continue'
    $output = @(& powershell.exe -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -File $backupScript -Target Local 2>&1)
    $exitCode = $LASTEXITCODE
}
finally {
    $ErrorActionPreference = $previousErrorActionPreference
}
$text = ($output | ForEach-Object { $_.ToString() }) -join [Environment]::NewLine
Write-SourceArtAtomicText -Path $logPath -Content ($text + [Environment]::NewLine)
foreach ($line in $output) {
    Write-Host $line.ToString()
}
exit $exitCode
