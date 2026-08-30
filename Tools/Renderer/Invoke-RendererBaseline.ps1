[CmdletBinding()]
param(
    [ValidateSet('Audit', 'Package', 'Capture', 'Visual', 'All')]
    [string]$Action = 'Audit',
    [string]$EngineRoot,
    [string]$PackageRoot,
    [ValidateRange(1, 10)][int]$Runs = 3,
    [ValidateRange(1200, 20000)][int]$CaptureFrames = 3600,
    [ValidateRange(0, 10000)][int]$WarmupFrames = 600,
    [ValidateRange(30, 900)][int]$RuntimeTimeoutSeconds = 180,
    [switch]$PlanOnly
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = Split-Path -Parent (Split-Path -Parent $scriptRoot)
$auditScript = Join-Path $scriptRoot 'Invoke-RendererBaselineAudit.ps1'
$projectFile = Join-Path $projectRoot 'BrokenStreets.uproject'
$benchmarkMap = '/Game/BS/Maps/Benchmark/L_Benchmark_Street'
$presetId = 'BS-PC-Recommended-P0'
$qualityCommands = @(
    'r.VSync 0',
    'r.DynamicRes.OperationMode 0',
    'r.ScreenPercentage 100',
    'sg.ViewDistanceQuality 2',
    'sg.AntiAliasingQuality 2',
    'sg.ShadowQuality 2',
    'sg.GlobalIlluminationQuality 2',
    'sg.ReflectionQuality 2',
    'sg.PostProcessQuality 2',
    'sg.TextureQuality 2',
    'sg.EffectsQuality 2',
    'sg.FoliageQuality 2',
    'sg.ShadingQuality 2',
    'sg.LandscapeQuality 2',
    't.MaxFPS 0'
)

function Write-JsonAtomic {
    param(
        [Parameter(Mandatory = $true)]$Value,
        [Parameter(Mandatory = $true)][string]$Path
    )

    $directory = Split-Path -Parent $Path
    [System.IO.Directory]::CreateDirectory($directory) | Out-Null
    $temporaryPath = "$Path.tmp-$([Guid]::NewGuid().ToString('N'))"
    $json = $Value | ConvertTo-Json -Depth 10
    [System.IO.File]::WriteAllText($temporaryPath, $json, (New-Object System.Text.UTF8Encoding($false)))
    Move-Item -LiteralPath $temporaryPath -Destination $Path -Force
}

function Get-Sha256 {
    param([Parameter(Mandatory = $true)][string]$Path)
    return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToLowerInvariant()
}

function Get-GitValue {
    param([Parameter(Mandatory = $true)][string[]]$Arguments)

    $value = & git -C $projectRoot @Arguments 2>$null
    if ($LASTEXITCODE -ne 0) {
        throw "Git failed while reading candidate identity: git $($Arguments -join ' ')"
    }
    return ([string]$value).Trim()
}

function Assert-CleanCandidate {
    $status = & git -C $projectRoot status --porcelain
    if ($LASTEXITCODE -ne 0) { throw 'Git status failed.' }
    if (@($status).Count -ne 0) {
        throw 'Package and capture require a clean committed candidate. Commit the intended BS-013B files first.'
    }
}

function Resolve-EngineRoot {
    if (-not [string]::IsNullOrWhiteSpace($EngineRoot)) {
        $candidate = [System.IO.Path]::GetFullPath($EngineRoot)
    }
    elseif (-not [string]::IsNullOrWhiteSpace([Environment]::GetEnvironmentVariable('BROKENSTREETS_UE_ROOT'))) {
        $candidate = [System.IO.Path]::GetFullPath([Environment]::GetEnvironmentVariable('BROKENSTREETS_UE_ROOT'))
    }
    else {
        $launcherFile = 'C:\ProgramData\Epic\UnrealEngineLauncher\LauncherInstalled.dat'
        if (-not (Test-Path -LiteralPath $launcherFile -PathType Leaf)) {
            throw 'Epic Launcher installation manifest was not found. Supply -EngineRoot.'
        }
        $launcher = Get-Content -LiteralPath $launcherFile -Raw | ConvertFrom-Json
        $entry = @($launcher.InstallationList | Where-Object {
            $_.ArtifactId -ceq 'UE_5.8' -and ([string]$_.AppVersion).StartsWith('5.8.2-56702186', [System.StringComparison]::Ordinal)
        }) | Select-Object -First 1
        if ($null -eq $entry) {
            throw 'The pinned Unreal Engine 5.8.2 CL 56702186 installation was not found. Supply -EngineRoot.'
        }
        $candidate = [System.IO.Path]::GetFullPath([string]$entry.InstallLocation)
    }

    $buildVersionPath = Join-Path $candidate 'Engine\Build\Build.version'
    if (-not (Test-Path -LiteralPath $buildVersionPath -PathType Leaf)) {
        throw "Invalid Unreal Engine root: $candidate"
    }
    $buildVersion = Get-Content -LiteralPath $buildVersionPath -Raw | ConvertFrom-Json
    if ([int]$buildVersion.MajorVersion -ne 5 -or [int]$buildVersion.MinorVersion -ne 8 -or [int]$buildVersion.PatchVersion -ne 2 -or [int]$buildVersion.Changelist -ne 56702186) {
        throw "Engine mismatch at $candidate. Expected 5.8.2 CL 56702186."
    }
    return $candidate
}

function Invoke-Audit {
    Write-Host '[RUN] Renderer configuration audit.'
    if ($PlanOnly) {
        & powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File $auditScript -NoWrite
    }
    else {
        & powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File $auditScript
    }
    if ($LASTEXITCODE -ne 0) {
        throw "Renderer configuration audit failed with exit code $LASTEXITCODE."
    }
}

function Get-LatestPackageRoot {
    if (-not [string]::IsNullOrWhiteSpace($PackageRoot)) {
        return [System.IO.Path]::GetFullPath($PackageRoot)
    }

    $latestPath = Join-Path $projectRoot 'Saved\Verification\BS-013B\LATEST-PACKAGE.json'
    if (-not (Test-Path -LiteralPath $latestPath -PathType Leaf)) {
        throw 'No BS-013B package pointer exists. Run Package first or supply -PackageRoot.'
    }
    $latest = Get-Content -LiteralPath $latestPath -Raw | ConvertFrom-Json
    return [System.IO.Path]::GetFullPath([string]$latest.packageRoot)
}

function Invoke-Package {
    if (-not $PlanOnly) { Assert-CleanCandidate }
    $resolvedEngineRoot = Resolve-EngineRoot
    $commit = Get-GitValue -Arguments @('rev-parse', 'HEAD')
    $shortCommit = $commit.Substring(0, 7)
    $runId = $shortCommit + '-' + [DateTime]::UtcNow.ToString('yyyyMMddTHHmmssZ')
    $archiveRoot = if ([string]::IsNullOrWhiteSpace($PackageRoot)) {
        Join-Path $projectRoot "Saved\Packages\BS-013B\$runId"
    } else {
        [System.IO.Path]::GetFullPath($PackageRoot)
    }
    $windowsRoot = Join-Path $archiveRoot 'Windows'
    $verificationRoot = Join-Path $projectRoot "Saved\Verification\BS-013B\Package-$runId"
    $uatLog = Join-Path $verificationRoot 'BuildCookRun.log'
    $dotnet = Join-Path $resolvedEngineRoot 'Engine\Binaries\ThirdParty\DotNet\10.0\win-x64\dotnet.exe'
    $uatDll = Join-Path $resolvedEngineRoot 'Engine\Binaries\DotNET\AutomationTool\AutomationTool.dll'

    if (Test-Path -LiteralPath $archiveRoot) {
        throw "Package destination already exists; choose a new destination: $archiveRoot"
    }

    $uatArguments = @(
        $uatDll,
        'BuildCookRun',
        "-project=$projectFile",
        '-noP4',
        '-platform=Win64',
        '-clientconfig=Development',
        '-build',
        '-nocompileeditor',
        '-cook',
        '-stage',
        '-pak',
        '-package',
        '-archive',
        "-archivedirectory=$archiveRoot",
        "-map=$benchmarkMap",
        '-ubtargs=-NoUBA',
        '-utf8output'
    )

    if ($PlanOnly) {
        Write-Host '[PLAN] Build/Cook/Stage/Package/Archive Win64 Development.'
        Write-Host "[PLAN] Engine: $resolvedEngineRoot"
        Write-Host "[PLAN] Map: $benchmarkMap"
        Write-Host "[PLAN] Archive: $archiveRoot"
        return $archiveRoot
    }

    [System.IO.Directory]::CreateDirectory($verificationRoot) | Out-Null
    Write-Host "[RUN] Packaging committed candidate $commit."
    & $dotnet @uatArguments *> $uatLog
    $uatExitCode = $LASTEXITCODE
    if ($uatExitCode -ne 0) {
        Write-Host "[FAIL] UAT exited with $uatExitCode. Log: $uatLog"
        exit $uatExitCode
    }

    $bootstrapExe = Join-Path $windowsRoot 'BrokenStreets.exe'
    $gameExe = Join-Path $windowsRoot 'BrokenStreets\Binaries\Win64\BrokenStreets.exe'
    $pakRoot = Join-Path $windowsRoot 'BrokenStreets\Content\Paks'
    $requiredPackageFiles = @(
        $bootstrapExe,
        $gameExe,
        (Join-Path $pakRoot 'BrokenStreets-Windows.pak'),
        (Join-Path $pakRoot 'BrokenStreets-Windows.ucas'),
        (Join-Path $pakRoot 'BrokenStreets-Windows.utoc')
    )
    $missing = @($requiredPackageFiles | Where-Object { -not (Test-Path -LiteralPath $_ -PathType Leaf) })
    $uatText = [System.IO.File]::ReadAllText($uatLog)
    $markersPass = $uatText -match 'BUILD SUCCESSFUL' -and $uatText -match 'AutomationTool exiting with ExitCode=0' -and $uatText -match [regex]::Escape($benchmarkMap)
    if ($missing.Count -ne 0 -or -not $markersPass) {
        throw "Package audit failed. Missing files: $($missing.Count). Log: $uatLog"
    }

    $summary = [ordered]@{
        schemaVersion = 1
        task = 'BS-013B'
        presetId = $presetId
        result = 'PASS'
        generatedUtc = [DateTime]::UtcNow.ToString('o')
        commit = $commit
        engineRoot = $resolvedEngineRoot
        map = $benchmarkMap
        packageRoot = $archiveRoot
        windowsRoot = $windowsRoot
        uatExitCode = $uatExitCode
        uatLog = $uatLog
        uatLogSha256 = Get-Sha256 -Path $uatLog
        bootstrapExeSha256 = Get-Sha256 -Path $bootstrapExe
        gameExeSha256 = Get-Sha256 -Path $gameExe
        pakSha256 = Get-Sha256 -Path (Join-Path $pakRoot 'BrokenStreets-Windows.pak')
        ucasSha256 = Get-Sha256 -Path (Join-Path $pakRoot 'BrokenStreets-Windows.ucas')
        utocSha256 = Get-Sha256 -Path (Join-Path $pakRoot 'BrokenStreets-Windows.utoc')
    }
    $summaryPath = Join-Path $verificationRoot 'package.json'
    Write-JsonAtomic -Value $summary -Path $summaryPath
    Write-JsonAtomic -Value $summary -Path (Join-Path $projectRoot 'Saved\Verification\BS-013B\LATEST-PACKAGE.json')
    Write-Host "[PASS] Package: $windowsRoot"
    Write-Host "[INFO] Summary: $summaryPath"
    return $archiveRoot
}

function Get-Percentile {
    param(
        [Parameter(Mandatory = $true)][double[]]$Values,
        [Parameter(Mandatory = $true)][ValidateRange(0.0, 1.0)][double]$Percentile
    )

    if ($Values.Count -eq 0) { return $null }
    $sorted = @($Values | Sort-Object)
    $position = ($sorted.Count - 1) * $Percentile
    $lower = [Math]::Floor($position)
    $upper = [Math]::Ceiling($position)
    if ($lower -eq $upper) { return [double]$sorted[$lower] }
    $fraction = $position - $lower
    return ([double]$sorted[$lower] * (1.0 - $fraction)) + ([double]$sorted[$upper] * $fraction)
}

function Read-PerformanceCsv {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][int]$WarmupCount
    )

    Add-Type -AssemblyName Microsoft.VisualBasic
    $columnNames = @('FrameTime', 'GameThreadTime', 'RenderThreadTime', 'GPUTime')
    $indices = @{}
    $series = @{}
    foreach ($columnName in $columnNames) {
        $series[$columnName] = New-Object System.Collections.Generic.List[double]
    }

    $parser = New-Object Microsoft.VisualBasic.FileIO.TextFieldParser($Path)
    try {
        $parser.TextFieldType = [Microsoft.VisualBasic.FileIO.FieldType]::Delimited
        $parser.SetDelimiters(',')
        $parser.HasFieldsEnclosedInQuotes = $true
        $header = $parser.ReadFields()
        foreach ($columnName in $columnNames) {
            $matches = New-Object System.Collections.Generic.List[int]
            for ($index = 0; $index -lt $header.Length; $index++) {
                if ($header[$index] -ceq $columnName) { $matches.Add($index) }
            }
            if ($matches.Count -ne 1) {
                throw "CSV column '$columnName' must appear exactly once; found $($matches.Count)."
            }
            $indices[$columnName] = $matches[0]
        }

        $rowCount = 0
        while (-not $parser.EndOfData) {
            $fields = $parser.ReadFields()
            if ($null -eq $fields) { continue }
            if ($fields.Length -gt 0 -and $fields[0] -ceq 'EVENTS') {
                break
            }
            if ($fields.Length -ne $header.Length) {
                throw "CSV row $($rowCount + 1) has $($fields.Length) fields; expected $($header.Length)."
            }
            if ($rowCount -ge $WarmupCount) {
                foreach ($columnName in $columnNames) {
                    $parsed = 0.0
                    $value = $fields[[int]$indices[$columnName]]
                    if (-not [double]::TryParse($value, [System.Globalization.NumberStyles]::Float, [System.Globalization.CultureInfo]::InvariantCulture, [ref]$parsed)) {
                        throw "CSV row $($rowCount + 1) has an invalid '$columnName' value."
                    }
                    $series[$columnName].Add($parsed)
                }
            }
            $rowCount++
        }
    }
    finally {
        $parser.Close()
    }

    return [pscustomobject]@{
        rowCount = $rowCount
        stableCount = [Math]::Max(0, $rowCount - $WarmupCount)
        frame = $series['FrameTime'].ToArray()
        gameThread = $series['GameThreadTime'].ToArray()
        renderThread = $series['RenderThreadTime'].ToArray()
        gpu = $series['GPUTime'].ToArray()
    }
}

