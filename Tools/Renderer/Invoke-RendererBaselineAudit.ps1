[CmdletBinding()]
param(
    [string]$ProjectRoot,
    [string]$ConfigPath,
    [string]$OutputDirectory,
    [switch]$NoWrite
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
Import-Module Microsoft.PowerShell.Utility -ErrorAction Stop

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
if ([string]::IsNullOrWhiteSpace($ProjectRoot)) {
    $ProjectRoot = Split-Path -Parent (Split-Path -Parent $scriptRoot)
}
if ([string]::IsNullOrWhiteSpace($ConfigPath)) {
    $ConfigPath = Join-Path $scriptRoot 'RendererBaselineConfig.json'
}

$checks = New-Object System.Collections.Generic.List[object]

function Add-Check {
    param(
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)][bool]$Passed,
        [Parameter(Mandatory = $true)][string]$Detail
    )

    $script:checks.Add([pscustomobject]@{
        name = $Name
        passed = $Passed
        detail = $Detail
    })
}

function Get-TrimmedLines {
    param([Parameter(Mandatory = $true)][string]$Path)

    return @([System.IO.File]::ReadAllLines($Path) | ForEach-Object { $_.Trim() })
}

function Test-RequiredLines {
    param(
        [Parameter(Mandatory = $true)][string]$CheckPrefix,
        [Parameter(Mandatory = $true)][AllowEmptyString()][AllowEmptyCollection()][string[]]$ActualLines,
        [Parameter(Mandatory = $true)][object[]]$ExpectedLines
    )

    foreach ($expectedObject in $ExpectedLines) {
        $expected = [string]$expectedObject
        $count = @($ActualLines | Where-Object { $_ -ceq $expected }).Count
        Add-Check -Name "$CheckPrefix exact line: $expected" -Passed ($count -eq 1) -Detail $(
            if ($count -eq 1) { 'Present exactly once.' } else { "Expected exactly once; found $count." }
        )
    }
}

function Get-FileHashValue {
    param([Parameter(Mandatory = $true)][string]$Path)
    return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToLowerInvariant()
}

