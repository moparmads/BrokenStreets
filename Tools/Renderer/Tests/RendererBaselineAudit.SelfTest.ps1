[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$rendererRoot = Split-Path -Parent $scriptRoot
$projectRoot = Split-Path -Parent (Split-Path -Parent $rendererRoot)
$auditScript = Join-Path $rendererRoot 'Invoke-RendererBaselineAudit.ps1'
$fixtureRoot = Join-Path ([System.IO.Path]::GetTempPath()) ('BS013B-RendererAudit-' + [Guid]::NewGuid().ToString('N'))
$testsPassed = 0
$testsFailed = 0

function Invoke-AuditFixture {
    param([Parameter(Mandatory = $true)][string]$Name)

    $output = Join-Path $fixtureRoot "Output-$Name"
    & powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File $auditScript -ProjectRoot $fixtureRoot -OutputDirectory $output *> $null
    return $LASTEXITCODE
}

function Assert-ExitCode {
    param(
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)][int]$Actual,
        [Parameter(Mandatory = $true)][int]$Expected
    )

    if ($Actual -eq $Expected) {
        $script:testsPassed++
        Write-Host "[PASS] $Name"
    }
    else {
        $script:testsFailed++
        Write-Host "[FAIL] $Name - expected exit $Expected, received $Actual."
    }
}

function Reset-FixtureFiles {
    Copy-Item -LiteralPath (Join-Path $projectRoot 'Config\DefaultEngine.ini') -Destination (Join-Path $fixtureRoot 'Config\DefaultEngine.ini') -Force
    Copy-Item -LiteralPath (Join-Path $projectRoot 'Config\DefaultGameUserSettings.ini') -Destination (Join-Path $fixtureRoot 'Config\DefaultGameUserSettings.ini') -Force
    Copy-Item -LiteralPath (Join-Path $projectRoot 'BrokenStreets.uproject') -Destination (Join-Path $fixtureRoot 'BrokenStreets.uproject') -Force
}

try {
    [System.IO.Directory]::CreateDirectory((Join-Path $fixtureRoot 'Config')) | Out-Null
    [System.IO.Directory]::CreateDirectory((Join-Path $fixtureRoot 'Content\BS\Maps\Test')) | Out-Null
    [System.IO.File]::WriteAllBytes((Join-Path $fixtureRoot 'Content\BS\Maps\Test\L_TestGym_Core.umap'), [byte[]](0))
    Reset-FixtureFiles

    Assert-ExitCode -Name 'Canonical renderer baseline passes' -Actual (Invoke-AuditFixture -Name 'Valid') -Expected 0

    $enginePath = Join-Path $fixtureRoot 'Config\DefaultEngine.ini'
    $engineText = [System.IO.File]::ReadAllText($enginePath)
    [System.IO.File]::WriteAllText($enginePath, $engineText.Replace("r.Nanite.ProjectEnabled=True`r`n", '').Replace("r.Nanite.ProjectEnabled=True`n", ''))
    Assert-ExitCode -Name 'Missing required renderer setting fails' -Actual (Invoke-AuditFixture -Name 'MissingSetting') -Expected 1

    Reset-FixtureFiles
    [System.IO.File]::AppendAllText($enginePath, "`nSecurityToken=self-test-value`n")
    Assert-ExitCode -Name 'Security token fails without exposing its value' -Actual (Invoke-AuditFixture -Name 'SecurityToken') -Expected 1

    Reset-FixtureFiles
    $uprojectPath = Join-Path $fixtureRoot 'BrokenStreets.uproject'
    $uprojectText = [System.IO.File]::ReadAllText($uprojectPath)
    [System.IO.File]::WriteAllText($uprojectPath, $uprojectText.Replace('"Name": "AndroidFileServer",' + "`r`n" + "`t`t`t" + '"Enabled": false', '"Name": "AndroidFileServer",' + "`r`n" + "`t`t`t" + '"Enabled": true').Replace('"Name": "AndroidFileServer",' + "`n" + "`t`t`t" + '"Enabled": false', '"Name": "AndroidFileServer",' + "`n" + "`t`t`t" + '"Enabled": true'))
    Assert-ExitCode -Name 'Enabled Android file server fails' -Actual (Invoke-AuditFixture -Name 'AndroidEnabled') -Expected 1

    Reset-FixtureFiles
    $settingsPath = Join-Path $fixtureRoot 'Config\DefaultGameUserSettings.ini'
    $settingsText = [System.IO.File]::ReadAllText($settingsPath).Replace('sg.ShadowQuality=2', 'sg.ShadowQuality=3')
    [System.IO.File]::WriteAllText($settingsPath, $settingsText)
    Assert-ExitCode -Name 'Changed quality preset fails' -Actual (Invoke-AuditFixture -Name 'PresetChanged') -Expected 1
}
finally {
    $tempRoot = [System.IO.Path]::GetFullPath([System.IO.Path]::GetTempPath())
    $fixtureFullPath = [System.IO.Path]::GetFullPath($fixtureRoot)
    $fixtureLeaf = Split-Path -Leaf $fixtureFullPath
    if ($fixtureFullPath.StartsWith($tempRoot, [System.StringComparison]::OrdinalIgnoreCase) -and $fixtureLeaf.StartsWith('BS013B-RendererAudit-', [System.StringComparison]::Ordinal)) {
        if (Test-Path -LiteralPath $fixtureFullPath) {
            Remove-Item -LiteralPath $fixtureFullPath -Recurse -Force
        }
    }
    else {
        throw "Refusing to remove unexpected self-test path: $fixtureFullPath"
    }
}

Write-Host "[INFO] Renderer audit self-test: $testsPassed passed, $testsFailed failed."
if ($testsFailed -ne 0) { exit 1 }
exit 0
