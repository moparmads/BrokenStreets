#requires -Version 5.1

[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$sourceArtToolsRoot = Split-Path -Parent $PSScriptRoot
$toolsRoot = Split-Path -Parent $sourceArtToolsRoot
$repositoryRoot = Split-Path -Parent $toolsRoot
$config = [System.IO.File]::ReadAllText((Join-Path $sourceArtToolsRoot 'SourceArtBackupConfig.json'), (New-Object System.Text.UTF8Encoding($false))) | ConvertFrom-Json
$runId = '{0}-{1}-{2}' -f [DateTime]::UtcNow.ToString('yyyyMMddTHHmmssZ'), $PID, ([Guid]::NewGuid().ToString('N').Substring(0, 8))
$sourceTestsParent = Join-Path $repositoryRoot 'Saved\SourceArtBackupSelfTest'
$sourceTestRoot = Join-Path $sourceTestsParent $runId
$sourceRoot = Join-Path $sourceTestRoot 'Source'
$externalTestsParent = Join-Path ([string]$config.localBackupRoot) 'SelfTests'
$externalTestRoot = Join-Path $externalTestsParent $runId
$backupRoot = Join-Path $externalTestRoot 'Backup'
$restoreRoot = Join-Path $externalTestRoot 'Restore'
$existingDestination = Join-Path $externalTestRoot 'ExistingDestination'
$corruptDestination = Join-Path $externalTestRoot 'CorruptDestination'
$sameDriveBackupRoot = Join-Path $sourceTestRoot 'InvalidSameDriveBackup'
$backupScript = Join-Path $sourceArtToolsRoot 'Invoke-SourceArtBackup.ps1'
$restoreScript = Join-Path $sourceArtToolsRoot 'Invoke-SourceArtRestore.ps1'
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
$unicodeFolderName = 'Caf' + [char]0x00E9
$passed = $false

function Invoke-SourceArtSelfTestProcess {
    param(
        [Parameter(Mandatory = $true)][string]$ScriptPath,
        [Parameter(Mandatory = $true)][string[]]$Arguments
    )

    $previousErrorActionPreference = $ErrorActionPreference
    try {
        $ErrorActionPreference = 'Continue'
        $output = @(& powershell.exe -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -File $ScriptPath @Arguments 2>&1)
        $exitCode = $LASTEXITCODE
    }
    finally {
        $ErrorActionPreference = $previousErrorActionPreference
    }
    return [pscustomobject]@{
        ExitCode = $exitCode
        Output = (($output | ForEach-Object { $_.ToString() }) -join [Environment]::NewLine)
    }
}

function Assert-SourceArtSelfTestSuccess {
    param(
        [Parameter(Mandatory = $true)]$Result,
        [Parameter(Mandatory = $true)][string]$Label
    )

    if ($Result.ExitCode -ne 0) {
        throw "$Label failed with exit code $($Result.ExitCode):`n$($Result.Output)"
    }
}

function Assert-SourceArtSelfTestFailure {
    param(
        [Parameter(Mandatory = $true)]$Result,
        [Parameter(Mandatory = $true)][string]$Label
    )

    if ($Result.ExitCode -eq 0) {
        throw "$Label unexpectedly succeeded:`n$($Result.Output)"
    }
}

function Get-SourceArtSelfTestInventory {
    param(
        [Parameter(Mandatory = $true)][string]$Root,
        [string[]]$ExcludedRelativePaths = @()
    )

    $excluded = @{}
    foreach ($relative in $ExcludedRelativePaths) {
        $excluded[$relative.ToLowerInvariant()] = $true
    }
    $map = @{}
    foreach ($file in @(Get-ChildItem -LiteralPath $Root -Recurse -Force -File | Sort-Object FullName)) {
        $relative = $file.FullName.Substring($Root.TrimEnd([char[]]@('\', '/')).Length).TrimStart([char[]]@('\', '/')).Replace('\', '/')
        if ($excluded.ContainsKey($relative.ToLowerInvariant())) {
            continue
        }
        $stream = [System.IO.File]::Open($file.FullName, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::Read)
        $algorithm = [System.Security.Cryptography.SHA256]::Create()
        try {
            $hashBytes = $algorithm.ComputeHash($stream)
        }
        finally {
            $algorithm.Dispose()
            $stream.Dispose()
        }
        $map[$relative] = [pscustomobject]@{
            Length = [Int64]$file.Length
            Sha256 = (($hashBytes | ForEach-Object { $_.ToString('x2') }) -join '')
        }
    }
    return $map
}

function Assert-SourceArtSelfTestInventoryEqual {
    param(
        [Parameter(Mandatory = $true)]$Expected,
        [Parameter(Mandatory = $true)]$Actual
    )

    if ($Expected.Count -ne $Actual.Count) {
        throw "Restored file count mismatch. Expected $($Expected.Count), found $($Actual.Count)."
    }
    foreach ($path in $Expected.Keys) {
        if (-not $Actual.ContainsKey($path)) {
            throw "Restored file is missing: $path"
        }
        if (($Expected[$path].Length -ne $Actual[$path].Length) -or (-not [string]::Equals($Expected[$path].Sha256, $Actual[$path].Sha256, [StringComparison]::OrdinalIgnoreCase))) {
            throw "Restored file content mismatch: $path"
        }
    }
}

function Assert-SourceArtSelfTestCleanupTarget {
    param(
        [Parameter(Mandatory = $true)][string]$Target,
        [Parameter(Mandatory = $true)][string]$RequiredParent
    )

    $targetPath = [System.IO.Path]::GetFullPath($Target).TrimEnd([char[]]@('\', '/'))
    $parentPath = [System.IO.Path]::GetFullPath($RequiredParent).TrimEnd([char[]]@('\', '/'))
    $prefix = $parentPath + [System.IO.Path]::DirectorySeparatorChar
    if (-not $targetPath.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase)) {
        throw "Self-test cleanup target escapes its verified parent: $targetPath"
    }
}

try {
    $unicodeDirectory = Join-Path (Join-Path $sourceRoot 'Nested') $unicodeFolderName
    New-Item -ItemType Directory -Path $unicodeDirectory -Force | Out-Null
    New-Item -ItemType Directory -Path $externalTestRoot -Force | Out-Null
    [System.IO.File]::WriteAllText((Join-Path $unicodeDirectory 'notes.txt'), "Broken Streets Source Art generation one.`r`n", $utf8NoBom)
    $binaryFixture = [byte[]](0..255)
    [System.IO.File]::WriteAllBytes((Join-Path $sourceRoot 'mesh-source.bin'), $binaryFixture)
    [System.IO.File]::WriteAllBytes((Join-Path $sourceRoot 'mesh-duplicate.bin'), $binaryFixture)

    $firstBackup = Invoke-SourceArtSelfTestProcess -ScriptPath $backupScript -Arguments @(
        '-Target', 'SelfTest', '-SourceRoot', $sourceRoot, '-BackupRoot', $backupRoot, '-FullObjectAudit'
    )
    Assert-SourceArtSelfTestSuccess -Result $firstBackup -Label 'First synthetic Source Art backup'
    if ($firstBackup.Output -notmatch '\[PASS\] Published Source Art generation') {
        throw 'First synthetic Source Art backup did not report publication.'
    }

    [System.IO.File]::WriteAllText((Join-Path $unicodeDirectory 'notes.txt'), "Broken Streets Source Art generation two.`r`n", $utf8NoBom)
    [System.IO.File]::WriteAllBytes((Join-Path $sourceRoot 'Nested\second-copy.bin'), $binaryFixture)
    $secondBackup = Invoke-SourceArtSelfTestProcess -ScriptPath $backupScript -Arguments @(
        '-Target', 'SelfTest', '-SourceRoot', $sourceRoot, '-BackupRoot', $backupRoot, '-FullObjectAudit'
    )
    Assert-SourceArtSelfTestSuccess -Result $secondBackup -Label 'Second synthetic Source Art backup'

    $generationCount = @(Get-ChildItem -LiteralPath (Join-Path $backupRoot 'Generations') -Directory).Count
    if ($generationCount -ne 2) {
        throw "Expected two immutable Source Art generations, found $generationCount."
    }
    $objectCount = @(Get-ChildItem -LiteralPath (Join-Path $backupRoot 'Objects') -Recurse -File).Count
    if ($objectCount -ne 3) {
        throw "Expected three deduplicated content objects, found $objectCount."
    }
    if (-not (Test-Path -LiteralPath (Join-Path $backupRoot 'LATEST.previous.json') -PathType Leaf)) {
        throw 'Previous successful Source Art pointer was not preserved.'
    }

    $latestPath = Join-Path $backupRoot 'LATEST.json'
    $latestBeforeFailure = [System.IO.File]::ReadAllText($latestPath, $utf8NoBom)
    $lockedPath = Join-Path $sourceRoot 'locked-during-backup.bin'
    [System.IO.File]::WriteAllBytes($lockedPath, [byte[]](1..32))
    $lockedStream = [System.IO.File]::Open($lockedPath, [System.IO.FileMode]::Open, [System.IO.FileAccess]::ReadWrite, [System.IO.FileShare]::None)
    try {
        $failedBackup = Invoke-SourceArtSelfTestProcess -ScriptPath $backupScript -Arguments @(
            '-Target', 'SelfTest', '-SourceRoot', $sourceRoot, '-BackupRoot', $backupRoot
        )
    }
    finally {
        $lockedStream.Dispose()
    }
    Assert-SourceArtSelfTestFailure -Result $failedBackup -Label 'Locked-file backup'
    $latestAfterFailure = [System.IO.File]::ReadAllText($latestPath, $utf8NoBom)
    if (-not [string]::Equals($latestBeforeFailure, $latestAfterFailure, [StringComparison]::Ordinal)) {
        throw 'A failed Source Art backup advanced or changed LATEST.json.'
    }
    Remove-Item -LiteralPath $lockedPath -Force

    $sameDriveResult = Invoke-SourceArtSelfTestProcess -ScriptPath $backupScript -Arguments @(
        '-Target', 'SelfTest', '-SourceRoot', $sourceRoot, '-BackupRoot', $sameDriveBackupRoot
    )
    Assert-SourceArtSelfTestFailure -Result $sameDriveResult -Label 'Same-drive safety check'

    $restore = Invoke-SourceArtSelfTestProcess -ScriptPath $restoreScript -Arguments @(
        '-Target', 'SelfTest', '-BackupRoot', $backupRoot, '-DestinationRoot', $restoreRoot
    )
    Assert-SourceArtSelfTestSuccess -Result $restore -Label 'Synthetic Source Art restore'
    $expectedInventory = Get-SourceArtSelfTestInventory -Root $sourceRoot
    $actualInventory = Get-SourceArtSelfTestInventory -Root $restoreRoot -ExcludedRelativePaths @('restore.json')
    Assert-SourceArtSelfTestInventoryEqual -Expected $expectedInventory -Actual $actualInventory

    New-Item -ItemType Directory -Path $existingDestination | Out-Null
    $existingDestinationResult = Invoke-SourceArtSelfTestProcess -ScriptPath $restoreScript -Arguments @(
        '-Target', 'SelfTest', '-BackupRoot', $backupRoot, '-DestinationRoot', $existingDestination
    )
    Assert-SourceArtSelfTestFailure -Result $existingDestinationResult -Label 'Existing restore destination safety check'
    Remove-Item -LiteralPath $existingDestination -Recurse -Force

    $latest = [System.IO.File]::ReadAllText($latestPath, $utf8NoBom) | ConvertFrom-Json
    $latestInventoryPath = Join-Path (Join-Path (Join-Path $backupRoot 'Generations') ([string]$latest.generationId)) 'files.json'
    $latestInventory = [System.IO.File]::ReadAllText($latestInventoryPath, $utf8NoBom) | ConvertFrom-Json
    $firstFile = @($latestInventory.files)[0]
    $sha256 = [string]$firstFile.sha256
    $objectPath = Join-Path $backupRoot ('Objects\{0}\{1}\{2}' -f $sha256.Substring(0, 2), $sha256.Substring(2, 2), $sha256)
    $corruptBytes = [System.IO.File]::ReadAllBytes($objectPath)
    $corruptBytes[0] = $corruptBytes[0] -bxor 0xFF
    [System.IO.File]::WriteAllBytes($objectPath, $corruptBytes)
    $corruptRestore = Invoke-SourceArtSelfTestProcess -ScriptPath $restoreScript -Arguments @(
        '-Target', 'SelfTest', '-BackupRoot', $backupRoot, '-DestinationRoot', $corruptDestination
    )
    Assert-SourceArtSelfTestFailure -Result $corruptRestore -Label 'Corrupted-object restore'
    if (Test-Path -LiteralPath $corruptDestination) {
        throw 'Corrupted-object restore created a destination before completing object verification.'
    }

    $passed = $true
    Write-Host '[PASS] Source Art backup self-test verified deduplication, immutable generations, pointer safety, exact restore, and corruption rejection.'
}
finally {
    if ($passed) {
        Assert-SourceArtSelfTestCleanupTarget -Target $sourceTestRoot -RequiredParent $sourceTestsParent
        Assert-SourceArtSelfTestCleanupTarget -Target $externalTestRoot -RequiredParent $externalTestsParent
        if (Test-Path -LiteralPath $sourceTestRoot) {
            Remove-Item -LiteralPath $sourceTestRoot -Recurse -Force
        }
        if (Test-Path -LiteralPath $externalTestRoot) {
            Remove-Item -LiteralPath $externalTestRoot -Recurse -Force
        }
    }
    else {
        Write-Warning "Source Art self-test artifacts were retained for diagnosis: $sourceTestRoot and $externalTestRoot"
    }
}