try {
    $projectFullPath = [System.IO.Path]::GetFullPath($ProjectRoot)
    $configFullPath = [System.IO.Path]::GetFullPath($ConfigPath)
    $engineIniPath = Join-Path $projectFullPath 'Config\DefaultEngine.ini'
    $userSettingsPath = Join-Path $projectFullPath 'Config\DefaultGameUserSettings.ini'
    $uprojectPath = Join-Path $projectFullPath 'BrokenStreets.uproject'

    foreach ($requiredPath in @($configFullPath, $engineIniPath, $userSettingsPath, $uprojectPath)) {
        if (-not (Test-Path -LiteralPath $requiredPath -PathType Leaf)) {
            throw "Required file does not exist: $requiredPath"
        }
    }

    $config = Get-Content -LiteralPath $configFullPath -Raw | ConvertFrom-Json
    if ([int]$config.schemaVersion -ne 1) {
        throw "Unsupported renderer baseline schema version: $($config.schemaVersion)"
    }

    $engineLines = Get-TrimmedLines -Path $engineIniPath
    $userSettingsLines = Get-TrimmedLines -Path $userSettingsPath
    $engineText = [System.IO.File]::ReadAllText($engineIniPath)

    Test-RequiredLines -CheckPrefix 'DefaultEngine.ini' -ActualLines $engineLines -ExpectedLines @($config.engineConfigLines)
    Test-RequiredLines -CheckPrefix 'DefaultGameUserSettings.ini' -ActualLines $userSettingsLines -ExpectedLines @($config.gameUserSettingsLines)

    foreach ($patternObject in @($config.forbiddenEnginePatterns)) {
        $pattern = [string]$patternObject
        $matched = [System.Text.RegularExpressions.Regex]::IsMatch($engineText, $pattern)
        Add-Check -Name "DefaultEngine.ini forbidden pattern: $pattern" -Passed (-not $matched) -Detail $(
            if ($matched) { 'Forbidden configuration was found.' } else { 'Not present.' }
        )
    }

    $uproject = Get-Content -LiteralPath $uprojectPath -Raw | ConvertFrom-Json
    Add-Check -Name 'Runtime game module' -Passed (@($uproject.Modules | Where-Object { $_.Name -ceq 'BrokenStreets' -and $_.Type -ceq 'Runtime' }).Count -eq 1) -Detail 'BrokenStreets must remain a single Runtime module.'

    foreach ($pluginNameObject in @($config.requiredDisabledPlugins)) {
        $pluginName = [string]$pluginNameObject
        $matchingPlugins = @($uproject.Plugins | Where-Object { $_.Name -ceq $pluginName })
        $isDisabled = $matchingPlugins.Count -eq 1 -and $matchingPlugins[0].Enabled -eq $false
        Add-Check -Name "Disabled plugin: $pluginName" -Passed $isDisabled -Detail $(
            if ($isDisabled) { 'Explicitly disabled.' } else { 'Missing, duplicated, or enabled.' }
        )
    }

    foreach ($mapObject in @($config.requiredMaps)) {
        $mapPackage = [string]$mapObject
        $relativeMap = $mapPackage.Substring('/Game/'.Length).Replace('/', [System.IO.Path]::DirectorySeparatorChar) + '.umap'
        $mapPath = Join-Path (Join-Path $projectFullPath 'Content') $relativeMap
        $exists = Test-Path -LiteralPath $mapPath -PathType Leaf
        Add-Check -Name "Required project map: $mapPackage" -Passed $exists -Detail $(
            if ($exists) { 'Project-owned map exists.' } else { 'Project-owned map is missing.' }
        )
    }

    $checkArray = $checks.ToArray()
    $failedChecks = @($checkArray | Where-Object { -not $_.passed })
    $result = if ($failedChecks.Count -eq 0) { 'PASS' } else { 'FAIL' }
    $summary = [ordered]@{
        schemaVersion = 1
        task = 'BS-013B'
        presetId = [string]$config.presetId
        result = $result
        generatedUtc = [DateTime]::UtcNow.ToString('o')
        projectRoot = $projectFullPath
        inputs = [ordered]@{
            defaultEngineSha256 = Get-FileHashValue -Path $engineIniPath
            defaultGameUserSettingsSha256 = Get-FileHashValue -Path $userSettingsPath
            uprojectSha256 = Get-FileHashValue -Path $uprojectPath
            auditConfigSha256 = Get-FileHashValue -Path $configFullPath
        }
        passed = $checks.Count - $failedChecks.Count
        failed = $failedChecks.Count
        checks = $checkArray
    }

    $summaryPath = $null
    if (-not $NoWrite) {
        if ([string]::IsNullOrWhiteSpace($OutputDirectory)) {
            $runId = [DateTime]::UtcNow.ToString('yyyyMMddTHHmmssZ') + '-' + [System.Diagnostics.Process]::GetCurrentProcess().Id
            $OutputDirectory = Join-Path $projectFullPath "Saved\Verification\BS-013B\$runId"
        }

        $outputFullPath = [System.IO.Path]::GetFullPath($OutputDirectory)
        [System.IO.Directory]::CreateDirectory($outputFullPath) | Out-Null
        $summaryPath = Join-Path $outputFullPath 'renderer-audit.json'
        $temporaryPath = "$summaryPath.tmp-$([Guid]::NewGuid().ToString('N'))"
        $json = $summary | ConvertTo-Json -Depth 8
        [System.IO.File]::WriteAllText($temporaryPath, $json, (New-Object System.Text.UTF8Encoding($false)))
        Move-Item -LiteralPath $temporaryPath -Destination $summaryPath -Force
    }

    Write-Host "[$result] BS-013B renderer baseline audit: $($summary.passed) passed, $($summary.failed) failed."
    if ($summaryPath) {
        Write-Host "[INFO] Summary: $summaryPath"
    }

    foreach ($failedCheck in $failedChecks) {
        Write-Host "[FAIL] $($failedCheck.name) - $($failedCheck.detail)"
    }

    if ($failedChecks.Count -eq 0) { exit 0 }
    exit 1
}
catch {
    Write-Error ("{0}`n{1}" -f $_.Exception.Message, $_.ScriptStackTrace)
    exit 70
}
