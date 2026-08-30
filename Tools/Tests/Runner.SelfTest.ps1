#requires -Version 5.1

[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if (($PSVersionTable.PSEdition -ne 'Desktop') -or ($PSVersionTable.PSVersion.Major -ne 5)) {
    throw 'Run this self-test with Windows PowerShell 5.1 (powershell.exe), not PowerShell 7.'
}

$runnerPath = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\Invoke-BrokenStreets.ps1'))
if (-not (Test-Path -LiteralPath $runnerPath -PathType Leaf)) {
    throw "Runner not found: $runnerPath"
}

# Dot-sourcing exposes the runner's reusable functions. Its main entry point detects
# this invocation form and returns without discovering Unreal or running a gate.
. $runnerPath -Action Doctor

$script:SelfTestPassed = 0
$script:SelfTestFailed = 0
$script:TestRoot = Join-Path ([System.IO.Path]::GetTempPath()) (
    'Broken Streets Runner Self Test ' + [Guid]::NewGuid().ToString('N')
)
$script:PowerShellExe = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
$script:KnownProcessIds = New-Object System.Collections.ArrayList

function Assert-SelfTest {
    param(
        [Parameter(Mandatory = $true)][bool]$Condition,
        [Parameter(Mandatory = $true)][string]$Message
    )

    if (-not $Condition) {
        throw $Message
    }
}

function Assert-SelfTestEqual {
    param(
        $Expected,
        $Actual,
        [Parameter(Mandatory = $true)][string]$Message
    )

    $equal = $Expected -eq $Actual
    if (($Expected -is [string]) -and ($Actual -is [string])) {
        $equal = [string]::Equals($Expected, $Actual, [System.StringComparison]::Ordinal)
    }
    if (-not $equal) {
        throw ('{0} Expected <{1}>, actual <{2}>.' -f $Message, $Expected, $Actual)
    }
}

function Test-SelfTestProcessExists {
    param([Parameter(Mandatory = $true)][int]$ProcessId)

    $process = $null
    try {
        $process = [System.Diagnostics.Process]::GetProcessById($ProcessId)
        return (-not $process.HasExited)
    }
    catch {
        return $false
    }
    finally {
        if ($null -ne $process) {
            $process.Dispose()
        }
    }
}

function Wait-SelfTestProcessExit {
    param(
        [Parameter(Mandatory = $true)][int]$ProcessId,
        [int]$TimeoutMilliseconds = 5000
    )

    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    do {
        if (-not (Test-SelfTestProcessExists -ProcessId $ProcessId)) {
            return $true
        }
        Start-Sleep -Milliseconds 100
    } while ($stopwatch.ElapsedMilliseconds -lt $TimeoutMilliseconds)

    return (-not (Test-SelfTestProcessExists -ProcessId $ProcessId))
}

function Register-SelfTestProcessId {
    param($ProcessId)

    if ($null -ne $ProcessId) {
        $knownProcess = $null
        try {
            $knownProcess = [System.Diagnostics.Process]::GetProcessById([int]$ProcessId)
            if (-not $knownProcess.HasExited) {
                [void]$script:KnownProcessIds.Add([pscustomobject]@{
                    ProcessId = [int]$ProcessId
                    CreationUtc = $knownProcess.StartTime.ToUniversalTime().ToString('o')
                })
            }
        }
        catch {
            # Completed processes do not need cleanup.
        }
        finally {
            if ($null -ne $knownProcess) {
                $knownProcess.Dispose()
            }
        }
    }
}

function Stop-SelfTestKnownProcesses {
    foreach ($knownIdentity in @($script:KnownProcessIds)) {
        $knownProcess = $null
        try {
            $knownProcess = [System.Diagnostics.Process]::GetProcessById([int]$knownIdentity.ProcessId)
            $expectedStart = [DateTime]::Parse(
                [string]$knownIdentity.CreationUtc,
                [System.Globalization.CultureInfo]::InvariantCulture,
                [System.Globalization.DateTimeStyles]::RoundtripKind
            ).ToUniversalTime()
            $actualStart = $knownProcess.StartTime.ToUniversalTime()
            if ((-not $knownProcess.HasExited) -and
                ([Math]::Abs(($actualStart - $expectedStart).TotalMilliseconds) -le 100.0)) {
                $taskKillPath = Join-Path $env:SystemRoot 'System32\taskkill.exe'
                & $taskKillPath /PID ([int]$knownIdentity.ProcessId) /T /F *> $null
            }
        }
        catch {
            # The process is already gone or its identity cannot be proven.
        }
        finally {
            if ($null -ne $knownProcess) {
                $knownProcess.Dispose()
            }
        }
    }
}

function New-SelfTestCaseContext {
    param([Parameter(Mandatory = $true)][string]$Name)

    $safeName = $Name -replace '[^A-Za-z0-9_-]', '-'
    $caseRoot = Join-Path $script:TestRoot $safeName
    [void](New-Item -ItemType Directory -Path $caseRoot -Force)

    $script:StepNumber = 0
    $script:Context = [pscustomobject]@{
        ProjectRoot = $script:TestRoot
        RunRoot = $caseRoot
    }
    $script:RunState = [ordered]@{
        schemaVersion = 1
        requestedAction = 'SelfTest'
        status = 'RUNNING'
        steps = New-Object System.Collections.ArrayList
    }
    $script:RunnerLogPath = Join-Path $caseRoot 'runner.log'
    $script:RunJsonPath = Join-Path $caseRoot 'run.json'
    Write-BsTextFile -Path $script:RunnerLogPath -Content ''
    Save-BsRunState

    return $caseRoot
}

function Invoke-SelfTestCase {
    param(
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)][scriptblock]$Body
    )

    try {
        & $Body
        $script:SelfTestPassed++
        Write-Host ('[PASS] ' + $Name) -ForegroundColor Green
    }
    catch {
        $script:SelfTestFailed++
        Write-Host ('[FAIL] ' + $Name + ': ' + $_.Exception.Message) -ForegroundColor Red
    }
}

