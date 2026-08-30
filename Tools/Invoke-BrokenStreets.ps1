#requires -Version 5.1

[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [ValidateSet('Doctor', 'Generate', 'Build', 'Test', 'Validate', 'Cook', 'All')]
    [string]$Action = 'Doctor',

    [string]$EngineRoot,

    [ValidateRange(0, 86400)]
    [int]$TimeoutSeconds = 0,

    [switch]$PlanOnly
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$script:ExitPreflight = 20
$script:ExitSemantic = 21
$script:ExitInternal = 70
$script:ExitTimeout = 124
$script:Utf8NoBom = New-Object System.Text.UTF8Encoding($false)
$script:RunnerLogPath = $null
$script:RunJsonPath = $null
$script:RunState = $null
$script:LockHandle = $null
$script:StepNumber = 0
$script:Context = $null
$script:ToolsRoot = $PSScriptRoot

if ($null -eq ('BrokenStreets.ProcessJobNative' -as [type])) {
    Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;

namespace BrokenStreets
{
    public static class ProcessJobNative
    {
        public const UInt32 JOB_OBJECT_LIMIT_KILL_ON_JOB_CLOSE = 0x00002000;

        [StructLayout(LayoutKind.Sequential)]
        public struct JOBOBJECT_BASIC_LIMIT_INFORMATION
        {
            public Int64 PerProcessUserTimeLimit;
            public Int64 PerJobUserTimeLimit;
            public UInt32 LimitFlags;
            public UIntPtr MinimumWorkingSetSize;
            public UIntPtr MaximumWorkingSetSize;
            public UInt32 ActiveProcessLimit;
            public UIntPtr Affinity;
            public UInt32 PriorityClass;
            public UInt32 SchedulingClass;
        }

        [StructLayout(LayoutKind.Sequential)]
        public struct IO_COUNTERS
        {
            public UInt64 ReadOperationCount;
            public UInt64 WriteOperationCount;
            public UInt64 OtherOperationCount;
            public UInt64 ReadTransferCount;
            public UInt64 WriteTransferCount;
            public UInt64 OtherTransferCount;
        }

        [StructLayout(LayoutKind.Sequential)]
        public struct JOBOBJECT_EXTENDED_LIMIT_INFORMATION
        {
            public JOBOBJECT_BASIC_LIMIT_INFORMATION BasicLimitInformation;
            public IO_COUNTERS IoInfo;
            public UIntPtr ProcessMemoryLimit;
            public UIntPtr JobMemoryLimit;
            public UIntPtr PeakProcessMemoryUsed;
            public UIntPtr PeakJobMemoryUsed;
        }

        [StructLayout(LayoutKind.Sequential)]
        public struct JOBOBJECT_BASIC_ACCOUNTING_INFORMATION
        {
            public Int64 TotalUserTime;
            public Int64 TotalKernelTime;
            public Int64 ThisPeriodTotalUserTime;
            public Int64 ThisPeriodTotalKernelTime;
            public UInt32 TotalPageFaultCount;
            public UInt32 TotalProcesses;
            public UInt32 ActiveProcesses;
            public UInt32 TotalTerminatedProcesses;
        }

        [DllImport("kernel32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
        public static extern IntPtr CreateJobObject(IntPtr jobAttributes, string name);

        [DllImport("kernel32.dll", SetLastError = true)]
        [return: MarshalAs(UnmanagedType.Bool)]
        public static extern bool SetInformationJobObject(
            IntPtr job,
            Int32 informationClass,
            IntPtr information,
            UInt32 informationLength);

        [DllImport("kernel32.dll", SetLastError = true)]
        [return: MarshalAs(UnmanagedType.Bool)]
        public static extern bool AssignProcessToJobObject(IntPtr job, IntPtr process);

        [DllImport("kernel32.dll", SetLastError = true)]
        [return: MarshalAs(UnmanagedType.Bool)]
        public static extern bool TerminateJobObject(IntPtr job, UInt32 exitCode);

        [DllImport("kernel32.dll", SetLastError = true)]
        [return: MarshalAs(UnmanagedType.Bool)]
        public static extern bool QueryInformationJobObject(
            IntPtr job,
            Int32 informationClass,
            IntPtr information,
            UInt32 informationLength,
            out UInt32 returnLength);

        [DllImport("kernel32.dll", SetLastError = true)]
        [return: MarshalAs(UnmanagedType.Bool)]
        public static extern bool CloseHandle(IntPtr handle);
    }
}
'@
}

function Write-BsTextFile {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [AllowEmptyString()][string]$Content
    )

    [System.IO.File]::WriteAllText($Path, $Content, $script:Utf8NoBom)
}

function Read-BsTextFileWithRetry {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [int]$TimeoutMilliseconds = 10000
    )

    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    do {
        if (Test-Path -LiteralPath $Path -PathType Leaf) {
            $stream = $null
            $reader = $null
            try {
                $stream = [System.IO.File]::Open(
                    $Path,
                    [System.IO.FileMode]::Open,
                    [System.IO.FileAccess]::Read,
                    [System.IO.FileShare]::ReadWrite
                )
                $reader = New-Object System.IO.StreamReader -ArgumentList $stream, $script:Utf8NoBom, $true
                return $reader.ReadToEnd()
            }
            catch [System.IO.IOException] {
                # A short-lived child can still be releasing the redirected file handle.
            }
            finally {
                if ($null -ne $reader) {
                    $reader.Dispose()
                }
                elseif ($null -ne $stream) {
                    $stream.Dispose()
                }
            }
        }
        Start-Sleep -Milliseconds 250
    } while ($stopwatch.ElapsedMilliseconds -lt $TimeoutMilliseconds)

    throw "Output file did not become available within ${TimeoutMilliseconds}ms: $Path"
}

function Write-BsMessage {
    param(
        [Parameter(Mandatory = $true)][ValidateSet('INFO', 'RUN', 'PASS', 'SKIP', 'WARN', 'FAIL', 'PLAN')]
        [string]$Level,
        [Parameter(Mandatory = $true)][string]$Message
    )

    $timestamp = [DateTime]::UtcNow.ToString('o')
    $line = '[{0}] [{1}] {2}' -f $timestamp, $Level, $Message

    if ($null -ne $script:RunnerLogPath) {
        [System.IO.File]::AppendAllText($script:RunnerLogPath, $line + [Environment]::NewLine, $script:Utf8NoBom)
    }

    $color = 'Gray'
    switch ($Level) {
        'PASS' { $color = 'Green' }
        'SKIP' { $color = 'Yellow' }
        'WARN' { $color = 'Yellow' }
        'FAIL' { $color = 'Red' }
        'RUN'  { $color = 'Cyan' }
        'PLAN' { $color = 'DarkCyan' }
    }

    Write-Host ('[{0,-4}] {1}' -f $Level, $Message) -ForegroundColor $color
}

function Save-BsRunState {
    if (($null -eq $script:RunState) -or ($null -eq $script:RunJsonPath)) {
        return
    }

    $json = $script:RunState | ConvertTo-Json -Depth 12
    $temporaryPath = $script:RunJsonPath + '.tmp-' + $PID
    Write-BsTextFile -Path $temporaryPath -Content ($json + [Environment]::NewLine)
    Move-Item -LiteralPath $temporaryPath -Destination $script:RunJsonPath -Force
}

function ConvertTo-BsNativeArgument {
    param([AllowEmptyString()][string]$Value)

    if ($null -eq $Value) {
        $Value = ''
    }

    if (($Value.Length -gt 0) -and ($Value -notmatch '[\s"]')) {
        return $Value
    }

    $builder = New-Object System.Text.StringBuilder
    [void]$builder.Append('"')
    $backslashCount = 0

    for ($index = 0; $index -lt $Value.Length; $index++) {
        $character = $Value[$index]

        if ($character -eq '\') {
            $backslashCount++
            continue
        }

        if ($character -eq '"') {
            if ($backslashCount -gt 0) {
                [void]$builder.Append(('\' * ($backslashCount * 2)))
            }
            [void]$builder.Append('\')
            [void]$builder.Append('"')
            $backslashCount = 0
            continue
        }

        if ($backslashCount -gt 0) {
            [void]$builder.Append(('\' * $backslashCount))
            $backslashCount = 0
        }

        [void]$builder.Append($character)
    }

    if ($backslashCount -gt 0) {
        [void]$builder.Append(('\' * ($backslashCount * 2)))
    }

    [void]$builder.Append('"')
    return $builder.ToString()
}

function Join-BsNativeArguments {
    param([string[]]$ArgumentList)

    $quoted = @()
    foreach ($argument in $ArgumentList) {
        $quoted += ConvertTo-BsNativeArgument -Value $argument
    }
    return ($quoted -join ' ')
}

function New-BsProcessJob {
    $jobHandle = [BrokenStreets.ProcessJobNative]::CreateJobObject([IntPtr]::Zero, $null)
    if ($jobHandle -eq [IntPtr]::Zero) {
        throw (New-Object System.ComponentModel.Win32Exception(
            [System.Runtime.InteropServices.Marshal]::GetLastWin32Error()
        ))
    }

    $buffer = [IntPtr]::Zero
    try {
        $basicLimits = New-Object BrokenStreets.ProcessJobNative+JOBOBJECT_BASIC_LIMIT_INFORMATION
        $basicLimits.LimitFlags = [BrokenStreets.ProcessJobNative]::JOB_OBJECT_LIMIT_KILL_ON_JOB_CLOSE
        $extendedLimits = New-Object BrokenStreets.ProcessJobNative+JOBOBJECT_EXTENDED_LIMIT_INFORMATION
        $extendedLimits.BasicLimitInformation = $basicLimits
        $size = [System.Runtime.InteropServices.Marshal]::SizeOf($extendedLimits)
        $buffer = [System.Runtime.InteropServices.Marshal]::AllocHGlobal($size)
        [System.Runtime.InteropServices.Marshal]::StructureToPtr($extendedLimits, $buffer, $false)
        if (-not [BrokenStreets.ProcessJobNative]::SetInformationJobObject(
            $jobHandle,
            9,
            $buffer,
            [uint32]$size
        )) {
            throw (New-Object System.ComponentModel.Win32Exception(
                [System.Runtime.InteropServices.Marshal]::GetLastWin32Error()
            ))
        }
        return $jobHandle
    }
    catch {
        [void][BrokenStreets.ProcessJobNative]::CloseHandle($jobHandle)
        throw
    }
    finally {
        if ($buffer -ne [IntPtr]::Zero) {
            [System.Runtime.InteropServices.Marshal]::FreeHGlobal($buffer)
        }
    }
}

function Add-BsProcessToJob {
    param(
        [Parameter(Mandatory = $true)][IntPtr]$JobHandle,
        [Parameter(Mandatory = $true)][System.Diagnostics.Process]$Process
    )

    if (-not [BrokenStreets.ProcessJobNative]::AssignProcessToJobObject($JobHandle, $Process.Handle)) {
        throw (New-Object System.ComponentModel.Win32Exception(
            [System.Runtime.InteropServices.Marshal]::GetLastWin32Error()
        ))
    }
}

function Get-BsJobActiveProcessCount {
    param([Parameter(Mandatory = $true)][IntPtr]$JobHandle)

    $accounting = New-Object BrokenStreets.ProcessJobNative+JOBOBJECT_BASIC_ACCOUNTING_INFORMATION
    $size = [System.Runtime.InteropServices.Marshal]::SizeOf($accounting)
    $buffer = [System.Runtime.InteropServices.Marshal]::AllocHGlobal($size)
    try {
        $returnLength = [uint32]0
        if (-not [BrokenStreets.ProcessJobNative]::QueryInformationJobObject(
            $JobHandle,
            1,
            $buffer,
            [uint32]$size,
            [ref]$returnLength
        )) {
            throw (New-Object System.ComponentModel.Win32Exception(
                [System.Runtime.InteropServices.Marshal]::GetLastWin32Error()
            ))
        }
        $result = [System.Runtime.InteropServices.Marshal]::PtrToStructure(
            $buffer,
            [type][BrokenStreets.ProcessJobNative+JOBOBJECT_BASIC_ACCOUNTING_INFORMATION]
        )
        return [int]$result.ActiveProcesses
    }
    finally {
        [System.Runtime.InteropServices.Marshal]::FreeHGlobal($buffer)
    }
}

function Stop-BsProcessJob {
    param(
        [Parameter(Mandatory = $true)][IntPtr]$JobHandle,
        [uint32]$ExitCode = 124
    )

    $terminateSucceeded = [BrokenStreets.ProcessJobNative]::TerminateJobObject($JobHandle, $ExitCode)
    $terminateError = $null
    if (-not $terminateSucceeded) {
        $terminateError = (New-Object System.ComponentModel.Win32Exception(
            [System.Runtime.InteropServices.Marshal]::GetLastWin32Error()
        )).Message
    }

    $activeProcesses = $null
    $queryError = $null
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    do {
        try {
            $activeProcesses = Get-BsJobActiveProcessCount -JobHandle $JobHandle
            if ($activeProcesses -eq 0) {
                break
            }
        }
        catch {
            $queryError = $_.Exception.Message
            break
        }
        Start-Sleep -Milliseconds 250
    } while ($stopwatch.ElapsedMilliseconds -lt 5000)

    return [pscustomobject][ordered]@{
        Confirmed = [bool]($terminateSucceeded -and ($activeProcesses -eq 0) -and ($null -eq $queryError))
        TerminateSucceeded = $terminateSucceeded
        TerminateError = $terminateError
        ActiveProcesses = $activeProcesses
        QueryError = $queryError
    }
}

function Close-BsProcessJob {
    param([IntPtr]$JobHandle)
    if ($JobHandle -ne [IntPtr]::Zero) {
        [void][BrokenStreets.ProcessJobNative]::CloseHandle($JobHandle)
    }
}

function Get-BsProcessTreeSnapshot {
    param(
        [Parameter(Mandatory = $true)][int]$RootProcessId,
        $RootCreationUtc
    )

    $querySucceeded = $false
    $queryError = $null
    $allProcesses = @()
    try {
        $allProcesses = @(Get-CimInstance -ClassName Win32_Process `
            -Property ProcessId, ParentProcessId, CreationDate -OperationTimeoutSec 5 -ErrorAction Stop)
        $querySucceeded = $true
    }
    catch {
        $queryError = $_.Exception.Message
    }

    $captured = New-Object System.Collections.ArrayList
    if ($querySucceeded) {
        $childrenByParent = @{}
        $processById = @{}
        $creationById = @{}
        foreach ($item in $allProcesses) {
            $itemProcessId = [int]$item.ProcessId
            $itemParentId = [int]$item.ParentProcessId
            $itemKey = [string]$itemProcessId
            $processById[$itemKey] = $item
            $itemCreationUtc = $null
            if ($null -ne $item.CreationDate) {
                try {
                    if ($item.CreationDate -is [DateTime]) {
                        $itemCreationUtc = ([DateTime]$item.CreationDate).ToUniversalTime()
                    }
                    else {
                        $itemCreationUtc = [System.Management.ManagementDateTimeConverter]::ToDateTime(
                            [string]$item.CreationDate
                        ).ToUniversalTime()
                    }
                }
                catch {
                    $itemCreationUtc = $null
                }
            }
            $creationById[$itemKey] = $itemCreationUtc
            $parentKey = [string]$itemParentId
            if (-not $childrenByParent.ContainsKey($parentKey)) {
                $childrenByParent[$parentKey] = New-Object System.Collections.ArrayList
            }
            [void]$childrenByParent[$parentKey].Add($itemProcessId)
        }

        $pending = New-Object System.Collections.Queue
        $visited = New-Object 'System.Collections.Generic.HashSet[int]'
        $pending.Enqueue($RootProcessId)
        while ($pending.Count -gt 0) {
            $currentProcessId = [int]$pending.Dequeue()
            if (-not $visited.Add($currentProcessId)) {
                continue
            }

            $currentKey = [string]$currentProcessId
            if ($processById.ContainsKey($currentKey)) {
                $current = $processById[$currentKey]
                $creationUtc = $null
                if ($null -ne $creationById[$currentKey]) {
                    $creationUtc = ([DateTime]$creationById[$currentKey]).ToString('o')
                }
                [void]$captured.Add([pscustomobject]@{
                    ProcessId = $currentProcessId
                    ParentProcessId = [int]$current.ParentProcessId
                    CreationUtc = $creationUtc
                })
            }

            if ($childrenByParent.ContainsKey($currentKey)) {
                $parentCreation = $null
                if (($currentProcessId -eq $RootProcessId) -and ($null -ne $RootCreationUtc)) {
                    $parentCreation = ([DateTime]$RootCreationUtc).ToUniversalTime()
                }
                elseif ($creationById.ContainsKey($currentKey)) {
                    $parentCreation = $creationById[$currentKey]
                }
                foreach ($childProcessId in @($childrenByParent[$currentKey])) {
                    $childKey = [string][int]$childProcessId
                    $childCreation = $null
                    if ($creationById.ContainsKey($childKey)) {
                        $childCreation = $creationById[$childKey]
                    }
                    if (($null -ne $parentCreation) -and ($null -ne $childCreation) -and
                        (([DateTime]$childCreation) -ge ([DateTime]$parentCreation).AddMilliseconds(-100))) {
                        $pending.Enqueue([int]$childProcessId)
                    }
                }
            }
        }
    }
    else {
        $fallbackProcess = $null
        try {
            $fallbackProcess = [System.Diagnostics.Process]::GetProcessById($RootProcessId)
            [void]$captured.Add([pscustomobject]@{
                ProcessId = $RootProcessId
                ParentProcessId = $null
                CreationUtc = $fallbackProcess.StartTime.ToUniversalTime().ToString('o')
            })
        }
        catch {
            # The root can exit while the snapshot is being captured.
        }
        finally {
            if ($null -ne $fallbackProcess) {
                $fallbackProcess.Dispose()
            }
        }
    }

    return [pscustomobject]@{
        QuerySucceeded = $querySucceeded
        Error = $queryError
        Processes = @($captured)
    }
}

function Test-BsCapturedProcessStillRunning {
    param([Parameter(Mandatory = $true)]$CapturedProcess)

    $liveProcess = $null
    try {
        $liveProcess = [System.Diagnostics.Process]::GetProcessById([int]$CapturedProcess.ProcessId)
        if ($liveProcess.HasExited) {
            return $false
        }

        if (-not [string]::IsNullOrWhiteSpace([string]$CapturedProcess.CreationUtc)) {
            try {
                $capturedStart = [DateTime]::Parse(
                    [string]$CapturedProcess.CreationUtc,
                    [System.Globalization.CultureInfo]::InvariantCulture,
                    [System.Globalization.DateTimeStyles]::RoundtripKind
                ).ToUniversalTime()
                $liveStart = $liveProcess.StartTime.ToUniversalTime()
                if ([Math]::Abs(($liveStart - $capturedStart).TotalMilliseconds) -gt 100.0) {
                    return $false
                }
            }
            catch {
                # A live PID whose identity cannot be checked is conservatively retained.
                return $true
            }
        }
        return $true
    }
    catch [System.ArgumentException] {
        return $false
    }
    catch {
        return $true
    }
    finally {
        if ($null -ne $liveProcess) {
            $liveProcess.Dispose()
        }
    }
}

function Stop-BsProcessTree {
    param(
        [Parameter(Mandatory = $true)][System.Diagnostics.Process]$Process
    )

    $rootProcessId = $Process.Id
    $rootCreationUtc = $null
    try {
        $rootCreationUtc = $Process.StartTime.ToUniversalTime()
    }
    catch {
        $rootCreationUtc = $null
    }
    $snapshot = Get-BsProcessTreeSnapshot -RootProcessId $rootProcessId -RootCreationUtc $rootCreationUtc
    $capturedProcessIds = @($snapshot.Processes | ForEach-Object { [int]$_.ProcessId })
    $taskKillExitCode = $null
    $taskKillCompleted = $false
    $taskKillError = $null
    $taskKillPath = Join-Path $env:SystemRoot 'System32\taskkill.exe'
    $killProcess = $null
    $killStdoutTask = $null
    $killStderrTask = $null
    $rootExitedBeforeTaskKill = $false

    try {
        $rootExitedBeforeTaskKill = $Process.HasExited
    }
    catch {
        $rootExitedBeforeTaskKill = $true
    }

    try {
        if ($rootExitedBeforeTaskKill) {
            throw 'The root process exited before taskkill; complete process-tree termination can no longer be confirmed.'
        }
        $killInfo = New-Object System.Diagnostics.ProcessStartInfo
        $killInfo.FileName = $taskKillPath
        $killInfo.Arguments = '/PID {0} /T /F' -f $rootProcessId
        $killInfo.UseShellExecute = $false
        $killInfo.CreateNoWindow = $true
        $killInfo.RedirectStandardOutput = $true
        $killInfo.RedirectStandardError = $true
        $killProcess = New-Object System.Diagnostics.Process
        $killProcess.StartInfo = $killInfo
        [void]$killProcess.Start()
        $killStdoutTask = $killProcess.StandardOutput.ReadToEndAsync()
        $killStderrTask = $killProcess.StandardError.ReadToEndAsync()
        $taskKillCompleted = $killProcess.WaitForExit(10000)
        if ($taskKillCompleted) {
            $taskKillExitCode = $killProcess.ExitCode
        }
        else {
            try {
                $killProcess.Kill()
                [void]$killProcess.WaitForExit(5000)
            }
            catch {
                # A hung taskkill helper is reflected by TaskKillCompleted = false.
            }
        }
        if (($null -ne $killStdoutTask) -and $killStdoutTask.Wait(1000)) {
            [void]$killStdoutTask.Result
        }
        if (($null -ne $killStderrTask) -and $killStderrTask.Wait(1000)) {
            [void]$killStderrTask.Result
        }
    }
    catch {
        $taskKillError = $_.Exception.Message
    }
    finally {
        if ($null -ne $killProcess) {
            $killProcess.Dispose()
        }
    }

    try {
        [void]$Process.WaitForExit(5000)
    }
    catch {
        # The root can exit between taskkill and WaitForExit().
    }

    $remaining = @($snapshot.Processes | Where-Object {
        Test-BsCapturedProcessStillRunning -CapturedProcess $_
    })

    # Best-effort fallback prevents known descendants from leaking even when taskkill
    # itself failed. A fallback-only result is deliberately not marked confirmed.
    $fallbackOrder = @($remaining | Where-Object { [int]$_.ProcessId -eq $rootProcessId }) +
        @($remaining | Where-Object { [int]$_.ProcessId -ne $rootProcessId } | Sort-Object ProcessId -Descending)
    foreach ($capturedProcess in $fallbackOrder) {
        $fallbackProcess = $null
        try {
            if ([int]$capturedProcess.ProcessId -eq $rootProcessId) {
                if (-not $Process.HasExited) {
                    $Process.Kill()
                    [void]$Process.WaitForExit(5000)
                }
            }
            elseif (-not [string]::IsNullOrWhiteSpace([string]$capturedProcess.CreationUtc)) {
                $fallbackProcess = [System.Diagnostics.Process]::GetProcessById([int]$capturedProcess.ProcessId)
                $capturedStart = [DateTime]::Parse(
                    [string]$capturedProcess.CreationUtc,
                    [System.Globalization.CultureInfo]::InvariantCulture,
                    [System.Globalization.DateTimeStyles]::RoundtripKind
                ).ToUniversalTime()
                $liveStart = $fallbackProcess.StartTime.ToUniversalTime()
                $identityMatches = [Math]::Abs(($liveStart - $capturedStart).TotalMilliseconds) -le 100.0
                if ($identityMatches -and (-not $fallbackProcess.HasExited)) {
                    $fallbackProcess.Kill()
                    [void]$fallbackProcess.WaitForExit(5000)
                }
            }
        }
        catch {
            # Verification below decides whether termination can be confirmed.
        }
        finally {
            if ($null -ne $fallbackProcess) {
                $fallbackProcess.Dispose()
            }
        }
    }

    $remainingProcessIds = @($snapshot.Processes | Where-Object {
        Test-BsCapturedProcessStillRunning -CapturedProcess $_
    } | ForEach-Object { [int]$_.ProcessId })
    $confirmed = [bool](
        $snapshot.QuerySucceeded -and
        $taskKillCompleted -and
        ($taskKillExitCode -eq 0) -and
        ($remainingProcessIds.Count -eq 0)
    )

    return [pscustomobject][ordered]@{
        Confirmed = $confirmed
        RootExitedBeforeTaskKill = $rootExitedBeforeTaskKill
        ProcessTreeQuerySucceeded = [bool]$snapshot.QuerySucceeded
        ProcessTreeQueryError = $snapshot.Error
        TaskKillCompleted = $taskKillCompleted
        TaskKillExitCode = $taskKillExitCode
        TaskKillError = $taskKillError
        CapturedProcessIds = $capturedProcessIds
        RemainingProcessIds = $remainingProcessIds
    }
}

function Get-BsEngineCandidate {
    param(
        [Parameter(Mandatory = $true)][string]$Root,
        [Parameter(Mandatory = $true)][string]$Source,
        [switch]$ThrowOnInvalid
    )

    try {
        $fullRoot = [System.IO.Path]::GetFullPath($Root.Trim().TrimEnd('\', '/'))
        $buildVersionPath = Join-Path $fullRoot 'Engine\Build\Build.version'
        $ubtDll = Join-Path $fullRoot 'Engine\Binaries\DotNET\UnrealBuildTool\UnrealBuildTool.dll'
        $editorCmd = Join-Path $fullRoot 'Engine\Binaries\Win64\UnrealEditor-Cmd.exe'

        foreach ($requiredPath in @($buildVersionPath, $ubtDll, $editorCmd)) {
            if (-not (Test-Path -LiteralPath $requiredPath -PathType Leaf)) {
                throw "Required file is missing: $requiredPath"
            }
        }

        $dotnetSearchRoot = Join-Path $fullRoot 'Engine\Binaries\ThirdParty\DotNet'
        $dotnetCandidates = New-Object System.Collections.ArrayList
        foreach ($versionDirectory in (Get-ChildItem -LiteralPath $dotnetSearchRoot -Directory)) {
            try {
                $parsedVersion = [version]$versionDirectory.Name
                $candidatePath = Join-Path $versionDirectory.FullName 'win-x64\dotnet.exe'
                if (Test-Path -LiteralPath $candidatePath -PathType Leaf) {
                    [void]$dotnetCandidates.Add([pscustomobject]@{
                        Version = $parsedVersion
                        Path = $candidatePath
                    })
                }
            }
            catch {
                # Ignore folders that are not semantic DotNet versions.
            }
        }
        $dotnet = $dotnetCandidates | Sort-Object Version -Descending | Select-Object -First 1

        if ($null -eq $dotnet) {
            throw "The engine does not contain a bundled win-x64 DotNet runtime under $dotnetSearchRoot"
        }
        $ubtRuntimeConfig = Join-Path $fullRoot 'Engine\Binaries\DotNET\UnrealBuildTool\UnrealBuildTool.runtimeconfig.json'
        if (-not (Test-Path -LiteralPath $ubtRuntimeConfig -PathType Leaf)) {
            throw "UnrealBuildTool runtime configuration is missing: $ubtRuntimeConfig"
        }

        $version = Get-Content -LiteralPath $buildVersionPath -Raw | ConvertFrom-Json
        $expected = $script:Context.Config.expectedEngine
        $actualVersion = '{0}.{1}.{2}' -f $version.MajorVersion, $version.MinorVersion, $version.PatchVersion
        $expectedVersion = '{0}.{1}.{2}' -f $expected.major, $expected.minor, $expected.patch

        if ($actualVersion -ne $expectedVersion) {
            throw "Engine $actualVersion was found; the project requires exactly $expectedVersion"
        }

        if ([Int64]$version.Changelist -ne [Int64]$expected.changelist) {
            throw "Engine changelist $($version.Changelist) was found; the project requires exactly $($expected.changelist)"
        }

        return [pscustomobject][ordered]@{
            Root = $fullRoot
            Source = $Source
            Version = $actualVersion
            Changelist = [Int64]$version.Changelist
            DotNetExe = $dotnet.Path
            UbtDll = $ubtDll
            EditorCmd = $editorCmd
        }
    }
    catch {
        if ($ThrowOnInvalid) {
            throw
        }
        return $null
    }
}

function Resolve-BsEngine {
    param([string]$ExplicitRoot)

    if (-not [string]::IsNullOrWhiteSpace($ExplicitRoot)) {
        return Get-BsEngineCandidate -Root $ExplicitRoot -Source 'ExplicitParameter' -ThrowOnInvalid
    }

    $environmentRoot = [Environment]::GetEnvironmentVariable('BROKENSTREETS_UE_ROOT')
    if (-not [string]::IsNullOrWhiteSpace($environmentRoot)) {
        return Get-BsEngineCandidate -Root $environmentRoot -Source 'EnvironmentVariable' -ThrowOnInvalid
    }

    $candidateInputs = New-Object System.Collections.ArrayList
    $association = $script:Context.ProjectDescriptor.EngineAssociation

    if (-not [string]::IsNullOrWhiteSpace([string]$association)) {
        try {
            $registeredBuilds = Get-ItemProperty -LiteralPath 'HKCU:\SOFTWARE\Epic Games\Unreal Engine\Builds'
            $property = $registeredBuilds.PSObject.Properties[[string]$association]
            if (($null -ne $property) -and (-not [string]::IsNullOrWhiteSpace([string]$property.Value))) {
                [void]$candidateInputs.Add([pscustomobject]@{ Root = [string]$property.Value; Source = 'EngineAssociationRegistry' })
            }
        }
        catch {
            # Launcher installations commonly use a GUID that is not present in this profile.
        }

        foreach ($registryPath in @(
            ('HKLM:\SOFTWARE\EpicGames\Unreal Engine\' + [string]$association),
            ('HKLM:\SOFTWARE\WOW6432Node\EpicGames\Unreal Engine\' + [string]$association)
        )) {
            try {
                $registeredEngine = Get-ItemProperty -LiteralPath $registryPath
                if (-not [string]::IsNullOrWhiteSpace([string]$registeredEngine.InstalledDirectory)) {
                    [void]$candidateInputs.Add([pscustomobject]@{
                        Root = [string]$registeredEngine.InstalledDirectory
                        Source = 'MachineEngineRegistry'
                    })
                }
            }
            catch {
                # The association can be a per-user GUID or a Launcher manifest only.
            }
        }
    }

    $manifestRoot = 'C:\ProgramData\Epic\EpicGamesLauncher\Data\Manifests'
    if (Test-Path -LiteralPath $manifestRoot -PathType Container) {
        foreach ($manifestFile in (Get-ChildItem -LiteralPath $manifestRoot -Filter '*.item' -File)) {
            try {
                $manifest = Get-Content -LiteralPath $manifestFile.FullName -Raw | ConvertFrom-Json
                $isEngineManifest = ([string]$manifest.AppName -match '^UE_') -or
                    ([string]$manifest.DisplayName -eq 'Unreal Engine')
                if ($isEngineManifest -and (-not [string]::IsNullOrWhiteSpace([string]$manifest.InstallLocation))) {
                    [void]$candidateInputs.Add([pscustomobject]@{
                        Root = [string]$manifest.InstallLocation
                        Source = 'EpicLauncherManifest'
                    })
                }
            }
            catch {
                # Ignore unrelated or incomplete Launcher manifests.
            }
        }
    }

    $validByPath = @{}
    foreach ($inputCandidate in $candidateInputs) {
        $candidate = Get-BsEngineCandidate -Root $inputCandidate.Root -Source $inputCandidate.Source
        if ($null -ne $candidate) {
            $key = $candidate.Root.ToLowerInvariant()
            if (-not $validByPath.ContainsKey($key)) {
                $validByPath[$key] = $candidate
            }
        }
    }

    $validCandidates = @($validByPath.Values)
    if ($validCandidates.Count -eq 0) {
        throw 'UE 5.8.2 CL 56702186 was not found. Use -EngineRoot or set BROKENSTREETS_UE_ROOT.'
    }
    if ($validCandidates.Count -gt 1) {
        throw 'Multiple valid UE 5.8.2 installations were found. Select one explicitly with -EngineRoot.'
    }

    return $validCandidates[0]
}

function Initialize-BsContext {
    param([string]$ExplicitEngineRoot)

    $toolsRoot = $script:ToolsRoot
    $projectRoot = [System.IO.Path]::GetFullPath((Join-Path $toolsRoot '..'))
    $configPath = Join-Path $toolsRoot 'Build\RunnerConfig.json'
    if (-not (Test-Path -LiteralPath $configPath -PathType Leaf)) {
        throw "Runner configuration is missing: $configPath"
    }

    $config = Get-Content -LiteralPath $configPath -Raw | ConvertFrom-Json
    if ([int]$config.schemaVersion -ne 1) {
        throw "Unsupported RunnerConfig.json schema: $($config.schemaVersion)"
    }

    $projectFile = Join-Path $projectRoot ([string]$config.projectFile)
    if (-not (Test-Path -LiteralPath $projectFile -PathType Leaf)) {
        throw "Unreal project is missing: $projectFile"
    }

    $projectDescriptor = Get-Content -LiteralPath $projectFile -Raw | ConvertFrom-Json
    $automationRoot = Join-Path $projectRoot 'Saved\Automation\BS-009'
    [void](New-Item -ItemType Directory -Path $automationRoot -Force)

    $lockPath = Join-Path $automationRoot 'runner.lock'
    try {
        $script:LockHandle = [System.IO.File]::Open(
            $lockPath,
            [System.IO.FileMode]::OpenOrCreate,
            [System.IO.FileAccess]::ReadWrite,
            [System.IO.FileShare]::None
        )
    }
    catch {
        throw 'Another Broken Streets automation run is already using the project. Wait for it to finish.'
    }

    $runId = '{0}-{1}-{2}' -f [DateTime]::UtcNow.ToString('yyyyMMddTHHmmssZ'), $PID,
        ([Guid]::NewGuid().ToString('N').Substring(0, 8))
    $runRoot = Join-Path $automationRoot $runId
    [void](New-Item -ItemType Directory -Path $runRoot -Force)

    $script:RunnerLogPath = Join-Path $runRoot 'runner.log'
    $script:RunJsonPath = Join-Path $runRoot 'run.json'
    Write-BsTextFile -Path $script:RunnerLogPath -Content ''

    $script:Context = [pscustomobject][ordered]@{
        ToolsRoot = $toolsRoot
        ProjectRoot = $projectRoot
        ProjectFile = $projectFile
        ProjectDescriptor = $projectDescriptor
        Config = $config
        AutomationRoot = $automationRoot
        RunRoot = $runRoot
        Engine = $null
    }

    $script:RunState = [ordered]@{
        schemaVersion = 1
        requestedAction = $Action
        planOnly = [bool]$PlanOnly
        startUtc = [DateTime]::UtcNow.ToString('o')
        endUtc = $null
        status = 'RUNNING'
        runnerExitCode = $null
        project = $projectFile
        engine = $null
        steps = New-Object System.Collections.ArrayList
    }
    Save-BsRunState

    $script:Context.Engine = Resolve-BsEngine -ExplicitRoot $ExplicitEngineRoot
    $script:RunState.engine = [ordered]@{
        root = $script:Context.Engine.Root
        source = $script:Context.Engine.Source
        version = $script:Context.Engine.Version
        changelist = $script:Context.Engine.Changelist
    }
    Save-BsRunState
}

function Get-BsDotNetEnvironment {
    $dotnetRoot = Split-Path -Parent $script:Context.Engine.DotNetExe
    $parentPath = [Environment]::GetEnvironmentVariable('PATH')
    return @{
        'DOTNET_ROOT' = $dotnetRoot
        'DOTNET_MULTILEVEL_LOOKUP' = '0'
        'DOTNET_ROLL_FORWARD' = 'LatestMajor'
        'UE_DOTNET_VERSION' = (Split-Path -Leaf (Split-Path -Parent $dotnetRoot))
        'PATH' = $dotnetRoot + ';' + $parentPath
    }
}

function Get-BsTimeoutSeconds {
    param([Parameter(Mandatory = $true)][string]$StepName)

    if ($TimeoutSeconds -gt 0) {
        return $TimeoutSeconds
    }

    $property = $script:Context.Config.timeoutsSeconds.PSObject.Properties[$StepName]
    if ($null -eq $property) {
        throw "No timeout is configured for $StepName"
    }
    return [int]$property.Value
}

function Invoke-BsProcess {
    param(
        [Parameter(Mandatory = $true)][string]$StepName,
        [Parameter(Mandatory = $true)][string]$FilePath,
        [Parameter(Mandatory = $true)][AllowEmptyString()][string[]]$ArgumentList,
        [Parameter(Mandatory = $true)][int]$StepTimeoutSeconds,
        [hashtable]$EnvironmentVariables,
        [string]$ExplicitStepDirectory,
        [switch]$ForceExecution
    )

    if ([string]::IsNullOrWhiteSpace($ExplicitStepDirectory)) {
        $script:StepNumber++
        $stepDirectory = Join-Path $script:Context.RunRoot ('Steps\{0:D2}-{1}' -f $script:StepNumber, $StepName)
    }
    else {
        $stepDirectory = [System.IO.Path]::GetFullPath($ExplicitStepDirectory)
    }
    [void](New-Item -ItemType Directory -Path $stepDirectory -Force)
    $stdoutPath = Join-Path $stepDirectory 'stdout.log'
    $stderrPath = Join-Path $stepDirectory 'stderr.log'
    $commandPath = Join-Path $stepDirectory 'command.txt'
    $combinedLogPath = Join-Path $stepDirectory 'combined.log'
    $commandLine = (ConvertTo-BsNativeArgument -Value $FilePath) + ' ' + (Join-BsNativeArguments -ArgumentList $ArgumentList)
    Write-BsTextFile -Path $commandPath -Content ($commandLine + [Environment]::NewLine)

    if ($PlanOnly -and (-not $ForceExecution)) {
        Write-BsTextFile -Path $stdoutPath -Content ''
        Write-BsTextFile -Path $stderrPath -Content ''
        Write-BsTextFile -Path $combinedLogPath -Content ("PLAN ONLY`r`n" + $commandLine + [Environment]::NewLine)
        return [pscustomobject][ordered]@{
            Planned = $true
            Started = $false
            TimedOut = $false
            ToolExitCode = 0
            DurationSeconds = 0.0
            ProcessId = $null
            StdoutPath = $stdoutPath
            StderrPath = $stderrPath
            CombinedLogPath = $combinedLogPath
            CombinedOutput = ''
            LaunchError = $null
            TreeTerminated = $true
            ProcessTreeQuerySucceeded = $true
            TaskKillExitCode = $null
            CapturedProcessIds = @()
            RemainingProcessIds = @()
            ExitCodeReadError = $null
            NativeFailureTreeCleanup = $null
            JobAssigned = $false
            JobTerminateSucceeded = $null
            JobActiveProcesses = $null
            JobTerminateError = $null
            JobQueryError = $null
            ContainmentError = $null
        }
    }

    if (-not (Test-Path -LiteralPath $FilePath -PathType Leaf)) {
        $message = "Executable does not exist: $FilePath"
        Write-BsTextFile -Path $stdoutPath -Content ''
        Write-BsTextFile -Path $stderrPath -Content ($message + [Environment]::NewLine)
        Write-BsTextFile -Path $combinedLogPath -Content ($message + [Environment]::NewLine)
        return [pscustomobject][ordered]@{
            Planned = $false
            Started = $false
            TimedOut = $false
            ToolExitCode = $null
            DurationSeconds = 0.0
            ProcessId = $null
            StdoutPath = $stdoutPath
            StderrPath = $stderrPath
            CombinedLogPath = $combinedLogPath
            CombinedOutput = $message
            LaunchError = $message
            TreeTerminated = $true
            ProcessTreeQuerySucceeded = $true
            TaskKillExitCode = $null
            CapturedProcessIds = @()
            RemainingProcessIds = @()
            ExitCodeReadError = $null
            NativeFailureTreeCleanup = $null
            JobAssigned = $false
            JobTerminateSucceeded = $null
            JobActiveProcesses = $null
            JobTerminateError = $null
            JobQueryError = $null
            ContainmentError = $null
        }
    }

    $process = $null
    $jobHandle = [IntPtr]::Zero
    $jobAssigned = $false
    $jobTermination = $null
    $processStarted = $false
    $processId = $null
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    $stdout = ''
    $stderr = ''
    $stdoutTask = $null
    $stderrTask = $null
    $timedOut = $false
    $treeTerminated = $true
    $termination = $null
    $nativeFailureTreeCleanup = $null
    $toolExitCode = $null
    $exitCodeReadError = $null
    $outputReadError = $null
    $containmentError = $null

    try {
        $joinedArguments = Join-BsNativeArguments -ArgumentList $ArgumentList
        $startInfo = New-Object System.Diagnostics.ProcessStartInfo
        $startInfo.FileName = $FilePath
        $startInfo.Arguments = $joinedArguments
        $startInfo.WorkingDirectory = $script:Context.ProjectRoot
        $startInfo.UseShellExecute = $false
        $startInfo.CreateNoWindow = $true
        $startInfo.WindowStyle = [System.Diagnostics.ProcessWindowStyle]::Hidden
        $startInfo.RedirectStandardOutput = $true
        $startInfo.RedirectStandardError = $true
        if ($null -ne $EnvironmentVariables) {
            foreach ($entry in $EnvironmentVariables.GetEnumerator()) {
                $startInfo.EnvironmentVariables[[string]$entry.Key] = [string]$entry.Value
            }
        }

        $jobHandle = New-BsProcessJob
        $process = New-Object System.Diagnostics.Process
        $process.StartInfo = $startInfo
        if (-not $process.Start()) {
            throw "Process could not be started: $FilePath"
        }
        $processStarted = $true
        $processId = $process.Id
        Add-BsProcessToJob -JobHandle $jobHandle -Process $process
        $jobAssigned = $true
        $stdoutTask = $process.StandardOutput.ReadToEndAsync()
        $stderrTask = $process.StandardError.ReadToEndAsync()
        $nextProgressSecond = 30
        $finished = $false

        while (-not $finished) {
            $elapsedMilliseconds = [int][Math]::Min([Int32]::MaxValue, $stopwatch.ElapsedMilliseconds)
            $remainingMilliseconds = ($StepTimeoutSeconds * 1000) - $elapsedMilliseconds
            if ($remainingMilliseconds -le 0) {
                break
            }

            $waitMilliseconds = [int][Math]::Min(1000, $remainingMilliseconds)
            $finished = $process.WaitForExit($waitMilliseconds)
            if ((-not $finished) -and ($stopwatch.Elapsed.TotalSeconds -ge $nextProgressSecond)) {
                Write-BsMessage -Level 'INFO' -Message ('{0} has been running for {1:N0}s...' -f $StepName, $stopwatch.Elapsed.TotalSeconds)
                $nextProgressSecond += 30
            }
        }

        $timedOut = -not $finished
        if ($timedOut) {
            $treeTerminated = $false
            $termination = Stop-BsProcessTree -Process $process
            if ($jobAssigned) {
                $jobTermination = Stop-BsProcessJob -JobHandle $jobHandle -ExitCode ([uint32]$script:ExitTimeout)
            }
            $rootExitedAfterCleanup = $false
            try {
                [void]$process.WaitForExit(5000)
                $rootExitedAfterCleanup = $process.HasExited
            }
            catch {
                $rootExitedAfterCleanup = $false
            }
            $treeTerminated = [bool](
                $jobAssigned -and
                ($null -ne $jobTermination) -and
                $jobTermination.Confirmed -and
                $rootExitedAfterCleanup
            )
        }
        else {
            $process.WaitForExit()
            if ($jobAssigned) {
                $jobTermination = Stop-BsProcessJob -JobHandle $jobHandle -ExitCode 125
                if (-not $jobTermination.Confirmed) {
                    $containmentError = 'Windows Job cleanup could not be confirmed after the process exited.'
                }
            }
        }

        try {
            if ($process.HasExited) {
                $toolExitCode = [int]$process.ExitCode
            }
            else {
                $exitCodeReadError = 'The process was still running when its native exit code was read.'
            }
        }
        catch {
            $exitCodeReadError = $_.Exception.Message
            $toolExitCode = $null
        }

        if ((-not $timedOut) -and ($null -ne $toolExitCode) -and ([int]$toolExitCode -ne 0)) {
            $nativeFailureTreeCleanup = [pscustomobject][ordered]@{
                Confirmed = [bool](($null -ne $jobTermination) -and $jobTermination.Confirmed)
                JobAssigned = $jobAssigned
                JobTerminateSucceeded = if ($null -eq $jobTermination) { $false } else { [bool]$jobTermination.TerminateSucceeded }
                JobActiveProcesses = if ($null -eq $jobTermination) { $null } else { $jobTermination.ActiveProcesses }
                JobTerminateError = if ($null -eq $jobTermination) { $null } else { $jobTermination.TerminateError }
                JobQueryError = if ($null -eq $jobTermination) { $null } else { $jobTermination.QueryError }
                CapturedProcessIds = @()
                RemainingProcessIds = @()
            }
        }

        try {
            if (($null -eq $stdoutTask) -or (-not $stdoutTask.Wait(15000))) {
                throw 'Reading stdout did not finish within 15 seconds.'
            }
            $stdout = [string]$stdoutTask.Result
            if (($null -eq $stderrTask) -or (-not $stderrTask.Wait(15000))) {
                throw 'Reading stderr did not finish within 15 seconds.'
            }
            $stderr = [string]$stderrTask.Result
        }
        catch {
            $outputReadError = $_.Exception.Message
            if (($null -ne $stdoutTask) -and $stdoutTask.IsCompleted -and (-not $stdoutTask.IsFaulted)) {
                $stdout = [string]$stdoutTask.Result
            }
            if (($null -ne $stderrTask) -and $stderrTask.IsCompleted -and (-not $stderrTask.IsFaulted)) {
                $stderr = [string]$stderrTask.Result
            }
        }

        Write-BsTextFile -Path $stdoutPath -Content $stdout
        Write-BsTextFile -Path $stderrPath -Content $stderr
        $stopwatch.Stop()
        $combined = @(
            'COMMAND'
            $commandLine
            ''
            'STDOUT'
            $stdout
            ''
            'STDERR'
            $stderr
        ) -join [Environment]::NewLine
        Write-BsTextFile -Path $combinedLogPath -Content $combined

        return [pscustomobject][ordered]@{
            Planned = $false
            Started = $true
            TimedOut = $timedOut
            ToolExitCode = $toolExitCode
            DurationSeconds = [Math]::Round($stopwatch.Elapsed.TotalSeconds, 3)
            ProcessId = $processId
            StdoutPath = $stdoutPath
            StderrPath = $stderrPath
            CombinedLogPath = $combinedLogPath
            CombinedOutput = $stdout + [Environment]::NewLine + $stderr
            LaunchError = if (($null -eq $outputReadError) -or $timedOut) { $null } else { $outputReadError }
            TreeTerminated = $treeTerminated
            ProcessTreeQuerySucceeded = if ($null -eq $termination) { $true } else { [bool]$termination.ProcessTreeQuerySucceeded }
            TaskKillExitCode = if ($null -eq $termination) { $null } else { $termination.TaskKillExitCode }
            CapturedProcessIds = if ($null -eq $termination) { @() } else { @($termination.CapturedProcessIds) }
            RemainingProcessIds = if ($null -eq $termination) { @() } else { @($termination.RemainingProcessIds) }
            ExitCodeReadError = $exitCodeReadError
            NativeFailureTreeCleanup = $nativeFailureTreeCleanup
            JobAssigned = $jobAssigned
            JobTerminateSucceeded = if ($null -eq $jobTermination) { $null } else { [bool]$jobTermination.TerminateSucceeded }
            JobActiveProcesses = if ($null -eq $jobTermination) { $null } else { $jobTermination.ActiveProcesses }
            JobTerminateError = if ($null -eq $jobTermination) { $null } else { $jobTermination.TerminateError }
            JobQueryError = if ($null -eq $jobTermination) { $null } else { $jobTermination.QueryError }
            ContainmentError = $containmentError
        }
    }
    catch {
        $message = $_.Exception.Message
        $details = ($_ | Format-List * -Force | Out-String)
        if ($processStarted -and ($null -ne $process)) {
            try {
                $processStillRunning = -not $process.HasExited
            }
            catch {
                $processStillRunning = $true
            }
            if ($processStillRunning) {
                try {
                    $treeTerminated = $false
                    $termination = Stop-BsProcessTree -Process $process
                    $treeTerminated = [bool]$termination.Confirmed
                }
                catch {
                    $treeTerminated = $false
                }
            }
        }
        if ($jobAssigned -and ($jobHandle -ne [IntPtr]::Zero)) {
            try {
                $jobTermination = Stop-BsProcessJob -JobHandle $jobHandle -ExitCode ([uint32]$script:ExitInternal)
                if ($processStarted) {
                    try {
                        [void]$process.WaitForExit(5000)
                    }
                    catch {
                        # The launch error below remains authoritative.
                    }
                }
                if ($timedOut) {
                    $treeTerminated = [bool]($jobTermination.Confirmed -and $process.HasExited)
                }
            }
            catch {
                $treeTerminated = $false
                $containmentError = $_.Exception.Message
            }
        }
        if (($null -ne $stdoutTask) -and $stdoutTask.IsCompleted -and (-not $stdoutTask.IsFaulted)) {
            $stdout = [string]$stdoutTask.Result
        }
        if (($null -ne $stderrTask) -and $stderrTask.IsCompleted -and (-not $stderrTask.IsFaulted)) {
            $stderr = [string]$stderrTask.Result
        }
        $stopwatch.Stop()
        Write-BsTextFile -Path $stdoutPath -Content $stdout
        Write-BsTextFile -Path $stderrPath -Content ($stderr + [Environment]::NewLine + $details)
        Write-BsTextFile -Path $combinedLogPath -Content ($commandLine + [Environment]::NewLine + $details)
        return [pscustomobject][ordered]@{
            Planned = $false
            Started = $processStarted
            TimedOut = $timedOut
            ToolExitCode = $toolExitCode
            DurationSeconds = [Math]::Round($stopwatch.Elapsed.TotalSeconds, 3)
            ProcessId = $processId
            StdoutPath = $stdoutPath
            StderrPath = $stderrPath
            CombinedLogPath = $combinedLogPath
            CombinedOutput = $stdout + [Environment]::NewLine + $stderr
            LaunchError = $message
            TreeTerminated = $treeTerminated
            ProcessTreeQuerySucceeded = if ($null -eq $termination) { $false } else { [bool]$termination.ProcessTreeQuerySucceeded }
            TaskKillExitCode = if ($null -eq $termination) { $null } else { $termination.TaskKillExitCode }
            CapturedProcessIds = if ($null -eq $termination) { @() } else { @($termination.CapturedProcessIds) }
            RemainingProcessIds = if ($null -eq $termination) { @() } else { @($termination.RemainingProcessIds) }
            ExitCodeReadError = $exitCodeReadError
            NativeFailureTreeCleanup = $nativeFailureTreeCleanup
            JobAssigned = $jobAssigned
            JobTerminateSucceeded = if ($null -eq $jobTermination) { $null } else { [bool]$jobTermination.TerminateSucceeded }
            JobActiveProcesses = if ($null -eq $jobTermination) { $null } else { $jobTermination.ActiveProcesses }
            JobTerminateError = if ($null -eq $jobTermination) { $null } else { $jobTermination.TerminateError }
            JobQueryError = if ($null -eq $jobTermination) { $null } else { $jobTermination.QueryError }
            ContainmentError = $containmentError
        }
    }
    finally {
        if ($jobHandle -ne [IntPtr]::Zero) {
            Close-BsProcessJob -JobHandle $jobHandle
            $jobHandle = [IntPtr]::Zero
        }
        if ($null -ne $process) {
            $process.Dispose()
        }
    }
}

function New-BsAnalysis {
    param(
        [Parameter(Mandatory = $true)][string]$Status,
        [Parameter(Mandatory = $true)][string]$Diagnostic,
        [int]$RunnerExitCode = 0,
        [hashtable]$Metrics
    )

    if ($null -eq $Metrics) {
        $Metrics = @{}
    }
    return [pscustomobject]@{
        Status = $Status
        Diagnostic = $Diagnostic
        RunnerExitCode = $RunnerExitCode
        Metrics = $Metrics
    }
}

function Add-BsStepRecord {
    param(
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)][string]$Status,
        [Parameter(Mandatory = $true)][string]$Diagnostic,
        $ToolExitCode,
        [Parameter(Mandatory = $true)][int]$RunnerExitCode,
        [Parameter(Mandatory = $true)][string]$ExitSource,
        [Parameter(Mandatory = $true)][double]$DurationSeconds,
        $ProcessId,
        $TimedOut,
        $LogPath,
        [hashtable]$Metrics
    )

    if ($null -eq $Metrics) {
        $Metrics = @{}
    }

    $record = [pscustomobject][ordered]@{
        name = $Name
        status = $Status
        diagnostic = $Diagnostic
        toolExitCode = $ToolExitCode
        runnerExitCode = $RunnerExitCode
        exitSource = $ExitSource
        durationSeconds = $DurationSeconds
        processId = $ProcessId
        timedOut = [bool]$TimedOut
        logPath = $LogPath
        metrics = $Metrics
    }
    [void]$script:RunState.steps.Add($record)
    Save-BsRunState
    return $record
}

function Show-BsFailureTail {
    param([string]$Path)

    if ((-not [string]::IsNullOrWhiteSpace($Path)) -and (Test-Path -LiteralPath $Path -PathType Leaf)) {
        Write-Host 'Relevant log tail:' -ForegroundColor DarkGray
        Get-Content -LiteralPath $Path -Tail 12 | ForEach-Object {
            if (-not [string]::IsNullOrWhiteSpace($_)) {
                Write-Host ('  ' + $_) -ForegroundColor DarkGray
            }
        }
    }
}

function Invoke-BsExternalStep {
    param(
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)][string]$FilePath,
        [Parameter(Mandatory = $true)][AllowEmptyString()][string[]]$ArgumentList,
        [Parameter(Mandatory = $true)][int]$StepTimeoutSeconds,
        [Parameter(Mandatory = $true)][scriptblock]$Analyzer,
        [hashtable]$EnvironmentVariables
    )

    if ($PlanOnly) {
        Write-BsMessage -Level 'PLAN' -Message "$Name — command prepared without launching it."
    }
    else {
        Write-BsMessage -Level 'RUN' -Message ('{0} — timeout {1:N0} minutes.' -f $Name, ($StepTimeoutSeconds / 60.0))
    }

    $raw = Invoke-BsProcess -StepName $Name -FilePath $FilePath -ArgumentList $ArgumentList `
        -StepTimeoutSeconds $StepTimeoutSeconds -EnvironmentVariables $EnvironmentVariables

    if ($raw.Planned) {
        $record = Add-BsStepRecord -Name $Name -Status 'PLANNED' -Diagnostic 'PLAN_ONLY' `
            -ToolExitCode 0 -RunnerExitCode 0 -ExitSource 'None' -DurationSeconds 0 `
            -ProcessId $null -TimedOut $false -LogPath $raw.CombinedLogPath
        return $record
    }

    if ($raw.TimedOut) {
        $timeoutDiagnostic = 'TIMEOUT_TREE_TERMINATED'
        if (-not $raw.TreeTerminated) {
            $timeoutDiagnostic = 'TIMEOUT_TREE_TERMINATION_UNCONFIRMED'
        }
        $record = Add-BsStepRecord -Name $Name -Status 'FAILED' -Diagnostic $timeoutDiagnostic `
            -ToolExitCode $raw.ToolExitCode -RunnerExitCode $script:ExitTimeout -ExitSource 'Runner' `
            -DurationSeconds $raw.DurationSeconds -ProcessId $raw.ProcessId -TimedOut $true `
            -LogPath $raw.CombinedLogPath -Metrics @{
                treeTerminated = [bool]$raw.TreeTerminated
                processTreeQuerySucceeded = [bool]$raw.ProcessTreeQuerySucceeded
                taskKillExitCode = $raw.TaskKillExitCode
                capturedProcessIds = @($raw.CapturedProcessIds)
                remainingProcessIds = @($raw.RemainingProcessIds)
                jobAssigned = [bool]$raw.JobAssigned
                jobTerminateSucceeded = $raw.JobTerminateSucceeded
                jobActiveProcesses = $raw.JobActiveProcesses
                jobTerminateError = $raw.JobTerminateError
                jobQueryError = $raw.JobQueryError
            }
        if ($raw.TreeTerminated) {
            Write-BsMessage -Level 'FAIL' -Message "$Name timed out; termination of the complete process tree was confirmed."
        }
        else {
            Write-BsMessage -Level 'FAIL' -Message "$Name timed out; complete process-tree termination could not be confirmed."
        }
        Write-BsMessage -Level 'INFO' -Message "Log: $($raw.CombinedLogPath)"
        return $record
    }

    if ($null -ne $raw.LaunchError) {
        $record = Add-BsStepRecord -Name $Name -Status 'FAILED' -Diagnostic 'PROCESS_LAUNCH_FAILED' `
            -ToolExitCode $null -RunnerExitCode $script:ExitInternal -ExitSource 'Runner' `
            -DurationSeconds $raw.DurationSeconds -ProcessId $raw.ProcessId -TimedOut $false `
            -LogPath $raw.CombinedLogPath
        Write-BsMessage -Level 'FAIL' -Message "$Name nu a putut porni: $($raw.LaunchError)"
        Write-BsMessage -Level 'INFO' -Message "Log: $($raw.CombinedLogPath)"
        return $record
    }

    if ($null -ne $raw.ContainmentError) {
        $record = Add-BsStepRecord -Name $Name -Status 'FAILED' -Diagnostic 'PROCESS_CONTAINMENT_FAILED' `
            -ToolExitCode $raw.ToolExitCode -RunnerExitCode $script:ExitInternal -ExitSource 'Runner' `
            -DurationSeconds $raw.DurationSeconds -ProcessId $raw.ProcessId -TimedOut $false `
            -LogPath $raw.CombinedLogPath -Metrics @{
                jobAssigned = [bool]$raw.JobAssigned
                jobTerminateSucceeded = $raw.JobTerminateSucceeded
                jobActiveProcesses = $raw.JobActiveProcesses
                jobTerminateError = $raw.JobTerminateError
                jobQueryError = $raw.JobQueryError
                containmentError = $raw.ContainmentError
            }
        Write-BsMessage -Level 'FAIL' -Message "$Name exited, but child-process containment could not be confirmed."
        Write-BsMessage -Level 'INFO' -Message "Log: $($raw.CombinedLogPath)"
        return $record
    }

    if ($null -eq $raw.ToolExitCode) {
        $record = Add-BsStepRecord -Name $Name -Status 'FAILED' -Diagnostic 'NATIVE_EXIT_CODE_UNAVAILABLE' `
            -ToolExitCode $null -RunnerExitCode $script:ExitInternal -ExitSource 'Runner' `
            -DurationSeconds $raw.DurationSeconds -ProcessId $raw.ProcessId -TimedOut $false `
            -LogPath $raw.CombinedLogPath -Metrics @{ exitCodeReadError = $raw.ExitCodeReadError }
        Write-BsMessage -Level 'FAIL' -Message "$Name exited, but its native exit code could not be read."
        Write-BsMessage -Level 'INFO' -Message "Log: $($raw.CombinedLogPath)"
        return $record
    }

    if ([int]$raw.ToolExitCode -ne 0) {
        $failureCleanupMetrics = @{}
        if ($null -ne $raw.NativeFailureTreeCleanup) {
            $failureCleanupMetrics = @{
                treeCleanupConfirmed = [bool]$raw.NativeFailureTreeCleanup.Confirmed
                jobAssigned = [bool]$raw.NativeFailureTreeCleanup.JobAssigned
                jobTerminateSucceeded = [bool]$raw.NativeFailureTreeCleanup.JobTerminateSucceeded
                jobActiveProcesses = $raw.NativeFailureTreeCleanup.JobActiveProcesses
                jobTerminateError = $raw.NativeFailureTreeCleanup.JobTerminateError
                jobQueryError = $raw.NativeFailureTreeCleanup.JobQueryError
                capturedProcessIds = @($raw.NativeFailureTreeCleanup.CapturedProcessIds)
                remainingProcessIds = @($raw.NativeFailureTreeCleanup.RemainingProcessIds)
            }
        }
        $record = Add-BsStepRecord -Name $Name -Status 'FAILED' -Diagnostic 'NATIVE_EXIT_NONZERO' `
            -ToolExitCode $raw.ToolExitCode -RunnerExitCode ([int]$raw.ToolExitCode) -ExitSource 'Tool' `
            -DurationSeconds $raw.DurationSeconds -ProcessId $raw.ProcessId -TimedOut $false `
            -LogPath $raw.CombinedLogPath -Metrics $failureCleanupMetrics
        Write-BsMessage -Level 'FAIL' -Message "$Name returned native exit code $($raw.ToolExitCode)."
        Show-BsFailureTail -Path $raw.CombinedLogPath
        Write-BsMessage -Level 'INFO' -Message "Log: $($raw.CombinedLogPath)"
        return $record
    }

    $analysis = & $Analyzer $raw.CombinedOutput
    $exitSource = 'None'
    if ([int]$analysis.RunnerExitCode -ne 0) {
        $exitSource = 'Runner'
    }
    $record = Add-BsStepRecord -Name $Name -Status $analysis.Status -Diagnostic $analysis.Diagnostic `
        -ToolExitCode $raw.ToolExitCode -RunnerExitCode ([int]$analysis.RunnerExitCode) `
        -ExitSource $exitSource -DurationSeconds $raw.DurationSeconds -ProcessId $raw.ProcessId `
        -TimedOut $false -LogPath $raw.CombinedLogPath -Metrics $analysis.Metrics

    if ([int]$analysis.RunnerExitCode -ne 0) {
        Write-BsMessage -Level 'FAIL' -Message "$Name failed semantic verification: $($analysis.Diagnostic)."
        Show-BsFailureTail -Path $raw.CombinedLogPath
        Write-BsMessage -Level 'INFO' -Message "Log: $($raw.CombinedLogPath)"
    }
    elseif ($analysis.Status -like 'SKIPPED*') {
        Write-BsMessage -Level 'SKIP' -Message "$Name — $($analysis.Diagnostic)."
    }
    elseif ($analysis.Status -eq 'PASS_WITH_WARNINGS') {
        Write-BsMessage -Level 'WARN' -Message "$Name — PASS with warnings. Log: $($raw.CombinedLogPath)"
    }
    elseif ($analysis.Status -eq 'PASS_WITH_SKIPS') {
        Write-BsMessage -Level 'SKIP' -Message "$Name — PASS with controlled omissions. Log: $($raw.CombinedLogPath)"
    }
    else {
        Write-BsMessage -Level 'PASS' -Message ('{0} — {1:N2}s.' -f $Name, $raw.DurationSeconds)
    }

    return $record
}

function Invoke-BsDoctor {
    $doctorStopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    $script:StepNumber++
    $stepDirectory = Join-Path $script:Context.RunRoot ('Steps\{0:D2}-Doctor' -f $script:StepNumber)
    [void](New-Item -ItemType Directory -Path $stepDirectory -Force)
    $logPath = Join-Path $stepDirectory 'doctor.log'
    $lines = New-Object System.Collections.ArrayList
    $failures = New-Object System.Collections.ArrayList
    $warnings = New-Object System.Collections.ArrayList
    $dotNetVersion = $null
    $windowsSdkVersion = $null
    $visualStudioVersion = $null
    $msvcToolsetVersion = $null

    function Add-DoctorCheck {
        param([string]$State, [string]$Text)
        [void]$lines.Add(('[{0}] {1}' -f $State, $Text))
        if ($State -eq 'FAIL') {
            [void]$failures.Add($Text)
        }
        elseif ($State -eq 'WARN') {
            [void]$warnings.Add($Text)
        }
    }

    Add-DoctorCheck -State 'PASS' -Text "Project: $($script:Context.ProjectFile)"
    Add-DoctorCheck -State 'PASS' -Text ("Engine: {0} CL {1} ({2})" -f $script:Context.Engine.Version,
        $script:Context.Engine.Changelist, $script:Context.Engine.Source)

    foreach ($requiredPath in @(
        $script:Context.Engine.DotNetExe,
        $script:Context.Engine.UbtDll,
        $script:Context.Engine.EditorCmd,
        (Join-Path $script:Context.ProjectRoot 'Source\BrokenStreets.Target.cs'),
        (Join-Path $script:Context.ProjectRoot 'Source\BrokenStreetsEditor.Target.cs'),
        (Join-Path $script:Context.ProjectRoot 'Source\BrokenStreets\BrokenStreets.Build.cs')
    )) {
        if (Test-Path -LiteralPath $requiredPath -PathType Leaf) {
            Add-DoctorCheck -State 'PASS' -Text "Exists: $requiredPath"
        }
        else {
            Add-DoctorCheck -State 'FAIL' -Text "Missing: $requiredPath"
        }
    }

    $localApplicationData = [Environment]::GetFolderPath([Environment+SpecialFolder]::LocalApplicationData)
    $ubtWritableRoots = @(
        (Join-Path $localApplicationData 'UnrealBuildTool'),
        (Join-Path $localApplicationData 'UnrealEngine\Intermediate\Build')
    )
    foreach ($ubtWritableRoot in $ubtWritableRoots) {
        $ubtProbePath = Join-Path $ubtWritableRoot ('bs009-write-probe-' + [Guid]::NewGuid().ToString('N') + '.tmp')
        try {
            [void](New-Item -ItemType Directory -Path $ubtWritableRoot -Force)
            Write-BsTextFile -Path $ubtProbePath -Content 'probe'
            [System.IO.File]::Delete($ubtProbePath)
            Add-DoctorCheck -State 'PASS' -Text "UnrealBuildTool poate folosi $ubtWritableRoot"
        }
        catch {
            if (Test-Path -LiteralPath $ubtProbePath -PathType Leaf) {
                [System.IO.File]::Delete($ubtProbePath)
            }
            Add-DoctorCheck -State 'FAIL' -Text "UnrealBuildTool nu poate folosi $ubtWritableRoot"
        }
    }

    $driveRoot = [System.IO.Path]::GetPathRoot($script:Context.ProjectRoot)
    $driveInfo = New-Object System.IO.DriveInfo($driveRoot)
    if (-not $driveInfo.IsReady) {
        Add-DoctorCheck -State 'FAIL' -Text "Drive $driveRoot is not ready."
        $freeGb = 0.0
    }
    else {
        $freeGb = [Math]::Round(([double]$driveInfo.AvailableFreeSpace / 1GB), 2)
    }
    $minimumGb = [double]$script:Context.Config.minimumFreeDiskGb
    if ($freeGb -ge $minimumGb) {
        Add-DoctorCheck -State 'PASS' -Text ("Free space: {0:N2} GB (minimum {1:N0} GB)." -f $freeGb, $minimumGb)
    }
    else {
        Add-DoctorCheck -State 'FAIL' -Text ("Insufficient free space: {0:N2} GB; minimum {1:N0} GB." -f $freeGb, $minimumGb)
    }

    $editorProcesses = @(Get-Process -Name 'UnrealEditor*' -ErrorAction SilentlyContinue)
    if ($editorProcesses.Count -gt 0) {
        if ($Action -eq 'Doctor') {
            Add-DoctorCheck -State 'WARN' -Text 'Unreal Editor is running; close it before Generate/Build/Test/Validate/Cook.'
        }
        else {
            Add-DoctorCheck -State 'FAIL' -Text 'Unreal Editor is running. Close it before the requested action.'
        }
    }
    else {
        Add-DoctorCheck -State 'PASS' -Text 'Unreal Editor is closed.'
    }

    if (($failures.Count -eq 0) -and (-not $PlanOnly)) {
        $probeRoot = Join-Path $stepDirectory 'ToolchainProbes'
        [void](New-Item -ItemType Directory -Path $probeRoot -Force)
        $probeTimeout = [int]$script:Context.Config.doctorProbeTimeoutSeconds
        $dotnetEnvironment = Get-BsDotNetEnvironment

        $dotnetProbe = Invoke-BsProcess -StepName 'Doctor-DotNet' `
            -FilePath $script:Context.Engine.DotNetExe -ArgumentList @('--version') `
            -StepTimeoutSeconds $probeTimeout -EnvironmentVariables $dotnetEnvironment `
            -ExplicitStepDirectory (Join-Path $probeRoot '01-DotNet') -ForceExecution
        if ($dotnetProbe.Started -and (-not $dotnetProbe.TimedOut) -and
            ([int]$dotnetProbe.ToolExitCode -eq 0) -and
            ($dotnetProbe.CombinedOutput -match '(?m)^\s*(\d+\.\d+\.\d+(?:[-+][^\s]+)?)\s*$')) {
            $dotNetVersion = $Matches[1]
            Add-DoctorCheck -State 'PASS' -Text "Bundled .NET runs: $dotNetVersion"
        }
        else {
            Add-DoctorCheck -State 'FAIL' -Text "Bundled .NET failed its probe. Log: $($dotnetProbe.CombinedLogPath)"
        }

        if ($null -ne $dotNetVersion) {
            $ubtDetailedLogPath = Join-Path $probeRoot '02-Win64Sdk\UnrealBuildTool.log'
            $ubtArguments = @(
                $script:Context.Engine.UbtDll,
                '-Mode=ValidatePlatforms',
                '-Platforms=Win64',
                '-OutputSDKs',
                ('-Project=' + $script:Context.ProjectFile),
                ('-Log=' + $ubtDetailedLogPath),
                '-Verbose',
                '-Timestamps'
            )
            $ubtProbe = Invoke-BsProcess -StepName 'Doctor-Win64Sdk' `
                -FilePath $script:Context.Engine.DotNetExe -ArgumentList $ubtArguments `
                -StepTimeoutSeconds $probeTimeout -EnvironmentVariables $dotnetEnvironment `
                -ExplicitStepDirectory (Join-Path $probeRoot '02-Win64Sdk') -ForceExecution
            $ubtAnalysisOutput = $ubtProbe.CombinedOutput
            if (Test-Path -LiteralPath $ubtDetailedLogPath -PathType Leaf) {
                $ubtAnalysisOutput += [Environment]::NewLine +
                    (Read-BsTextFileWithRetry -Path $ubtDetailedLogPath)
            }
            $sdkMatch = [regex]::Match(
                $ubtAnalysisOutput,
                '##PlatformValidate:\s*Win64\s+VALID\s+(\S+)',
                [System.Text.RegularExpressions.RegexOptions]::IgnoreCase
            )
            $installedSdkMatch = [regex]::Match(
                $ubtAnalysisOutput,
                'Win64 Installed SDK\(s\):.*?CurrentVersion_Sdk=(?<sdk>[^,\s]*).*?CurrentVersion_AutoSdk=(?<autosdk>[^,\s]*)',
                [System.Text.RegularExpressions.RegexOptions]::IgnoreCase
            )
            if ($ubtProbe.Started -and (-not $ubtProbe.TimedOut) -and
                ([int]$ubtProbe.ToolExitCode -eq 0) -and $sdkMatch.Success -and
                $installedSdkMatch.Success) {
                $windowsSdkVersion = $installedSdkMatch.Groups['sdk'].Value
                if (-not [string]::IsNullOrWhiteSpace($installedSdkMatch.Groups['autosdk'].Value)) {
                    $windowsSdkVersion = $installedSdkMatch.Groups['autosdk'].Value
                }
                $expectedSdk = [string]$script:Context.Config.expectedWindowsSdk
                if (($sdkMatch.Groups[1].Value -eq $expectedSdk) -and
                    ($windowsSdkVersion -eq $expectedSdk)) {
                    Add-DoctorCheck -State 'PASS' -Text "UnrealBuildTool confirms Win64 SDK $windowsSdkVersion"
                }
                else {
                    Add-DoctorCheck -State 'FAIL' -Text "Detected Win64 SDK is $windowsSdkVersion; RunnerConfig requires $expectedSdk."
                }
            }
            else {
                Add-DoctorCheck -State 'FAIL' -Text "UnrealBuildTool did not confirm the Win64 platform. Log: $($ubtProbe.CombinedLogPath)"
            }
        }

        $vswherePath = Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio\Installer\vswhere.exe'
        if (-not (Test-Path -LiteralPath $vswherePath -PathType Leaf)) {
            Add-DoctorCheck -State 'FAIL' -Text "Visual Studio Installer discovery tool is missing: $vswherePath"
        }
        else {
            $vswhereArguments = @(
                '-latest',
                '-version',
                ('[{0}.0,{1}.0)' -f [int]$script:Context.Config.expectedVisualStudioMajor,
                    ([int]$script:Context.Config.expectedVisualStudioMajor + 1)),
                '-products',
                '*',
                '-requires',
                'Microsoft.VisualStudio.Component.VC.Tools.x86.x64',
                '-format',
                'json',
                '-utf8'
            )
            $vswhereProbe = Invoke-BsProcess -StepName 'Doctor-VisualStudio' `
                -FilePath $vswherePath -ArgumentList $vswhereArguments `
                -StepTimeoutSeconds $probeTimeout `
                -ExplicitStepDirectory (Join-Path $probeRoot '03-VisualStudio') -ForceExecution
            $visualStudio = $null
            if ($vswhereProbe.Started -and (-not $vswhereProbe.TimedOut) -and
                ([int]$vswhereProbe.ToolExitCode -eq 0)) {
                try {
                    $vswhereStdout = Read-BsTextFileWithRetry -Path $vswhereProbe.StdoutPath
                    $installations = @($vswhereStdout | ConvertFrom-Json -ErrorAction Stop)
                    $expectedVsMajor = [int]$script:Context.Config.expectedVisualStudioMajor
                    $visualStudio = @($installations | Where-Object {
                        try { ([version]$_.installationVersion).Major -eq $expectedVsMajor } catch { $false }
                    } | Select-Object -First 1)
                    if ($visualStudio.Count -gt 0) {
                        $visualStudio = $visualStudio[0]
                    }
                    else {
                        $visualStudio = $null
                    }
                }
                catch {
                    $visualStudio = $null
                }
            }

            if ($null -eq $visualStudio) {
                Add-DoctorCheck -State 'FAIL' -Text "Visual Studio with a compatible C++ toolchain was not detected. Log: $($vswhereProbe.CombinedLogPath)"
            }
            else {
                $visualStudioVersion = [string]$visualStudio.installationVersion
                Add-DoctorCheck -State 'PASS' -Text "Visual Studio C++ detected: $visualStudioVersion"

                $msvcRoot = Join-Path ([string]$visualStudio.installationPath) 'VC\Tools\MSVC'
                $expectedMsvcFamily = [string]$script:Context.Config.expectedMsvcFamily
                $toolsetDirectories = @()
                if (Test-Path -LiteralPath $msvcRoot -PathType Container) {
                    $toolsetDirectories = @(Get-ChildItem -LiteralPath $msvcRoot -Directory | ForEach-Object {
                        $parsedToolsetVersion = $null
                        if ($_.Name.StartsWith($expectedMsvcFamily + '.', [System.StringComparison]::OrdinalIgnoreCase) -and
                            [version]::TryParse($_.Name, [ref]$parsedToolsetVersion)) {
                            [pscustomobject]@{
                                Directory = $_
                                Version = $parsedToolsetVersion
                            }
                        }
                    } | Sort-Object Version -Descending)
                }

                $compilerPath = $null
                foreach ($toolsetDirectory in $toolsetDirectories) {
                    $candidateCompiler = Join-Path $toolsetDirectory.Directory.FullName 'bin\Hostx64\x64\cl.exe'
                    if (Test-Path -LiteralPath $candidateCompiler -PathType Leaf) {
                        $compilerPath = $candidateCompiler
                        $msvcToolsetVersion = $toolsetDirectory.Directory.Name
                        break
                    }
                }

                if ($null -eq $compilerPath) {
                    Add-DoctorCheck -State 'FAIL' -Text "The MSVC $expectedMsvcFamily x64 toolset required by UE 5.8.2 is missing."
                }
                else {
                    $toolsetRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $compilerPath)))
                    $linkerPath = Join-Path (Split-Path -Parent $compilerPath) 'link.exe'
                    $runtimeLibraryPath = Join-Path $toolsetRoot 'lib\x64\libcpmt.lib'
                    if ((-not (Test-Path -LiteralPath $linkerPath -PathType Leaf)) -or
                        (-not (Test-Path -LiteralPath $runtimeLibraryPath -PathType Leaf))) {
                        Add-DoctorCheck -State 'FAIL' -Text "MSVC toolset $msvcToolsetVersion does not contain the x64 linker or runtime library."
                    }
                    $compilerProbe = Invoke-BsProcess -StepName 'Doctor-Msvc' `
                        -FilePath $compilerPath -ArgumentList @('/?') `
                        -StepTimeoutSeconds $probeTimeout `
                        -ExplicitStepDirectory (Join-Path $probeRoot '04-Msvc') -ForceExecution
                    if ($compilerProbe.Started -and (-not $compilerProbe.TimedOut) -and
                        ([int]$compilerProbe.ToolExitCode -eq 0)) {
                        Add-DoctorCheck -State 'PASS' -Text "MSVC x64 runs: toolset $msvcToolsetVersion"
                    }
                    else {
                        Add-DoctorCheck -State 'FAIL' -Text "MSVC x64 failed its probe. Log: $($compilerProbe.CombinedLogPath)"
                    }
                }
            }
        }
    }
    elseif ($PlanOnly) {
        [void]$lines.Add('[PLAN] External .NET/UBT/MSVC probes are described but not launched in PlanOnly.')
    }
    else {
        [void]$lines.Add('[SKIP] .NET/UBT/MSVC probes were not launched because preflight had already failed.')
    }

    $doctorStopwatch.Stop()
    $doctorDurationSeconds = [Math]::Round($doctorStopwatch.Elapsed.TotalSeconds, 3)
    Write-BsTextFile -Path $logPath -Content (($lines -join [Environment]::NewLine) + [Environment]::NewLine)

    if ($failures.Count -gt 0) {
        $record = Add-BsStepRecord -Name 'Doctor' -Status 'FAILED' -Diagnostic 'PREFLIGHT_FAILED' `
            -ToolExitCode $null -RunnerExitCode $script:ExitPreflight -ExitSource 'Runner' `
            -DurationSeconds $doctorDurationSeconds -ProcessId $null -TimedOut $false -LogPath $logPath `
            -Metrics @{
                failures = $failures.Count
                warnings = $warnings.Count
                dotNetVersion = $dotNetVersion
                windowsSdk = $windowsSdkVersion
                visualStudioVersion = $visualStudioVersion
                msvcToolset = $msvcToolsetVersion
            }
        Write-BsMessage -Level 'FAIL' -Message "Doctor — $($failures.Count) checks failed. Log: $logPath"
        foreach ($failure in $failures) {
            Write-Host ('  - ' + $failure) -ForegroundColor Red
        }
        return $record
    }

    $status = 'PASS'
    $diagnostic = 'PREFLIGHT_OK'
    if ($PlanOnly) {
        $status = 'PLANNED'
        $diagnostic = 'PLAN_ONLY'
    }
    elseif ($warnings.Count -gt 0) {
        $status = 'PASS_WITH_WARNINGS'
    }
    $record = Add-BsStepRecord -Name 'Doctor' -Status $status -Diagnostic $diagnostic `
        -ToolExitCode 0 -RunnerExitCode 0 -ExitSource 'None' -DurationSeconds $doctorDurationSeconds `
        -ProcessId $null -TimedOut $false -LogPath $logPath `
        -Metrics @{
            failures = 0
            warnings = $warnings.Count
            freeDiskGb = $freeGb
            dotNetVersion = $dotNetVersion
            windowsSdk = $windowsSdkVersion
            visualStudioVersion = $visualStudioVersion
            msvcToolset = $msvcToolsetVersion
        }
    if ($PlanOnly) {
        Write-BsMessage -Level 'PLAN' -Message 'Doctor — external checks are planned without launching them.'
    }
    elseif ($warnings.Count -gt 0) {
        Write-BsMessage -Level 'WARN' -Message "Doctor — PASS with $($warnings.Count) warnings. Log: $logPath"
    }
    else {
        Write-BsMessage -Level 'PASS' -Message 'Doctor — toolchain is ready.'
    }
    return $record
}

function Invoke-BsGenerate {
    $arguments = @(
        $script:Context.Engine.UbtDll,
        '-Mode=GenerateProjectFiles',
        ('-Project=' + $script:Context.ProjectFile),
        '-Game',
        '-CurrentPlatform',
        [string]$script:Context.Config.visualStudioArgument,
        '-Automated',
        '-Progress',
        '-WaitMutex'
    )

    $analyzer = {
        param($output)
        $solution = Join-Path $script:Context.ProjectRoot 'BrokenStreets.sln'
        $solutionX = Join-Path $script:Context.ProjectRoot 'BrokenStreets.slnx'
        if (($output -notmatch 'Result:\s*Succeeded') -or
            (-not (Test-Path -LiteralPath $solution -PathType Leaf)) -or
            (-not (Test-Path -LiteralPath $solutionX -PathType Leaf))) {
            return New-BsAnalysis -Status 'FAILED' -Diagnostic 'GENERATION_MARKER_OR_OUTPUT_MISSING' `
                -RunnerExitCode $script:ExitSemantic
        }
        return New-BsAnalysis -Status 'PASS' -Diagnostic 'GENERATED'
    }

    return Invoke-BsExternalStep -Name 'Generate' -FilePath $script:Context.Engine.DotNetExe `
        -ArgumentList $arguments -StepTimeoutSeconds (Get-BsTimeoutSeconds -StepName 'Generate') `
        -Analyzer $analyzer -EnvironmentVariables (Get-BsDotNetEnvironment)
}

function Invoke-BsBuild {
    $arguments = @(
        $script:Context.Engine.UbtDll,
        [string]$script:Context.Config.editorTarget,
        [string]$script:Context.Config.platform,
        [string]$script:Context.Config.configuration,
        ('-Project=' + $script:Context.ProjectFile),
        '-WaitMutex',
        '-NoHotReloadFromIDE'
    )

    $analyzer = {
        param($output)
        $binary = Join-Path $script:Context.ProjectRoot 'Binaries\Win64\UnrealEditor-BrokenStreets.dll'
        if (($output -notmatch 'Result:\s*Succeeded') -or
            (-not (Test-Path -LiteralPath $binary -PathType Leaf))) {
            return New-BsAnalysis -Status 'FAILED' -Diagnostic 'BUILD_MARKER_OR_BINARY_MISSING' `
                -RunnerExitCode $script:ExitSemantic
        }
        return New-BsAnalysis -Status 'PASS' -Diagnostic 'BUILT'
    }

    return Invoke-BsExternalStep -Name 'Build' -FilePath $script:Context.Engine.DotNetExe `
        -ArgumentList $arguments -StepTimeoutSeconds (Get-BsTimeoutSeconds -StepName 'Build') `
        -Analyzer $analyzer -EnvironmentVariables (Get-BsDotNetEnvironment)
}

function Invoke-BsTest {
    $filter = [string]$script:Context.Config.testFilter
    if ($filter -notmatch '^[A-Za-z0-9_.:+ -]+$') {
        throw "Test filter contains unsafe characters: $filter"
    }

    $nextStepNumber = $script:StepNumber + 1
    $stepDirectory = Join-Path $script:Context.RunRoot ('Steps\{0:D2}-Test' -f $nextStepNumber)
    $reportPath = Join-Path $stepDirectory 'TestReport'
    $unrealLogPath = Join-Path $stepDirectory 'Unreal.log'
    $execCommands = 'Automation AllowZeroTestResults,Automation RunTests {0},Automation SoftQuit' -f $filter
    $arguments = @(
        $script:Context.ProjectFile,
        '-unattended',
        '-nop4',
        '-nopause',
        '-nosplash',
        '-NullRHI',
        '-NoSound',
        '-culture=en',
        '-language=en',
        '-stdout',
        '-FullStdOutLogOutput',
        '-CrashForUAT',
        '-NoLogTimes',
        ('-ReportExportPath=' + $reportPath),
        ('-AbsLog=' + $unrealLogPath),
        ('-ExecCmds=' + $execCommands)
    )

    $analyzer = {
        param($output)
        $terminal = [regex]::Match(
            $output,
            '\*{4}\s+TEST COMPLETE\.\s+EXIT CODE:\s+(-?\d+)\s+\*{4}',
            [System.Text.RegularExpressions.RegexOptions]::IgnoreCase
        )
        $queue = [regex]::Match(
            $output,
            'Automation Test Queue Empty\s+(\d+)\s+tests performed\.',
            [System.Text.RegularExpressions.RegexOptions]::IgnoreCase
        )

        if ((-not $terminal.Success) -or ([int]$terminal.Groups[1].Value -ne 0) -or (-not $queue.Success)) {
            return New-BsAnalysis -Status 'FAILED' -Diagnostic 'AUTOMATION_TERMINAL_MARKER_MISSING_OR_FAILED' `
                -RunnerExitCode $script:ExitSemantic
        }

        $testCount = [int]$queue.Groups[1].Value
        if ($testCount -eq 0) {
            $zeroAllowed = [bool]$script:Context.Config.allowNoTests
            if ((-not $zeroAllowed) -or ($output -notmatch "No automation tests matched '")) {
                return New-BsAnalysis -Status 'FAILED' -Diagnostic 'NO_TESTS_NOT_ALLOWED_OR_UNCONFIRMED' `
                    -RunnerExitCode $script:ExitSemantic -Metrics @{ testsPerformed = 0 }
            }
            return New-BsAnalysis -Status 'SKIPPED_NO_TESTS' -Diagnostic 'NO_PROJECT_TESTS_UNTIL_BS_010' `
                -Metrics @{ testsPerformed = 0 }
        }

        $successCount = [regex]::Matches(
            $output,
            'Test Completed\.\s+Result=\{Success\}',
            [System.Text.RegularExpressions.RegexOptions]::IgnoreCase
        ).Count
        $failureCount = [regex]::Matches(
            $output,
            'Test Completed\.\s+Result=\{Fail\}',
            [System.Text.RegularExpressions.RegexOptions]::IgnoreCase
        ).Count
        $skippedCount = [regex]::Matches(
            $output,
            'Test Completed\.\s+Result=\{Skipped\}',
            [System.Text.RegularExpressions.RegexOptions]::IgnoreCase
        ).Count
        $metrics = @{
            testsPerformed = $testCount
            succeeded = $successCount
            failed = $failureCount
            skipped = $skippedCount
        }

        if (($failureCount -gt 0) -or ($output -match 'Setting GIsCriticalError due to test failures')) {
            return New-BsAnalysis -Status 'FAILED' -Diagnostic 'AUTOMATION_REPORTED_FAILURE' `
                -RunnerExitCode $script:ExitSemantic -Metrics $metrics
        }

        if (($successCount + $failureCount + $skippedCount) -ne $testCount) {
            return New-BsAnalysis -Status 'FAILED' -Diagnostic 'AUTOMATION_RESULT_COUNT_MISMATCH' `
                -RunnerExitCode $script:ExitSemantic -Metrics $metrics
        }

        $reportIndex = Join-Path $reportPath 'index.json'
        if (-not (Test-Path -LiteralPath $reportIndex -PathType Leaf)) {
            return New-BsAnalysis -Status 'FAILED' -Diagnostic 'AUTOMATION_REPORT_MISSING' `
                -RunnerExitCode $script:ExitSemantic -Metrics $metrics
        }

        if ($skippedCount -gt 0) {
            return New-BsAnalysis -Status 'PASS_WITH_SKIPS' -Diagnostic 'TESTS_PASSED_WITH_SKIPS' `
                -Metrics $metrics
        }
        return New-BsAnalysis -Status 'PASS' -Diagnostic 'TESTS_PASSED' -Metrics $metrics
    }

    return Invoke-BsExternalStep -Name 'Test' -FilePath $script:Context.Engine.EditorCmd `
        -ArgumentList $arguments -StepTimeoutSeconds (Get-BsTimeoutSeconds -StepName 'Test') `
        -Analyzer $analyzer
}

function Add-BsAssetManifestRoot {
    param(
        [Parameter(Mandatory = $true)][string]$ContentRoot,
        [Parameter(Mandatory = $true)][string]$MountRoot,
        [Parameter(Mandatory = $true)][AllowEmptyCollection()][System.Collections.ArrayList]$Manifest,
        [Parameter(Mandatory = $true)][AllowEmptyCollection()][hashtable]$SeenPackages
    )

    if (-not (Test-Path -LiteralPath $ContentRoot -PathType Container)) {
        return
    }

    $resolvedContentRoot = [System.IO.Path]::GetFullPath($ContentRoot).TrimEnd('\')
    $contentPrefix = $resolvedContentRoot + '\'
    foreach ($assetFile in (Get-ChildItem -LiteralPath $resolvedContentRoot -File -Recurse | Where-Object {
        $_.Extension -in @('.uasset', '.umap')
    })) {
        if (-not $assetFile.FullName.StartsWith($contentPrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
            continue
        }
        $relativePath = $assetFile.FullName.Substring($contentPrefix.Length)
        $relativeWithoutExtension = $relativePath.Substring(0, $relativePath.Length - $assetFile.Extension.Length)
        $packageName = $MountRoot.TrimEnd('/') + '/' + $relativeWithoutExtension.Replace('\', '/')
        if (-not $SeenPackages.ContainsKey($packageName)) {
            $SeenPackages[$packageName] = $true
            [void]$Manifest.Add([pscustomobject][ordered]@{
                packageName = $packageName
                filePath = $assetFile.FullName
            })
        }
    }
}

function Get-BsProjectAssetManifest {
    $manifest = New-Object System.Collections.ArrayList
    $seenPackages = @{}
    Add-BsAssetManifestRoot -ContentRoot (Join-Path $script:Context.ProjectRoot 'Content') `
        -MountRoot '/Game' -Manifest $manifest -SeenPackages $seenPackages

    $pluginsRoot = Join-Path $script:Context.ProjectRoot 'Plugins'
    if (Test-Path -LiteralPath $pluginsRoot -PathType Container) {
        foreach ($pluginDescriptor in (Get-ChildItem -LiteralPath $pluginsRoot -File -Recurse -Filter '*.uplugin')) {
            $pluginName = [System.IO.Path]::GetFileNameWithoutExtension($pluginDescriptor.Name)
            $pluginContent = Join-Path $pluginDescriptor.Directory.FullName 'Content'
            Add-BsAssetManifestRoot -ContentRoot $pluginContent -MountRoot ('/' + $pluginName) `
                -Manifest $manifest -SeenPackages $seenPackages
        }
    }

    return @($manifest | Sort-Object packageName)
}

function Invoke-BsValidate {
    $nextStepNumber = $script:StepNumber + 1
    $stepDirectory = Join-Path $script:Context.RunRoot ('Steps\{0:D2}-Validate' -f $nextStepNumber)
    $unrealLogPath = Join-Path $stepDirectory 'Unreal.log'
    $assetManifest = @(Get-BsProjectAssetManifest)
    $diskAssetFileCount = $assetManifest.Count
    $manifestPackageNames = @($assetManifest | ForEach-Object { [string]$_.packageName })
    $arguments = @(
        $script:Context.ProjectFile,
        '-run=DataValidation',
        '-IncludeOnlyOnDiskAssets',
        '-unattended',
        '-nop4',
        '-nopause',
        '-nosplash',
        '-NullRHI',
        '-NoSound',
        '-culture=en',
        '-language=en',
        '-stdout',
        '-FullStdOutLogOutput',
        '-CrashForUAT',
        '-NoLogTimes',
        ('-AbsLog=' + $unrealLogPath)
    )

    $analyzer = {
        param($output)
        $footer = [regex]::Match(
            $output,
            'Success\s*-\s*0\s+error\(s\),\s*(\d+)\s+warning\(s\)',
            [System.Text.RegularExpressions.RegexOptions]::IgnoreCase
        )

        if ((-not $footer.Success) -or
            ($output -notmatch 'Commandlet DataValidationCommandlet_\d+ finished execution \(result 0\)')) {
            return New-BsAnalysis -Status 'FAILED' -Diagnostic 'VALIDATION_COMPLETION_OR_FOOTER_MISSING' `
                -RunnerExitCode $script:ExitSemantic
        }

        $linePrefix = '^\s*(?:\[[^\]\r\n]*\]\s*)*'
        $regexOptions = [System.Text.RegularExpressions.RegexOptions]::IgnoreCase -bor
            [System.Text.RegularExpressions.RegexOptions]::Multiline
        $validationStartMatches = [regex]::Matches(
            $output,
            $linePrefix + 'LogContentValidation:\s*Display:\s*Starting to validate\s+(?<requested>\d+)\s+assets\s+\((?<associated>\d+)\s+associated objects such as actors\)\s*$',
            $regexOptions
        )
        if ($validationStartMatches.Count -ne 1) {
            return New-BsAnalysis -Status 'FAILED' -Diagnostic 'VALIDATION_REQUEST_COUNT_MISSING_OR_AMBIGUOUS' `
                -RunnerExitCode $script:ExitSemantic -Metrics @{
                    projectAssetFilesOnDisk = $diskAssetFileCount
                    requestMarkers = $validationStartMatches.Count
                }
        }

        $requestedCount = [int]$validationStartMatches[0].Groups['requested'].Value
        $associatedObjectCount = [int]$validationStartMatches[0].Groups['associated'].Value
        $assetStartMatches = [regex]::Matches(
            $output,
            $linePrefix + 'AssetCheck:\s*(?:Display:\s*)?(?<asset>.*?)\s+Validating asset\s*$',
            $regexOptions
        )
        $resultMatches = [regex]::Matches(
            $output,
            $linePrefix + 'AssetCheck:\s*(?:Display:\s*)?(?<asset>.*?)\s+(?:(?<valid>contains valid data(?:,\s*but has warnings)?\.)|(?<invalid>contains invalid data\.)|(?<unable>has no data validation\.))\s*$',
            $regexOptions
        )
        $startIdentities = @($assetStartMatches | ForEach-Object { $_.Groups['asset'].Value.Trim() })
        $resultIdentities = @($resultMatches | ForEach-Object { $_.Groups['asset'].Value.Trim() })
        $duplicateStartCount = $startIdentities.Count - @($startIdentities | Sort-Object -Unique).Count
        $duplicateResultCount = $resultIdentities.Count - @($resultIdentities | Sort-Object -Unique).Count

        $validCount = @($resultMatches | Where-Object { $_.Groups['valid'].Success }).Count
        $invalidCount = @($resultMatches | Where-Object { $_.Groups['invalid'].Success }).Count
        $unableCount = @($resultMatches | Where-Object { $_.Groups['unable'].Success }).Count
        $assetErrors = [regex]::Matches(
            $output,
            '(?:AssetCheck|LogContentValidation):\s*Error:',
            [System.Text.RegularExpressions.RegexOptions]::IgnoreCase
        ).Count
        $assetWarnings = [regex]::Matches(
            $output,
            'AssetCheck:\s*Warning:',
            [System.Text.RegularExpressions.RegexOptions]::IgnoreCase
        ).Count
        $footerWarnings = [int]$footer.Groups[1].Value
        $processedCount = $resultMatches.Count
        $missingProjectPackages = New-Object System.Collections.ArrayList
        foreach ($manifestPackageName in $manifestPackageNames) {
            $packagePattern = '^' + [regex]::Escape($manifestPackageName) + '(?:[\.:]|$)'
            if (@($startIdentities | Where-Object { $_ -match $packagePattern }).Count -eq 0) {
                [void]$missingProjectPackages.Add($manifestPackageName)
            }
        }
        $metrics = @{
            projectAssetFilesOnDisk = $diskAssetFileCount
            requestedAssets = $requestedCount
            associatedObjects = $associatedObjectCount
            validationStartLines = $assetStartMatches.Count
            resultLines = $processedCount
            duplicateStartLines = $duplicateStartCount
            duplicateResultLines = $duplicateResultCount
            missingProjectPackageCount = $missingProjectPackages.Count
            missingProjectPackages = @($missingProjectPackages | Select-Object -First 25)
            valid = $validCount
            invalid = $invalidCount
            unableToValidate = $unableCount
            assetErrors = $assetErrors
            assetWarnings = $assetWarnings
            commandletWarnings = $footerWarnings
        }

        if (($invalidCount -gt 0) -or ($unableCount -gt 0) -or ($assetErrors -gt 0)) {
            return New-BsAnalysis -Status 'FAILED' -Diagnostic 'INVALID_OR_UNVALIDATABLE_ASSETS' `
                -RunnerExitCode $script:ExitSemantic -Metrics $metrics
        }

        if ($diskAssetFileCount -eq 0) {
            if (($requestedCount -ne 0) -or ($assetStartMatches.Count -ne 0) -or ($processedCount -ne 0)) {
                return New-BsAnalysis -Status 'FAILED' -Diagnostic 'NO_PROJECT_ASSETS_BUT_VALIDATION_PROCESSED_ASSETS' `
                    -RunnerExitCode $script:ExitSemantic -Metrics $metrics
            }
            return New-BsAnalysis -Status 'SKIPPED_NO_ASSETS' -Diagnostic 'NO_PROJECT_ASSETS_UNTIL_BS_011' `
                -Metrics $metrics
        }

        if (($requestedCount -eq 0) -or
            ($assetStartMatches.Count -ne $requestedCount) -or
            ($processedCount -ne $requestedCount) -or
            ($duplicateStartCount -ne 0) -or
            ($duplicateResultCount -ne 0) -or
            ($missingProjectPackages.Count -ne 0)) {
            return New-BsAnalysis -Status 'FAILED' -Diagnostic 'PROJECT_ASSET_VALIDATION_COVERAGE_INCOMPLETE' `
                -RunnerExitCode $script:ExitSemantic -Metrics $metrics
        }

        $status = 'PASS'
        if (($assetWarnings -gt 0) -or ($footerWarnings -gt 0)) {
            $status = 'PASS_WITH_WARNINGS'
        }
        return New-BsAnalysis -Status $status -Diagnostic 'ASSETS_VALID' -Metrics $metrics
    }

    return Invoke-BsExternalStep -Name 'Validate' -FilePath $script:Context.Engine.EditorCmd `
        -ArgumentList $arguments -StepTimeoutSeconds (Get-BsTimeoutSeconds -StepName 'Validate') `
        -Analyzer $analyzer
}

function Invoke-BsCook {
    $nextStepNumber = $script:StepNumber + 1
    $stepDirectory = Join-Path $script:Context.RunRoot ('Steps\{0:D2}-Cook' -f $nextStepNumber)
    $unrealLogPath = Join-Path $stepDirectory 'Unreal.log'
    $arguments = @(
        $script:Context.ProjectFile,
        '-run=Cook',
        '-TargetPlatform=Windows',
        '-unattended',
        '-nop4',
        '-nopause',
        '-nosplash',
        '-stdout',
        '-FullStdOutLogOutput',
        '-CrashForUAT',
        '-NoLogTimes',
        '-culture=en',
        '-language=en',
        '-LogCmds=LogSavePackage Verbose',
        ('-AbsLog=' + $unrealLogPath)
    )

    $analyzer = {
        param($output)
        $linePrefix = '^\s*(?:\[[^\]\r\n]*\]\s*)*'
        $regexOptions = [System.Text.RegularExpressions.RegexOptions]::IgnoreCase -bor
            [System.Text.RegularExpressions.RegexOptions]::Multiline
        if (($output -match '(?im)^\s*(?:\[[^\]\r\n]*\]\s*)*LogInit:\s*Display:\s*Failure\s*-') -or
            ($output -match 'LogCook:\s*Error:') -or
            ($output -match 'Commandlet->Main return this error code:\s*(?!0\b)-?\d+')) {
            return New-BsAnalysis -Status 'FAILED' -Diagnostic 'COOK_REPORTED_FAILURE' `
                -RunnerExitCode $script:ExitSemantic
        }

        $successMatches = [regex]::Matches(
            $output,
            $linePrefix + 'LogInit:\s*Display:\s*Success\s*-\s*0\s+error\(s\),\s*(?<warnings>\d+)\s+warning\(s\)\s*$',
            $regexOptions
        )
        $cookDirectory = Join-Path $script:Context.ProjectRoot 'Saved\Cooked\Windows'
        if (($successMatches.Count -ne 1) -or
            ($output -notmatch '(?im)^\s*(?:\[[^\]\r\n]*\]\s*)*LogCook:\s*Display:\s*Cook by the book total time in tick') -or
            (-not (Test-Path -LiteralPath $cookDirectory -PathType Container))) {
            return New-BsAnalysis -Status 'FAILED' -Diagnostic 'COOK_SUCCESS_MARKER_OR_OUTPUT_MISSING' `
                -RunnerExitCode $script:ExitSemantic
        }

        $warningCount = [int]$successMatches[0].Groups['warnings'].Value
        $packageStatsMatches = [regex]::Matches(
            $output,
            $linePrefix + 'LogCook:\s*Display:\s*Packages Cooked:\s*(?<cooked>\d+),\s*(?:Packages Incrementally Skipped:\s*(?<incremental>\d+),\s*)?Packages Skipped by Platform:\s*(?<platform>\d+),\s*Total Packages:\s*(?<total>\d+)\s*$',
            $regexOptions
        )
        $metrics = @{
            warnings = $warningCount
            output = $cookDirectory
            packageStatsMarkers = $packageStatsMatches.Count
        }
        if ($packageStatsMatches.Count -ne 1) {
            return New-BsAnalysis -Status 'FAILED' -Diagnostic 'COOK_PACKAGE_STATS_MISSING_OR_AMBIGUOUS' `
                -RunnerExitCode $script:ExitSemantic -Metrics $metrics
        }

        $packageStats = $packageStatsMatches[0]
        $incrementallySkipped = 0
        if ($packageStats.Groups['incremental'].Success -and
            (-not [string]::IsNullOrWhiteSpace($packageStats.Groups['incremental'].Value))) {
            $incrementallySkipped = [int]$packageStats.Groups['incremental'].Value
        }
        $platformSkipped = [int]$packageStats.Groups['platform'].Value
        $metrics.packagesCooked = [int]$packageStats.Groups['cooked'].Value
        $metrics.packagesIncrementallySkipped = $incrementallySkipped
        $metrics.packagesSkippedByPlatform = $platformSkipped
        $metrics.totalPackages = [int]$packageStats.Groups['total'].Value

        $accountedPackages = $metrics.packagesCooked + $incrementallySkipped + $platformSkipped
        if (($metrics.packagesCooked -le 0) -or
            ($metrics.totalPackages -le 0) -or
            ($accountedPackages -ne $metrics.totalPackages)) {
            $metrics.accountedPackages = $accountedPackages
            return New-BsAnalysis -Status 'FAILED' -Diagnostic 'COOK_PACKAGE_STATS_INCONSISTENT' `
                -RunnerExitCode $script:ExitSemantic -Metrics $metrics
        }

        $benignSkipRecords = New-Object System.Collections.ArrayList
        $benignSkipKeys = @{}
        $benignPatterns = @(
            [pscustomobject]@{
                Reason = 'NO_EXPORTS_OR_EDITOR_ONLY'
                Regex = $linePrefix + 'LogSavePackage:\s*Verbose:\s*No exports found \(or all exports are editor-only\) for\s+(?<package>.+?)\.\s*Package will not be saved\.\s*$'
            },
            [pscustomobject]@{
                Reason = 'PACKAGE_MARKED_EDITOR_ONLY'
                Regex = $linePrefix + 'LogSavePackage:\s*Verbose:\s*Package marked as editor-only:\s*(?<package>.+?)\.\s*Package will not be saved\.\s*$'
            }
        )
        foreach ($benignPattern in $benignPatterns) {
            foreach ($match in [regex]::Matches($output, $benignPattern.Regex, $regexOptions)) {
                $packageIdentity = $match.Groups['package'].Value.Trim().Replace('\', '/')
                $key = $benignPattern.Reason + '|' + $packageIdentity
                if (-not $benignSkipKeys.ContainsKey($key)) {
                    $benignSkipKeys[$key] = $true
                    $engineOwned = $packageIdentity -match '(?i)/Saved/Cooked/Windows/Engine/'
                    [void]$benignSkipRecords.Add([pscustomobject][ordered]@{
                        reason = $benignPattern.Reason
                        package = $packageIdentity
                        engineOwned = $engineOwned
                    })
                }
            }
        }

        $rejectionPattern = $linePrefix + 'LogCook:\s*Display:\s*Cooking\s+(?<package>.+?)(?:,\s*Instigator:\s*\{.*?\})?\s*->\s*Rejected\s+(?<reason>!bCookSaveGeneratorPackage|EngineEditorContent|NotAssetManagerShouldCookForPlatform|PlatformSpecificNeverCook)\s*$'
        foreach ($match in [regex]::Matches($output, $rejectionPattern, $regexOptions)) {
            $packageIdentity = $match.Groups['package'].Value.Trim().Replace('\', '/')
            $reason = $match.Groups['reason'].Value
            $key = $reason + '|' + $packageIdentity
            if (-not $benignSkipKeys.ContainsKey($key)) {
                $benignSkipKeys[$key] = $true
                $engineOwned = ($packageIdentity -match '(?i)^/Engine(?:/|$)') -or
                    ($packageIdentity -match '(?i)/Saved/Cooked/Windows/Engine/')
                [void]$benignSkipRecords.Add([pscustomobject][ordered]@{
                    reason = $reason
                    package = $packageIdentity
                    engineOwned = $engineOwned
                })
            }
        }

        $nonEngineSkipRecords = @($benignSkipRecords | Where-Object { -not $_.engineOwned })
        $metrics.classifiedPlatformSkips = $benignSkipRecords.Count
        $metrics.nonEngineClassifiedSkips = $nonEngineSkipRecords.Count
        $metrics.classifiedSkipDetails = @($benignSkipRecords | Select-Object -First 25)
        if (($benignSkipRecords.Count -ne $platformSkipped) -or ($nonEngineSkipRecords.Count -ne 0)) {
            return New-BsAnalysis -Status 'FAILED' -Diagnostic 'COOK_PLATFORM_SKIPS_UNCLASSIFIED_OR_PROJECT_OWNED' `
                -RunnerExitCode $script:ExitSemantic -Metrics $metrics
        }

        $status = 'PASS'
        $diagnostic = 'COOKED_WINDOWS'
        if ($warningCount -gt 0) {
            $status = 'PASS_WITH_WARNINGS'
            if (($platformSkipped -gt 0) -or ($incrementallySkipped -gt 0)) {
                $diagnostic = 'COOKED_WINDOWS_WITH_WARNINGS_AND_CLASSIFIED_SKIPS'
            }
        }
        elseif (($platformSkipped -gt 0) -or ($incrementallySkipped -gt 0)) {
            $status = 'PASS_WITH_SKIPS'
            $diagnostic = 'COOKED_WINDOWS_WITH_CLASSIFIED_ENGINE_SKIPS'
        }
        return New-BsAnalysis -Status $status -Diagnostic $diagnostic `
            -Metrics $metrics
    }

    return Invoke-BsExternalStep -Name 'Cook' -FilePath $script:Context.Engine.EditorCmd `
        -ArgumentList $arguments -StepTimeoutSeconds (Get-BsTimeoutSeconds -StepName 'Cook') `
        -Analyzer $analyzer
}

function Test-BsStepSucceeded {
    param($Step)
    return ([int]$Step.runnerExitCode -eq 0)
}

function Complete-BsRun {
    param([int]$FinalExitCode)

    $statuses = @($script:RunState.steps | ForEach-Object { $_.status })
    $overallStatus = 'PASS'
    if ($FinalExitCode -ne 0) {
        $overallStatus = 'FAILED'
    }
    elseif ($PlanOnly) {
        $overallStatus = 'PLANNED'
    }
    elseif (@($statuses | Where-Object { $_ -eq 'PASS_WITH_WARNINGS' }).Count -gt 0) {
        $overallStatus = 'PASS_WITH_WARNINGS'
    }
    elseif (@($statuses | Where-Object { ($_ -like 'SKIPPED*') -or ($_ -eq 'PASS_WITH_SKIPS') }).Count -gt 0) {
        $overallStatus = 'PASS_WITH_SKIPS'
    }

    $script:RunState.status = $overallStatus
    $script:RunState.runnerExitCode = $FinalExitCode
    $script:RunState.endUtc = [DateTime]::UtcNow.ToString('o')
    Save-BsRunState

    if ($FinalExitCode -eq 0) {
        Write-BsMessage -Level 'PASS' -Message "Final result: $overallStatus"
    }
    else {
        Write-BsMessage -Level 'FAIL' -Message "Final result: FAILED (code $FinalExitCode)"
    }
    Write-BsMessage -Level 'INFO' -Message "Summary: $($script:RunJsonPath)"
}

if ($MyInvocation.InvocationName -eq '.') {
    return
}

$finalExitCode = $script:ExitPreflight
try {
    Initialize-BsContext -ExplicitEngineRoot $EngineRoot
    Write-BsMessage -Level 'INFO' -Message "Broken Streets automation — $Action"
    Write-BsMessage -Level 'INFO' -Message ("UE {0} CL {1}, source: {2}" -f $script:Context.Engine.Version,
        $script:Context.Engine.Changelist, $script:Context.Engine.Source)

    $doctor = Invoke-BsDoctor
    if (-not (Test-BsStepSucceeded -Step $doctor)) {
        $finalExitCode = [int]$doctor.runnerExitCode
    }
    else {
        $requestedSteps = @()
        if ($Action -eq 'All') {
            $requestedSteps = @('Generate', 'Build', 'Test', 'Validate', 'Cook')
        }
        elseif ($Action -in @('Test', 'Validate', 'Cook')) {
            $requestedSteps = @('Build', $Action)
        }
        elseif ($Action -ne 'Doctor') {
            $requestedSteps = @($Action)
        }

        $finalExitCode = 0
        foreach ($stepName in $requestedSteps) {
            $step = $null
            switch ($stepName) {
                'Generate' { $step = Invoke-BsGenerate }
                'Build' { $step = Invoke-BsBuild }
                'Test' { $step = Invoke-BsTest }
                'Validate' { $step = Invoke-BsValidate }
                'Cook' { $step = Invoke-BsCook }
                default { throw "Unknown internal action: $stepName" }
            }

            if (-not (Test-BsStepSucceeded -Step $step)) {
                $finalExitCode = [int]$step.runnerExitCode
                break
            }
        }
    }

    Complete-BsRun -FinalExitCode $finalExitCode
}
catch {
    $message = $_.Exception.Message
    if ($null -ne $script:RunnerLogPath) {
        [System.IO.File]::AppendAllText(
            $script:RunnerLogPath,
            (($_ | Out-String) + [Environment]::NewLine),
            $script:Utf8NoBom
        )
    }
    $failureCode = $script:ExitInternal
    $failureLabel = 'Internal error'
    if (($null -eq $script:Context) -or ($null -eq $script:Context.Engine)) {
        $failureCode = $script:ExitPreflight
        $failureLabel = 'Preflight failed'
    }
    Write-BsMessage -Level 'FAIL' -Message "${failureLabel}: $message"
    if ($null -ne $script:RunState) {
        $script:RunState.status = 'FAILED'
        $script:RunState.runnerExitCode = $failureCode
        $script:RunState.endUtc = [DateTime]::UtcNow.ToString('o')
        Save-BsRunState
    }
    $finalExitCode = $failureCode
}
finally {
    if ($null -ne $script:LockHandle) {
        $script:LockHandle.Dispose()
        $script:LockHandle = $null
    }
}

exit $finalExitCode
