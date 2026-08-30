#requires -Version 5.1

[CmdletBinding()]
param(
    [switch]$PlanOnly
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'SourceArtBackup.Common.ps1')

function Invoke-OfflineChild {
    param(
        [Parameter(Mandatory = $true)][string]$Label,
        [Parameter(Mandatory = $true)][string]$ScriptPath,
        [Parameter(Mandatory = $true)][string[]]$Arguments
    )

    Write-SourceArtMessage -Level 'RUN' -Message $Label
    $previousErrorActionPreference = $ErrorActionPreference
    try {
        $ErrorActionPreference = 'Continue'
        $output = @(& powershell.exe -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -File $ScriptPath @Arguments 2>&1)
        $exitCode = $LASTEXITCODE
    }
    finally {
        $ErrorActionPreference = $previousErrorActionPreference
    }
    foreach ($line in $output) {
        Write-Host $line.ToString()
    }
    if ($exitCode -ne 0) {
        throw "$Label failed with exit code $exitCode."
    }
}

$stagingPath = $null
try {
    $config = Get-SourceArtConfig
    $offlineRoot = Resolve-BrokenStreetsOfflineRoot -Config $config
    $drive = Get-SourceArtDriveInfo -Path $offlineRoot
    $hardReserveBytes = [Int64]([double]$config.hardMinimumFreeSpaceGiB * 1GB)
    if ($drive.AvailableFreeSpace -lt $hardReserveBytes) {
        throw "The offline drive is below the $($config.hardMinimumFreeSpaceGiB) GiB hard reserve."
    }
    if ($drive.AvailableFreeSpace -lt [Int64]([double]$config.warningFreeSpaceGiB * 1GB)) {
        Write-SourceArtMessage -Level 'WARN' -Message "Offline drive free space is below $($config.warningFreeSpaceGiB) GiB."
    }

    $toolsRoot = Split-Path -Parent $PSScriptRoot
    $repositoryScript = Join-Path $toolsRoot 'Backup\Invoke-RepositoryBackup.ps1'
    $sourceArtScript = Join-Path $PSScriptRoot 'Invoke-SourceArtBackup.ps1'
    $repositoryBackupRoot = Join-Path $offlineRoot ([string]$config.repositoryOfflineRelativeRoot)
    $sourceArtBackupRoot = Join-Path $offlineRoot ([string]$config.sourceArtOfflineRelativeRoot)

    $repositoryArguments = @('-BackupRoot', $repositoryBackupRoot, '-SkipOriginRefresh')
    $sourceArtArguments = @('-Target', 'Offline', '-BackupRoot', $sourceArtBackupRoot, '-FullObjectAudit')
    if ($PlanOnly) {
        $repositoryArguments += '-PlanOnly'
        $sourceArtArguments += '-PlanOnly'
    }
    Invoke-OfflineChild -Label 'Repository and Git LFS offline backup' -ScriptPath $repositoryScript -Arguments $repositoryArguments
    Invoke-OfflineChild -Label 'Source Art offline backup' -ScriptPath $sourceArtScript -Arguments $sourceArtArguments
    if ($PlanOnly) {
        Write-SourceArtMessage -Level 'PASS' -Message 'Offline recovery checkpoint plan passed; no checkpoint was published.'
        exit 0
    }

    $repositoryLatestPath = Join-Path $repositoryBackupRoot 'LATEST.json'
    $sourceArtLatestPath = Join-Path $sourceArtBackupRoot 'LATEST.json'
    $repositoryLatest = Read-SourceArtJson -Path $repositoryLatestPath
    $sourceArtLatest = Read-SourceArtJson -Path $sourceArtLatestPath
    $checkpointId = '{0}-{1}-{2}' -f [DateTime]::UtcNow.ToString('yyyyMMddTHHmmssZ'), $PID, ([Guid]::NewGuid().ToString('N').Substring(0, 8))
    $stagingPath = Join-Path (Join-Path $offlineRoot '.Staging') $checkpointId
    New-Item -ItemType Directory -Path $stagingPath -Force | Out-Null
    $checkpoint = [ordered]@{
        schemaVersion = 1
        format = 'BrokenStreets.OfflineRecoveryCheckpoint'
        status = 'PASS'
        checkpointId = $checkpointId
        completedUtc = [DateTime]::UtcNow.ToString('o')
        offlineStoreId = [string]$config.offlineStoreId
        repository = [ordered]@{
            backupRoot = [string]$config.repositoryOfflineRelativeRoot
            generationId = [string]$repositoryLatest.generationId
            sourceCommit = [string]$repositoryLatest.sourceCommit
            latestPointerSha256 = Get-SourceArtSha256 -Path $repositoryLatestPath
        }
        sourceArt = [ordered]@{
            backupRoot = [string]$config.sourceArtOfflineRelativeRoot
            generationId = [string]$sourceArtLatest.generationId
            fileCount = [int]$sourceArtLatest.fileCount
            totalBytes = [Int64]$sourceArtLatest.totalBytes
            latestPointerSha256 = Get-SourceArtSha256 -Path $sourceArtLatestPath
        }
        encryptionPolicy = [string]$config.encryptionPolicy
        offsitePolicy = [string]$config.offsitePolicy
    }
    $checkpointPath = Join-Path $stagingPath 'checkpoint.json'
    Write-SourceArtAtomicJson -Path $checkpointPath -Value $checkpoint
    $checkpointHash = Get-SourceArtSha256 -Path $checkpointPath
    Write-SourceArtAtomicText -Path (Join-Path $stagingPath 'checksums.sha256') -Content "$checkpointHash`tcheckpoint.json$([Environment]::NewLine)"
    $publishedPath = Join-Path (Join-Path $offlineRoot 'Checkpoints') $checkpointId
    [System.IO.Directory]::Move($stagingPath, $publishedPath)
    $stagingPath = $null

    $pointer = [ordered]@{
        schemaVersion = 1
        checkpointId = $checkpointId
        completedUtc = [DateTime]::UtcNow.ToString('o')
        checkpointSha256 = $checkpointHash
        checksumsSha256 = Get-SourceArtSha256 -Path (Join-Path $publishedPath 'checksums.sha256')
    }
    $offlineLatestPath = Join-Path $offlineRoot 'OfflineLATEST.json'
    $offlinePreviousPath = Join-Path $offlineRoot 'OfflineLATEST.previous.json'
    if (Test-Path -LiteralPath $offlineLatestPath -PathType Leaf) {
        Write-SourceArtAtomicText -Path $offlinePreviousPath -Content ([System.IO.File]::ReadAllText($offlineLatestPath, $script:SourceArtUtf8NoBom))
    }
    Write-SourceArtAtomicJson -Path $offlineLatestPath -Value $pointer

    Write-SourceArtMessage -Level 'PASS' -Message "Published offline recovery checkpoint $checkpointId."
    Write-SourceArtMessage -Level 'INFO' -Message "Repository generation: $($repositoryLatest.generationId)"
    Write-SourceArtMessage -Level 'INFO' -Message "Source Art generation: $($sourceArtLatest.generationId)"
    Write-SourceArtMessage -Level 'WARN' -Message 'Safely eject this unencrypted drive and store it separately from the PC.'
    exit 0
}
catch {
    Write-SourceArtMessage -Level 'FAIL' -Message $_.Exception.Message
    if (($null -ne $stagingPath) -and (Test-Path -LiteralPath $stagingPath -PathType Container)) {
        Write-SourceArtMessage -Level 'INFO' -Message "Failed checkpoint staging retained for diagnosis: $stagingPath"
    }
    exit 1
}
