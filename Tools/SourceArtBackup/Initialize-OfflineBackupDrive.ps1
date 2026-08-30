#requires -Version 5.1

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$DriveRoot
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'SourceArtBackup.Common.ps1')

try {
    $config = Get-SourceArtConfig
    $normalizedDriveRoot = Get-SourceArtFullPath -Path $DriveRoot
    $pathRoot = [System.IO.Path]::GetPathRoot($normalizedDriveRoot)
    if (-not [string]::Equals($normalizedDriveRoot.TrimEnd([char[]]@('\', '/')), $pathRoot.TrimEnd([char[]]@('\', '/')), [StringComparison]::OrdinalIgnoreCase)) {
        throw "DriveRoot must be an exact drive root such as G:\: $normalizedDriveRoot"
    }
    foreach ($forbiddenRoot in @(
        [System.IO.Path]::GetPathRoot([string]$config.sourceRoot),
        [System.IO.Path]::GetPathRoot([string]$config.localBackupRoot),
        [System.IO.Path]::GetPathRoot('C:\Windows')
    )) {
        if ([string]::Equals($pathRoot, $forbiddenRoot, [StringComparison]::OrdinalIgnoreCase)) {
            throw "Refusing to initialize the offline store on a protected working, local-backup, or system drive: $pathRoot"
        }
    }

    $drive = Get-SourceArtDriveInfo -Path $pathRoot
    $offlineRoot = Join-Path $pathRoot ([string]$config.offlineRelativeRoot)
    $markerPath = Join-Path $offlineRoot 'OfflineDrive.json'
    if (Test-Path -LiteralPath $markerPath -PathType Leaf) {
        $existing = Read-SourceArtJson -Path $markerPath
        if (([int]$existing.schemaVersion -ne 1) -or (-not [string]::Equals([string]$existing.offlineStoreId, [string]$config.offlineStoreId, [StringComparison]::OrdinalIgnoreCase))) {
            throw "A different offline-store marker already exists: $markerPath"
        }
        Write-SourceArtMessage -Level 'PASS' -Message "Approved offline drive is already initialized: $offlineRoot"
        exit 0
    }
    if (Test-Path -LiteralPath $offlineRoot -PathType Container) {
        $existingItems = @(Get-ChildItem -LiteralPath $offlineRoot -Force)
        if ($existingItems.Count -gt 0) {
            throw "Refusing to initialize a non-empty unmarked offline root: $offlineRoot"
        }
    }
    else {
        New-Item -ItemType Directory -Path $offlineRoot | Out-Null
    }

    $marker = [ordered]@{
        schemaVersion = 1
        format = 'BrokenStreets.OfflineRecoveryDrive'
        offlineStoreId = [string]$config.offlineStoreId
        createdUtc = [DateTime]::UtcNow.ToString('o')
        owner = [string]$config.owner
        volumeLabelAtInitialization = [string]$drive.VolumeLabel
        totalSizeBytesAtInitialization = [Int64]$drive.TotalSize
        encryptionPolicy = [string]$config.encryptionPolicy
        offsitePolicy = [string]$config.offsitePolicy
    }
    Write-SourceArtAtomicJson -Path $markerPath -Value $marker
    foreach ($folder in @('Checkpoints', '.Staging', 'Logs', 'RestoreTests')) {
        New-Item -ItemType Directory -Path (Join-Path $offlineRoot $folder) -Force | Out-Null
    }
    Write-SourceArtMessage -Level 'PASS' -Message "Initialized the approved Broken Streets offline root: $offlineRoot"
    Write-SourceArtMessage -Level 'WARN' -Message 'This drive is not encrypted. Keep it physically controlled and stored separately after a successful checkpoint.'
    exit 0
}
catch {
    Write-SourceArtMessage -Level 'FAIL' -Message $_.Exception.Message
    exit 1
}
