#requires -Version 5.1

[CmdletBinding()]
param(
    [string]$RepositoryRoot,
    [string]$BackupRoot,
    [switch]$SkipOriginRefresh,
    [switch]$AllowDirty,
    [switch]$PlanOnly,
    [ValidateSet('Local', 'Offline')]
    [string]$PolicyContext = 'Local',
    [string]$EncryptionPolicyOverride,
    [string]$OffsitePolicyOverride,
    [string]$SchedulePolicyOverride
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$script:Utf8NoBom = New-Object System.Text.UTF8Encoding($false)
$script:LogLines = New-Object System.Collections.Generic.List[string]
$script:RunId = $null
$script:ResolvedBackupRoot = $null
$script:GitExecutable = $null

function Write-BackupTextFile {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [AllowEmptyString()][string]$Content
    )

    [System.IO.File]::WriteAllText($Path, $Content, $script:Utf8NoBom)
}

function Write-BackupMessage {
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

function Assert-SafeRoot {
    param(
        [Parameter(Mandatory = $true)][string]$SourceRoot,
        [Parameter(Mandatory = $true)][string]$DestinationRoot
    )

    $source = Get-NormalizedFullPath -Path $SourceRoot
    $destination = Get-NormalizedFullPath -Path $DestinationRoot
    $destinationDriveRoot = Get-NormalizedFullPath -Path ([System.IO.Path]::GetPathRoot($destination))

    if ([string]::Equals($destination, $destinationDriveRoot, [StringComparison]::OrdinalIgnoreCase)) {
        throw "The backup destination must not be a drive root: $destination"
    }
    if ([string]::Equals($source, $destination, [StringComparison]::OrdinalIgnoreCase)) {
        throw 'The source repository and backup destination must be different.'
    }

    $sourcePrefix = $source + [System.IO.Path]::DirectorySeparatorChar
    $destinationPrefix = $destination + [System.IO.Path]::DirectorySeparatorChar
    if ($destination.StartsWith($sourcePrefix, [StringComparison]::OrdinalIgnoreCase)) {
        throw 'The backup destination must not be inside the source repository.'
    }
    if ($source.StartsWith($destinationPrefix, [StringComparison]::OrdinalIgnoreCase)) {
        throw 'The source repository must not be inside the backup destination.'
    }

    $sourceDrive = [System.IO.Path]::GetPathRoot($source)
    $destinationDrive = [System.IO.Path]::GetPathRoot($destination)
    if ([string]::Equals($sourceDrive, $destinationDrive, [StringComparison]::OrdinalIgnoreCase)) {
        throw "The backup must use a different volume from the repository. Both resolve to $sourceDrive"
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

function Write-JsonFile {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)]$Value
    )

    $json = $Value | ConvertTo-Json -Depth 12
    Write-BackupTextFile -Path $Path -Content ($json + [Environment]::NewLine)
}

function Get-RequiredLfsOids {
    param([Parameter(Mandatory = $true)][string]$RepoRoot)

    $result = Invoke-Git -Arguments @('lfs', 'ls-files', '--all', '--long') -WorkingDirectory $RepoRoot
    $oids = New-Object System.Collections.Generic.HashSet[string] ([StringComparer]::OrdinalIgnoreCase)
    foreach ($line in ($result.Output -split "`r?`n")) {
        if ($line -match '^([0-9a-fA-F]{64})\s') {
            [void]$oids.Add($Matches[1].ToLowerInvariant())
        }
    }
    return @($oids | Sort-Object)
}

function Get-LfsObjectPath {
    param(
        [Parameter(Mandatory = $true)][string]$Root,
        [Parameter(Mandatory = $true)][string]$Oid
    )

    return Join-Path (Join-Path (Join-Path $Root $Oid.Substring(0, 2)) $Oid.Substring(2, 2)) $Oid
}

