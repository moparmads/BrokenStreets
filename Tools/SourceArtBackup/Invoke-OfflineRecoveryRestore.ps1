#requires -Version 5.1

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$DestinationRoot,
    [switch]$PlanOnly
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'SourceArtBackup.Common.ps1')

function Invoke-OfflineRestoreChild {
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

$destinationPath = $null
$destinationCreated = $false
try {
    $config = Get-SourceArtConfig
    $offlineRoot = Resolve-BrokenStreetsOfflineRoot -Config $config
    $latestPath = Join-Path $offlineRoot 'OfflineLATEST.json'
    if (-not (Test-Path -LiteralPath $latestPath -PathType Leaf)) {
        throw "Offline checkpoint pointer is missing: $latestPath"
    }
    $latest = Read-SourceArtJson -Path $latestPath
    if (([int]$latest.schemaVersion -ne 1) -or ([string]$latest.checkpointId -notmatch '^[0-9]{8}T[0-9]{6}Z-[0-9]+-[0-9a-f]{8}$')) {
        throw 'Offline checkpoint pointer is invalid.'
    }
    $checkpointRoot = Join-Path (Join-Path $offlineRoot 'Checkpoints') ([string]$latest.checkpointId)
    $checkpointPath = Join-Path $checkpointRoot 'checkpoint.json'
    $checksumsPath = Join-Path $checkpointRoot 'checksums.sha256'
    if (-not [string]::Equals((Get-SourceArtSha256 -Path $checkpointPath), [string]$latest.checkpointSha256, [StringComparison]::OrdinalIgnoreCase)) {
        throw 'Offline checkpoint manifest checksum does not match its pointer.'
    }
    if (-not [string]::Equals((Get-SourceArtSha256 -Path $checksumsPath), [string]$latest.checksumsSha256, [StringComparison]::OrdinalIgnoreCase)) {
        throw 'Offline checkpoint checksum file does not match its pointer.'
    }
    $checkpoint = Read-SourceArtJson -Path $checkpointPath
    if (([int]$checkpoint.schemaVersion -ne 1) -or ([string]$checkpoint.status -ne 'PASS') -or (-not [string]::Equals([string]$checkpoint.offlineStoreId, [string]$config.offlineStoreId, [StringComparison]::OrdinalIgnoreCase))) {
        throw 'Offline checkpoint manifest is invalid or belongs to another drive.'
    }
    $repositoryBackupRoot = Join-Path $offlineRoot ([string]$checkpoint.repository.backupRoot)
    $sourceArtBackupRoot = Join-Path $offlineRoot ([string]$checkpoint.sourceArt.backupRoot)
    $repositoryLatestPath = Join-Path $repositoryBackupRoot 'LATEST.json'
    $sourceArtLatestPath = Join-Path $sourceArtBackupRoot 'LATEST.json'
    if (-not [string]::Equals((Get-SourceArtSha256 -Path $repositoryLatestPath), [string]$checkpoint.repository.latestPointerSha256, [StringComparison]::OrdinalIgnoreCase)) {
        throw 'Repository latest pointer changed after the selected offline checkpoint.'
    }
    if (-not [string]::Equals((Get-SourceArtSha256 -Path $sourceArtLatestPath), [string]$checkpoint.sourceArt.latestPointerSha256, [StringComparison]::OrdinalIgnoreCase)) {
        throw 'Source Art latest pointer changed after the selected offline checkpoint.'
    }

    $destinationPath = Assert-SourceArtNewRestoreDestination -DestinationRoot $DestinationRoot -ProtectedRoots @(
        [string]$config.sourceRoot,
        'F:\BrokenStreets',
        'F:\UE_5.8.2',
        [string]$config.localBackupRoot,
        $offlineRoot
    )
    $repositoryDestination = Join-Path $destinationPath 'Repository'
    $sourceArtDestination = Join-Path $destinationPath 'SourceArt'
    $toolsRoot = Split-Path -Parent $PSScriptRoot
    $repositoryRestoreScript = Join-Path $toolsRoot 'Backup\Invoke-RepositoryRestore.ps1'
    $sourceArtRestoreScript = Join-Path $PSScriptRoot 'Invoke-SourceArtRestore.ps1'
    $repositoryArguments = @(
        '-BackupRoot', $repositoryBackupRoot,
        '-DestinationRoot', $repositoryDestination,
        '-GenerationId', [string]$checkpoint.repository.generationId
    )
    $sourceArtArguments = @(
        '-Target', 'Offline',
        '-BackupRoot', $sourceArtBackupRoot,
        '-DestinationRoot', $sourceArtDestination,
        '-GenerationId', [string]$checkpoint.sourceArt.generationId
    )
    if ($PlanOnly) {
        $repositoryArguments += '-PlanOnly'
        $sourceArtArguments += '-PlanOnly'
    }
    else {
        New-Item -ItemType Directory -Path $destinationPath | Out-Null
        $destinationCreated = $true
    }
    Invoke-OfflineRestoreChild -Label 'Offline repository restore verification' -ScriptPath $repositoryRestoreScript -Arguments $repositoryArguments
    Invoke-OfflineRestoreChild -Label 'Offline Source Art restore verification' -ScriptPath $sourceArtRestoreScript -Arguments $sourceArtArguments
    if ($PlanOnly) {
        Write-SourceArtMessage -Level 'PASS' -Message 'Complete offline restore plan passed; no destination was created.'
        exit 0
    }

    $result = [ordered]@{
        schemaVersion = 1
        status = 'PASS'
        checkpointId = [string]$latest.checkpointId
        completedUtc = [DateTime]::UtcNow.ToString('o')
        networkUsed = $false
        repositoryGenerationId = [string]$checkpoint.repository.generationId
        sourceArtGenerationId = [string]$checkpoint.sourceArt.generationId
        repositoryRestore = $repositoryDestination
        sourceArtRestore = $sourceArtDestination
    }
    Write-SourceArtAtomicJson -Path (Join-Path $destinationPath 'OfflineRestore.json') -Value $result
    Write-SourceArtMessage -Level 'PASS' -Message "Restored the complete offline checkpoint $($latest.checkpointId) without GitHub."
    exit 0
}
catch {
    Write-SourceArtMessage -Level 'FAIL' -Message $_.Exception.Message
    if ($destinationCreated -and ($null -ne $destinationPath)) {
        Write-SourceArtMessage -Level 'INFO' -Message "Partial offline restore retained for diagnosis: $destinationPath"
    }
    exit 1
}