function Get-SeriesSummary {
    param([Parameter(Mandatory = $true)][double[]]$Values)

    if ($Values.Count -eq 0) { return $null }
    return [ordered]@{
        count = $Values.Count
        meanMs = [Math]::Round(($Values | Measure-Object -Average).Average, 4)
        p50Ms = [Math]::Round((Get-Percentile -Values $Values -Percentile 0.50), 4)
        p95Ms = [Math]::Round((Get-Percentile -Values $Values -Percentile 0.95), 4)
        p99Ms = [Math]::Round((Get-Percentile -Values $Values -Percentile 0.99), 4)
        maxMs = [Math]::Round(($Values | Measure-Object -Maximum).Maximum, 4)
    }
}

function Test-RuntimeLog {
    param([Parameter(Mandatory = $true)][string]$LogPath)

    $text = [System.IO.File]::ReadAllText($LogPath)
    $requiredPatterns = @(
        [regex]::Escape($benchmarkMap),
        'Bringing World /Game/BS/Maps/Benchmark/L_Benchmark_Street',
        'Using Forced RHI: D3D12',
        'rhifeaturelevel="SM6"',
        'shaderplatform="PCD3D_SM6"',
        'raytracing="0"',
        'r\.ScreenPercentage = "100"',
        'sg\.ShadowQuality = "2"',
        'sg\.GlobalIlluminationQuality = "2"',
        'FPlatformMisc::RequestExitWithStatus\(0, 0, CsvProfiler\.ExitAfterCsvProfiling\)',
        'LogInit: Display: PreExit Game\.',
        'LogExit: Exiting\.'
    )
    $missingPatterns = @($requiredPatterns | Where-Object { $text -notmatch $_ })
    $forbidden = $text -match '(?im)Fatal error:|Unhandled Exception:|Assertion failed:|GPU Crashed or D3D Device Removed'
    return [pscustomobject]@{
        passed = $missingPatterns.Count -eq 0 -and -not $forbidden
        missingPatternCount = $missingPatterns.Count
        fatalMarkerFound = $forbidden
    }
}

