#requires -Version 5.1

[CmdletBinding()]
param(
    [string]$BackupRoot,
    [string]$GenerationId = 'Latest',
    [Parameter(Mandatory = $true)][string]$DestinationRoot,
    [switch]$PlanOnly
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$script:Utf8NoBom = New-Object System.Text.UTF8Encoding($false)
$script:LogLines = New-Object System.Collections.Generic.List[string]
$script:GitExecutable = $null

function Write-RestoreTextFile {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [AllowEmptyString()][string]$Content
    )

    [System.IO.File]::WriteAllText($Path, $Content, $script:Utf8NoBom)
}

function Write-RestoreMessage {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('INFO', 'PLAN', 'PASS', 'WARN', 'FAIL')]
        [string]$Level,
        [Parameter(Mandatory = $true)][string]$Message
    )

    $line = '[{0}] {1}' -f $Level.PadRight(4), $Message
    Write-Host $line
    $script:LogLines.Add(('{0:o} {1}' -f [DateTime]::UtcNow, $line))
}

function Get-NormalizedFullPath {
    param([Parameter(Mandatory = $true)][string]$Path)

    return [System.IO.Path]::GetFullPath($Path).TrimEnd([char[]]@('\', '/'))
}

function Assert-SafeRestoreDestination {
    param(
        [Parameter(Mandatory = $true)][string]$BackupPath,
        [Parameter(Mandatory = $true)][string]$RestorePath
    )

    $backup = Get-NormalizedFullPath -Path $BackupPath
    $restore = Get-NormalizedFullPath -Path $RestorePath
    $restoreDriveRoot = Get-NormalizedFullPath -Path ([System.IO.Path]::GetPathRoot($restore))
    if ([string]::Equals($restore, $restoreDriveRoot, [StringComparison]::OrdinalIgnoreCase)) {
        throw "The restore destination must not be a drive root: $restore"
    }
    if ([string]::Equals($backup, $restore, [StringComparison]::OrdinalIgnoreCase)) {
        throw 'The restore destination must not be the backup root.'
    }
    if ($backup.StartsWith(($restore + [System.IO.Path]::DirectorySeparatorChar), [StringComparison]::OrdinalIgnoreCase)) {
        throw 'The backup root must not be inside the restore destination.'
    }
}

function Invoke-NativeCommand {
    param(
        [Parameter(Mandatory = $true)][string]$FilePath,
        [Parameter(Mandatory = $true)][string[]]$Arguments,
        [Parameter(Mandatory = $true)][string]$WorkingDirectory,
        [switch]$AllowFailure
    )

    $output = @()
    $exitCode = 0
    $previousErrorActionPreference = $ErrorActionPreference
    Push-Location -LiteralPath $WorkingDirectory
    try {
        $ErrorActionPreference = 'Continue'
        $output = @(& $FilePath @Arguments 2>&1)
        $exitCode = $LASTEXITCODE
    }
    finally {
        $ErrorActionPreference = $previousErrorActionPreference
        Pop-Location
    }

    $text = ($output | ForEach-Object { $_.ToString() }) -join [Environment]::NewLine
    if (($exitCode -ne 0) -and (-not $AllowFailure)) {
        throw "Command failed with exit code ${exitCode}: $FilePath $($Arguments -join ' ')`n$text"
    }

    return [pscustomobject]@{
        ExitCode = $exitCode
        Output = $text
    }
}

function Resolve-GitExecutable {
    param([string]$PreferredPath)

    $candidates = New-Object System.Collections.Generic.List[string]
    if (-not [string]::IsNullOrWhiteSpace($PreferredPath)) {
        $candidates.Add([System.IO.Path]::GetFullPath($PreferredPath))
    }
    $pathCommand = Get-Command git.exe -ErrorAction SilentlyContinue
    if ($null -ne $pathCommand) {
        $candidates.Add([string]$pathCommand.Source)
    }
    $candidates.Add('C:\Program Files\Git\cmd\git.exe')

    foreach ($candidate in ($candidates | Select-Object -Unique)) {
        if (Test-Path -LiteralPath $candidate -PathType Leaf) {
            return $candidate
        }
    }
    throw 'A Git executable could not be resolved. Update gitExecutable in RepositoryBackupConfig.json.'
}

function Invoke-Git {
    param(
        [Parameter(Mandatory = $true)][string[]]$Arguments,
        [Parameter(Mandatory = $true)][string]$WorkingDirectory,
        [switch]$AllowFailure
    )

    return Invoke-NativeCommand -FilePath $script:GitExecutable -Arguments $Arguments -WorkingDirectory $WorkingDirectory -AllowFailure:$AllowFailure
}

function Get-Sha256 {
    param([Parameter(Mandatory = $true)][string]$Path)

    $stream = $null
    $algorithm = $null
    try {
        $stream = [System.IO.File]::Open($Path, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::Read)
        $algorithm = [System.Security.Cryptography.SHA256]::Create()
        $bytes = $algorithm.ComputeHash($stream)
        return (($bytes | ForEach-Object { $_.ToString('x2') }) -join '')
    }
    finally {
        if ($null -ne $algorithm) {
            $algorithm.Dispose()
        }
        if ($null -ne $stream) {
            $stream.Dispose()
        }
    }
}

function Get-LfsObjectPath {
    param(
        [Parameter(Mandatory = $true)][string]$Root,
        [Parameter(Mandatory = $true)][string]$Oid
    )

    return Join-Path (Join-Path (Join-Path $Root $Oid.Substring(0, 2)) $Oid.Substring(2, 2)) $Oid
}

function Get-RefMap {
    param([Parameter(Mandatory = $true)][string[]]$Lines)

    $map = @{}
    foreach ($line in $Lines) {
        if ([string]::IsNullOrWhiteSpace($line)) {
            continue
        }
        if ($line -notmatch '^([0-9a-fA-F]{40,64})\s+(.+)$') {
            throw "Invalid ref inventory line: $line"
        }
        $map[$Matches[2]] = $Matches[1].ToLowerInvariant()
    }
    return $map
}

function Get-LfsInventory {
    param([Parameter(Mandatory = $true)][AllowEmptyCollection()][string[]]$Lines)

    $inventory = @{}
    foreach ($line in $Lines) {
        if ([string]::IsNullOrWhiteSpace($line)) {
            continue
        }
        $parts = $line -split "`t"
        if (($parts.Count -ne 2) -or ($parts[0] -notmatch '^[0-9a-fA-F]{64}$')) {
            throw "Invalid Git LFS inventory line: $line"
        }
        $inventory[$parts[0].ToLowerInvariant()] = [Int64]$parts[1]
    }
    return $inventory
}

function Compare-ExactMap {
    param(
        [Parameter(Mandatory = $true)][hashtable]$Expected,
        [Parameter(Mandatory = $true)][hashtable]$Actual,
        [Parameter(Mandatory = $true)][string]$Label
    )

    if ($Expected.Count -ne $Actual.Count) {
        throw "$Label count mismatch. Expected $($Expected.Count), found $($Actual.Count)."
    }
    foreach ($key in $Expected.Keys) {
        if (-not $Actual.ContainsKey($key)) {
            throw "$Label is missing: $key"
        }
        if (-not [string]::Equals([string]$Expected[$key], [string]$Actual[$key], [StringComparison]::OrdinalIgnoreCase)) {
            throw "$Label value mismatch for $key"
        }
    }
}

try {
    $configPath = Join-Path $PSScriptRoot 'RepositoryBackupConfig.json'
    $config = Get-Content -Raw -LiteralPath $configPath | ConvertFrom-Json
    if ([int]$config.schemaVersion -ne 1) {
        throw "Unsupported backup configuration schema: $($config.schemaVersion)"
    }
    $script:GitExecutable = Resolve-GitExecutable -PreferredPath ([string]$config.gitExecutable)
    if ([string]::IsNullOrWhiteSpace($BackupRoot)) {
        $BackupRoot = [string]$config.backupRoot
    }

    $BackupRoot = Get-NormalizedFullPath -Path $BackupRoot
    $DestinationRoot = Get-NormalizedFullPath -Path $DestinationRoot
    Assert-SafeRestoreDestination -BackupPath $BackupRoot -RestorePath $DestinationRoot

    if (-not (Test-Path -LiteralPath $BackupRoot -PathType Container)) {
        throw "Backup root does not exist: $BackupRoot"
    }
    if (Test-Path -LiteralPath $DestinationRoot) {
        throw "Restore destination already exists. Choose a new folder: $DestinationRoot"
    }

    $latestPath = Join-Path $BackupRoot 'LATEST.json'
    if ([string]::Equals($GenerationId, 'Latest', [StringComparison]::OrdinalIgnoreCase)) {
        if (-not (Test-Path -LiteralPath $latestPath -PathType Leaf)) {
            throw "Latest-generation pointer is missing: $latestPath"
        }
        $latest = Get-Content -Raw -LiteralPath $latestPath | ConvertFrom-Json
        if ([int]$latest.schemaVersion -ne 1) {
            throw "Unsupported latest-pointer schema: $($latest.schemaVersion)"
        }
        $GenerationId = [string]$latest.generationId
    }
    else {
        $latest = $null
    }

    if ($GenerationId -notmatch '^[0-9]{8}T[0-9]{6}Z-[0-9]+-[0-9a-f]{8}$') {
        throw "Invalid backup generation ID: $GenerationId"
    }
    $generationPath = Get-NormalizedFullPath -Path (Join-Path (Join-Path $BackupRoot 'Generations') $GenerationId)
    if (-not (Test-Path -LiteralPath $generationPath -PathType Container)) {
        throw "Backup generation does not exist: $generationPath"
    }

    $manifestPath = Join-Path $generationPath 'manifest.json'
    $checksumsPath = Join-Path $generationPath 'checksums.sha256'
    if (($null -ne $latest) -and (-not [string]::Equals((Get-Sha256 -Path $manifestPath), [string]$latest.manifestSha256, [StringComparison]::OrdinalIgnoreCase))) {
        throw 'The latest pointer manifest checksum does not match the selected generation.'
    }
    if (($null -ne $latest) -and (-not [string]::Equals((Get-Sha256 -Path $checksumsPath), [string]$latest.checksumsSha256, [StringComparison]::OrdinalIgnoreCase))) {
        throw 'The latest pointer checksum-file hash does not match the selected generation.'
    }

    foreach ($line in (Get-Content -LiteralPath $checksumsPath)) {
        if ([string]::IsNullOrWhiteSpace($line)) {
            continue
        }
        $parts = $line -split "`t"
        if (($parts.Count -ne 2) -or ($parts[0] -notmatch '^[0-9a-fA-F]{64}$')) {
            throw "Invalid checksum inventory line: $line"
        }
        $candidate = Get-NormalizedFullPath -Path (Join-Path $generationPath $parts[1])
        $requiredPrefix = $generationPath + [System.IO.Path]::DirectorySeparatorChar
        if (-not $candidate.StartsWith($requiredPrefix, [StringComparison]::OrdinalIgnoreCase)) {
            throw "Checksum path escapes the generation root: $($parts[1])"
        }
        if (-not (Test-Path -LiteralPath $candidate -PathType Leaf)) {
            throw "Checksummed generation file is missing: $candidate"
        }
        if (-not [string]::Equals((Get-Sha256 -Path $candidate), $parts[0], [StringComparison]::OrdinalIgnoreCase)) {
            throw "Generation checksum failed: $($parts[1])"
        }
    }

    $manifest = Get-Content -Raw -LiteralPath $manifestPath | ConvertFrom-Json
    if (([int]$manifest.schemaVersion -ne 1) -or ([string]$manifest.status -ne 'PASS')) {
        throw 'The selected backup manifest is not a supported successful generation.'
    }
    if (-not [string]::Equals([string]$manifest.generationId, $GenerationId, [StringComparison]::Ordinal)) {
        throw 'The manifest generation ID does not match the selected directory.'
    }

    $refsPath = Join-Path $generationPath ([string]$manifest.git.refsFile)
    $lfsInventoryPath = Join-Path $generationPath ([string]$manifest.lfs.inventoryFile)
    $bundlePath = Join-Path $generationPath ([string]$manifest.git.bundleFile)
    $expectedRefs = Get-RefMap -Lines @(Get-Content -LiteralPath $refsPath)
    $expectedLfs = Get-LfsInventory -Lines @(Get-Content -LiteralPath $lfsInventoryPath)
    if ($expectedRefs.Count -ne [int]$manifest.git.refsCount) {
        throw 'The ref inventory count does not match the manifest.'
    }
    if ($expectedLfs.Count -ne [int]$manifest.lfs.objectCount) {
        throw 'The LFS inventory count does not match the manifest.'
    }

    if ($PlanOnly) {
        Write-RestoreMessage -Level 'PLAN' -Message "Generation: $GenerationId"
        Write-RestoreMessage -Level 'PLAN' -Message "Destination: $DestinationRoot"
        Write-RestoreMessage -Level 'PLAN' -Message "Refs: $($expectedRefs.Count); LFS objects: $($expectedLfs.Count)."
        Write-RestoreMessage -Level 'PASS' -Message 'Restore plan, manifest, and checksum checks passed; no destination was created.'
        exit 0
    }

    New-Item -ItemType Directory -Path $DestinationRoot | Out-Null
    $bareRepository = Join-Path $DestinationRoot 'Repository.git'
    $workingCopy = Join-Path $DestinationRoot 'WorkingCopy'
    $restoreStartUtc = [DateTime]::UtcNow

    Write-RestoreMessage -Level 'INFO' -Message "Restoring generation $GenerationId without a network remote."
    [void](Invoke-Git -Arguments @('init', '--bare', $bareRepository) -WorkingDirectory $DestinationRoot)
    [void](Invoke-Git -Arguments @('--git-dir', $bareRepository, 'bundle', 'verify', $bundlePath) -WorkingDirectory $DestinationRoot)
    [void](Invoke-Git -Arguments @('--git-dir', $bareRepository, 'fetch', $bundlePath, '+refs/*:refs/*') -WorkingDirectory $DestinationRoot)
    [void](Invoke-Git -Arguments @('--git-dir', $bareRepository, 'symbolic-ref', 'HEAD', ('refs/heads/' + [string]$config.defaultBranch)) -WorkingDirectory $DestinationRoot)

    $actualRefResult = Invoke-Git -Arguments @('--git-dir', $bareRepository, 'show-ref') -WorkingDirectory $DestinationRoot
    $actualRefs = Get-RefMap -Lines @(($actualRefResult.Output -split "`r?`n") | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
    Compare-ExactMap -Expected $expectedRefs -Actual $actualRefs -Label 'Restored ref'

    $sharedLfsRoot = Join-Path $BackupRoot 'LfsObjects'
    $bareLfsRoot = Join-Path $bareRepository 'lfs\objects'
    foreach ($oid in $expectedLfs.Keys) {
        $backupObject = Get-LfsObjectPath -Root $sharedLfsRoot -Oid $oid
        if (-not (Test-Path -LiteralPath $backupObject -PathType Leaf)) {
            throw "Backup Git LFS object is missing: $oid"
        }
        if ((Get-Item -LiteralPath $backupObject).Length -ne [Int64]$expectedLfs[$oid]) {
            throw "Backup Git LFS object size mismatch: $oid"
        }
        if (-not [string]::Equals((Get-Sha256 -Path $backupObject), $oid, [StringComparison]::OrdinalIgnoreCase)) {
            throw "Backup Git LFS object checksum failed: $oid"
        }
        $bareObject = Get-LfsObjectPath -Root $bareLfsRoot -Oid $oid
        New-Item -ItemType Directory -Path (Split-Path -Parent $bareObject) -Force | Out-Null
        Copy-Item -LiteralPath $backupObject -Destination $bareObject
    }

    [void](Invoke-Git -Arguments @('--git-dir', $bareRepository, 'fsck', '--full', '--strict') -WorkingDirectory $DestinationRoot)
    $restoredLfsResult = Invoke-Git -Arguments @('--git-dir', $bareRepository, 'lfs', 'ls-files', '--all', '--long') -WorkingDirectory $DestinationRoot
    $restoredLfsOids = @{}
    foreach ($line in ($restoredLfsResult.Output -split "`r?`n")) {
        if ($line -match '^([0-9a-fA-F]{64})\s') {
            $restoredLfsOids[$Matches[1].ToLowerInvariant()] = $true
        }
    }
    if ($restoredLfsOids.Count -ne $expectedLfs.Count) {
        throw "Restored Git LFS pointer count mismatch. Expected $($expectedLfs.Count), found $($restoredLfsOids.Count)."
    }
    foreach ($oid in $expectedLfs.Keys) {
        if (-not $restoredLfsOids.ContainsKey($oid)) {
            throw "Restored Git history is missing an expected LFS pointer: $oid"
        }
    }

    $previousSkipSmudge = $env:GIT_LFS_SKIP_SMUDGE
    try {
        $env:GIT_LFS_SKIP_SMUDGE = '1'
        [void](Invoke-Git -Arguments @('clone', '--no-local', '--branch', [string]$config.defaultBranch, $bareRepository, $workingCopy) -WorkingDirectory $DestinationRoot)
    }
    finally {
        if ($null -eq $previousSkipSmudge) {
            Remove-Item Env:GIT_LFS_SKIP_SMUDGE -ErrorAction SilentlyContinue
        }
        else {
            $env:GIT_LFS_SKIP_SMUDGE = $previousSkipSmudge
        }
    }

    $workingLfsRoot = Join-Path $workingCopy '.git\lfs\objects'
    foreach ($oid in $expectedLfs.Keys) {
        $backupObject = Get-LfsObjectPath -Root $sharedLfsRoot -Oid $oid
        $workingObject = Get-LfsObjectPath -Root $workingLfsRoot -Oid $oid
        New-Item -ItemType Directory -Path (Split-Path -Parent $workingObject) -Force | Out-Null
        Copy-Item -LiteralPath $backupObject -Destination $workingObject
    }
    [void](Invoke-Git -Arguments @('lfs', 'checkout') -WorkingDirectory $workingCopy)
    [void](Invoke-Git -Arguments @('lfs', 'fsck', '--pointers', 'HEAD') -WorkingDirectory $workingCopy)
    [void](Invoke-Git -Arguments @('fsck', '--full', '--strict') -WorkingDirectory $workingCopy)

    $workingStatus = (Invoke-Git -Arguments @('status', '--porcelain=v1', '--untracked-files=all') -WorkingDirectory $workingCopy).Output
    if (-not [string]::IsNullOrWhiteSpace($workingStatus)) {
        throw "The restored working copy is not clean:`n$workingStatus"
    }
    $restoredHead = (Invoke-Git -Arguments @('rev-parse', 'HEAD') -WorkingDirectory $workingCopy).Output.Trim()
    $expectedMainRef = 'refs/heads/' + [string]$config.defaultBranch
    if (-not $expectedRefs.ContainsKey($expectedMainRef)) {
        throw "The backup does not contain the configured default branch: $expectedMainRef"
    }
    if (-not [string]::Equals($restoredHead, [string]$expectedRefs[$expectedMainRef], [StringComparison]::OrdinalIgnoreCase)) {
        throw 'The restored working-copy HEAD does not match the captured default branch.'
    }

    $restoreResult = [ordered]@{
        schemaVersion = 1
        status = 'PASS'
        generationId = $GenerationId
        startedUtc = $restoreStartUtc.ToString('o')
        completedUtc = [DateTime]::UtcNow.ToString('o')
        networkUsed = $false
        restoredHead = $restoredHead
        restoredRefCount = $actualRefs.Count
        verifiedLfsObjectCount = $expectedLfs.Count
        bareRepository = $bareRepository
        workingCopy = $workingCopy
        workingCopyOrigin = $bareRepository
    }
    $restoreJsonPath = Join-Path $DestinationRoot 'restore.json'
    Write-RestoreTextFile -Path $restoreJsonPath -Content (($restoreResult | ConvertTo-Json -Depth 8) + [Environment]::NewLine)

    Write-RestoreMessage -Level 'PASS' -Message "Restored $($actualRefs.Count) refs and verified $($expectedLfs.Count) LFS objects without GitHub."
    Write-RestoreMessage -Level 'INFO' -Message "Working copy: $workingCopy"
    Write-RestoreTextFile -Path (Join-Path $DestinationRoot 'restore.log') -Content (($script:LogLines -join [Environment]::NewLine) + [Environment]::NewLine)
    exit 0
}
catch {
    Write-RestoreMessage -Level 'FAIL' -Message $_.Exception.Message
    if (Test-Path -LiteralPath $DestinationRoot -PathType Container) {
        try {
            Write-RestoreTextFile -Path (Join-Path $DestinationRoot 'restore-failed.log') -Content (($script:LogLines -join [Environment]::NewLine) + [Environment]::NewLine)
        }
        catch {
            Write-Warning "Could not write the restore failure log: $($_.Exception.Message)"
        }
    }
    exit 1
}
