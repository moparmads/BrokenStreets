#requires -Version 5.1

Set-StrictMode -Version Latest

$script:SourceArtUtf8NoBom = New-Object System.Text.UTF8Encoding($false)

function Get-SourceArtConfig {
    $configPath = Join-Path $PSScriptRoot 'SourceArtBackupConfig.json'
    $config = [System.IO.File]::ReadAllText($configPath, $script:SourceArtUtf8NoBom) | ConvertFrom-Json
    if ([int]$config.schemaVersion -ne 1) {
        throw "Unsupported Source Art backup configuration schema: $($config.schemaVersion)"
    }
    return $config
}

function Read-SourceArtJson {
    param([Parameter(Mandatory = $true)][string]$Path)

    return ([System.IO.File]::ReadAllText((Get-SourceArtFullPath -Path $Path), $script:SourceArtUtf8NoBom) | ConvertFrom-Json)
}

function Write-SourceArtMessage {
    param(
        [Parameter(Mandatory = $true)][string]$Level,
        [Parameter(Mandatory = $true)][string]$Message
    )

    Write-Host "[$Level] $Message"
}

function Get-SourceArtFullPath {
    param([Parameter(Mandatory = $true)][string]$Path)

    $fullPath = [System.IO.Path]::GetFullPath($Path)
    $pathRoot = [System.IO.Path]::GetPathRoot($fullPath)
    $trimmed = $fullPath.TrimEnd([char[]]@('\', '/'))
    if ([string]::Equals($trimmed, $pathRoot.TrimEnd([char[]]@('\', '/')), [StringComparison]::OrdinalIgnoreCase)) {
        return $pathRoot
    }
    return $trimmed
}

function Test-SourceArtPathInside {
    param(
        [Parameter(Mandatory = $true)][string]$Candidate,
        [Parameter(Mandatory = $true)][string]$Parent
    )

    $candidatePath = Get-SourceArtFullPath -Path $Candidate
    $parentPath = Get-SourceArtFullPath -Path $Parent
    if ([string]::Equals($candidatePath, $parentPath, [StringComparison]::OrdinalIgnoreCase)) {
        return $true
    }
    $prefix = $parentPath.TrimEnd([char[]]@('\', '/')) + [System.IO.Path]::DirectorySeparatorChar
    return $candidatePath.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase)
}

function Get-SourceArtSha256 {
    param([Parameter(Mandatory = $true)][string]$Path)

    $fullPath = Get-SourceArtFullPath -Path $Path
    $stream = [System.IO.File]::Open($fullPath, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::Read)
    $algorithm = [System.Security.Cryptography.SHA256]::Create()
    try {
        $hashBytes = $algorithm.ComputeHash($stream)
    }
    finally {
        $algorithm.Dispose()
        $stream.Dispose()
    }
    return (($hashBytes | ForEach-Object { $_.ToString('x2') }) -join '')
}

function Write-SourceArtAtomicText {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][AllowEmptyString()][string]$Content
    )

    $fullPath = Get-SourceArtFullPath -Path $Path
    $parent = Split-Path -Parent $fullPath
    if (-not (Test-Path -LiteralPath $parent -PathType Container)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }
    $temporaryPath = Join-Path $parent ('.{0}.{1}.{2}.tmp' -f ([System.IO.Path]::GetFileName($fullPath)), $PID, [Guid]::NewGuid().ToString('N'))
    $replacementBackupPath = Join-Path $parent ('.{0}.{1}.{2}.replace-backup' -f ([System.IO.Path]::GetFileName($fullPath)), $PID, [Guid]::NewGuid().ToString('N'))
    try {
        [System.IO.File]::WriteAllText($temporaryPath, $Content, $script:SourceArtUtf8NoBom)
        if (Test-Path -LiteralPath $fullPath -PathType Leaf) {
            [System.IO.File]::Replace($temporaryPath, $fullPath, $replacementBackupPath, $true)
        }
        else {
            [System.IO.File]::Move($temporaryPath, $fullPath)
        }
    }
    finally {
        if (Test-Path -LiteralPath $temporaryPath -PathType Leaf) {
            Remove-Item -LiteralPath $temporaryPath -Force
        }
        if (Test-Path -LiteralPath $replacementBackupPath -PathType Leaf) {
            Remove-Item -LiteralPath $replacementBackupPath -Force
        }
    }
}

function Write-SourceArtAtomicJson {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)]$Value,
        [int]$Depth = 10
    )

    $json = ($Value | ConvertTo-Json -Depth $Depth) + [Environment]::NewLine
    Write-SourceArtAtomicText -Path $Path -Content $json
}

function Publish-SourceArtLatestPointer {
    param(
        [Parameter(Mandatory = $true)][string]$BackupRoot,
        [Parameter(Mandatory = $true)]$Pointer
    )

    $latestPath = Join-Path $BackupRoot 'LATEST.json'
    $previousPath = Join-Path $BackupRoot 'LATEST.previous.json'
    if (Test-Path -LiteralPath $latestPath -PathType Leaf) {
        $previousContent = [System.IO.File]::ReadAllText($latestPath, $script:SourceArtUtf8NoBom)
        Write-SourceArtAtomicText -Path $previousPath -Content $previousContent
    }
    Write-SourceArtAtomicJson -Path $latestPath -Value $Pointer
}

function Resolve-SourceArtSafeChild {
    param(
        [Parameter(Mandatory = $true)][string]$Root,
        [Parameter(Mandatory = $true)][string]$RelativePath
    )

    if ([string]::IsNullOrWhiteSpace($RelativePath) -or [System.IO.Path]::IsPathRooted($RelativePath)) {
        throw "Invalid relative path in backup inventory: $RelativePath"
    }
    $platformRelativePath = $RelativePath.Replace('/', [System.IO.Path]::DirectorySeparatorChar)
    $candidate = Get-SourceArtFullPath -Path (Join-Path $Root $platformRelativePath)
    if (-not (Test-SourceArtPathInside -Candidate $candidate -Parent $Root)) {
        throw "Backup inventory path escapes its root: $RelativePath"
    }
    return $candidate
}

function Get-SourceArtObjectRelativePath {
    param([Parameter(Mandatory = $true)][string]$Sha256)

    if ($Sha256 -notmatch '^[0-9a-f]{64}$') {
        throw "Invalid SHA-256 object ID: $Sha256"
    }
    return ('Objects/{0}/{1}/{2}' -f $Sha256.Substring(0, 2), $Sha256.Substring(2, 2), $Sha256)
}

function Get-SourceArtDriveInfo {
    param([Parameter(Mandatory = $true)][string]$Path)

    $fullPath = Get-SourceArtFullPath -Path $Path
    $root = [System.IO.Path]::GetPathRoot($fullPath)
    $drive = New-Object System.IO.DriveInfo($root)
    if (-not $drive.IsReady) {
        throw "Backup drive is not ready: $root"
    }
    return $drive
}

function Assert-SourceArtBackupSeparation {
    param(
        [Parameter(Mandatory = $true)][string]$SourceRoot,
        [Parameter(Mandatory = $true)][string]$BackupRoot
    )

    $sourcePath = Get-SourceArtFullPath -Path $SourceRoot
    $backupPath = Get-SourceArtFullPath -Path $BackupRoot
    if (Test-SourceArtPathInside -Candidate $backupPath -Parent $sourcePath) {
        throw "Backup root must not be the Source Art root or a child of it: $backupPath"
    }
    if (Test-SourceArtPathInside -Candidate $sourcePath -Parent $backupPath) {
        throw "Source Art root must not be inside the backup root: $sourcePath"
    }
    $sourceDrive = [System.IO.Path]::GetPathRoot($sourcePath)
    $backupDrive = [System.IO.Path]::GetPathRoot($backupPath)
    if ([string]::Equals($sourceDrive, $backupDrive, [StringComparison]::OrdinalIgnoreCase)) {
        throw "Source Art and its backup must be on different drives. Both resolve to $sourceDrive"
    }
}

function Assert-SourceArtNewRestoreDestination {
    param(
        [Parameter(Mandatory = $true)][string]$DestinationRoot,
        [Parameter(Mandatory = $true)][string[]]$ProtectedRoots
    )

    $destination = Get-SourceArtFullPath -Path $DestinationRoot
    $driveRoot = [System.IO.Path]::GetPathRoot($destination)
    if ([string]::Equals($destination.TrimEnd([char[]]@('\', '/')), $driveRoot.TrimEnd([char[]]@('\', '/')), [StringComparison]::OrdinalIgnoreCase)) {
        throw "Restore destination must not be a drive root: $destination"
    }
    if (Test-Path -LiteralPath $destination) {
        throw "Restore destination already exists. Choose a new folder: $destination"
    }
    foreach ($protectedRoot in $ProtectedRoots) {
        if ([string]::IsNullOrWhiteSpace($protectedRoot)) {
            continue
        }
        $protected = Get-SourceArtFullPath -Path $protectedRoot
        if ((Test-SourceArtPathInside -Candidate $destination -Parent $protected) -or (Test-SourceArtPathInside -Candidate $protected -Parent $destination)) {
            throw "Restore destination overlaps a protected root: $protected"
        }
    }
    return $destination
}

function Resolve-BrokenStreetsOfflineRoot {
    param([Parameter(Mandatory = $true)]$Config)

    $matches = New-Object System.Collections.Generic.List[string]
    foreach ($drive in @(Get-PSDrive -PSProvider FileSystem)) {
        try {
            $candidate = Join-Path $drive.Root ([string]$Config.offlineRelativeRoot)
            $markerPath = Join-Path $candidate 'OfflineDrive.json'
            if (-not (Test-Path -LiteralPath $markerPath -PathType Leaf)) {
                continue
            }
            $marker = Read-SourceArtJson -Path $markerPath
            if (([int]$marker.schemaVersion -eq 1) -and [string]::Equals([string]$marker.offlineStoreId, [string]$Config.offlineStoreId, [StringComparison]::OrdinalIgnoreCase)) {
                $matches.Add((Get-SourceArtFullPath -Path $candidate))
            }
        }
        catch {
            continue
        }
    }
    if ($matches.Count -eq 0) {
        throw "The approved Broken Streets offline drive was not found. Connect it and confirm its OfflineDrive.json marker is present."
    }
    if ($matches.Count -gt 1) {
        throw "More than one drive has the approved Broken Streets offline marker. Disconnect duplicates and retry."
    }
    return $matches[0]
}

function Initialize-SourceArtBackupStore {
    param(
        [Parameter(Mandatory = $true)][string]$BackupRoot,
        [Parameter(Mandatory = $true)][ValidateSet('Local', 'Offline', 'SelfTest')][string]$Kind
    )

    $root = Get-SourceArtFullPath -Path $BackupRoot
    $storePath = Join-Path $root 'Store.json'
    if (-not (Test-Path -LiteralPath $root -PathType Container)) {
        New-Item -ItemType Directory -Path $root -Force | Out-Null
    }
    if (Test-Path -LiteralPath $storePath -PathType Leaf) {
        $store = Read-SourceArtJson -Path $storePath
        if (([int]$store.schemaVersion -ne 1) -or ([string]$store.kind -ne $Kind)) {
            throw "Backup store identity mismatch: $storePath"
        }
        return $store
    }
    $existing = @(Get-ChildItem -LiteralPath $root -Force)
    $unexpectedExisting = @($existing | Where-Object { $_.Name -ne 'SelfTests' })
    if ($unexpectedExisting.Count -gt 0) {
        throw "Refusing to initialize a Source Art store in an unmarked folder containing non-test data: $root"
    }
    $store = [ordered]@{
        schemaVersion = 1
        format = 'BrokenStreets.SourceArt.ContentAddressed'
        kind = $Kind
        createdUtc = [DateTime]::UtcNow.ToString('o')
        storeId = [Guid]::NewGuid().ToString()
        objectHash = 'SHA-256'
        automaticObjectDeletion = $false
    }
    Write-SourceArtAtomicJson -Path $storePath -Value $store
    foreach ($folder in @('Objects', 'Generations', '.Staging', 'Logs', 'RestoreTests', 'SelfTests')) {
        New-Item -ItemType Directory -Path (Join-Path $root $folder) -Force | Out-Null
    }
    return [pscustomobject]$store
}

function Get-SourceArtGeneration {
    param(
        [Parameter(Mandatory = $true)][string]$BackupRoot,
        [string]$GenerationId = 'Latest'
    )

    $root = Get-SourceArtFullPath -Path $BackupRoot
    $latest = $null
    if ([string]::Equals($GenerationId, 'Latest', [StringComparison]::OrdinalIgnoreCase)) {
        $latestPath = Join-Path $root 'LATEST.json'
        if (-not (Test-Path -LiteralPath $latestPath -PathType Leaf)) {
            throw "Latest-generation pointer is missing: $latestPath"
        }
        $latest = Read-SourceArtJson -Path $latestPath
        if ([int]$latest.schemaVersion -ne 1) {
            throw "Unsupported Source Art latest-pointer schema: $($latest.schemaVersion)"
        }
        $GenerationId = [string]$latest.generationId
    }
    if ($GenerationId -notmatch '^[0-9]{8}T[0-9]{6}Z-[0-9]+-[0-9a-f]{8}$') {
        throw "Invalid Source Art generation ID: $GenerationId"
    }
    $generationPath = Get-SourceArtFullPath -Path (Join-Path (Join-Path $root 'Generations') $GenerationId)
    if (-not (Test-SourceArtPathInside -Candidate $generationPath -Parent (Join-Path $root 'Generations'))) {
        throw "Generation path escapes the backup store: $GenerationId"
    }
    if (-not (Test-Path -LiteralPath $generationPath -PathType Container)) {
        throw "Source Art generation does not exist: $generationPath"
    }
    return [pscustomobject]@{
        GenerationId = $GenerationId
        GenerationPath = $generationPath
        Latest = $latest
    }
}