function Remove-ExpiredGenerations {
    param(
        [Parameter(Mandatory = $true)][string]$GenerationsRoot,
        [Parameter(Mandatory = $true)][int]$RetentionCount,
        [Parameter(Mandatory = $true)][string]$CurrentGeneration
    )

    $root = Get-NormalizedFullPath -Path $GenerationsRoot
    $items = @(Get-ChildItem -LiteralPath $root -Directory |
        Where-Object { $_.Name -match '^[0-9]{8}T[0-9]{6}Z-[0-9]+-[0-9a-f]{8}$' } |
        Sort-Object Name -Descending)
    if ($items.Count -le $RetentionCount) {
        return 0
    }

    $removed = 0
    foreach ($item in ($items | Select-Object -Skip $RetentionCount)) {
        if ($item.Name -notmatch '^[0-9]{8}T[0-9]{6}Z-[0-9]+-[0-9a-f]{8}$') {
            throw "Refusing to remove a directory that is not a recognized generation: $($item.FullName)"
        }
        $target = Get-NormalizedFullPath -Path $item.FullName
        $parent = Get-NormalizedFullPath -Path $item.Parent.FullName
        if (-not [string]::Equals($parent, $root, [StringComparison]::OrdinalIgnoreCase)) {
            throw "Refusing to remove a generation outside the verified root: $target"
        }
        if ([string]::Equals($target, $CurrentGeneration, [StringComparison]::OrdinalIgnoreCase)) {
            throw 'Refusing to remove the current successful generation.'
        }
        Remove-Item -LiteralPath $target -Recurse -Force
        $removed++
    }
    return $removed
}

