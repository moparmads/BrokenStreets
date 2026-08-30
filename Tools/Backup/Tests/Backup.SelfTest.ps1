#requires -Version 5.1

[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
$backupToolsRoot = Split-Path -Parent $PSScriptRoot
$toolsRoot = Split-Path -Parent $backupToolsRoot
$repositoryRoot = Split-Path -Parent $toolsRoot
$configPath = Join-Path $backupToolsRoot 'RepositoryBackupConfig.json'
$config = Get-Content -Raw -LiteralPath $configPath | ConvertFrom-Json
$runId = '{0}-{1}-{2}' -f [DateTime]::UtcNow.ToString('yyyyMMddTHHmmssZ'), $PID, ([Guid]::NewGuid().ToString('N').Substring(0, 8))
$sourceTestRoot = Join-Path (Join-Path $repositoryRoot 'Saved\BackupSelfTest') $runId
$sourceRepository = Join-Path $sourceTestRoot 'Source'
$externalTestsRoot = Join-Path ([string]$config.backupRoot) 'SelfTests'
$externalTestRoot = Join-Path $externalTestsRoot $runId
$testBackupRoot = Join-Path $externalTestRoot 'Backup'
$restoreRoot = Join-Path $externalTestRoot 'Restore'
$backupScript = Join-Path $backupToolsRoot 'Invoke-RepositoryBackup.ps1'
$restoreScript = Join-Path $backupToolsRoot 'Invoke-RepositoryRestore.ps1'
$passed = $false

function Invoke-SelfTestNative {
    param(
        [Parameter(Mandatory = $true)][string]$FilePath,
        [Parameter(Mandatory = $true)][string[]]$Arguments,
        [Parameter(Mandatory = $true)][string]$WorkingDirectory
    )

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
    if ($exitCode -ne 0) {
        throw "Self-test command failed with exit code ${exitCode}: $FilePath $($Arguments -join ' ')`n$text"
    }
    return $text
}

function Assert-ExactCleanupTarget {
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
    New-Item -ItemType Directory -Path $sourceRepository -Force | Out-Null
    New-Item -ItemType Directory -Path $externalTestRoot -Force | Out-Null
    [System.IO.File]::WriteAllText((Join-Path $sourceRepository '.gitattributes'), "*.bin filter=lfs diff=lfs merge=lfs -text`r`n", $utf8NoBom)
    $fixtureContent = "Broken Streets BS-010A synthetic Git LFS transfer fixture.`r`n"
    [System.IO.File]::WriteAllText((Join-Path $sourceRepository 'sample.bin'), $fixtureContent, $utf8NoBom)

    [void](Invoke-SelfTestNative -FilePath 'git.exe' -Arguments @('init', '-b', 'main') -WorkingDirectory $sourceRepository)
    [void](Invoke-SelfTestNative -FilePath 'git.exe' -Arguments @('lfs', 'install', '--local') -WorkingDirectory $sourceRepository)
    [void](Invoke-SelfTestNative -FilePath 'git.exe' -Arguments @('config', 'user.name', 'Broken Streets Backup Self-Test') -WorkingDirectory $sourceRepository)
    [void](Invoke-SelfTestNative -FilePath 'git.exe' -Arguments @('config', 'user.email', 'backup-selftest@invalid.local') -WorkingDirectory $sourceRepository)
    [void](Invoke-SelfTestNative -FilePath 'git.exe' -Arguments @('add', '--', '.gitattributes', 'sample.bin') -WorkingDirectory $sourceRepository)
    [void](Invoke-SelfTestNative -FilePath 'git.exe' -Arguments @('commit', '-m', 'test: add synthetic LFS fixture') -WorkingDirectory $sourceRepository)
    [void](Invoke-SelfTestNative -FilePath 'git.exe' -Arguments @('branch', 'feature/selftest-ref') -WorkingDirectory $sourceRepository)
    [void](Invoke-SelfTestNative -FilePath 'git.exe' -Arguments @('tag', 'selftest-v1') -WorkingDirectory $sourceRepository)

    for ($backupNumber = 1; $backupNumber -le 3; $backupNumber++) {
        $backupOutput = Invoke-SelfTestNative -FilePath 'powershell.exe' -Arguments @(
            '-NoLogo', '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $backupScript,
            '-RepositoryRoot', $sourceRepository,
            '-BackupRoot', $testBackupRoot,
            '-SkipOriginRefresh'
        ) -WorkingDirectory $repositoryRoot
        if ($backupOutput -notmatch '\[PASS\] Published generation') {
            throw "Synthetic backup $backupNumber did not report a published generation."
        }
    }
    if (-not (Test-Path -LiteralPath (Join-Path $testBackupRoot 'LATEST.previous.json') -PathType Leaf)) {
        throw 'The synthetic backup did not preserve the previous successful pointer.'
    }
    $syntheticGenerationCount = @(Get-ChildItem -LiteralPath (Join-Path $testBackupRoot 'Generations') -Directory).Count
    if ($syntheticGenerationCount -ne 3) {
        throw "Expected 3 synthetic generations, found $syntheticGenerationCount."
    }

    $restoreOutput = Invoke-SelfTestNative -FilePath 'powershell.exe' -Arguments @(
        '-NoLogo', '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $restoreScript,
        '-BackupRoot', $testBackupRoot,
        '-DestinationRoot', $restoreRoot
    ) -WorkingDirectory $repositoryRoot
    if ($restoreOutput -notmatch '\[PASS\] Restored 3 refs and verified 1 LFS objects without GitHub') {
        throw 'The synthetic restore did not report the expected ref and LFS counts.'
    }

    $restoredWorkingCopy = Join-Path $restoreRoot 'WorkingCopy'
    $restoredContent = [System.IO.File]::ReadAllText((Join-Path $restoredWorkingCopy 'sample.bin'), $utf8NoBom)
    if (-not [string]::Equals($restoredContent, $fixtureContent, [StringComparison]::Ordinal)) {
        throw 'The restored Git LFS payload content does not match the source fixture.'
    }
    $status = Invoke-SelfTestNative -FilePath 'git.exe' -Arguments @('status', '--porcelain=v1') -WorkingDirectory $restoredWorkingCopy
    if (-not [string]::IsNullOrWhiteSpace($status)) {
        throw "The synthetic restored working copy is dirty:`n$status"
    }
    $remote = Invoke-SelfTestNative -FilePath 'git.exe' -Arguments @('remote', 'get-url', 'origin') -WorkingDirectory $restoredWorkingCopy
    if ($remote -match 'github\.com') {
        throw 'The synthetic restored working copy unexpectedly references GitHub.'
    }

    $passed = $true
    Write-Host '[PASS] Backup self-test restored 3 refs and 1 verified Git LFS object without GitHub.'
}
finally {
    if ($passed) {
        Assert-ExactCleanupTarget -Target $sourceTestRoot -RequiredParent (Join-Path $repositoryRoot 'Saved\BackupSelfTest')
        Assert-ExactCleanupTarget -Target $externalTestRoot -RequiredParent $externalTestsRoot
        if (Test-Path -LiteralPath $sourceTestRoot) {
            Remove-Item -LiteralPath $sourceTestRoot -Recurse -Force
        }
        if (Test-Path -LiteralPath $externalTestRoot) {
            Remove-Item -LiteralPath $externalTestRoot -Recurse -Force
        }
    }
    else {
        Write-Warning "Backup self-test artifacts were retained for diagnosis: $sourceTestRoot and $externalTestRoot"
    }
}
