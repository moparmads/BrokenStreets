#requires -Version 5.1

[CmdletBinding()]
param(
    [ValidateSet('Local', 'Offline', 'SelfTest')]
    [string]$Target = 'Local',
    [string]$SourceRoot,
    [string]$BackupRoot,
    [switch]$PlanOnly,
    [switch]$FullObjectAudit
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'SourceArtBackup.Common.ps1')

$config = Get-SourceArtConfig
$runId = '{0}-{1}-{2}' -f [DateTime]::UtcNow.ToString('yyyyMMddTHHmmssZ'), $PID, ([Guid]::NewGuid().ToString('N').Substring(0, 8))
$stagingPath = $null

try {
    if ([string]::IsNullOrWhiteSpace($SourceRoot)) {
        $SourceRoot = [string]$config.sourceRoot
    }
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

    $sourcePath = Get-SourceArtFullPath -Path $SourceRoot
    $backupPath = Get-SourceArtFullPath -Path $BackupRoot
    if (-not (Test-Path -LiteralPath $sourcePath -PathType Container)) {
        throw "Source Art root does not exist: $sourcePath"
    }
    Assert-SourceArtBackupSeparation -SourceRoot $sourcePath -BackupRoot $backupPath

    $sourceItems = @(Get-ChildItem -LiteralPath $sourcePath -Recurse -Force)
    $reparseItems = @($sourceItems | Where-Object { ($_.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0 })
    if ($reparseItems.Count -gt 0) {
        throw "Source Art contains a reparse point, which is not followed for safety: $($reparseItems[0].FullName)"
    }

    $directories = New-Object System.Collections.Generic.List[string]
    $files = New-Object System.Collections.Generic.List[object]
    $sourceSnapshots = New-Object System.Collections.Generic.List[object]
    $newObjects = @{}
    $seenPaths = @{}
    $totalBytes = [Int64]0

    foreach ($directory in @($sourceItems | Where-Object { $_.PSIsContainer } | Sort-Object FullName)) {
        $relative = $directory.FullName.Substring($sourcePath.TrimEnd([char[]]@('\', '/')).Length).TrimStart([char[]]@('\', '/')).Replace('\', '/')
        if (-not [string]::IsNullOrWhiteSpace($relative)) {
            [void](Resolve-SourceArtSafeChild -Root $sourcePath -RelativePath $relative)
            $directories.Add($relative)
        }
    }

    foreach ($file in @($sourceItems | Where-Object { -not $_.PSIsContainer } | Sort-Object FullName)) {
        $relative = $file.FullName.Substring($sourcePath.TrimEnd([char[]]@('\', '/')).Length).TrimStart([char[]]@('\', '/')).Replace('\', '/')
        [void](Resolve-SourceArtSafeChild -Root $sourcePath -RelativePath $relative)
        $pathKey = $relative.ToLowerInvariant()
        if ($seenPaths.ContainsKey($pathKey)) {
            throw "Source Art contains a case-insensitive path collision: $relative"
        }
        $seenPaths[$pathKey] = $true

        $before = Get-Item -LiteralPath $file.FullName -Force
        $hash = Get-SourceArtSha256 -Path $file.FullName
        $after = Get-Item -LiteralPath $file.FullName -Force
        if (($before.Length -ne $after.Length) -or ($before.LastWriteTimeUtc.Ticks -ne $after.LastWriteTimeUtc.Ticks)) {
            throw "Source file changed while it was being hashed: $relative"
        }

        $objectRelative = Get-SourceArtObjectRelativePath -Sha256 $hash
        $objectPath = Resolve-SourceArtSafeChild -Root $backupPath -RelativePath $objectRelative
        if (Test-Path -LiteralPath $objectPath -PathType Leaf) {
            if ((Get-Item -LiteralPath $objectPath).Length -ne $after.Length) {
                throw "Existing backup object has the wrong size: $hash"
            }
            if ($FullObjectAudit -and (-not [string]::Equals((Get-SourceArtSha256 -Path $objectPath), $hash, [StringComparison]::OrdinalIgnoreCase))) {
                throw "Existing backup object failed SHA-256 verification: $hash"
            }
        }
        elseif (-not $newObjects.ContainsKey($hash)) {
            $newObjects[$hash] = [pscustomobject]@{
                SourcePath = $file.FullName
                RelativePath = $relative
                Length = [Int64]$after.Length
                LastWriteUtcTicks = [Int64]$after.LastWriteTimeUtc.Ticks
                ObjectPath = $objectPath
            }
        }

        $files.Add([pscustomobject][ordered]@{
            path = $relative
            length = [Int64]$after.Length
            lastWriteUtc = $after.LastWriteTimeUtc.ToString('o')
            sha256 = $hash
            object = $objectRelative
        })
        $sourceSnapshots.Add([pscustomobject]@{
            Path = $file.FullName
            RelativePath = $relative
            Length = [Int64]$after.Length
            LastWriteUtcTicks = [Int64]$after.LastWriteTimeUtc.Ticks
        })
        $totalBytes += [Int64]$after.Length
    }

    $newBytes = [Int64]0
    foreach ($newObject in $newObjects.Values) {
        $newBytes += [Int64]$newObject.Length
    }
    $drive = Get-SourceArtDriveInfo -Path $backupPath
    $hardReserveBytes = [Int64]([double]$config.hardMinimumFreeSpaceGiB * 1GB)
    $warningBytes = [Int64]([double]$config.warningFreeSpaceGiB * 1GB)
    $estimatedOverhead = [Int64][Math]::Max(16MB, [Math]::Ceiling($files.Count * 1024.0))
    if (($drive.AvailableFreeSpace - $newBytes - $estimatedOverhead) -lt $hardReserveBytes) {
        throw "Insufficient backup capacity. The operation would cross the $($config.hardMinimumFreeSpaceGiB) GiB hard reserve on $($drive.Name)."
    }
    if ($drive.AvailableFreeSpace -lt $warningBytes) {
        Write-SourceArtMessage -Level 'WARN' -Message "Backup drive free space is below $($config.warningFreeSpaceGiB) GiB: $([Math]::Round($drive.AvailableFreeSpace / 1GB, 2)) GiB."
    }

    Write-SourceArtMessage -Level 'INFO' -Message "Source: $sourcePath"
    Write-SourceArtMessage -Level 'INFO' -Message "Target: $backupPath ($Target)"
    Write-SourceArtMessage -Level 'INFO' -Message "Inventory: $($files.Count) files, $($directories.Count) directories, $([Math]::Round($totalBytes / 1MB, 2)) MiB; new unique data $([Math]::Round($newBytes / 1MB, 2)) MiB."
    if ($PlanOnly) {
        Write-SourceArtMessage -Level 'PASS' -Message 'Source Art backup plan passed; no backup data was written.'
        exit 0
    }

    $store = Initialize-SourceArtBackupStore -BackupRoot $backupPath -Kind $Target
    foreach ($hash in @($newObjects.Keys | Sort-Object)) {
        $newObject = $newObjects[$hash]
        $objectParent = Split-Path -Parent $newObject.ObjectPath
        New-Item -ItemType Directory -Path $objectParent -Force | Out-Null
        $temporaryObject = Join-Path $objectParent ('.{0}.{1}.{2}.partial' -f $hash, $PID, [Guid]::NewGuid().ToString('N'))
        try {
            $sourceBeforeCopy = Get-Item -LiteralPath $newObject.SourcePath -Force
            $sourceStream = [System.IO.File]::Open($newObject.SourcePath, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::Read)
            try {
                $destinationStream = [System.IO.File]::Open($temporaryObject, [System.IO.FileMode]::CreateNew, [System.IO.FileAccess]::Write, [System.IO.FileShare]::None)
                try {
                    $sourceStream.CopyTo($destinationStream, 4MB)
                    $destinationStream.Flush($true)
                }
                finally {
                    $destinationStream.Dispose()
                }
            }
            finally {
                $sourceStream.Dispose()
            }
            $sourceAfterCopy = Get-Item -LiteralPath $newObject.SourcePath -Force
            if (($sourceBeforeCopy.Length -ne $sourceAfterCopy.Length) -or ($sourceBeforeCopy.LastWriteTimeUtc.Ticks -ne $sourceAfterCopy.LastWriteTimeUtc.Ticks)) {
                throw "Source file changed while it was being copied: $($newObject.RelativePath)"
            }
            if (-not [string]::Equals((Get-SourceArtSha256 -Path $temporaryObject), $hash, [StringComparison]::OrdinalIgnoreCase)) {
                throw "Copied object failed SHA-256 verification: $($newObject.RelativePath)"
            }
            if (Test-Path -LiteralPath $newObject.ObjectPath -PathType Leaf) {
                if ((Get-Item -LiteralPath $newObject.ObjectPath).Length -ne $newObject.Length) {
                    throw "Concurrent backup object has the wrong size: $hash"
                }
            }
            else {
                [System.IO.File]::Move($temporaryObject, $newObject.ObjectPath)
            }
        }
        finally {
            if (Test-Path -LiteralPath $temporaryObject -PathType Leaf) {
                Remove-Item -LiteralPath $temporaryObject -Force
            }
        }
    }

    foreach ($snapshot in $sourceSnapshots) {
        $current = Get-Item -LiteralPath $snapshot.Path -Force
        if (($current.Length -ne $snapshot.Length) -or ($current.LastWriteTimeUtc.Ticks -ne $snapshot.LastWriteUtcTicks)) {
            throw "Source file changed before generation publication: $($snapshot.RelativePath)"
        }
    }

    $stagingRoot = Join-Path $backupPath '.Staging'
    $stagingPath = Join-Path $stagingRoot $runId
    New-Item -ItemType Directory -Path $stagingPath -Force | Out-Null
    $inventory = [ordered]@{
        schemaVersion = 1
        generationId = $runId
        sourceRoot = $sourcePath
        directories = @($directories.ToArray())
        files = @($files.ToArray())
    }
    $inventoryPath = Join-Path $stagingPath 'files.json'
    Write-SourceArtAtomicJson -Path $inventoryPath -Value $inventory -Depth 12

    $manifest = [ordered]@{
        schemaVersion = 1
        format = 'BrokenStreets.SourceArt.ContentAddressed'
        status = 'PASS'
        generationId = $runId
        createdUtc = [DateTime]::UtcNow.ToString('o')
        target = $Target
        storeId = [string]$store.storeId
        sourceRoot = $sourcePath
        sourceVolume = [System.IO.Path]::GetPathRoot($sourcePath)
        backupRoot = $backupPath
        fileCount = $files.Count
        directoryCount = $directories.Count
        totalBytes = $totalBytes
        uniqueObjectsAdded = $newObjects.Count
        uniqueBytesAdded = $newBytes
        inventoryFile = 'files.json'
        objectHash = 'SHA-256'
        existingObjectAudit = $(if ($FullObjectAudit) { 'full-sha256' } else { 'trusted-prior-sha256-plus-size' })
        warningFreeSpaceGiB = [int]$config.warningFreeSpaceGiB
        hardMinimumFreeSpaceGiB = [int]$config.hardMinimumFreeSpaceGiB
        automaticObjectDeletion = $false
        encryptionPolicy = [string]$config.encryptionPolicy
    }
    $manifestPath = Join-Path $stagingPath 'manifest.json'
    Write-SourceArtAtomicJson -Path $manifestPath -Value $manifest
    $inventoryHash = Get-SourceArtSha256 -Path $inventoryPath
    $manifestHash = Get-SourceArtSha256 -Path $manifestPath
    $checksumsContent = "$inventoryHash`tfiles.json$([Environment]::NewLine)$manifestHash`tmanifest.json$([Environment]::NewLine)"
    $checksumsPath = Join-Path $stagingPath 'checksums.sha256'
    Write-SourceArtAtomicText -Path $checksumsPath -Content $checksumsContent
    if (-not [string]::Equals((Get-SourceArtSha256 -Path $inventoryPath), $inventoryHash, [StringComparison]::OrdinalIgnoreCase)) {
        throw 'Staged Source Art inventory checksum changed before publication.'
    }
    if (-not [string]::Equals((Get-SourceArtSha256 -Path $manifestPath), $manifestHash, [StringComparison]::OrdinalIgnoreCase)) {
        throw 'Staged Source Art manifest checksum changed before publication.'
    }

    $generationRoot = Join-Path $backupPath 'Generations'
    $generationPath = Join-Path $generationRoot $runId
    if (Test-Path -LiteralPath $generationPath) {
        throw "Generation path already exists: $generationPath"
    }
    [System.IO.Directory]::Move($stagingPath, $generationPath)
    $stagingPath = $null

    $pointer = [ordered]@{
        schemaVersion = 1
        generationId = $runId
        completedUtc = [DateTime]::UtcNow.ToString('o')
        manifestSha256 = $manifestHash
        inventorySha256 = $inventoryHash
        checksumsSha256 = Get-SourceArtSha256 -Path (Join-Path $generationPath 'checksums.sha256')
        fileCount = $files.Count
        totalBytes = $totalBytes
    }
    Publish-SourceArtLatestPointer -BackupRoot $backupPath -Pointer $pointer

    Write-SourceArtMessage -Level 'PASS' -Message "Published Source Art generation $runId."
    Write-SourceArtMessage -Level 'INFO' -Message "Generation: $generationPath"
    exit 0
}
catch {
    Write-SourceArtMessage -Level 'FAIL' -Message $_.Exception.Message
    if (($null -ne $stagingPath) -and (Test-Path -LiteralPath $stagingPath -PathType Container)) {
        Write-SourceArtMessage -Level 'INFO' -Message "Failed staging data was retained for diagnosis: $stagingPath"
    }
    exit 1
}