try {
    $configPath = Join-Path $PSScriptRoot 'RepositoryBackupConfig.json'
    if (-not (Test-Path -LiteralPath $configPath -PathType Leaf)) {
        throw "Backup configuration is missing: $configPath"
    }
    $config = Get-Content -Raw -LiteralPath $configPath | ConvertFrom-Json
    if ([int]$config.schemaVersion -ne 1) {
        throw "Unsupported backup configuration schema: $($config.schemaVersion)"
    }
    $effectiveEncryptionPolicy = if ([string]::IsNullOrWhiteSpace($EncryptionPolicyOverride)) { [string]$config.encryptionPolicy } else { $EncryptionPolicyOverride }
    $effectiveOffsitePolicy = if ([string]::IsNullOrWhiteSpace($OffsitePolicyOverride)) { [string]$config.offsitePolicy } else { $OffsitePolicyOverride }
    $effectiveSchedulePolicy = if ([string]::IsNullOrWhiteSpace($SchedulePolicyOverride)) { [string]$config.scheduleLocalTime } else { $SchedulePolicyOverride }
    $script:GitExecutable = Resolve-GitExecutable -PreferredPath ([string]$config.gitExecutable)

    if ([string]::IsNullOrWhiteSpace($RepositoryRoot)) {
        $RepositoryRoot = [string]$config.repositoryRoot
    }
    if ([string]::IsNullOrWhiteSpace($BackupRoot)) {
        $BackupRoot = [string]$config.backupRoot
    }

    $RepositoryRoot = Get-NormalizedFullPath -Path $RepositoryRoot
    $BackupRoot = Get-NormalizedFullPath -Path $BackupRoot
    $script:ResolvedBackupRoot = $BackupRoot
    Assert-SafeRoot -SourceRoot $RepositoryRoot -DestinationRoot $BackupRoot

    if (-not (Test-Path -LiteralPath $RepositoryRoot -PathType Container)) {
        throw "Repository root does not exist: $RepositoryRoot"
    }
    if (-not (Test-Path -LiteralPath (Join-Path $RepositoryRoot '.git'))) {
        throw "The source is not the expected non-bare Git repository: $RepositoryRoot"
    }

    $gitVersion = (Invoke-Git -Arguments @('--version') -WorkingDirectory $RepositoryRoot).Output.Trim()
    $lfsVersion = (Invoke-Git -Arguments @('lfs', 'version') -WorkingDirectory $RepositoryRoot).Output.Trim()
    $topLevel = (Invoke-Git -Arguments @('rev-parse', '--show-toplevel') -WorkingDirectory $RepositoryRoot).Output.Trim()
    if (-not [string]::Equals((Get-NormalizedFullPath -Path $topLevel), $RepositoryRoot, [StringComparison]::OrdinalIgnoreCase)) {
        throw "Repository root mismatch. Expected $RepositoryRoot but Git reported $topLevel"
    }

    $statusText = (Invoke-Git -Arguments @('status', '--porcelain=v1', '--untracked-files=all') -WorkingDirectory $RepositoryRoot).Output
    $sourceDirty = -not [string]::IsNullOrWhiteSpace($statusText)
    if ($sourceDirty -and (-not $AllowDirty)) {
        throw 'The repository has uncommitted changes. Commit or explicitly use -AllowDirty; uncommitted files are never included in the repository backup.'
    }
    if ($sourceDirty) {
        Write-BackupMessage -Level 'WARN' -Message 'The repository is dirty. The backup captures committed refs only; uncommitted files are excluded.'
    }

    $destinationDrive = New-Object System.IO.DriveInfo ([System.IO.Path]::GetPathRoot($BackupRoot))
    if (-not $destinationDrive.IsReady) {
        throw "Backup volume is not ready: $($destinationDrive.Name)"
    }
    $freeGiB = [Math]::Round($destinationDrive.AvailableFreeSpace / 1GB, 2)
    if ($freeGiB -lt [double]$config.hardMinimumFreeSpaceGiB) {
        throw "Backup volume has only $freeGiB GiB free; the hard reserve is $($config.hardMinimumFreeSpaceGiB) GiB."
    }
    if ($freeGiB -lt [double]$config.warningFreeSpaceGiB) {
        Write-BackupMessage -Level 'WARN' -Message "Backup capacity is below the warning threshold: $freeGiB GiB free."
    }

    $refPreview = (Invoke-Git -Arguments @('show-ref') -WorkingDirectory $RepositoryRoot).Output
    $previewRefCount = @(($refPreview -split "`r?`n") | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }).Count
    $previewLfsOids = @(Get-RequiredLfsOids -RepoRoot $RepositoryRoot)

    if ($PlanOnly) {
        Write-BackupMessage -Level 'PLAN' -Message "Repository: $RepositoryRoot"
        Write-BackupMessage -Level 'PLAN' -Message "Independent backup root: $BackupRoot"
        Write-BackupMessage -Level 'PLAN' -Message "Captured refs now: $previewRefCount; required LFS objects now: $($previewLfsOids.Count)."
        Write-BackupMessage -Level 'PLAN' -Message "Retention: $($config.retentionGenerationCount) Git generations; LFS objects are never deleted automatically."
        Write-BackupMessage -Level 'PASS' -Message 'Backup plan and safety checks passed; no files were written.'
        exit 0
    }

    New-Item -ItemType Directory -Path $BackupRoot -Force | Out-Null
    $logsRoot = Join-Path $BackupRoot 'Logs'
    $stagingRoot = Join-Path $BackupRoot 'Staging'
    $generationsRoot = Join-Path $BackupRoot 'Generations'
    $sharedLfsRoot = Join-Path $BackupRoot 'LfsObjects'
    foreach ($directory in @($logsRoot, $stagingRoot, $generationsRoot, $sharedLfsRoot)) {
        New-Item -ItemType Directory -Path $directory -Force | Out-Null
    }

    $lockPath = Join-Path $BackupRoot '.backup.lock'
    $lockHandle = $null
    try {
        $lockHandle = [System.IO.File]::Open($lockPath, [System.IO.FileMode]::OpenOrCreate, [System.IO.FileAccess]::ReadWrite, [System.IO.FileShare]::None)
    }
    catch {
        throw "Another repository backup appears to be running. Lock: $lockPath"
    }

    try {
        $startUtc = [DateTime]::UtcNow
        $script:RunId = '{0}-{1}-{2}' -f $startUtc.ToString('yyyyMMddTHHmmssZ'), $PID, ([Guid]::NewGuid().ToString('N').Substring(0, 8))
        $stagingPath = Join-Path $stagingRoot $script:RunId
        $generationPath = Join-Path $generationsRoot $script:RunId
        if ((Test-Path -LiteralPath $stagingPath) -or (Test-Path -LiteralPath $generationPath)) {
            throw "Backup run path already exists: $script:RunId"
        }
        New-Item -ItemType Directory -Path $stagingPath | Out-Null

        Write-BackupMessage -Level 'INFO' -Message "Starting repository backup generation $script:RunId."

        $originRefresh = [ordered]@{
            requested = (-not $SkipOriginRefresh) -and [bool]$config.refreshOrigin
            status = 'SKIPPED'
            message = 'Origin refresh was not requested.'
        }
        if ($originRefresh.requested) {
            try {
                Write-BackupMessage -Level 'INFO' -Message "Refreshing Git refs and Git LFS from remote '$($config.originRemote)'."
                [void](Invoke-Git -Arguments @('fetch', [string]$config.originRemote, '--tags') -WorkingDirectory $RepositoryRoot)
                [void](Invoke-Git -Arguments @('lfs', 'fetch', '--all', [string]$config.originRemote) -WorkingDirectory $RepositoryRoot)
                $originRefresh.status = 'PASS'
                $originRefresh.message = 'Git refs and Git LFS refresh completed.'
            }
            catch {
                $originRefresh.status = 'WARN'
                $originRefresh.message = $_.Exception.Message
                Write-BackupMessage -Level 'WARN' -Message 'Origin refresh failed. Backup continues only if every locally captured ref and LFS payload is complete.'
            }
        }

        $headCommit = (Invoke-Git -Arguments @('rev-parse', 'HEAD') -WorkingDirectory $RepositoryRoot).Output.Trim()
        $headBranchResult = Invoke-Git -Arguments @('symbolic-ref', '--short', '-q', 'HEAD') -WorkingDirectory $RepositoryRoot -AllowFailure
        $headBranch = if ($headBranchResult.ExitCode -eq 0) { $headBranchResult.Output.Trim() } else { $null }

        $refResult = Invoke-Git -Arguments @('show-ref') -WorkingDirectory $RepositoryRoot
        $refLines = @(($refResult.Output -split "`r?`n") | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Sort-Object)
        if ($refLines.Count -eq 0) {
            throw 'No Git refs were found; refusing to publish an empty backup.'
        }
        $refsPath = Join-Path $stagingPath 'refs.txt'
        Write-BackupTextFile -Path $refsPath -Content (($refLines -join [Environment]::NewLine) + [Environment]::NewLine)

        $bundlePath = Join-Path $stagingPath 'repository.bundle'
        Write-BackupMessage -Level 'INFO' -Message "Creating a full Git bundle for $($refLines.Count) refs."
        [void](Invoke-Git -Arguments @('bundle', 'create', $bundlePath, '--all') -WorkingDirectory $RepositoryRoot)
        $bundleVerify = Invoke-Git -Arguments @('bundle', 'verify', $bundlePath) -WorkingDirectory $RepositoryRoot

        $gitDirText = (Invoke-Git -Arguments @('rev-parse', '--git-dir') -WorkingDirectory $RepositoryRoot).Output.Trim()
        $gitDir = if ([System.IO.Path]::IsPathRooted($gitDirText)) {
            Get-NormalizedFullPath -Path $gitDirText
        }
        else {
            Get-NormalizedFullPath -Path (Join-Path $RepositoryRoot $gitDirText)
        }
        $sourceLfsRoot = Join-Path $gitDir 'lfs\objects'

        $lfsOids = @(Get-RequiredLfsOids -RepoRoot $RepositoryRoot)
        $lfsInventoryLines = New-Object System.Collections.Generic.List[string]
        $copiedLfsObjects = 0
        $reusedLfsObjects = 0
        $lfsTotalBytes = [Int64]0
        foreach ($oid in $lfsOids) {
            $sourceObject = Get-LfsObjectPath -Root $sourceLfsRoot -Oid $oid
            if (-not (Test-Path -LiteralPath $sourceObject -PathType Leaf)) {
                throw "Required Git LFS object is missing locally after refresh: $oid"
            }
            $sourceHash = Get-Sha256 -Path $sourceObject
            if (-not [string]::Equals($sourceHash, $oid, [StringComparison]::OrdinalIgnoreCase)) {
                throw "Source Git LFS object checksum does not match its OID: $oid"
            }
            $size = (Get-Item -LiteralPath $sourceObject).Length
            $lfsTotalBytes += $size

            $backupObject = Get-LfsObjectPath -Root $sharedLfsRoot -Oid $oid
            $backupObjectDirectory = Split-Path -Parent $backupObject
            New-Item -ItemType Directory -Path $backupObjectDirectory -Force | Out-Null
            if (Test-Path -LiteralPath $backupObject -PathType Leaf) {
                if (-not [string]::Equals((Get-Sha256 -Path $backupObject), $oid, [StringComparison]::OrdinalIgnoreCase)) {
                    throw "Existing backup Git LFS object is corrupt: $backupObject"
                }
                $reusedLfsObjects++
            }
            else {
                $temporaryObject = $backupObject + '.tmp.' + $script:RunId
                Copy-Item -LiteralPath $sourceObject -Destination $temporaryObject
                if (-not [string]::Equals((Get-Sha256 -Path $temporaryObject), $oid, [StringComparison]::OrdinalIgnoreCase)) {
                    throw "Copied Git LFS object checksum failed: $oid"
                }
                Move-Item -LiteralPath $temporaryObject -Destination $backupObject
                $copiedLfsObjects++
            }
            $lfsInventoryLines.Add(("{0}`t{1}" -f $oid, $size))
        }

        $lfsInventoryPath = Join-Path $stagingPath 'lfs-objects.tsv'
        $lfsInventoryContent = if ($lfsInventoryLines.Count -gt 0) {
            ($lfsInventoryLines -join [Environment]::NewLine) + [Environment]::NewLine
        }
        else {
            ''
        }
        Write-BackupTextFile -Path $lfsInventoryPath -Content $lfsInventoryContent

        $bundleFile = Get-Item -LiteralPath $bundlePath
        $manifest = [ordered]@{
            schemaVersion = 1
            status = 'PASS'
            generationId = $script:RunId
            startUtc = $startUtc.ToString('o')
            completedUtc = [DateTime]::UtcNow.ToString('o')
            source = [ordered]@{
                repositoryRoot = $RepositoryRoot
                headCommit = $headCommit
                headBranch = $headBranch
                workingTreeDirty = $sourceDirty
                uncommittedFilesIncluded = $false
            }
            git = [ordered]@{
                executable = $script:GitExecutable
                version = $gitVersion
                lfsVersion = $lfsVersion
                bundleFile = 'repository.bundle'
                bundleBytes = $bundleFile.Length
                bundleSha256 = Get-Sha256 -Path $bundlePath
                bundleVerify = $bundleVerify.Output
                refsFile = 'refs.txt'
                refsCount = $refLines.Count
                refsSha256 = Get-Sha256 -Path $refsPath
                localBranchCount = @($refLines | Where-Object { $_ -match ' refs/heads/' }).Count
                tagCount = @($refLines | Where-Object { $_ -match ' refs/tags/' }).Count
            }
            lfs = [ordered]@{
                inventoryFile = 'lfs-objects.tsv'
                inventorySha256 = Get-Sha256 -Path $lfsInventoryPath
                objectCount = $lfsOids.Count
                totalBytes = $lfsTotalBytes
                copiedThisRun = $copiedLfsObjects
                reusedThisRun = $reusedLfsObjects
                sharedStore = $sharedLfsRoot
                automaticDeletion = $false
            }
            originRefresh = $originRefresh
            policy = [ordered]@{
                context = $PolicyContext
                owner = [string]$config.owner
                retentionGenerationCount = [int]$config.retentionGenerationCount
                warningFreeSpaceGiB = [double]$config.warningFreeSpaceGiB
                hardMinimumFreeSpaceGiB = [double]$config.hardMinimumFreeSpaceGiB
                scheduleLocalTime = $(if ($PolicyContext -eq 'Local') { [string]$config.scheduleLocalTime } else { $null })
                schedule = $effectiveSchedulePolicy
                encryption = $effectiveEncryptionPolicy
                offsite = $effectiveOffsitePolicy
            }
        }
        $manifestPath = Join-Path $stagingPath 'manifest.json'
        Write-JsonFile -Path $manifestPath -Value $manifest

        $checksums = @(
            ("{0}`t{1}" -f (Get-Sha256 -Path $bundlePath), 'repository.bundle'),
            ("{0}`t{1}" -f (Get-Sha256 -Path $refsPath), 'refs.txt'),
            ("{0}`t{1}" -f (Get-Sha256 -Path $lfsInventoryPath), 'lfs-objects.tsv'),
            ("{0}`t{1}" -f (Get-Sha256 -Path $manifestPath), 'manifest.json')
        )
        $checksumsPath = Join-Path $stagingPath 'checksums.sha256'
        Write-BackupTextFile -Path $checksumsPath -Content (($checksums -join [Environment]::NewLine) + [Environment]::NewLine)

        Move-Item -LiteralPath $stagingPath -Destination $generationPath
        $generationPath = Get-NormalizedFullPath -Path $generationPath

        $latest = [ordered]@{
            schemaVersion = 1
            generationId = $script:RunId
            generationPath = $generationPath
            completedUtc = $manifest.completedUtc
            sourceHeadCommit = $headCommit
            manifestSha256 = Get-Sha256 -Path (Join-Path $generationPath 'manifest.json')
            checksumsSha256 = Get-Sha256 -Path (Join-Path $generationPath 'checksums.sha256')
        }
        $latestPath = Join-Path $BackupRoot 'LATEST.json'
        $previousLatestPath = Join-Path $BackupRoot 'LATEST.previous.json'
        $temporaryLatestPath = Join-Path $BackupRoot ('.LATEST.{0}.tmp' -f $script:RunId)
        Write-JsonFile -Path $temporaryLatestPath -Value $latest
        if (Test-Path -LiteralPath $latestPath -PathType Leaf) {
            [System.IO.File]::Replace($temporaryLatestPath, $latestPath, $previousLatestPath, $true)
        }
        else {
            Move-Item -LiteralPath $temporaryLatestPath -Destination $latestPath
        }

        $removedGenerations = Remove-ExpiredGenerations -GenerationsRoot $generationsRoot -RetentionCount ([int]$config.retentionGenerationCount) -CurrentGeneration $generationPath
        Write-BackupMessage -Level 'PASS' -Message "Published generation $script:RunId with $($refLines.Count) refs and $($lfsOids.Count) LFS objects."
        Write-BackupMessage -Level 'INFO' -Message "Generation: $generationPath"
        Write-BackupMessage -Level 'INFO' -Message "Removed expired Git generations: $removedGenerations. Shared LFS objects were not deleted."
    }
    finally {
        if ($null -ne $lockHandle) {
            $lockHandle.Dispose()
        }
    }

    $logPath = Join-Path (Join-Path $BackupRoot 'Logs') ($script:RunId + '.log')
    Write-BackupTextFile -Path $logPath -Content (($script:LogLines -join [Environment]::NewLine) + [Environment]::NewLine)
    exit 0
}
catch {
    $message = $_.Exception.Message
    Write-BackupMessage -Level 'FAIL' -Message $message
    if ((-not [string]::IsNullOrWhiteSpace($script:ResolvedBackupRoot)) -and (Test-Path -LiteralPath $script:ResolvedBackupRoot -PathType Container)) {
        try {
            $logsRoot = Join-Path $script:ResolvedBackupRoot 'Logs'
            New-Item -ItemType Directory -Path $logsRoot -Force | Out-Null
            $failureId = if ([string]::IsNullOrWhiteSpace($script:RunId)) {
                'failed-{0}-{1}' -f [DateTime]::UtcNow.ToString('yyyyMMddTHHmmssZ'), $PID
            }
            else {
                $script:RunId + '-failed'
            }
            Write-BackupTextFile -Path (Join-Path $logsRoot ($failureId + '.log')) -Content (($script:LogLines -join [Environment]::NewLine) + [Environment]::NewLine)
        }
        catch {
            Write-Warning "Could not write the backup failure log: $($_.Exception.Message)"
        }
    }
    exit 1
}
