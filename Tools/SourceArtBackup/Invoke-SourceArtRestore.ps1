#requires -Version 5.1

[CmdletBinding()]
param(
    [ValidateSet('Local', 'Offline', 'SelfTest')]
    [string]$Target = 'Local',
    [string]$BackupRoot,
    [Parameter(Mandatory = $true)][string]$DestinationRoot,
    [string]$GenerationId = 'Latest',
    [switch]$PlanOnly
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'SourceArtBackup.Common.ps1')

$config = Get-SourceArtConfig
$destinationPath = $null
$destinationCreated = $false

try {
    if ([string]::IsNullOrWhiteSpace($BackupRoot)) {
        if ($Target -eq 'Local') {
            $BackupRoot = [string]$config.localBackupRoot
        }
        elseif ($Target -eq 'Offline') {
            $offlineRoot = Resolve-BrokenStreetsOfflineRoot -Config $config
            $BackupRoot = Join-Path $offlineRoot ([string]$config.sourceArtOfflineRelativeRoot)
        }
        else {
            throw 'SelfTest target requires an explicit BackupRoot.'
        }
    }
    $backupPath = Get-SourceArtFullPath -Path $BackupRoot
    $storePath = Join-Path $backupPath 'Store.json'
    if (-not (Test-Path -LiteralPath $storePath -PathType Leaf)) {
        throw "Source Art backup store marker is missing: $storePath"
    }
    $store = Read-SourceArtJson -Path $storePath
    if (([int]$store.schemaVersion -ne 1) -or ([string]$store.format -ne 'BrokenStreets.SourceArt.ContentAddressed')) {
        throw "Unsupported Source Art backup store: $storePath"
    }

    $generation = Get-SourceArtGeneration -BackupRoot $backupPath -GenerationId $GenerationId
    $generationPath = [string]$generation.GenerationPath
    $manifestPath = Join-Path $generationPath 'manifest.json'
    $inventoryPath = Join-Path $generationPath 'files.json'
    $checksumsPath = Join-Path $generationPath 'checksums.sha256'
    foreach ($required in @($manifestPath, $inventoryPath, $checksumsPath)) {
        if (-not (Test-Path -LiteralPath $required -PathType Leaf)) {
            throw "Required Source Art generation file is missing: $required"
        }
    }

    if ($null -ne $generation.Latest) {
        if (-not [string]::Equals((Get-SourceArtSha256 -Path $manifestPath), [string]$generation.Latest.manifestSha256, [StringComparison]::OrdinalIgnoreCase)) {
            throw 'Latest Source Art manifest checksum does not match its pointer.'
        }
        if (-not [string]::Equals((Get-SourceArtSha256 -Path $inventoryPath), [string]$generation.Latest.inventorySha256, [StringComparison]::OrdinalIgnoreCase)) {
            throw 'Latest Source Art inventory checksum does not match its pointer.'
        }
        if (-not [string]::Equals((Get-SourceArtSha256 -Path $checksumsPath), [string]$generation.Latest.checksumsSha256, [StringComparison]::OrdinalIgnoreCase)) {
            throw 'Latest Source Art checksum file does not match its pointer.'
        }
    }

    foreach ($line in @(Get-Content -LiteralPath $checksumsPath)) {
        if ([string]::IsNullOrWhiteSpace($line)) {
            continue
        }
        $parts = $line -split "`t"
        if (($parts.Count -ne 2) -or ($parts[0] -notmatch '^[0-9a-f]{64}$')) {
            throw "Invalid Source Art checksum inventory line: $line"
        }
        $candidate = Resolve-SourceArtSafeChild -Root $generationPath -RelativePath $parts[1]
        if (-not (Test-Path -LiteralPath $candidate -PathType Leaf)) {
            throw "Checksummed Source Art generation file is missing: $candidate"
        }
        if (-not [string]::Equals((Get-SourceArtSha256 -Path $candidate), $parts[0], [StringComparison]::OrdinalIgnoreCase)) {
            throw "Source Art generation checksum failed: $($parts[1])"
        }
    }

    $manifest = Read-SourceArtJson -Path $manifestPath
    $inventory = Read-SourceArtJson -Path $inventoryPath
    if (([int]$manifest.schemaVersion -ne 1) -or ([string]$manifest.status -ne 'PASS')) {
        throw 'The selected Source Art manifest is not a supported successful generation.'
    }
    if (-not [string]::Equals([string]$manifest.generationId, [string]$generation.GenerationId, [StringComparison]::Ordinal)) {
        throw 'Source Art manifest generation ID mismatch.'
    }
    if (-not [string]::Equals([string]$manifest.storeId, [string]$store.storeId, [StringComparison]::OrdinalIgnoreCase)) {
        throw 'Source Art generation belongs to a different backup store.'
    }
    $inventoryFiles = @($inventory.files)
    $inventoryDirectories = @($inventory.directories)
    if (($inventoryFiles.Count -ne [int]$manifest.fileCount) -or ($inventoryDirectories.Count -ne [int]$manifest.directoryCount)) {
        throw 'Source Art inventory counts do not match the manifest.'
    }

    $verifiedObjects = @{}
    $calculatedBytes = [Int64]0
    foreach ($file in $inventoryFiles) {
        $relative = [string]$file.path
        [void](Resolve-SourceArtSafeChild -Root ([string]$config.sourceRoot) -RelativePath $relative)
        $sha256 = [string]$file.sha256
        if ($sha256 -notmatch '^[0-9a-f]{64}$') {
            throw "Invalid Source Art file hash in inventory: $relative"
        }
        $expectedObjectRelative = Get-SourceArtObjectRelativePath -Sha256 $sha256
        if (-not [string]::Equals([string]$file.object, $expectedObjectRelative, [StringComparison]::Ordinal)) {
            throw "Source Art object path does not match its hash: $relative"
        }
        $objectPath = Resolve-SourceArtSafeChild -Root $backupPath -RelativePath $expectedObjectRelative
        if (-not (Test-Path -LiteralPath $objectPath -PathType Leaf)) {
            throw "Source Art backup object is missing: $sha256"
        }
        if ((Get-Item -LiteralPath $objectPath).Length -ne [Int64]$file.length) {
            throw "Source Art backup object size mismatch: $sha256"
        }
        if (-not $verifiedObjects.ContainsKey($sha256)) {
            if (-not [string]::Equals((Get-SourceArtSha256 -Path $objectPath), $sha256, [StringComparison]::OrdinalIgnoreCase)) {
                throw "Source Art backup object checksum failed: $sha256"
            }
            $verifiedObjects[$sha256] = $objectPath
        }
        $calculatedBytes += [Int64]$file.length
    }
    if ($calculatedBytes -ne [Int64]$manifest.totalBytes) {
        throw 'Source Art inventory byte count does not match the manifest.'
    }

    $protectedRoots = @(
        [string]$config.sourceRoot,
        'F:\BrokenStreets',
        'F:\UE_5.8.2',
        $backupPath
    )
    if ($Target -ne 'SelfTest') {
        $protectedRoots += [string]$config.localBackupRoot
    }
    $destinationPath = Assert-SourceArtNewRestoreDestination -DestinationRoot $DestinationRoot -ProtectedRoots $protectedRoots
    Write-SourceArtMessage -Level 'INFO' -Message "Generation: $($generation.GenerationId)"
    Write-SourceArtMessage -Level 'INFO' -Message "Restore destination: $destinationPath"
    Write-SourceArtMessage -Level 'INFO' -Message "Verified $($verifiedObjects.Count) unique objects for $($inventoryFiles.Count) files."
    if ($PlanOnly) {
        Write-SourceArtMessage -Level 'PASS' -Message 'Source Art restore plan and full object audit passed; no destination was created.'
        exit 0
    }

    New-Item -ItemType Directory -Path $destinationPath | Out-Null
    $destinationCreated = $true
    foreach ($relativeDirectory in $inventoryDirectories) {
        $directoryPath = Resolve-SourceArtSafeChild -Root $destinationPath -RelativePath ([string]$relativeDirectory)
        New-Item -ItemType Directory -Path $directoryPath -Force | Out-Null
    }
    foreach ($file in $inventoryFiles) {
        $destinationFile = Resolve-SourceArtSafeChild -Root $destinationPath -RelativePath ([string]$file.path)
        $destinationParent = Split-Path -Parent $destinationFile
        New-Item -ItemType Directory -Path $destinationParent -Force | Out-Null
        $objectPath = $verifiedObjects[[string]$file.sha256]
        Copy-Item -LiteralPath $objectPath -Destination $destinationFile
        if (-not [string]::Equals((Get-SourceArtSha256 -Path $destinationFile), [string]$file.sha256, [StringComparison]::OrdinalIgnoreCase)) {
            throw "Restored Source Art file failed SHA-256 verification: $($file.path)"
        }
        (Get-Item -LiteralPath $destinationFile).LastWriteTimeUtc = [DateTime]::Parse([string]$file.lastWriteUtc, [Globalization.CultureInfo]::InvariantCulture, [Globalization.DateTimeStyles]::RoundtripKind)
    }

    $restoreResult = [ordered]@{
        schemaVersion = 1
        status = 'PASS'
        generationId = [string]$generation.GenerationId
        completedUtc = [DateTime]::UtcNow.ToString('o')
        sourceBackupRoot = $backupPath
        destinationRoot = $destinationPath
        restoredFileCount = $inventoryFiles.Count
        restoredDirectoryCount = $inventoryDirectories.Count
        verifiedUniqueObjectCount = $verifiedObjects.Count
        restoredBytes = $calculatedBytes
    }
    Write-SourceArtAtomicJson -Path (Join-Path $destinationPath 'restore.json') -Value $restoreResult
    Write-SourceArtMessage -Level 'PASS' -Message "Restored and verified $($inventoryFiles.Count) Source Art files."
    exit 0
}
catch {
    Write-SourceArtMessage -Level 'FAIL' -Message $_.Exception.Message
    if ($destinationCreated -and ($null -ne $destinationPath) -and (Test-Path -LiteralPath $destinationPath -PathType Container)) {
        try {
            Write-SourceArtAtomicText -Path (Join-Path $destinationPath 'restore-failed.txt') -Content ($_.Exception.Message + [Environment]::NewLine)
            Write-SourceArtMessage -Level 'INFO' -Message "Partial restore retained for diagnosis: $destinationPath"
        }
        catch {
            Write-Warning "Could not write the restore failure marker: $($_.Exception.Message)"
        }
    }
    exit 1
}