function Write-SelfTestHelper {
    param(
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)][string]$Content
    )

    $path = Join-Path $script:TestRoot $Name
    [System.IO.File]::WriteAllText($path, $Content, $script:Utf8NoBom)
    return $path
}

if (-not (Test-Path -LiteralPath $script:PowerShellExe -PathType Leaf)) {
    throw "Windows PowerShell 5.1 executable not found: $script:PowerShellExe"
}

try {
    [void](New-Item -ItemType Directory -Path $script:TestRoot -Force)

    $argumentProbePath = Write-SelfTestHelper -Name 'Argument Probe.ps1' -Content @'
if ($args.Count -lt 1) {
    [Environment]::Exit(90)
}
$outputPath = [string]$args[0]
$values = @()
if ($args.Count -gt 1) {
    $values = @($args[1..($args.Count - 1)] | ForEach-Object { [string]$_ })
}
$payload = [pscustomobject]@{
    count = $values.Count
    values = [object[]]$values
}
[System.IO.File]::WriteAllText(
    $outputPath,
    (ConvertTo-Json -InputObject $payload -Compress),
    (New-Object System.Text.UTF8Encoding($false))
)
'@

    $timeoutIntermediatePath = Write-SelfTestHelper -Name 'Timeout Intermediate.ps1' -Content @'
if ($args.Count -ne 1) {
    [Environment]::Exit(92)
}
$grandchildPidPath = [string]$args[0]
$pingPath = Join-Path $env:SystemRoot 'System32\PING.EXE'
$grandchild = Start-Process -FilePath $pingPath -ArgumentList '-t', '127.0.0.1' -WindowStyle Hidden -PassThru
[System.IO.File]::WriteAllText($grandchildPidPath, [string]$grandchild.Id)
[Environment]::Exit(0)
'@

    $timeoutProbePath = Write-SelfTestHelper -Name 'Timeout Parent.ps1' -Content @'
if ($args.Count -ne 2) {
    [Environment]::Exit(93)
}
$intermediatePath = [string]$args[0]
$grandchildPidPath = [string]$args[1]
$powerShellExe = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
& $powerShellExe -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -File $intermediatePath $grandchildPidPath
if ($LASTEXITCODE -ne 0) {
    [Environment]::Exit(94)
}
while ($true) {
    Start-Sleep -Seconds 1
}
'@

    $exitProbePath = Write-SelfTestHelper -Name 'Exit Probe.ps1' -Content @'
[Environment]::Exit(37)
'@
    Invoke-SelfTestCase -Name 'native argument quoting (known forms)' -Body {
        $knownCases = @(
            [pscustomobject]@{ Value = 'plain'; Expected = 'plain' },
            [pscustomobject]@{ Value = ''; Expected = '""' },
            [pscustomobject]@{ Value = 'two words'; Expected = '"two words"' },
            [pscustomobject]@{ Value = 'say"hello'; Expected = '"say\"hello"' },
            [pscustomobject]@{ Value = 'C:\Path With Space\'; Expected = '"C:\Path With Space\\"' }
        )

        foreach ($knownCase in $knownCases) {
            $actual = ConvertTo-BsNativeArgument -Value $knownCase.Value
            Assert-SelfTestEqual -Expected $knownCase.Expected -Actual $actual `
                -Message ('Unexpected quoting for <{0}>.' -f $knownCase.Value)
        }
    }

    Invoke-SelfTestCase -Name 'native argument round trip through Windows PowerShell' -Body {
        $caseRoot = New-SelfTestCaseContext -Name 'ArgumentRoundTrip'
        $probeOutputPath = Join-Path $caseRoot 'received arguments.json'
        $expectedValues = @(
            '',
            'plain',
            'two words',
            'C:\Path With Space\',
            'embedded"quote',
            'slashes\\before"quote',
            'semi;colon|amp&',
            'dollar$(not-executed)',
            'unicode-lambda-λ'
        )
        $arguments = @(
            '-NoLogo',
            '-NoProfile',
            '-NonInteractive',
            '-ExecutionPolicy',
            'Bypass',
            '-File',
            $argumentProbePath,
            $probeOutputPath
        ) + $expectedValues

        $raw = Invoke-BsProcess -StepName 'ArgumentRoundTrip' -FilePath $script:PowerShellExe `
            -ArgumentList $arguments -StepTimeoutSeconds 15
        Register-SelfTestProcessId -ProcessId $raw.ProcessId

        Assert-SelfTest -Condition $raw.Started -Message 'Argument probe did not start.'
        Assert-SelfTest -Condition (-not $raw.TimedOut) -Message 'Argument probe timed out.'
        Assert-SelfTestEqual -Expected 0 -Actual ([int]$raw.ToolExitCode) `
            -Message 'Argument probe returned a native failure.'
        Assert-SelfTest -Condition (Test-Path -LiteralPath $probeOutputPath -PathType Leaf) `
            -Message 'Argument probe output is missing.'

        $received = [System.IO.File]::ReadAllText(
            $probeOutputPath,
            [System.Text.Encoding]::UTF8
        ) | ConvertFrom-Json
        Assert-SelfTestEqual -Expected $expectedValues.Count -Actual ([int]$received.count) `
            -Message 'Argument count changed during native launch.'
        for ($index = 0; $index -lt $expectedValues.Count; $index++) {
            Assert-SelfTestEqual -Expected $expectedValues[$index] -Actual ([string]$received.values[$index]) `
                -Message ("Argument $index changed during native launch.")
        }
    }

    Invoke-SelfTestCase -Name 'native exit-code propagation' -Body {
        [void](New-SelfTestCaseContext -Name 'NativeExit')
        $script:ExitAnalyzerCalled = $false
        $analyzer = {
            param($Output)
            $script:ExitAnalyzerCalled = $true
            return New-BsAnalysis -Status 'PASS' -Diagnostic 'SHOULD_NOT_RUN'
        }
        $arguments = @(
            '-NoLogo',
            '-NoProfile',
            '-NonInteractive',
            '-ExecutionPolicy',
            'Bypass',
            '-File',
            $exitProbePath
        )

        $record = Invoke-BsExternalStep -Name 'NativeExit' -FilePath $script:PowerShellExe `
            -ArgumentList $arguments -StepTimeoutSeconds 15 -Analyzer $analyzer
        Register-SelfTestProcessId -ProcessId $record.processId

        Assert-SelfTestEqual -Expected 'FAILED' -Actual $record.status `
            -Message 'Non-zero native exit was not classified as FAILED.'
        Assert-SelfTestEqual -Expected 'NATIVE_EXIT_NONZERO' -Actual $record.diagnostic `
            -Message 'Non-zero native exit received the wrong diagnostic.'
        Assert-SelfTestEqual -Expected 37 -Actual ([int]$record.toolExitCode) `
            -Message 'Native tool exit code was not preserved.'
        Assert-SelfTestEqual -Expected 37 -Actual ([int]$record.runnerExitCode) `
            -Message 'Runner exit code did not propagate the native code.'
        Assert-SelfTestEqual -Expected 'Tool' -Actual $record.exitSource `
            -Message 'Native failure received the wrong exit source.'
        Assert-SelfTest -Condition ([bool]$record.metrics.treeCleanupConfirmed) `
            -Message 'Native failure process cleanup was not confirmed.'
        Assert-SelfTest -Condition ([bool]$record.metrics.jobAssigned) `
            -Message 'Native failure process was not assigned to a Windows Job Object.'
        Assert-SelfTest -Condition ([bool]$record.metrics.jobTerminateSucceeded) `
            -Message 'Native failure Job Object termination did not succeed.'
        Assert-SelfTestEqual -Expected 0 -Actual ([int]$record.metrics.jobActiveProcesses) `
            -Message 'Native failure left active processes in the Windows Job Object.'
        Assert-SelfTest -Condition (-not $script:ExitAnalyzerCalled) `
            -Message 'Semantic analyzer ran after a native failure.'
    }

    Invoke-SelfTestCase -Name 'timeout terminates the launched process tree' -Body {
        $caseRoot = New-SelfTestCaseContext -Name 'TimeoutTree'
        $grandchildPidPath = Join-Path $caseRoot 'grandchild.pid'
        $analyzer = {
            param($Output)
            $script:TimeoutAnalyzerCalled = $true
            return New-BsAnalysis -Status 'PASS' -Diagnostic 'SHOULD_NOT_RUN'
        }
        $script:TimeoutAnalyzerCalled = $false
        $arguments = @(
            '-NoLogo',
            '-NoProfile',
            '-NonInteractive',
            '-ExecutionPolicy',
            'Bypass',
            '-File',
            $timeoutProbePath,
            $timeoutIntermediatePath,
            $grandchildPidPath
        )

        $record = Invoke-BsExternalStep -Name 'TimeoutTree' -FilePath $script:PowerShellExe `
            -ArgumentList $arguments -StepTimeoutSeconds 5 -Analyzer $analyzer
        Register-SelfTestProcessId -ProcessId $record.processId

        Assert-SelfTestEqual -Expected 'FAILED' -Actual $record.status `
            -Message 'Timeout was not classified as FAILED.'
        Assert-SelfTestEqual -Expected 'TIMEOUT_TREE_TERMINATED' -Actual $record.diagnostic `
            -Message 'Timeout termination was not confirmed.'
        Assert-SelfTestEqual -Expected 124 -Actual ([int]$record.runnerExitCode) `
            -Message 'Timeout did not return the runner timeout code.'
        Assert-SelfTestEqual -Expected 'Runner' -Actual $record.exitSource `
            -Message 'Timeout received the wrong exit source.'
        Assert-SelfTest -Condition ([bool]$record.timedOut) -Message 'Timeout flag is false.'
        Assert-SelfTest -Condition ([bool]$record.metrics.treeTerminated) `
            -Message 'Runner could not confirm process-tree termination.'
        Assert-SelfTest -Condition ([bool]$record.metrics.jobAssigned) `
            -Message 'Timeout process was not assigned to a Windows Job Object.'
        Assert-SelfTest -Condition ([bool]$record.metrics.jobTerminateSucceeded) `
            -Message 'Windows Job Object termination did not succeed.'
        Assert-SelfTestEqual -Expected 0 -Actual ([int]$record.metrics.jobActiveProcesses) `
            -Message 'The Windows Job Object still contains active processes.'
        Assert-SelfTest -Condition (-not $script:TimeoutAnalyzerCalled) `
            -Message 'Semantic analyzer ran after a timeout.'
        Assert-SelfTest -Condition (Test-Path -LiteralPath $grandchildPidPath -PathType Leaf) `
            -Message 'Timeout helper did not record its grandchild PID.'

        $grandchildProcessId = [int](Get-Content -LiteralPath $grandchildPidPath -Raw)
        Register-SelfTestProcessId -ProcessId $grandchildProcessId
        Assert-SelfTest -Condition (Wait-SelfTestProcessExit -ProcessId ([int]$record.processId)) `
            -Message 'Launched parent process is still running after timeout.'
        Assert-SelfTest -Condition (Wait-SelfTestProcessExit -ProcessId $grandchildProcessId) `
            -Message 'Orphaned grandchild process is still running after timeout.'

        $savedState = [System.IO.File]::ReadAllText(
            $script:RunJsonPath,
            [System.Text.Encoding]::UTF8
        ) | ConvertFrom-Json
        Assert-SelfTestEqual -Expected 1 -Actual @($savedState.steps).Count `
            -Message 'Timeout result was not persisted to run.json.'
        Assert-SelfTestEqual -Expected 124 -Actual ([int]$savedState.steps[0].runnerExitCode) `
            -Message 'Persisted timeout code is incorrect.'
    }

    Invoke-SelfTestCase -Name 'run.json is atomic UTF-8 and round-trips data' -Body {
        [void](New-SelfTestCaseContext -Name 'JsonSummary')
        $specialText = 'quotes " and slash \ and Unicode éß漢字 λ'
        [void](Add-BsStepRecord -Name 'JsonProbe' -Status 'PASS' -Diagnostic 'JSON_OK' `
            -ToolExitCode 0 -RunnerExitCode 0 -ExitSource 'None' -DurationSeconds 1.25 `
            -ProcessId 1234 -TimedOut $false -LogPath 'C:\Path With Space\probe.log' `
            -Metrics @{
                specialText = $specialText
                booleanValue = $true
                numberValue = 42
            })

        $bytes = [System.IO.File]::ReadAllBytes($script:RunJsonPath)
        $hasUtf8Bom = ($bytes.Length -ge 3) -and
            ($bytes[0] -eq 0xEF) -and ($bytes[1] -eq 0xBB) -and ($bytes[2] -eq 0xBF)
        Assert-SelfTest -Condition (-not $hasUtf8Bom) -Message 'run.json unexpectedly contains a UTF-8 BOM.'

        $savedState = [System.IO.File]::ReadAllText(
            $script:RunJsonPath,
            [System.Text.Encoding]::UTF8
        ) | ConvertFrom-Json -ErrorAction Stop
        Assert-SelfTestEqual -Expected 1 -Actual ([int]$savedState.schemaVersion) `
            -Message 'JSON schema version did not round-trip.'
        Assert-SelfTestEqual -Expected 'SelfTest' -Actual ([string]$savedState.requestedAction) `
            -Message 'JSON action did not round-trip.'
        Assert-SelfTestEqual -Expected 1 -Actual @($savedState.steps).Count `
            -Message 'JSON step count is incorrect.'
        Assert-SelfTestEqual -Expected 'JsonProbe' -Actual ([string]$savedState.steps[0].name) `
            -Message 'JSON step name is incorrect.'
        Assert-SelfTestEqual -Expected $specialText -Actual ([string]$savedState.steps[0].metrics.specialText) `
            -Message 'Escaped or Unicode JSON text changed.'
        Assert-SelfTest -Condition ([bool]$savedState.steps[0].metrics.booleanValue) `
            -Message 'JSON Boolean value changed type or value.'
        Assert-SelfTestEqual -Expected 42 -Actual ([int]$savedState.steps[0].metrics.numberValue) `
            -Message 'JSON numeric value changed.'
        Assert-SelfTest -Condition (-not (Test-Path -LiteralPath ($script:RunJsonPath + '.tmp-' + $PID))) `
            -Message 'Atomic JSON temporary file was left behind.'
    }
}
finally {
    Stop-SelfTestKnownProcesses

    $resolvedTempRoot = [System.IO.Path]::GetFullPath([System.IO.Path]::GetTempPath())
    $resolvedTestRoot = [System.IO.Path]::GetFullPath($script:TestRoot)
    if (($script:SelfTestFailed -eq 0) -and
        $resolvedTestRoot.StartsWith($resolvedTempRoot, [System.StringComparison]::OrdinalIgnoreCase) -and
        ($resolvedTestRoot -ne $resolvedTempRoot) -and
        (Test-Path -LiteralPath $resolvedTestRoot -PathType Container)) {
        Remove-Item -LiteralPath $resolvedTestRoot -Recurse -Force
    }
    elseif (($script:SelfTestFailed -gt 0) -and
        (Test-Path -LiteralPath $resolvedTestRoot -PathType Container)) {
        Write-Host ('Self-test evidence retained at: ' + $resolvedTestRoot) -ForegroundColor Yellow
    }
}

Write-Host ('Runner self-test: {0} passed, {1} failed.' -f $script:SelfTestPassed, $script:SelfTestFailed)
if ($script:SelfTestFailed -gt 0) {
    exit 1
}
exit 0