function Invoke-Capture {
    if (-not $PlanOnly) { Assert-CleanCandidate }
    if ($WarmupFrames -ge $CaptureFrames) {
        throw 'WarmupFrames must be lower than CaptureFrames.'
    }
    $archiveRoot = Get-LatestPackageRoot
    $windowsRoot = Join-Path $archiveRoot 'Windows'
    $gameExe = Join-Path $windowsRoot 'BrokenStreets\Binaries\Win64\BrokenStreets.exe'
    if (-not $PlanOnly -and -not (Test-Path -LiteralPath $gameExe -PathType Leaf)) {
        throw "Packaged executable is missing: $gameExe"
    }

    $commit = Get-GitValue -Arguments @('rev-parse', 'HEAD')
    $shortCommit = $commit.Substring(0, 7)
    $captureId = $shortCommit + '-' + [DateTime]::UtcNow.ToString('yyyyMMddTHHmmssZ')
    $captureRoot = Join-Path $projectRoot "Saved\Performance\BS-013B\$captureId"

    if ($PlanOnly) {
        Write-Host "[PLAN] Capture $Runs fresh run(s), $CaptureFrames frames each, excluding $WarmupFrames warm-up frames."
        Write-Host "[PLAN] Executable: $gameExe"
        Write-Host "[PLAN] Preset: $presetId; map: $benchmarkMap"
        return $captureRoot
    }

    [System.IO.Directory]::CreateDirectory($captureRoot) | Out-Null
    $runSummaries = New-Object System.Collections.Generic.List[object]
    $csvSourceRoot = Join-Path $windowsRoot 'BrokenStreets\Saved\Profiling\CSV'

    for ($runNumber = 1; $runNumber -le $Runs; $runNumber++) {
        $runLabel = '{0:D2}' -f $runNumber
        $runRoot = Join-Path $captureRoot "Run$runLabel"
        [System.IO.Directory]::CreateDirectory($runRoot) | Out-Null
        $logPath = Join-Path $runRoot 'BrokenStreets.log'
        $tracePath = Join-Path $runRoot "BS-013B-Run$runLabel.utrace"
        $csvDestination = Join-Path $runRoot "BS-013B-Run$runLabel.csv"
        $existingCsv = @{}
        if (Test-Path -LiteralPath $csvSourceRoot -PathType Container) {
            Get-ChildItem -LiteralPath $csvSourceRoot -File -Filter '*.csv' | ForEach-Object { $existingCsv[$_.FullName] = $true }
        }

        $execCommands = $qualityCommands -join ','
        $arguments = @(
            $benchmarkMap,
            '-d3d12',
            '-ResX=1920',
            '-ResY=1080',
            '-Windowed',
            '-ForceRes',
            '-NoVSync',
            '-nosplash',
            '-unattended',
            '-culture=en',
            '-language=en',
            "-ExecCmds=`"$execCommands`"",
            "-csvCaptureFrames=$CaptureFrames",
            '-csvGpuStats',
            '-csvNamedEvents',
            "-csvMetadata=task=BS-013B,preset=$presetId,commit=$shortCommit,run=$runLabel",
            '-ExitAfterCsvProfiling',
            '-trace=cpu,gpu,frame,bookmark,loadtime,file,rendercommands,rhicommands',
            "-tracefile=$tracePath",
            '-traceautostart=1',
            "-abslog=$logPath"
        ) -join ' '

        Write-Host "[RUN] Capture $runLabel/$Runs."
        $startInfo = New-Object System.Diagnostics.ProcessStartInfo
        $startInfo.FileName = $gameExe
        $startInfo.Arguments = $arguments
        $startInfo.WorkingDirectory = $windowsRoot
        $startInfo.UseShellExecute = $false
        $process = [System.Diagnostics.Process]::Start($startInfo)
        if ($null -eq $process) { throw "Could not start capture $runLabel." }

        $deadline = [DateTime]::UtcNow.AddSeconds($RuntimeTimeoutSeconds)
        $peakWorkingSetBytes = [int64]0
        while (-not $process.HasExited -and [DateTime]::UtcNow -lt $deadline) {
            try {
                $process.Refresh()
                if ($process.WorkingSet64 -gt $peakWorkingSetBytes) { $peakWorkingSetBytes = $process.WorkingSet64 }
            } catch { }
            Start-Sleep -Milliseconds 200
        }
        if (-not $process.HasExited) {
            $process.Kill()
            $process.WaitForExit()
            throw "Capture $runLabel exceeded $RuntimeTimeoutSeconds seconds and was terminated."
        }
        $process.WaitForExit()
        $exitCode = $process.ExitCode

        $newCsv = @()
        if (Test-Path -LiteralPath $csvSourceRoot -PathType Container) {
            $newCsv = @(Get-ChildItem -LiteralPath $csvSourceRoot -File -Filter '*.csv' | Where-Object { -not $existingCsv.ContainsKey($_.FullName) } | Sort-Object LastWriteTimeUtc -Descending)
        }
        if ($newCsv.Count -eq 0) {
            throw "Capture $runLabel produced no new CSV file. Log: $logPath"
        }
        Copy-Item -LiteralPath $newCsv[0].FullName -Destination $csvDestination

        if (-not (Test-Path -LiteralPath $tracePath -PathType Leaf) -or (Get-Item -LiteralPath $tracePath).Length -eq 0) {
            throw "Capture $runLabel produced no trace."
        }
        if (-not (Test-Path -LiteralPath $logPath -PathType Leaf)) {
            throw "Capture $runLabel produced no log."
        }

        $logAudit = Test-RuntimeLog -LogPath $logPath
        $csvData = Read-PerformanceCsv -Path $csvDestination -WarmupCount $WarmupFrames
        if ($csvData.rowCount -ne $CaptureFrames) {
            throw "Capture $runLabel expected $CaptureFrames CSV rows; found $($csvData.rowCount)."
        }
        $frameSeries = [double[]]$csvData.frame
        $gameSeries = [double[]]$csvData.gameThread
        $renderSeries = [double[]]$csvData.renderThread
        $gpuSeries = [double[]]$csvData.gpu
        if ($frameSeries.Count -ne $csvData.stableCount) {
            throw "Capture $runLabel has incomplete FrameTime data."
        }

        $frameSummary = Get-SeriesSummary -Values $frameSeries
        $runSummary = [ordered]@{
            run = $runLabel
            result = if ($logAudit.passed) { 'PASS' } else { 'FAIL' }
            processExitCode = $exitCode
            engineNormalExit = $logAudit.passed
            stableFrames = $csvData.stableCount
            frame = $frameSummary
            gameThread = Get-SeriesSummary -Values $gameSeries
            renderThread = Get-SeriesSummary -Values $renderSeries
            gpu = Get-SeriesSummary -Values $gpuSeries
            hitchesOver50Ms = @($frameSeries | Where-Object { $_ -gt 50.0 }).Count
            hitchesOver100Ms = @($frameSeries | Where-Object { $_ -gt 100.0 }).Count
            peakWorkingSetMiB = [Math]::Round($peakWorkingSetBytes / 1MB, 2)
            log = $logPath
            logSha256 = Get-Sha256 -Path $logPath
            csv = $csvDestination
            csvSha256 = Get-Sha256 -Path $csvDestination
            trace = $tracePath
            traceSha256 = Get-Sha256 -Path $tracePath
            missingRuntimeMarkers = $logAudit.missingPatternCount
            fatalMarkerFound = $logAudit.fatalMarkerFound
        }
        $runSummaries.Add([pscustomobject]$runSummary)
        if (-not $logAudit.passed) {
            throw "Capture $runLabel failed its runtime log audit. Log: $logPath"
        }
        Write-Host "[PASS] Capture ${runLabel}: p95 $($frameSummary.p95Ms) ms; >50 ms $($runSummary.hitchesOver50Ms); external exit $exitCode."
    }

    $captureSummary = [ordered]@{
        schemaVersion = 1
        task = 'BS-013B'
        presetId = $presetId
        result = 'PASS'
        generatedUtc = [DateTime]::UtcNow.ToString('o')
        commit = $commit
        packageRoot = $archiveRoot
        map = $benchmarkMap
        resolution = '1920x1080'
        scalability = 'High (sg.*=2)'
        screenPercentage = 100
        vsync = $false
        dynamicResolution = $false
        captureFramesPerRun = $CaptureFrames
        warmupFramesExcluded = $WarmupFrames
        runs = $runSummaries.ToArray()
    }
    $summaryPath = Join-Path $captureRoot 'capture-summary.json'
    Write-JsonAtomic -Value $captureSummary -Path $summaryPath
    Write-Host "[PASS] $Runs comparable renderer captures completed."
    Write-Host "[INFO] Summary: $summaryPath"
    return $captureRoot
}

function Invoke-Visual {
    if (-not $PlanOnly) { Assert-CleanCandidate }
    $archiveRoot = Get-LatestPackageRoot
    $windowsRoot = Join-Path $archiveRoot 'Windows'
    $gameExe = Join-Path $windowsRoot 'BrokenStreets\Binaries\Win64\BrokenStreets.exe'
    if (-not $PlanOnly -and -not (Test-Path -LiteralPath $gameExe -PathType Leaf)) { throw "Packaged executable is missing: $gameExe" }
    $visualRoot = Join-Path $projectRoot ('Saved\Verification\BS-013B\CreatorVisual-' + [DateTime]::UtcNow.ToString('yyyyMMddTHHmmssZ'))
    $logPath = Join-Path $visualRoot 'BrokenStreets.log'
    $execCommands = $qualityCommands -join ','
    $arguments = @($benchmarkMap, '-d3d12', '-ResX=1920', '-ResY=1080', '-Windowed', '-ForceRes', '-NoVSync', '-culture=en', '-language=en', "-ExecCmds=`"$execCommands`"", '-log', "-abslog=$logPath") -join ' '
    if ($PlanOnly) {
        Write-Host "[PLAN] Creator visual launch: $gameExe"
        Write-Host "[PLAN] Map: $benchmarkMap; preset: $presetId"
        return
    }
    [System.IO.Directory]::CreateDirectory($visualRoot) | Out-Null
    Write-Host '[INFO] Inspect and traverse the benchmark fixture, then close it with Alt+F4.'
    $process = Start-Process -FilePath $gameExe -ArgumentList $arguments -WorkingDirectory $windowsRoot -PassThru -Wait
    Write-Host "[INFO] Visual checkpoint exit code: $($process.ExitCode). Log: $logPath"
    if ($process.ExitCode -ne 0) { exit $process.ExitCode }
}

try {
    switch ($Action) {
        'Audit' { Invoke-Audit }
        'Package' { Invoke-Audit; [void](Invoke-Package) }
        'Capture' { Invoke-Audit; [void](Invoke-Capture) }
        'Visual' { Invoke-Audit; Invoke-Visual }
        'All' {
            Invoke-Audit
            if ($PlanOnly) {
                $plannedPackage = Invoke-Package
                $script:PackageRoot = $plannedPackage
                [void](Invoke-Capture)
            }
            else {
                $createdPackage = Invoke-Package
                $script:PackageRoot = $createdPackage
                [void](Invoke-Capture)
            }
        }
    }
    exit 0
}
catch {
    Write-Host "[FAIL] $($_.Exception.Message)"
    exit 70
}
